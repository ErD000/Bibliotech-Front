import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginScreen.dart';
import 'package:http/http.dart' as http;


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String email = "";
  File? _imageFile;

  late ConfettiController _confettiController;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  int totalPagesRead = 100;
  int totalBookPages = 0;

  int rank = 0;     // Ajouté
  int points = 0;   // Ajouté

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTotalPagesRead = prefs.getInt('totalPagesRead') ?? 0;
    final savedTotalBookPages = prefs.getInt('totalBookPages') ?? 0;

    print("Total pages read from SharedPreferences: $savedTotalPagesRead");
    print("Total book pages from SharedPreferences: $savedTotalBookPages");

    setState(() {
      totalPagesRead = savedTotalPagesRead;
      totalBookPages = savedTotalBookPages;
    });
  }

  Future<void> _loadUserFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      print('[ERREUR] Aucun token trouvé.');
      return;
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) throw FormatException("Format JWT invalide");

      final payload = utf8.decode(base64.decode(base64.normalize(parts[1])));
      final data = jsonDecode(payload);

      setState(() {
        name = data['user'] ?? name;
        email = data['email'] ?? email;
        rank = data['rank'] ?? 0;       // Ajouté
        points = data['points'] ?? 0;   // Ajouté
      });

      print('[INFO] Utilisateur chargé depuis le token : $name, $email, Rank: $rank, Points: $points');
    } catch (e) {
      print('[ERREUR] Impossible de décoder le token : $e');
    }
  }
  Future<bool> _updateUsername(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://10.0.6.2:3000/api/update_username'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'username': newName}),
    );

    return response.statusCode == 200;
  }

  Future<bool> _updateEmail(String newEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://10.0.6.2:3000/api/update_email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': newEmail}),
    );

    return response.statusCode == 200;
  }

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadUserFromToken();
    _nameController.text = name;
    _emailController.text = email;

    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    Future.delayed(Duration(milliseconds: 300), () {
      _confettiController.play();
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
      body: Stack(
        children: [
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: true,
              blastDirection: 3.14,
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileSection(),
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

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(totalPagesRead.toString(), "Pages lues"),
          _statItem(points.toString(), "Points"),       // Ajouté
          _statItem(rank.toString(), "Rang"),           // Ajouté
        ],
      ),
    );
  }

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

  Widget _buildMenuItem(IconData icon, String title, BuildContext context, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showEditDialog() {
    _nameController.text = name;   // Remettre les valeurs actuelles à chaque ouverture
    _emailController.text = email;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Modifier le profil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nom"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            SizedBox(height: 10),
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
        actions: [
          TextButton(
            onPressed: () async {
              final newName = _nameController.text.trim();
              final newEmail = _emailController.text.trim();

              bool hasChanges = false;

              if (newName.isNotEmpty && newName != name) {
                final success = await _updateUsername(newName);
                if (success) {
                  // ✅ Nom mis à jour avec succès côté serveur
                  setState(() {
                    name = newName;
                  });
                  hasChanges = true;
                } else {
                  // ❌ Échec de la mise à jour du nom côté serveur
                  print('[ERREUR] Échec mise à jour du nom');
                }
              }

              if (newEmail.isNotEmpty && newEmail != email) {
                final success = await _updateEmail(newEmail);
                if (success) {
                  // ✅ Email mis à jour avec succès côté serveur
                  setState(() {
                    email = newEmail;
                  });
                  hasChanges = true;
                } else {
                  // ❌ Échec de la mise à jour de l’email côté serveur
                  print('[ERREUR] Échec mise à jour de l\'email');
                }
              }

              if (hasChanges) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profil mis à jour')),
                );
              }

              Navigator.pop(context);
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
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Supprimer le token et autres données

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
              );
            },
            child: Text("Oui, déconnecter"),
          ),
        ],
      ),
    );
  }
}
