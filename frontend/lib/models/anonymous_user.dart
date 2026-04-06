class AnonymousUser {
  const AnonymousUser({
    required this.anonymousUserId,
    required this.createdAt,
    this.source = 'local',
  });

  final String anonymousUserId;
  final DateTime createdAt;
  final String source;

  AnonymousUser copyWith({
    String? anonymousUserId,
    DateTime? createdAt,
    String? source,
  }) {
    return AnonymousUser(
      anonymousUserId: anonymousUserId ?? this.anonymousUserId,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
    );
  }
}
