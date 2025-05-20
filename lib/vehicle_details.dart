import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_vehicle.dart';

class VehicleDetailsScreen extends StatelessWidget {
  const VehicleDetailsScreen({super.key});

  Future<bool> _hasExistingReport(String vehicleId) async {
    DocumentSnapshot reportSnapshot = await FirebaseFirestore.instance
        .collection('damageReports')
        .doc(vehicleId)
        .get();
    return reportSnapshot.exists;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('VEHICLE ID: $vehicleId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('vehicleId', isEqualTo: vehicleId)
                  .get();

              if (querySnapshot.docs.isNotEmpty) {
                DocumentSnapshot vehicleDoc = querySnapshot.docs.first;
                final vehicle = vehicleDoc.data() as Map<String, dynamic>;
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditVehicleDetailsScreen(
                        vehicleId: vehicleId,
                        status: vehicle['status'] ?? 'Unknown',
                        location: vehicle['location'] ?? 'Unknown',
                        details: vehicle['details'] ?? 'Unknown',
                        crew: vehicle['crew'] ?? 'Unknown',
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehicle not found.')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('vehicles')
            .where('vehicleId', isEqualTo: vehicleId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Vehicle not found.'));
          } else {
            final vehicle = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final isActive = vehicle['status'] == 'Active';

            return FutureBuilder<bool>(
              future: _hasExistingReport(vehicleId),
              builder: (context, reportSnapshot) {
                if (reportSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (reportSnapshot.hasError) {
                  return Center(child: Text('Error: ${reportSnapshot.error}'));
                } else {
                  final hasReport = reportSnapshot.data ?? false;
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${vehicle['status'] ?? 'Unknown'}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 10),
                        Text('Location: ${vehicle['location'] ?? 'Unknown'}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 10),
                        Text('Details: ${vehicle['details'] ?? 'Unknown'}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 10),
                        Text('Crew: ${vehicle['crew'] ?? 'Unknown'}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: isActive && !hasReport
                              ? () {
                                  Navigator.pushNamed(context, '/reportDamage', arguments: vehicleId);
                                }
                              : null,
                          child: const Text('Report Damage'),
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}