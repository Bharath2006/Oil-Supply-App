import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Auth/login.dart';
import 'Auth/register_screen.dart';
import 'admin/admin_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'firebase_config.dart';
import 'home/home_screen.dart';
import 'order/order_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bunskcy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primarySwatch: Colors.green,

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user == null) return const LoginScreen();

            return FutureBuilder<bool>(
              future: _isAdmin(user),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.done) {
                  return adminSnapshot.data == true
                      ? const AdminScreen()
                      : const HomeScreen();
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/order': (context) => const OrderScreen(),
        '/admin': (context) => const AdminScreen(),
      },
    );
  }

  Future<bool> _isAdmin(User user) async {
    final idToken = await user.getIdTokenResult();
    return idToken.claims?['admin'] == true;
  }
}
