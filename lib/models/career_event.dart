enum EventType { interview, deadline, submission, reminder }

class CareerEvent {
  final String id;
  final String title;
  final DateTime date;
  final EventType type;
  final String applicationId;

  CareerEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.applicationId,
  });
}
