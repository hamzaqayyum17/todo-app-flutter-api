using System.Net.Mail;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using TodoApi.Data;
using TodoApi.Dtos;
using TodoApi.Models;
using TodoApi.Services;

namespace TodoApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private const int OtpLifetimeMinutes = 10;
    private const int MaxOtpAttempts = 5;
    private const int ResendCooldownSeconds = 60;

    private readonly AppDbContext _db;
    private readonly IConfiguration _config;
    private readonly IEmailSender _email;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        AppDbContext db,
        IConfiguration config,
        IEmailSender email,
        ILogger<AuthController> logger)
    {
        _db = db;
        _config = config;
        _email = email;
        _logger = logger;
    }

    // POST /api/auth/register
    [HttpPost("register")]
    public async Task<IActionResult> Register(AuthRequest request)
    {
        var email = NormalizeEmail(request.Email);

        if (!IsValidEmail(email))
            return BadRequest("Enter a valid email address.");

        if (request.Password.Length < 8)
            return BadRequest("Password must be at least 8 characters.");

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        if (user != null && user.IsEmailVerified)
            return Conflict("This email is already registered.");

        var passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

        if (user == null)
        {
            user = new User { Email = email, PasswordHash = passwordHash };
            _db.Users.Add(user);
        }
        else
        {
            // Registered before but never verified: let them try again.
            var wait = SecondsUntilResend(user);
            if (wait > 0)
                return StatusCode(429, $"Please wait {wait} seconds before requesting a new code.");

            user.PasswordHash = passwordHash;
        }

        if (!await TrySendOtpAsync(user))
            return StatusCode(502, "Could not send the verification email. Try again later.");

        return Ok(new MessageResponse($"A verification code was sent to {email}."));
    }

    // POST /api/auth/verify-email
    [HttpPost("verify-email")]
    public async Task<ActionResult<AuthResponse>> VerifyEmail(VerifyEmailRequest request)
    {
        var email = NormalizeEmail(request.Email);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        if (user == null || user.IsEmailVerified
            || user.OtpHash == null || user.OtpExpiresAt == null)
            return BadRequest("Invalid or expired code. Request a new one.");

        if (user.OtpExpiresAt < DateTime.UtcNow)
            return BadRequest("This code has expired. Request a new one.");

        if (user.OtpFailedAttempts >= MaxOtpAttempts)
            return StatusCode(429, "Too many wrong attempts. Request a new code.");

        if (!BCrypt.Net.BCrypt.Verify(request.Code.Trim(), user.OtpHash))
        {
            user.OtpFailedAttempts++;
            await _db.SaveChangesAsync();
            return BadRequest("Incorrect code.");
        }

        user.IsEmailVerified = true;
        user.OtpHash = null;
        user.OtpExpiresAt = null;
        user.OtpSentAt = null;
        user.OtpFailedAttempts = 0;
        await _db.SaveChangesAsync();

        return new AuthResponse(CreateToken(user), user.Email);
    }

    // POST /api/auth/resend-otp
    [HttpPost("resend-otp")]
    public async Task<IActionResult> ResendOtp(EmailRequest request)
    {
        var email = NormalizeEmail(request.Email);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        // Same reply whether or not the email exists, so nobody can probe for accounts.
        var reply = new MessageResponse(
            "If this email is waiting for verification, a new code has been sent.");

        if (user == null || user.IsEmailVerified)
            return Ok(reply);

        var wait = SecondsUntilResend(user);
        if (wait > 0)
            return StatusCode(429, $"Please wait {wait} seconds before requesting a new code.");

        if (!await TrySendOtpAsync(user))
            return StatusCode(502, "Could not send the verification email. Try again later.");

        return Ok(reply);
    }

    // POST /api/auth/login
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(AuthRequest request)
    {
        var email = NormalizeEmail(request.Email);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        // Same message for "no such email" and "wrong password".
        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return Unauthorized("Invalid email or password.");

        if (!user.IsEmailVerified)
            return StatusCode(403, "Please verify your email first.");

        return new AuthResponse(CreateToken(user), user.Email);
    }

    // ---------- helpers ----------

    private async Task<bool> TrySendOtpAsync(User user)
    {
        // A uniformly random code from 000000 to 999999.
        var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");

        user.OtpHash = BCrypt.Net.BCrypt.HashPassword(code);
        user.OtpExpiresAt = DateTime.UtcNow.AddMinutes(OtpLifetimeMinutes);
        user.OtpSentAt = DateTime.UtcNow;
        user.OtpFailedAttempts = 0;
        await _db.SaveChangesAsync();

        var body = $"""
            <p>Your verification code is:</p>
            <h2 style="letter-spacing:4px">{code}</h2>
            <p>It expires in {OtpLifetimeMinutes} minutes.
            If you did not request this, you can ignore this email.</p>
            """;

        try
        {
            await _email.SendAsync(user.Email, "Your Todo App verification code", body);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send the OTP email to {Email}", user.Email);
            return false;
        }
    }

    private static int SecondsUntilResend(User user)
    {
        if (user.OtpSentAt == null) return 0;
        var left = ResendCooldownSeconds - (DateTime.UtcNow - user.OtpSentAt.Value).TotalSeconds;
        return left > 0 ? (int)Math.Ceiling(left) : 0;
    }

    // "  Hamza@Example.COM " -> "hamza@example.com"
    private static string NormalizeEmail(string email) =>
        email.Trim().ToLowerInvariant();

    private static bool IsValidEmail(string email)
    {
        if (email.Length == 0 || email.Length > 254) return false;
        try
        {
            var address = new MailAddress(email);
            return address.Address == email;
        }
        catch (FormatException)
        {
            return false;
        }
    }

    private string CreateToken(User user)
    {
        var keyText = _config["Jwt:Key"]
            ?? throw new InvalidOperationException("Jwt:Key is missing. Check your user secrets.");

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(keyText));

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email)
            }),
            Issuer = _config["Jwt:Issuer"],
            Audience = _config["Jwt:Audience"],
            Expires = DateTime.UtcNow.AddDays(7),
            SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
        };

        return new JsonWebTokenHandler().CreateToken(descriptor);
    }
}