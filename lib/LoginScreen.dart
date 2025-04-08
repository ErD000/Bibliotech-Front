import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import './RegisterScreen.dart';
import './book_utils.dart';

class LoginScreen extends StatefulWidget {

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Couleur de fond sombre
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la page
            Text(
              'Bienvenue sur BookShelf',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Connectez-vous pour continuer',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            // Champ Email
            TextField(
              controller: _emailController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Adresse e-mail',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.email, color: Colors.white70),
              ),
            ),
            SizedBox(height: 20),
            // Champ Mot de passe
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.lock, color: Colors.white70),
              ),
            ),
            SizedBox(height: 30),
            // Bouton Connexion
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _login,
                child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

              ),
            ),

            SizedBox(height: 20),
            // Bouton Mot de passe oublié
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                  print('Mot de passe oublié');
                },
                child: Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
            // Bouton Mot de passe oublié
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Registerscreen()),
                  );
                  print('Créer un compte');
                },
                child: Text(
                  'Créer un compte',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBooksForUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('[ERREUR] Token non disponible. Veuillez vous connecter.');
      return;
    }

    // Appel à la méthode loadUserBooks
    final books = await loadUserBooks(token);
    setState(() {
      print('[INFO] Livres chargés pour l\'utilisateur : $books');
    });
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      print('[DEBUG] Les champs email et mot de passe sont vides.');
      return;
    }

    try {
      final uri = Uri.parse('http://10.0.6.2:3000/api/login_users');
      print('[DEBUG] Envoi de la requête à $uri');

      final response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(Duration(seconds: 10));

      print('[DEBUG] Réponse reçue avec le statut : ${response.statusCode}');
      print('[DEBUG] Corps de la réponse : ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('[DEBUG] Corps décodé : $data');

        if (data['success'] == true) {
          final token = data['token'];
          print('[DEBUG] Connexion réussie. Token : $token');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);

          if (context.mounted) {
            await _loadBooksForUser();
            Navigator.pushReplacementNamed(context, '/bookList');
          }
        } else {
          print('[DEBUG] Échec de l\'authentification : ${data['message']}');
        }
      } else {
        print('[DEBUG] Erreur serveur : ${response.statusCode} ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      print('[ERREUR] Problème réseau : $e');
    } on TimeoutException {
      print('[ERREUR] Temps d\'attente dépassé lors de la connexion au serveur.');
    } catch (e) {
      print('[ERREUR] Erreur inconnue : $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('[DEBUG] Chargement terminé.');
    }
  }


}

