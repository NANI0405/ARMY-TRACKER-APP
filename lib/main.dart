import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'login.dart';
import 'vehicle_list.dart';
import 'vehicle_details.dart';
import 'report_damage.dart';
import 'profile.dart';
import 'map.dart';
import 'edit_vehicle.dart';
import 'add_vehicle.dart';
import 'firebase_options.dart';
import 'sign_up.dart';
import 'damage_reports.dart';
import 'role_provider.dart';
import 'users.dart';
import 'dart:async';
import 'theme.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  _setupLogging();
  
  runApp(const MyApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (record.level >= Level.SEVERE) {
    }
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String initialRoute = '/login';
  String userRole = 'Ops Team';
  final Logger _logger = Logger('MyApp');

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          String role = userDoc['role'];
          setState(() {
            userRole = role;
            if (role == 'Rescue Team') {
              initialRoute = '/map';
            } else if (role == 'Ops Team') {
              initialRoute = '/vehicleList';
            } else if (role == 'Admin') {
              initialRoute = '/users';
            }
          });
        }
      }
    } catch (e) {
      _logger.severe('Error checking user role', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleProvider(
      userRole: userRole,
      updateRole: (String newRole) {
        setState(() {
          userRole = newRole;
        });
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Army Tracker',
        theme: AppTheme.lightTheme,
        initialRoute: initialRoute,
        navigatorObservers: [routeObserver],
        routes: {
          '/login': (context) => const LoginScreen(),
          '/vehicleList': (context) => const VehicleListScreen(),
          '/vehicleDetails': (context) => const VehicleDetailsScreen(),
          '/reportDamage': (context) => const ReportDamageScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/map': (context) => const MapScreen(),
          '/addVehicle': (context) => const AddVehicleScreen(),
          '/signUp': (context) => const SignUpScreen(),
          '/damageReports': (context) => const DamageReportsScreen(),
          '/users': (context) => const UsersScreen()
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/editVehicleDetails') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) {
                return EditVehicleDetailsScreen(
                  vehicleId: args['vehicleId'],
                  status: args['status'],
                  location: args['location'],
                  details: args['details'],
                  crew: args['crew'],
                );
              },
            );
          }
          return null;
        },
      ),
    );
  }
}