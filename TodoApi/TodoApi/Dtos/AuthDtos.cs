namespace TodoApi.Dtos;

public class AuthRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public record AuthResponse(string Token, string Email);