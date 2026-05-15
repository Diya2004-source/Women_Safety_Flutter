import 'package:flutter/material.dart';
import 'package:women_safety/core/services/admin_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AdminService _adminService = AdminService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _adminService.getDashboardStats();
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _statsFuture = _adminService.getDashboardStats();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Unable to load analytics'));
              }

              final stats = snapshot.data;
              if (stats == null) {
                return const Center(child: Text('No analytics data available'));
              }

              final totalUsers = stats['totalUsers'] as int? ?? 0;
              final activeUsers = stats['activeUsers'] as int? ?? 0;
              final blockedUsers = stats['blockedUsers'] as int? ?? 0;
              //final inactiveUsers = stats['inactiveUsers'] as int? ?? 0;
              final totalSOS = stats['totalSOS'] as int? ?? 0;
              final activeSOS = stats['activeSOS'] as int? ?? 0;
              final resolvedSOS = stats['resolvedSOS'] as int? ?? 0;
              final cancelledSOS = stats['cancelledSOS'] as int? ?? 0;
              final totalContacts = stats['totalContacts'] as int? ?? 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('User Analytics'),
                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Total Users',
                        value: totalUsers.toString(),
                        color: Colors.blue,
                        subtitle: '$activeUsers active',
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        title: 'Blocked Users',
                        value: blockedUsers.toString(),
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      // _buildMetricCard(
                      //   title: 'Active Users',
                      //   value: activeUsers.toString(),
                      //   color: Colors.green,
                      // ),
                      SizedBox(width: 16),
                      // _buildMetricCard(
                      //   title: 'Inactive Users',
                      //   value: inactiveUsers.toString(),
                      //   color: Colors.orange,
                      // ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('SOS Analytics'),
                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Total Alerts',
                        value: totalSOS.toString(),
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        title: 'Active Alerts',
                        value: activeSOS.toString(),
                        color: Colors.pink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Resolved Alerts',
                        value: resolvedSOS.toString(),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildMetricCard(
                        title: 'Cancelled Alerts',
                        value: cancelledSOS.toString(),
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Emergency Contacts'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Emergency Contacts',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(totalContacts.toString(),
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
