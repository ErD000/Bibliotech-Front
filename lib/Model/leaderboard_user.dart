class LeaderboardUser {
  final String firstName;
  final int points;
  final int rank;
  final int pageRead;
  final int charRead;
  final String userUuid;

  LeaderboardUser({
    required this.firstName,
    required this.points,
    required this.rank,
    required this.pageRead,
    required this.charRead,
    required this.userUuid,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      firstName: json['first_name'] ?? 'Inconnu',
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      rank: int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      pageRead: int.tryParse(json['page_read']?.toString() ?? '0') ?? 0,
      charRead: int.tryParse(json['char_read']?.toString() ?? '0') ?? 0,
      userUuid: json['user_uuid'] ?? '',
    );
  }
}
