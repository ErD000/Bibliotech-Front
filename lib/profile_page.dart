import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';  // Importer la bibliothèque confetti
import 'Model/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Déclaration du ConfettiController
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Initialisation de ConfettiController
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    // Lancer l'animation de confettis
    Future.delayed(Duration(milliseconds: 300), () {
      _confettiController.play();  // Démarre l'animation après un délai
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();  // Nettoyage
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
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
          // Animation des confettis en arrière-plan
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,  // Direction de l'explosion
              particleDrag: 0.05,  // Résistance des particules
              emissionFrequency: 0.05,  // Fréquence des particules
              numberOfParticles: 30,  // Nombre de particules
              gravity: 0.1,  // Gravité des particules
              shouldLoop: true,  // Si l'animation doit boucler ou non
              blastDirection: 3.14,  // Direction des confettis
            ),
          ),

          // Contenu principal de la page
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
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: userItems.length,
                  itemBuilder: (context, index) {
                    final items = userItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                          right: 20, left: 20, bottom: 15),
                      child: Row(
                        children: [
                          Text(
                            items.rank,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage(items.image),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Text(
                            items.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 25,
                            width: 70,
                            decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(50)),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 5,
                                ),
                                const RotatedBox(
                                  quarterTurns: 1,
                                  child: Icon(
                                    Icons.back_hand,
                                    color: Color.fromARGB(255, 255, 187, 0),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  items.point.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.black),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }
              ),
            ),
          ),

          // Classement des utilisateurs (positionné)
          Positioned(
            top: 40,
            right: 155,
            child: rank(
                radius: 45.0,
                height: 25,
                image: "Images/e.jpeg",
                name: "Johnny Rios",
                point: "23131"),
          ),
          // Pour le 2ème rang
          Positioned(
            top: 70,
            left: 45,
            child: rank(
                radius: 30.0,
                height: 10,
                image: "Images/k.jpeg",
                name: "Hodges",
                point: "12323"),
          ),
          // Pour le 3ème rang
          Positioned(
            top: 70,
            right: 70,
            child: rank(
                radius: 30.0,
                height: 10,
                image: "Images/j.jpeg",
                name: "loram",
                point: "6343"),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher un utilisateur dans le classement
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
        SizedBox(
          height: height,
        ),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(
          height: height,
        ),
        Container(
          height: 25,
          width: 70,
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(50)),
          child: Row(
            children: [
              const SizedBox(
                width: 5,
              ),
              const Icon(
                Icons.back_hand,
                color: Color.fromARGB(255, 255, 187, 0),
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                point,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
