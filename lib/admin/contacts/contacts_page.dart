import 'package:flutter/material.dart';
import 'package:women_safety/admin/common/empty_state.dart';
import 'package:women_safety/core/models/contact.dart';
import 'package:women_safety/core/services/admin_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final AdminService _adminService = AdminService();
  late Future<List<ContactModel>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _adminService.getEmergencyContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _contactsFuture = _adminService.getEmergencyContacts();
          });
        },
        child: FutureBuilder<List<ContactModel>>(
          future: _contactsFuture,
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
                      'Error loading emergency contacts',
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
                message: 'No emergency contacts found',
                icon: Icons.contact_phone,
              );
            }

            final contacts = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink,
                      child: Text(contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(contact.name),
                    subtitle: Text('${contact.relation} • ${contact.phone}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone),
                      color: Colors.green,
                      onPressed: () {},
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
