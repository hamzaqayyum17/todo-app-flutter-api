# Todo App: Flutter + ASP.NET Core API

A todo list mobile app built step by step: first with a local SQLite
database, then with a REST API and SQL Server.

## Features
- Add, edit, delete, and complete tasks
- Priority levels (Low, Medium, High) and due date
- Filter by All, Pending, and Done
- Two versions: offline (SQLite) and online (REST API)

## Project structure

| Folder | What it is |
|---|---|
| `TodoApi/` | ASP.NET Core Web API with EF Core and SQL Server |
| `todolistapp_api/` | Flutter app that talks to the API over HTTP |
| `todolistapp/` | Flutter app that stores data locally with SQLite |

## Tech stack
Flutter, Dart, sqflite, http, ASP.NET Core, Entity Framework Core, SQL Server

## API endpoints

| Method | URL | Description |
|---|---|---|
| GET | `/api/tasks` | Get all tasks |
| GET | `/api/tasks/{id}` | Get one task |
| POST | `/api/tasks` | Add a task |
| PUT | `/api/tasks/{id}` | Update a task |
| DELETE | `/api/tasks/{id}` | Delete a task |

## How to run

### 1. API
1. Install the .NET SDK and SQL Server (or LocalDB).
2. In `TodoApi/TodoApi/appsettings.json`, set the `Server=` value in the connection string to your server.
3. From the folder containing `TodoApi.csproj`:
   ```bash
   dotnet run --urls "http://0.0.0.0:5219"
   ```
   The database and table are created on first run.

### 2. Flutter app
1. Open `todolistapp_api/`.
2. In `lib/config.dart`, set `baseUrl` to your computer's IP, for example `http://192.168.0.101:5219`.
3. Make sure the phone and the computer are on the same Wi-Fi.
4. Run:
   ```bash
   flutter pub get
   flutter run
   ```

## Author
[HAMZA QAYYUM] · [https://github.com/hamzaqayyum17/todo-app-flutter-api]
