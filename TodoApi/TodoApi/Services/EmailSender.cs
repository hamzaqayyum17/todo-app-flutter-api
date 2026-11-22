using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace TodoApi.Services;

public interface IEmailSender
{
    Task SendAsync(string toEmail, string subject, string htmlBody);
}

public class EmailSender : IEmailSender
{
    private readonly IConfiguration _config;
    private readonly IHostEnvironment _env;
    private readonly ILogger<EmailSender> _logger;

    public EmailSender(IConfiguration config, IHostEnvironment env, ILogger<EmailSender> logger)
    {
        _config = config;
        _env = env;
        _logger = logger;
    }

    public async Task SendAsync(string toEmail, string subject, string htmlBody)
    {
        var host = _config["Smtp:Host"];
        var user = _config["Smtp:User"];
        var password = _config["Smtp:Password"];

        var configured = !string.IsNullOrWhiteSpace(host)
                         && !string.IsNullOrWhiteSpace(user)
                         && !string.IsNullOrWhiteSpace(password);

        if (!configured)
        {
            // Never silently skip sending in production.
            if (!_env.IsDevelopment())
                throw new InvalidOperationException("SMTP is not configured.");

            // Dev mode: show the email in the terminal instead of sending it.
            _logger.LogWarning(
                "DEV EMAIL (SMTP not configured) | To: {To} | Subject: {Subject} | Body: {Body}",
                toEmail, subject, htmlBody);
            return;
        }

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_config["Smtp:FromName"] ?? "Todo App", user));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = subject;
        message.Body = new BodyBuilder { HtmlBody = htmlBody }.ToMessageBody();

        var port = int.TryParse(_config["Smtp:Port"], out var p) ? p : 587;
        var security = port == 465
            ? SecureSocketOptions.SslOnConnect
            : SecureSocketOptions.StartTls;

        using var client = new SmtpClient();
        await client.ConnectAsync(host, port, security);
        await client.AuthenticateAsync(user, password);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}