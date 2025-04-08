import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:confetti/confetti.dart';  // Importer la bibliothèque de confettis
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Nicolas Adams";
  String email = "nicolasadams@gmail.com";
  File? _imageFile;

  // Déclaration de ConfettiController
  late ConfettiController _confettiController;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  int totalPagesRead = 100; // Total pages read
  int totalBookPages = 0; // Total book pages


  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();

    // Récupérez le nombre total de pages lues
    final savedTotalPagesRead = prefs.getInt('totalPagesRead') ?? 0;
    print("Total pages read from SharedPreferences: $savedTotalPagesRead");  // Log du nombre de pages lues récupérées

    // Récupérez le nombre total de pages des livres
    final savedTotalBookPages = prefs.getInt('totalBookPages') ?? 0;
    print("Total book pages from SharedPreferences: $savedTotalBookPages");  // Log du nombre total de pages des livres récupérées

    setState(() {
      totalPagesRead = savedTotalPagesRead;
      totalBookPages = savedTotalBookPages;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _nameController.text = name;
    _emailController.text = email;

    // Initialisation de ConfettiController
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    // Lancer l'animation de confettis lors de l'initialisation de la page
    Future.delayed(Duration(milliseconds: 300), () {
      _confettiController.play();  // Démarre l'animation après le délai
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Profil",
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(  // Utiliser Stack pour superposer l'animation de confettis
        children: [
          // Animation de confettis en arrière-plan
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,  // Direction de l'explosion
              particleDrag: 0.05,  // Résistance des particules
              emissionFrequency: 0.05,  // Fréquence d'émission des particules
              numberOfParticles: 20,  // Nombre de particules
              gravity: 0.1,  // Gravité des particules
              shouldLoop: true,  // Si l'animation doit boucler ou non
              blastDirection: 3.14,  // Direction des confettis
            ),
          ),

          // Le contenu de la page
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileSection(),
                  SizedBox(height: 30),
                  _buildRankSection(),
                  SizedBox(height: 30),
                  _buildStatsSection(),
                  SizedBox(height: 30),
                  _buildMenu(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section de profil avec avatar et icône d'édition
  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _imageFile == null
                ? AssetImage('Images/j.jpeg') as ImageProvider
                : FileImage(_imageFile!),
          ),
          SizedBox(width: 20),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text(email, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.amber),
            onPressed: () {
              _showEditDialog();
            },
          ),
        ],
      ),
    );
  }

  // Section Rank #X avec icône
  Widget _buildRankSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Text(
            "Rank #42",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Icon(Icons.star, color: Colors.amber),
        ],
      ),
    );
  }

  // Section Statistiques avec icônes et données
  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem(totalPagesRead.toString(), "Pages lues"),
          _statItem("45", "Livres"),
        ],
      ),
    );
  }

  // Menu avec icônes et actions
  Widget _buildMenu(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(Icons.info, "À propos", context, () {
          _showDialog(context, "À propos", "BookShelf\nVersion 1.0\nUne application pour gérer vos lectures.");
        }),
        _buildMenuItem(Icons.help, "Aide", context, () {
          _showDialog(context, "Aide", "Besoin d'aide ?\nConsultez notre site ou contactez-nous.");
        }),
        _buildMenuItem(Icons.logout, "Déconnexion", context, () {
          _showLogoutDialog(context);
        }, color: Colors.red),
      ],
    );
  }

  // Widget pour un item de statistique
  Widget _statItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // Widget pour un élément du menu
  Widget _buildMenuItem(IconData icon, String title, BuildContext context, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Afficher un dialogue pour modifier le profil
  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Modifier le profil"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nom
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Nom"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              // Image upload
              ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
                child: Text("Choisir une image"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  name = _nameController.text;
                  email = _emailController.text;
                });
                Navigator.pop(context);
              }
            },
            child: Text("Sauvegarder"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
        ],
      ),
    );
  }

  // Afficher un dialogue à propos
  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer"),
          ),
        ],
      ),
    );
  }

  // Afficher un dialogue pour la déconnexion
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Se déconnecter"),
        content: Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              // Logique de déconnexion ici
              Navigator.pop(context);
            },
            child: Text("Oui, déconnecter"),
          ),
        ],
      ),
    );
  }
}
