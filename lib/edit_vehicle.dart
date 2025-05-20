import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditVehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;
  final String status;
  final String location;
  final String details;
  final String crew;

  const EditVehicleDetailsScreen({
    super.key,
    required this.vehicleId,
    required this.status,
    required this.location,
    required this.details,
    required this.crew,
  });

  @override
  EditVehicleDetailsScreenState createState() => EditVehicleDetailsScreenState();
}

class EditVehicleDetailsScreenState extends State<EditVehicleDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late String status;
  late String latitude;
  late String latDirection;
  late String longitude;
  late String lonDirection;
  late String details;
  late String crew;

  @override
  void initState() {
    super.initState();
    status = widget.status;
    details = widget.details;
    crew = widget.crew;

    try {
      final locationParts = widget.location.split(RegExp(r'[°, ]')).where((part) => part.isNotEmpty).toList();
      if (locationParts.length == 4) {
        latitude = locationParts[0];
        latDirection = '°${locationParts[1]}';
        longitude = locationParts[2];
        lonDirection = '°${locationParts[3]}';
      } else {
        throw RangeError('Invalid location format');
      }
    } catch (e) {
      latitude = '';
      latDirection = '°N';
      longitude = '';
      lonDirection = '°E';
    }
  }

  Future<void> _saveVehicleDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .where('vehicleId', isEqualTo: widget.vehicleId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          String documentId = querySnapshot.docs.first.id;

          if (status != 'Damaged') {
            QuerySnapshot damageReports = await FirebaseFirestore.instance
                .collection('damageReports')
                .where('vehicleId', isEqualTo: widget.vehicleId)
                .get();

            for (var doc in damageReports.docs) {
              await FirebaseFirestore.instance.collection('damageReports').doc(doc.id).delete();
            }
          }

          await FirebaseFirestore.instance.collection('vehicles').doc(documentId).update({
            'status': status,
            'location': '$latitude$latDirection, $longitude$lonDirection',
            'details': details,
            'crew': crew,
          });

          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vehicle not found.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving vehicle details: $e')),
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
        title: const Text('Edit Vehicle Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                items: <String>['Damaged', 'Active', 'In Repair'].map<DropdownMenuItem<String>>((String value) {
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
                          initialValue: latitude,
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
                          initialValue: longitude,
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
                initialValue: details,
                decoration: const InputDecoration(labelText: 'Details'),
                onChanged: (value) {
                  setState(() {
                    details = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: crew,
                decoration: const InputDecoration(labelText: 'Crew'),
                onChanged: (value) {
                  setState(() {
                    crew = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveVehicleDetails,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}