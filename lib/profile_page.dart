import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'Model/leaderboard_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ConfettiController _confettiController;
  List<LeaderboardUser> leaderboardUsers = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    Future.delayed(const Duration(milliseconds: 300), () {
      _confettiController.play();
    });
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    final response = await http.get(Uri.parse('http://10.0.6.2:3000/api/scoreboard/get_leaderboard'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> data = jsonData['leaderboard'];

      setState(() {
        leaderboardUsers = data.map((e) => LeaderboardUser.fromJson(e)).toList();
      });
    } else {
      debugPrint('Erreur de chargement: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              shouldLoop: true,
              blastDirection: 3.14,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height / 1.9,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: leaderboardUsers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: leaderboardUsers.length,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemBuilder: (context, index) {
                  final user = leaderboardUsers[index];
                  return _leaderboardRow(user);
                },
              ),
            ),
          ),
          if (leaderboardUsers.length >= 3) ...[
            _podiumItem(
              top: 40,
              right: 155,
              radius: 46,
              user: leaderboardUsers[0],
              color: Colors.amber,
            ),
            _podiumItem(
              top: 70,
              left: 45,
              radius: 34,
              user: leaderboardUsers[1],
              color: Colors.grey,
            ),
            _podiumItem(
              top: 70,
              right: 70,
              radius: 34,
              user: leaderboardUsers[2],
              color: const Color(0xffcd7f32),
            ),
          ]
        ],
      ),
    );
  }

  Widget _leaderboardRow(LeaderboardUser user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('${user.rank}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          CircleAvatar(
            radius: 18,
            backgroundImage: user.userUuid.isNotEmpty
                ? NetworkImage('http://10.0.6.2:3000/user-pictures/${user.userUuid}/profile_picture.webp')
                : null,
            child: user.userUuid.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              user.firstName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              children: [
                const RotatedBox(
                  quarterTurns: 1,
                  child: Icon(Icons.back_hand, size: 14, color: Color.fromARGB(255, 255, 187, 0)),
                ),
                const SizedBox(width: 5),
                Text('${user.points}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Positioned _podiumItem({
    required double top,
    double? left,
    double? right,
    required double radius,
    required LeaderboardUser user,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Column(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundImage: user.userUuid.isNotEmpty
                ? NetworkImage('http://10.0.6.2:3000/user-pictures/${user.userUuid}/profile_picture.webp')
                : null,
            child: user.userUuid.isEmpty ? const Icon(Icons.person, size: 32, color: Colors.white) : null,
            backgroundColor: color.withOpacity(0.2),
          ),
          const SizedBox(height: 6),
          Text(
            user.firstName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Container(
            height: 25,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.back_hand, size: 14, color: Color.fromARGB(255, 255, 187, 0)),
                const SizedBox(width: 5),
                Text(
                  '${user.points}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
