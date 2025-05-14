import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:convert';
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
    Future.delayed(Duration(milliseconds: 300), () {
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
        leaderboardUsers = data.map((json) => LeaderboardUser.fromJson(json)).toList();
      });
    } else {
      print("Erreur de chargement: ${response.statusCode}");
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
        iconTheme: IconThemeData(color: Colors.white),
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
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: leaderboardUsers.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: leaderboardUsers.length,
                itemBuilder: (context, index) {
                  final user = leaderboardUsers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          "${user.rank}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 15),
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: AssetImage("Images/default_avatar.png"),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            user.firstName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            children: [
                              const RotatedBox(
                                quarterTurns: 1,
                                child: Icon(
                                  Icons.back_hand,
                                  size: 14,
                                  color: Color.fromARGB(255, 255, 187, 0),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${user.points}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (leaderboardUsers.length >= 3) ...[
            Positioned(
              top: 40,
              right: 155,
              child: rank(
                radius: 45.0,
                height: 25,
                image: "Images/e.jpeg",
                name: leaderboardUsers[0].firstName,
                point: "${leaderboardUsers[0].points}",
              ),
            ),
            Positioned(
              top: 70,
              left: 45,
              child: rank(
                radius: 30.0,
                height: 10,
                image: "Images/k.jpeg",
                name: leaderboardUsers[1].firstName,
                point: "${leaderboardUsers[1].points}",
              ),
            ),
            Positioned(
              top: 70,
              right: 70,
              child: rank(
                radius: 30.0,
                height: 10,
                image: "Images/j.jpeg",
                name: leaderboardUsers[2].firstName,
                point: "${leaderboardUsers[2].points}",
              ),
            ),
          ]
        ],
      ),
    );
  }

  Column rank({
    required double radius,
    required double height,
    required String image,
    required String name,
    required String point,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: AssetImage(image),
        ),
        SizedBox(height: height),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: height),
        Container(
          height: 25,
          width: 70,
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(50)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.back_hand,
                size: 14,
                color: Color.fromARGB(255, 255, 187, 0),
              ),
              const SizedBox(width: 5),
              Text(
                point,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
