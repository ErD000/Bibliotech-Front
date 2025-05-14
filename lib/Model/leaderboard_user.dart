class LeaderboardUser {
  final String firstName;
  final int points;
  final int rank;
  final int pageRead;
  final int charRead;

  LeaderboardUser({
    required this.firstName,
    required this.points,
    required this.rank,
    required this.pageRead,
    required this.charRead,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      firstName: json['first_name'],
      points: json['points'],
      rank: json['rank'],
      pageRead: json['page_read'],
      charRead: json['char_read'],
    );
  }
}
