import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  UsersScreenState createState() => UsersScreenState();
}

class UsersScreenState extends State<UsersScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _approveUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({'isApproved': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User approved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error approving user: $e')));
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _logout();
          },
        ),
        title: const Text('Users'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').where('role', isNotEqualTo: 'Admin').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    var userData = user.data() as Map<String, dynamic>;

                    if (userData.containsKey('name') && userData.containsKey('email')) {
                      var name = userData['name'] ?? 'No Name';
                      var email = userData['email'] ?? 'No Email';
                      var isApproved = userData['isApproved'] ?? false;

                      return ListTile(
                        title: Text(name),
                        subtitle: Text(email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isApproved)
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () => _approveUser(user.id),
                              ),
                          ],
                        ),
                        tileColor: isApproved ? Colors.green[50] : Colors.red[50],
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}