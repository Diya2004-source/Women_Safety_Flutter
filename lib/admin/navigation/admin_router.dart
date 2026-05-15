import 'package:flutter/material.dart';
import '../dashboard/dashboard_page.dart';
import '../users/users_page.dart';
import '../sos/sos_alerts_page.dart';
import '../contacts/contacts_page.dart';
import '../analytics/analytics_page.dart';
import '../settings/admin_settings_page.dart';

class AdminRouter extends StatefulWidget {
  const AdminRouter({Key? key}) : super(key: key);

  @override
  State<AdminRouter> createState() => _AdminRouterState();
}

class _AdminRouterState extends State<AdminRouter> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const UsersPage(),
    const SOSAlertsPage(),
    const ContactsPage(),
    const _MoreMenu(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('More'),
          backgroundColor: Colors.pink,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Analytics'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AnalyticsPage(),
            AdminSettingsPage(),
          ],
        ),
      ),
    );
  }
}
