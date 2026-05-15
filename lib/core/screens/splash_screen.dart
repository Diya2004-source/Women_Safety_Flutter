import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'login.dart';
import '/admin/navigation/admin_router.dart';

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final staySignedIn = prefs.getBool('staySignedIn') ?? false;
      final isAdmin = prefs.getBool('isAdmin') ?? false;
      final user = FirebaseAuth.instance.currentUser;

      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      final navigator = Navigator.of(context);

      if (user != null && staySignedIn) {
        // Check if user is admin (either from SharedPreferences or Firestore)
        if (isAdmin) {
          navigator.pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminRouter()),
          );
        } else {
          // Check if user is admin in Firestore with timeout
          try {
            final adminDoc = await FirebaseFirestore.instance
                .collection('admins')
                .doc(user.uid)
                .get()
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () =>
                      throw TimeoutException('Firestore query timeout'),
                );

            if (adminDoc.exists) {
              if (!mounted) return;
              navigator.pushReplacement(
                MaterialPageRoute(builder: (context) => const AdminRouter()),
              );
            } else {
              if (!mounted) return;
              navigator.pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          } catch (e) {
            // If Firestore query fails, treat as non-admin user
            if (!mounted) return;
            navigator.pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      } else {
        if (user != null && !staySignedIn) {
          try {
            await FirebaseAuth.instance.signOut();
            // Clear admin status when signing out
            await prefs.setBool('isAdmin', false);
          } catch (e) {
            // Continue even if sign out fails
          }
          if (!mounted) return;
        }
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      // Fallback to login screen if anything goes wrong
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F5),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Image
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if image fails to load
                            return Container(
                              color: Colors.pink.shade50,
                              child: Icon(
                                Icons.shield_outlined,
                                size: 80,
                                color: Colors.pink.shade400,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // App Name
                    Text(
                      'SafeGuard',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade700,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Women Safety App',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Loading Indicator
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.pink.shade400),
                      backgroundColor: Colors.pink.shade100,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
