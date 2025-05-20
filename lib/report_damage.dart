import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDamageScreen extends StatefulWidget {
  const ReportDamageScreen({super.key});

  @override
  ReportDamageScreenState createState() => ReportDamageScreenState();
}

class ReportDamageScreenState extends State<ReportDamageScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedVehicleId;
  String? selectedDamageType;
  String? selectedDamageSeverity;
  String description = '';

  List<String> vehicleIds = [];
  bool isActive = false;
  bool hasExistingReport = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleIds();
  }

  Future<void> _loadVehicleIds() async {
    QuerySnapshot vehicleSnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('status', isEqualTo: 'Active')
        .get();

    List<String> activeVehicleIds = vehicleSnapshot.docs.map((doc) => doc['vehicleId'] as String).toList();

    QuerySnapshot reportSnapshot = await FirebaseFirestore.instance
        .collection('damageReports')
        .get();

    List<String> reportedVehicleIds = reportSnapshot.docs.map((doc) => doc['vehicleId'] as String).toList();

    List<String> filteredVehicleIds = activeVehicleIds.where((id) => !reportedVehicleIds.contains(id)).toList();

    filteredVehicleIds.sort((a, b) => b.compareTo(a));

    setState(() {
      vehicleIds = filteredVehicleIds;
      final vehicleId = ModalRoute.of(context)?.settings.arguments as String?;
      if (vehicleId != null && vehicleIds.contains(vehicleId)) {
        selectedVehicleId = vehicleId;
        _checkVehicleStatusAndReports(vehicleId);
      }
    });
  }

  Future<void> _checkVehicleStatusAndReports(String vehicleId) async {
    QuerySnapshot vehicleQuerySnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('vehicleId', isEqualTo: vehicleId)
        .get();

    if (vehicleQuerySnapshot.docs.isEmpty) {
      setState(() {
        isActive = false;
      });
      return;
    }

    DocumentSnapshot vehicleSnapshot = vehicleQuerySnapshot.docs.first;

    QuerySnapshot reportSnapshot = await FirebaseFirestore.instance
        .collection('damageReports')
        .where('vehicleId', isEqualTo: vehicleId)
        .get();

    setState(() {
      isActive = vehicleSnapshot['status'] == 'Active';
      hasExistingReport = reportSnapshot.docs.isNotEmpty;
    });
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (!isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only active vehicles can report damage')),
        );
        return;
      }

      if (hasExistingReport) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This vehicle already has a damage report')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('damageReports').add({
        'vehicleId': selectedVehicleId ?? '',
        'damageType': selectedDamageType ?? '',
        'damageSeverity': selectedDamageSeverity ?? '',
        'description': description,
        'reported_at': Timestamp.now(),
      });

      QuerySnapshot vehicleQuerySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('vehicleId', isEqualTo: selectedVehicleId)
          .get();

      if (vehicleQuerySnapshot.docs.isNotEmpty) {
        DocumentSnapshot vehicleDoc = vehicleQuerySnapshot.docs.first;
        await FirebaseFirestore.instance.collection('vehicles').doc(vehicleDoc.id).update({
          'status': 'Damaged',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Damage report submitted successfully')),
        );
        Navigator.pushNamed(context, '/damageReports');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Damage'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Vehicle ID'),
                dropdownColor: Colors.white,
                items: vehicleIds.map((String id) {
                  return DropdownMenuItem(value: id, child: Text(id));
                }).toList(),
                value: selectedVehicleId,
                onChanged: (value) {
                  setState(() {
                    selectedVehicleId = value;
                    if (selectedVehicleId != null) {
                      _checkVehicleStatusAndReports(selectedVehicleId!);
                    }
                  });
                },
                validator: (value) => value == null ? 'Please select a vehicle ID' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Damage Type'),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(value: 'type1', child: Text('Type 1')),
                  DropdownMenuItem(value: 'type2', child: Text('Type 2')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedDamageType = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a damage type' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Damage Severity'),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(value: 'minor', child: Text('Minor')),
                  DropdownMenuItem(value: 'major', child: Text('Major')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedDamageSeverity = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a damage severity' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  setState(() {
                    description = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitReport,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}