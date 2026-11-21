using System.Net.Mail;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using TodoApi.Data;
using TodoApi.Dtos;
using TodoApi.Models;

namespace TodoApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IConfiguration _config;

    public AuthController(AppDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    // POST /api/auth/register
    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(AuthRequest request)
    {
        var email = NormalizeEmail(request.Email);

        if (!IsValidEmail(email))
            return BadRequest("Enter a valid email address.");

        if (request.Password.Length < 8)
            return BadRequest("Password must be at least 8 characters.");

        if (await _db.Users.AnyAsync(u => u.Email == email))
            return Conflict("This email is already registered.");

        var user = new User
        {
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            IsEmailVerified = true // TEMPORARY: replaced by the OTP check in Step 3
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return new AuthResponse(CreateToken(user), user.Email);
    }

    // POST /api/auth/login
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(AuthRequest request)
    {
        var email = NormalizeEmail(request.Email);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        // Same message for "no such email" and "wrong password",
        // so nobody can find out which emails are registered.
        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return Unauthorized("Invalid email or password.");

        return new AuthResponse(CreateToken(user), user.Email);
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