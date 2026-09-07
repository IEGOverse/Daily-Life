class Topic {
  final String id;
  final String studySessionId;
  final String topic;

  const Topic({
    required this.id,
    required this.studySessionId,
    required this.topic,
  });

  Topic copyWith({String? id, String? studySessionId, String? topic}) => Topic(
    id: id ?? this.id,
    studySessionId: studySessionId ?? this.studySessionId,
    topic: topic ?? this.topic,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Topic && id == other.id;

  @override
  int get hashCode => Object.hashAll([id]);
}
