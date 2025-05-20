import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  AddVehicleScreenState createState() => AddVehicleScreenState();
}

class AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  String vehicleId = '';
  String status = 'Active';
  String latitude = '';
  String latDirection = '°N';
  String longitude = '';
  String lonDirection = '°E';
  String details = '';
  String crew = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('vehicles')
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await _firestore.collection('vehicles').add({
          'vehicleId': vehicleId,
          'status': status,
          'location': '$latitude$latDirection, $longitude$lonDirection',
          'details': details,
          'crew': crew,
          'created_at': Timestamp.now(),
        });
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle ID already exists.')),
          );
        }
      }
    }
  }

  void _toggleLatDirection() {
    setState(() {
      latDirection = (latDirection == '°N') ? '°S' : '°N';
    });
  }

  void _toggleLonDirection() {
    setState(() {
      lonDirection = (lonDirection == '°E') ? '°W' : '°E';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Vehicle ID'),
                onChanged: (value) {
                  setState(() {
                    vehicleId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a vehicle ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status'),
                dropdownColor: Colors.white,
                value: status,
                onChanged: (newValue) {
                  setState(() {
                    status = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a status';
                  }
                  return null;
                },
                items: <String>['Damaged', 'Active', 'In Repair']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Latitude'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          onChanged: (value) {
                            setState(() {
                              latitude = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter latitude';
                            }
                            return null;
                          },
                        ),
                        Positioned(
                          right: 0,
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.blue,
                              ),
                              GestureDetector(
                                onTap: _toggleLatDirection,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    latDirection,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Longitude'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          onChanged: (value) {
                            setState(() {
                              longitude = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter longitude';
                            }
                            return null;
                          },
                        ),
                        Positioned(
                          right: 0,
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.blue,
                              ),
                              GestureDetector(
                                onTap: _toggleLonDirection,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    lonDirection,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Details'),
                onChanged: (value) {
                  setState(() {
                    details = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Crew'),
                onChanged: (value) {
                  setState(() {
                    crew = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveVehicle,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}