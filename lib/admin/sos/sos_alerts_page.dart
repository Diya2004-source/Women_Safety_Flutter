import 'package:flutter/material.dart';
import 'package:women_safety/core/models/sos_model.dart';
import '/core/services/admin_service.dart';
import 'package:women_safety/admin/common/empty_state.dart';
import 'package:women_safety/admin/sos/widgets/sos_card.dart';

class SOSAlertsPage extends StatefulWidget {
  const SOSAlertsPage({Key? key}) : super(key: key);

  @override
  State<SOSAlertsPage> createState() => _SOSAlertsPageState();
}

class _SOSAlertsPageState extends State<SOSAlertsPage> {
  final AdminService _adminService = AdminService();
  late Future<List<SOSModel>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _adminService.getActiveSOSAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alerts'),
        centerTitle: true,
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _alertsFuture = _adminService.getActiveSOSAlerts();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _alertsFuture = _adminService.getActiveSOSAlerts();
          });
        },
        child: FutureBuilder<List<SOSModel>>(
          future: _alertsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading SOS alerts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const AdminEmptyState(
                message: 'No active SOS alerts',
                icon: Icons.done_all,
              );
            }

            final alerts = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return SOSCard(
                  alert: alert,
                  onResolve: () {
                    _showResolveDialog(context, alert);
                  },
                  onViewDetails: () {
                    // Show location on map
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showResolveDialog(BuildContext context, SOSModel alert) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Resolving alert from ${alert.userName}'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _adminService.resolveSOSAlert(
                  alert.id, notesController.text);
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _alertsFuture = _adminService.getActiveSOSAlerts();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alert resolved successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}
