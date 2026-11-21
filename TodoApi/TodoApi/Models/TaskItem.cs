namespace TodoApi.Models;

public class TaskItem
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public int Priority { get; set; } = 2;   // 1 = Low, 2 = Medium, 3 = High
    public bool IsCompleted { get; set; }
}