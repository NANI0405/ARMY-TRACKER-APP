import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sidebar.dart';
import 'role_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  LatLng? _selectedVehiclePosition;
  final Logger _logger = Logger('MapScreen');
  final String _googleMapsApiKey = 'AIzaSyBvCwjVWwg12X-f6LlUgO3ieTP1H_3BiXI';

  @override
  void initState() {
    super.initState();
    _setupLogger();
    _loadVehicleLocations();
  }

  void _setupLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      _logger.log(record.level, '${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  Future<void> _loadVehicleLocations({String filter = 'All'}) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('vehicles').get();
    _markers.clear();
    for (var document in snapshot.docs) {
      Map<String, dynamic> vehicle = document.data() as Map<String, dynamic>;
      String status = vehicle['status'];
      String location = vehicle['location'];
      List<String> latLng = _parseLocation(location);
      double? latitude = double.tryParse(latLng[0]);
      double? longitude = double.tryParse(latLng[1]);

      if (latitude != null && longitude != null) {
        if (filter == 'All' || filter == status) {
          _markers.add(
            Marker(
              markerId: MarkerId(vehicle['vehicleId']),
              position: LatLng(latitude, longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(status)),
              onTap: () {
                setState(() {
                  _selectedVehiclePosition = LatLng(latitude, longitude);
                });
                mapController.showMarkerInfoWindow(MarkerId(vehicle['vehicleId']));
              },
              infoWindow: InfoWindow(
                title: 'Vehicle ID: ${vehicle['vehicleId']}',
                snippet: 'Status: $status',
              ),
            ),
          );
        }
      } else {
        _logger.warning("Invalid coordinates for vehicle ${vehicle['vehicleId']}: $location");
      }
    }
    setState(() {});
  }

  List<String> _parseLocation(String location) {
    try {
      String cleanedLocation = location.replaceAll(RegExp(r'[^\d.,-]'), '');
      List<String> latLng = cleanedLocation.split(',');
      if (latLng.length != 2) {
        throw const FormatException("Invalid location format");
      }
      return latLng;
    } catch (e) {
      _logger.severe("Error parsing location: $e");
      return ['0.0', '0.0'];
    }
  }

  double _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'damaged':
        return BitmapDescriptor.hueRed;
      case 'active':
        return BitmapDescriptor.hueGreen;
      case 'in repair':
        return BitmapDescriptor.hueBlue;
      default:
        return BitmapDescriptor.hueYellow;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _zoomIn() {
    mapController.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    mapController.animateCamera(CameraUpdate.zoomOut());
  }

  void _searchVehicle() {
    final vehicleId = _searchController.text.trim();
    final marker = _markers.firstWhere(
      (marker) => marker.markerId.value == vehicleId,
      orElse: () => const Marker(markerId: MarkerId('')),
    );
    if (marker.markerId.value.isNotEmpty) {
      mapController.animateCamera(CameraUpdate.newLatLng(marker.position));
      mapController.showMarkerInfoWindow(marker.markerId);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle not found')),
        );
      }
    }
  }

  void _openGoogleMaps() async {
    if (_selectedVehiclePosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=${_selectedVehiclePosition!.latitude},${_selectedVehiclePosition!.longitude}&key=$_googleMapsApiKey";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      throw 'Could not open the map.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = RoleProvider.of(context);
    final userRole = roleProvider?.userRole ?? 'Ops Team';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Vehicle Locations'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Sidebar(userRole: userRole),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(29.00081, 77.67156),
              zoom: 10.0,
            ),
            markers: _markers,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            onTap: (LatLng position) {
              setState(() {
                _selectedVehiclePosition = position;
              });
            },
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Vehicle ID',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchVehicle,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<String>(
                      dropdownColor: Colors.white,
                      value: _selectedFilter,
                      items: <String>['All', 'Active', 'Damaged', 'In Repair']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                          _loadVehicleLocations(filter: _selectedFilter);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomInButton',
                  onPressed: _zoomIn,
                  mini: true,
                  backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
                  shape: Theme.of(context).floatingActionButtonTheme.shape,
                  child: const Icon(Icons.zoom_in, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoomOutButton',
                  onPressed: _zoomOut,
                  mini: true,
                  backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
                  shape: Theme.of(context).floatingActionButtonTheme.shape,
                  child: const Icon(Icons.zoom_out, color: Colors.blue),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'navigationButton',
              onPressed: _openGoogleMaps,
              backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
              shape: Theme.of(context).floatingActionButtonTheme.shape,
              child: const Icon(Icons.navigation, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}