import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      _showErrorDialog("Passwords do not match.");
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // After signing up, switch to login mode and show success message
      setState(() {
        _isSignUp = false;
      });
      _showErrorDialog("Account created successfully! Please log in.");
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushNamed(context, '/board');
      // Navigate to the game
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? "Sign Up" : "Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            if (_isSignUp)
              TextField(
                controller: _confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
                obscureText: true,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSignUp ? _signUp : _signIn,
              child: Text(_isSignUp ? "Sign Up" : "Login"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                });
              },
              child: Text(
                _isSignUp
                    ? "Already have an account? Log in"
                    : "Don't have an account? Sign up",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
