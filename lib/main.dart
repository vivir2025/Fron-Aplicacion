import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'api/api_service.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthProvider _authProvider = AuthProvider();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated (e.g., from shared preferences)
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Here you could load the token from shared preferences
    // and set _isAuthenticated accordingly
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FNPVI App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _isAuthenticated
          ? ProfileScreen(
              authProvider: _authProvider,
              onLogout: () {
                setState(() {
                  _isAuthenticated = false;
                });
              },
            )
          : LoginScreen(
              authProvider: _authProvider,
              onLoginSuccess: () {
                setState(() {
                  _isAuthenticated = true;
                });
              },
            ),
    );
  }
}