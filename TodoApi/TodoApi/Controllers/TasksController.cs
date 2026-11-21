using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TodoApi.Data;
using TodoApi.Models;

namespace TodoApi.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class TasksController : ControllerBase
{
    private readonly AppDbContext _db;

    public TasksController(AppDbContext db)
    {
        _db = db;
    }

    // The id of the logged-in user, taken from the token.
    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // GET /api/tasks
    [HttpGet]
    public async Task<ActionResult<List<TaskItem>>> GetAll()
    {
        var userId = CurrentUserId;
        return await _db.Tasks
            .AsNoTracking()
            .Where(t => t.UserId == userId)
            .ToListAsync();
    }

    // GET /api/tasks/5
    [HttpGet("{id}")]
    public async Task<ActionResult<TaskItem>> GetById(int id)
    {
        var userId = CurrentUserId;
        var task = await _db.Tasks
            .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId);

        if (task == null) return NotFound();
        return task;
    }

    // POST /api/tasks
    [HttpPost]
    public async Task<ActionResult<TaskItem>> Create(TaskItem task)
    {
        task.Id = 0;                  // the database assigns the id
        task.UserId = CurrentUserId;  // the owner comes from the token, never from the request
        _db.Tasks.Add(task);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = task.Id }, task);
    }

    // PUT /api/tasks/5
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, TaskItem task)
    {
        var userId = CurrentUserId;
        var existing = await _db.Tasks
            .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId);

        if (existing == null) return NotFound();

        existing.Title = task.Title;
        existing.Description = task.Description;
        existing.Date = task.Date;
        existing.Priority = task.Priority;
        existing.IsCompleted = task.IsCompleted;

        await _db.SaveChangesAsync();
        return NoContent();
    }

    // DELETE /api/tasks/5
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var userId = CurrentUserId;
        var existing = await _db.Tasks
            .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId);

        if (existing == null) return NotFound();

        _db.Tasks.Remove(existing);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}