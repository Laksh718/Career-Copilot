class RequiredDocument {
  final String name;
  final bool isCompleted;

  RequiredDocument({
    required this.name,
    this.isCompleted = false,
  });

  RequiredDocument copyWith({
    String? name,
    bool? isCompleted,
  }) {
    return RequiredDocument(
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isCompleted': isCompleted,
    };
  }

  factory RequiredDocument.fromJson(Map<String, dynamic> json) {
    return RequiredDocument(
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
