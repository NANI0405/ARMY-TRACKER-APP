import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Sidebar extends StatefulWidget {
  final String userRole;

  const Sidebar({required this.userRole, super.key});

  @override
  SidebarState createState() => SidebarState();
}

class SidebarState extends State<Sidebar> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'ARMY TRACKER',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          ListTile(
            title: Text('Profile', style: Theme.of(context).textTheme.bodyLarge),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            title: Text('Vehicles List', style: Theme.of(context).textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/vehicleList');
            },
          ),
          if (widget.userRole == 'Rescue Team') ...[
            ListTile(
              title: Text('Damage Reports', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.pushNamed(context, '/damageReports');
              },
            ),
          ] else ...[
            ListTile(
              title: Text('Report Damage', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                Navigator.pushNamed(context, '/reportDamage');
              },
            ),
          ],
          ListTile(
            title: Text('Map', style: Theme.of(context).textTheme.bodyLarge),
            onTap: () {
              Navigator.pushNamed(context, '/map');
            },
          ),
          ListTile(
            title: _isLoggingOut
                ? const CircularProgressIndicator()
                : const Text('Logout'),
            onTap: _isLoggingOut ? null : _logout,
          ),
        ],
      ),
    );
  }
}