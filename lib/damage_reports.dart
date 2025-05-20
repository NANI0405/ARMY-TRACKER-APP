import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'sidebar.dart';
import 'role_provider.dart';

class DamageReportsScreen extends StatefulWidget {
  const DamageReportsScreen({super.key});

  @override
  DamageReportsScreenState createState() => DamageReportsScreenState();
}

class DamageReportsScreenState extends State<DamageReportsScreen> with RouteAware {
  late Future<List<Map<String, dynamic>>> _damageReportsFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadDamageReports();
  }

  void _loadDamageReports() {
    setState(() {
      _damageReportsFuture = _getDamageReports();
    });
  }

  Future<List<Map<String, dynamic>>> _getDamageReports() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('damageReports')
        .orderBy('reported_at')
        .get();
    return snapshot.docs.map((doc) => {'documentId': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }

  String _formatDateTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateFormat dateFormat = DateFormat('HH:mm, dd/MM/yyyy');
    return dateFormat.format(dateTime);
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
    _loadDamageReports();
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = RoleProvider.of(context);
    final userRole = roleProvider?.userRole ?? 'Ops Team';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Damage Reports'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Sidebar(userRole: userRole),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _damageReportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No damage reports available.'));
          } else {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDamageReports();
              },
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final report = snapshot.data![index];
                  final formattedReportedAt = _formatDateTime(report['reported_at']);
                  return ListTile(
                    title: Text('Vehicle ID: ${report['vehicleId']}'),
                    subtitle: Text('Reported at: $formattedReportedAt'),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Type: ${report['damageType']}'),
                        Text('Severity: ${report['damageSeverity']}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/vehicleDetails',
                        arguments: report['vehicleId'],
                      ).then((value) {
                        if (value == true) {
                          _loadDamageReports();
                        }
                      });
                    },
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}