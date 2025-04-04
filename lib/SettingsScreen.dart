import 'package:flutter/material.dart';
import './LoginScreen.dart';

class SettingsScreen extends StatelessWidget {
  final Function toggleTheme; // Cette fonction modifie le thème

  SettingsScreen({required this.toggleTheme}); // Le constructeur reçoit la fonction

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Paramètres',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.info, color: Colors.blue),
            title: Text('À propos'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('À propos'),
                  content: Text('BookShelf\nVersion 1.0\nUne application pour gérer vos lectures.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.help_outline, color: Colors.green),
            title: Text('Aide'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Aide'),
                  content: Text('Besoin d\'aide ?\nConsultez notre site ou contactez-nous.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.brightness_6, color: Colors.yellow),
            title: Text('Changer de thème'),
            onTap: () {
              toggleTheme();  // Appel de la fonction pour changer le thème
              Navigator.pop(context); // Retour à l'écran précédent
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Se déconnecter'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Se déconnecter'),
                  content: Text(
                    'Voulez-vous vraiment vous déconnecter ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text('Déconnecter'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
