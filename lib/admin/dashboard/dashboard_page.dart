import 'package:flutter/material.dart';
import 'package:women_safety/admin/dashboard/widgets/recent_sos_list.dart';
import 'package:women_safety/core/services/admin_service.dart';
import 'package:women_safety/core/models/sos_model.dart';

// Note: If you still want to use your external StatsCard, 
// you MUST remove any fixed 'width' properties inside that file.
// import 'package:women_safety/admin/dashboard/widgets/stats_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AdminService _adminService = AdminService();
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<SOSModel>> _recentSOSFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _statsFuture = _adminService.getDashboardStats();
    _recentSOSFuture = _adminService.getRecentSOSAlerts(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Soft pink background for the whole page
      backgroundColor: const Color(0xFFFDEBFF), 
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.pink,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: CircularProgressIndicator(color: Colors.pink),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      const Text('Error loading data',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }

              final stats = snapshot.data ?? {};

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // This Row + Expanded structure prevents the "Right Overflow"
                  Row(
                    children: [
                      Expanded(
                        child: _buildResponsiveCard(
                          title: 'Total Users',
                          value: stats['totalUsers']?.toString() ?? '0',
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12), 
                      Expanded(
                        child: _buildResponsiveCard(
                          title: 'Contacts',
                          value: stats['totalContacts']?.toString() ?? '0',
                          icon: Icons.contact_emergency,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  FutureBuilder<List<SOSModel>>(
                    future: _recentSOSFuture,
                    builder: (context, sosSnapshot) {
                      if (sosSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final recentSOS = sosSnapshot.data ?? [];
                      return RecentSOSList(
                        alerts: recentSOS,
                        onViewMore: () {
                          // View All Logic
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // A local helper to ensure the card never overflows its parent width
  Widget _buildResponsiveCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flexible allows text to wrap or shrink if the card gets too narrow
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: Colors.white.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}