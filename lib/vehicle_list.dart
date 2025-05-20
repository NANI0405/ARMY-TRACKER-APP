import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'add_vehicle.dart';
import 'sidebar.dart';
import 'role_provider.dart';
import 'main.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  VehicleListScreenState createState() => VehicleListScreenState();
}

class VehicleListScreenState extends State<VehicleListScreen> with RouteAware {
  late Future<List<Map<String, dynamic>>> _vehicles;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Logger _logger = Logger('VehicleListScreen');

  @override
  void initState() {
    super.initState();
    _vehicles = _getVehicles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _vehicles = _getVehicles();
    });
  }

  Future<List<Map<String, dynamic>>> _getVehicles() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .orderBy('vehicleId')
          .get();
      return snapshot.docs.map((doc) => {'documentId': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      _logger.severe('Error fetching vehicles: $e');
      rethrow;
    }
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    try {
      _logger.info('Attempting to find and delete vehicle with vehicleId: $vehicleId');
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String documentId = querySnapshot.docs.first.id;
        _logger.info('Found vehicle document with ID: $documentId');
        await FirebaseFirestore.instance.collection('vehicles').doc(documentId).delete();
        _logger.info('Vehicle with ID $documentId deleted successfully');
        if (mounted) {
          setState(() {
            _vehicles = _getVehicles();
          });
        }
      } else {
        _logger.warning('No vehicle found with vehicleId: $vehicleId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No vehicle found with vehicleId: $vehicleId')),
          );
        }
      }
    } catch (e) {
      _logger.severe('Error deleting vehicle with vehicleId $vehicleId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting vehicle: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = RoleProvider.of(context);
    final userRole = roleProvider?.userRole ?? 'Ops Team';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('VEHICLES LIST'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddVehicleScreen(),
                ),
              ).then((_) {
                if (mounted) {
                  setState(() {
                    _vehicles = _getVehicles();
                  });
                }
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            height: 4.0,
          ),
        ),
      ),
      drawer: Sidebar(userRole: userRole),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _vehicles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No vehicles available.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final vehicle = snapshot.data![index];
                return ListTile(
                  title: Text('Vehicle ID: ${vehicle['vehicleId']}', style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text('Status: ${vehicle['status']}', style: Theme.of(context).textTheme.bodyMedium),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Vehicle'),
                            content: const Text('Are you sure you want to delete this vehicle?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _deleteVehicle(vehicle['vehicleId']);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                            backgroundColor: Colors.white,
                          );
                        },
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/vehicleDetails',
                      arguments: vehicle['vehicleId'],
                    ).then((value) {
                      if (value == true) {
                        setState(() {
                          _vehicles = _getVehicles();
                        });
                      }
                    });
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}