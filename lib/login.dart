import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'sign_up.dart';
import 'role_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String? _errorMessage;

  final Logger _logger = Logger('LoginScreen');

  LoginScreenState() {
    hierarchicalLoggingEnabled = true;
    _logger.level = Level.ALL;
    _logger.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  Future<void> _signIn() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          _logger.info('User document: ${userDoc.data()}');
          String role = userDoc['role'];
          _logger.info('User role: $role');

          if (role != 'Admin' && !user.emailVerified) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Please verify your email before logging in.';
              });
            }
            await _auth.signOut();
            return;
          }

          if (role != 'Admin' && !(userDoc['isApproved'] as bool)) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Your account has not been approved by the admin.';
              });
            }
            await _auth.signOut();
            return;
          }

          if (mounted) {
            RoleProvider.of(context)?.updateRole(role);
            if (role == 'Rescue Team') {
              Navigator.pushReplacementNamed(context, '/map');
            } else if (role == 'Ops Team') {
              Navigator.pushReplacementNamed(context, '/vehicleList');
            } else if (role == 'Admin') {
              Navigator.pushReplacementNamed(context, '/users');
            } else {
              setState(() {
                _errorMessage = 'Invalid role';
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'User role not found';
            });
          }
        }
      }
    } on FirebaseAuthException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid email/password';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign-in failed: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email')),
        );
      }
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } on FirebaseAuthException catch (e) {
      _logger.severe('Password reset failed: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset failed: ${e.message}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(),
                        onPressed: _signIn,
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpScreen()),
                              );
                            },
                            child: const Text('Create an Account'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(),
                            onPressed: _resetPassword,
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}