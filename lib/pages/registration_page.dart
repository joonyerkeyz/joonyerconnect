import 'package:flutter/material.dart';
import 'package:minimal/pages/home_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  bool _validateInputs() {
    if (nameController.text.trim().isEmpty ||
        surnameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: ListView(
        children:
            // mainAxisAlignment: MainAxisAlignment.center,
            [
          Container(
            height: 250,
            width: 250,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/logo.png'),
              ),
            ),
          ),
          const Center(
            child: Text("Let's create an account for you",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              controller: surnameController,
              decoration: const InputDecoration(
                labelText: 'Surname',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_validateInputs()) {
                        setState(() {
                          _isLoading = true;
                        });
                        context
                            .read<AuthService>()
                            .signUp(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                              name: nameController.text.trim(),
                              surname: surnameController.text.trim(),
                            )
                            .then((_) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomePage()),
                          );
                        }).catchError((error) {
                          setState(() {
                            _isLoading = false;
                          });
                          if (error is FirebaseAuthException) {
                            if (error.code == 'email-already-in-use') {
                              _showErrorDialog(
                                  'The account already exists for that email.');
                            } else {
                              _showErrorDialog(error.message ??
                                  'An error occurred during registration.');
                            }
                          } else {
                            _showErrorDialog(error.toString());
                          }
                        });
                      }
                    },
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Register'),
            ),
          ),
          const SizedBox(
            height:100
          ),
        ],
      ),
    );
  }
}
