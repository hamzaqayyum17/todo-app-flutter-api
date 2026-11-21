namespace TodoApi.Models;

public class User
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public bool IsEmailVerified { get; set; }
    public string? OtpHash { get; set; }
    public DateTime? OtpExpiresAt { get; set; }
    public DateTime? OtpSentAt { get; set; }
    public int OtpFailedAttempts { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}