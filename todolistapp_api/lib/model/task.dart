class Task {
  int? id;
  String title;
  String description;
  DateTime date;
  int priority;
  bool isCompleted;

  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.priority = 2,
    this.isCompleted = false,
  });
  // Task -> JSON (sent to the API)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'priority': priority,
      'isCompleted': isCompleted,
    };
  }

  // JSON (from the API) -> Task
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: (json['description'] ?? '') as String,
      date: DateTime.parse(json['date'] as String),
      priority: json['priority'] as int,
      isCompleted: json['isCompleted'] as bool,
    );
  }
  String get priorityText {
    switch (priority) {
      case 1:
        return 'Low';
      case 3:
        return 'High';
      default:
        return 'Medium';
    }
  }

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}';
  }
}
