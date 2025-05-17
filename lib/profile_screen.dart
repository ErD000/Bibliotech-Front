import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginScreen.dart';
import 'package:http/http.dart' as http;

// Couleurs modernes - harmonisées avec ton thème SaaS
const Color primaryColor = Color(0xFF2563EB);
const Color secondaryColor = Color(0xFF1E293B);
const Color accentColor = Color(0xFFF97316);
const Color lightBgColor = Color(0xFFF8FAFC);
const Color cardBgColor = Color(0xFFFFFFFF);

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String email = "";
  File? _imageFile;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  int totalPagesRead = 100;
  int totalBookPages = 0;
  int rank = 0;
  int points = 0;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadUserFromToken();
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalPagesRead = prefs.getInt('totalPagesRead') ?? 0;
      totalBookPages = prefs.getInt('totalBookPages') ?? 0;
    });
  }

  Future<void> _loadUserFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final parts = token.split('.');
      if (parts.length != 3) throw FormatException("Format JWT invalide");
      final payload = utf8.decode(base64.decode(base64.normalize(parts[1])));
      final data = jsonDecode(payload);

      setState(() {
        name = data['user'] ?? "";
        email = data['email'] ?? "";
        rank = data['rank'] ?? 0;
        points = data['points'] ?? 0;
        _nameController.text = name;
        _emailController.text = email;
      });
    } catch (e) {
      print('[ERREUR] Décodage token : $e');
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.account_circle_rounded, size: 28, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Profil',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            _buildProfileCard(),
            SizedBox(height: 30),
            _buildStatsCard(),
            SizedBox(height: 30),
            _buildMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _imageFile == null
                ? AssetImage('Images/j.jpeg')
                : FileImage(_imageFile!) as ImageProvider,
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Utilisateur' : name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  email.isEmpty ? 'Email non défini' : email,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: accentColor, size: 28),
            tooltip: 'Modifier le profil',
            onPressed: _showEditDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(totalPagesRead.toString(), "Pages lues"),
          _statItem(points.toString(), "Points"),
          _statItem(rank.toString(), "Rang"),
        ],
      ),
    );
  }

  Widget _statItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: secondaryColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu() {
    return Column(
      children: [
        _buildMenuItem(Icons.info_outline, "À propos", () {
          _showDialog("À propos", "BookShelf\nVersion 1.0\nUne application pour gérer vos lectures.");
        }),
        _buildMenuItem(Icons.help_outline, "Aide", () {
          _showDialog("Aide", "Besoin d'aide ? Consultez notre site ou contactez-nous.");
        }),
        _buildMenuItem(Icons.logout, "Déconnexion", _showLogoutDialog, color: Colors.redAccent),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final iconColor = color ?? secondaryColor;
    final textColor = color ?? secondaryColor;
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showEditDialog() {
    _nameController.text = name;
    _emailController.text = email;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Modifier le profil", style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nom",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
                icon: Icon(Icons.image),
                label: Text("Choisir une image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: TextStyle(color: secondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = _nameController.text.trim();
              final newEmail = _emailController.text.trim();
              bool hasChanges = false;

              if (newName.isNotEmpty && newName != name) {
                if (await _updateUsername(newName)) {
                  setState(() => name = newName);
                  hasChanges = true;
                } else {
                  _showSnackBar('Erreur lors de la mise à jour du nom');
                }
              }

              if (newEmail.isNotEmpty && newEmail != email) {
                if (await _updateEmail(newEmail)) {
                  setState(() => email = newEmail);
                  hasChanges = true;
                } else {
                  _showSnackBar('Erreur lors de la mise à jour de l\'email');
                }
              }

              if (hasChanges) {
                _showSnackBar('Profil mis à jour avec succès');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            child: Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion', style: TextStyle(color: secondaryColor)),
        content: Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
            child: Text('Déconnexion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          )
        ],
      ),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: secondaryColor)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
