import 'package:flutter/material.dart';
import 'package:women_safety/core/models/sos_model.dart';
import '/core/services/admin_service.dart';
import 'package:women_safety/admin/common/empty_state.dart';
import 'package:women_safety/admin/sos/widgets/sos_card.dart';

class SOSHistoryPage extends StatefulWidget {
  const SOSHistoryPage({Key? key}) : super(key: key);

  @override
  State<SOSHistoryPage> createState() => _SOSHistoryPageState();
}

class _SOSHistoryPageState extends State<SOSHistoryPage> {
  final AdminService _adminService = AdminService();
  late Future<List<SOSModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _adminService.getSOSHistory(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS History'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _historyFuture = _adminService.getSOSHistory(limit: 100);
          });
        },
        child: FutureBuilder<List<SOSModel>>(
          future: _historyFuture,
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
                      'Error loading SOS history',
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
                message: 'No SOS history',
                icon: Icons.history,
              );
            }

            final history = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final alert = history[index];
                return SOSCard(
                  alert: alert,
                  onResolve: () {},
                  onViewDetails: () {},
                  onStatusChange: (newStatus) {},
                );
              },
            );
          },
        ),
      ),
    );
  }
}
