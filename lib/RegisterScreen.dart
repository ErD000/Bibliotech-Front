import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import './LoginScreen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Registerscreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<Registerscreen> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordverifController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();

  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Couleur de fond sombre
      body: SingleChildScrollView(
      child:Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la page
            SizedBox(height: 40),
            Text(
              'Créez un compte gratuitement',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Connexion requise pour accéder à nos services',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            //name field
            TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Prénom',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.person, color: Colors.white70),
              ),
            ),
            SizedBox(height: 20),
            // last name field

            TextField(
              controller: _lastnameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nom',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.person, color: Colors.white70),
              ),
            ),
            SizedBox(height: 20),
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
            SizedBox(height: 20),
            TextField(
              controller: _passwordverifController,
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirmer votre mot de passe',
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
            // Bouton de création de compte
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
                onPressed: _createAccount,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Créer mon compte',
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
                  print('Menu de connexion');
                },
                child: Text(
                  'Retour au menu de connexion',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
  Future<void> _createAccount() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String password_verif = _passwordverifController.text.trim();
    final String firstName = _nameController.text.trim();
    final String lastName = _lastnameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    if (email.isEmpty || password.isEmpty || lastName.isEmpty || firstName.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      print('[DEBUG] Les champs email et mot de passe sont vides.');
      return;
    }
    else if(password != password_verif){
      setState(() {
        _isLoading = false;
      });
      print('[DEBUG] Les mots de passes ne sont pas identiques');
      return;
    }

    try {
      // Adresse mise à jour : utilisez l'adresse IP locale de votre machine
      final uri = Uri.parse('http://10.0.6.2:3000/api/register_users');
      print('[DEBUG] Envoi de la requête à $uri');

      final response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password':password,
        }),
      )
          .timeout(Duration(seconds: 10));

      print('[DEBUG] Réponse reçue avec le statut : ${response.statusCode}');
      print('[DEBUG] Corps de la réponse : ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('[DEBUG] Corps décodé : $data');

        if (data['success'] == true) {

          print('Compte a été crée avec succès');
          // Affiche une boîte de dialogue pour informer l'utilisateur
          Fluttertoast.showToast(
            msg: "Votre compte a été créé avec succès !",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          Navigator.pushReplacementNamed(context, '/login');

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

