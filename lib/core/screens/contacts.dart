import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_migration.dart';

class Contact {
  final String id;
  final String name;
  final String relation;
  final String phone;

  Contact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
  });

  factory Contact.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Contact(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown',
      relation: data['relation'] as String? ?? 'Guardian',
      phone: data['phone'] as String? ?? '',
    );
  }
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  bool _hasMigrated = false;

  @override
  void initState() {
    super.initState();
    _migrateOldContacts();
  }

  Future<void> _migrateOldContacts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _hasMigrated) {
      return;
    }

    _hasMigrated = true;
    await FirestoreMigrationService.migrateContacts(user.uid);
  }

  CollectionReference<Map<String, dynamic>> _contactsRef(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts');
  }

  Stream<List<Contact>> _contactsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _contactsRef(user.uid).snapshots().map((snapshot) {
      final contacts =
          snapshot.docs.map((doc) => Contact.fromDocument(doc)).toList();
      contacts.sort((a, b) => a.name.compareTo(b.name));
      return contacts;
    });
  }

  Future<void> _showAddContactDialog(int count) async {
    if (count >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 3 contacts')),
      );
      return;
    }

    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Trusted Guardian'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: relationController,
                  decoration: const InputDecoration(labelText: 'Relation'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a relation';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  await _contactsRef(user.uid).add({
                    'name': nameController.text.trim(),
                    'relation': relationController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'addedAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeContact(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _contactsRef(user.uid).doc(id).delete();
  }

  Future<void> _showEditContactDialog(Contact contact) async {
    final nameController = TextEditingController(text: contact.name);
    final relationController = TextEditingController(text: contact.relation);
    final phoneController = TextEditingController(text: contact.phone);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Contact'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: relationController,
                  decoration: const InputDecoration(labelText: 'Relation'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a relation';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  await _contactsRef(user.uid).doc(contact.id).update({
                    'name': nameController.text.trim(),
                    'relation': relationController.text.trim(),
                    'phone': phoneController.text.trim(),
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9EDF2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SafeGuard',
              style: TextStyle(
                color: Colors.pink.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Emergency Contacts',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.settings,
              color: Colors.pink.shade700,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
        child: StreamBuilder<List<Contact>>(
          stream: _contactsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load contacts. Please try again.',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              );
            }

            final contacts = snapshot.data ?? [];
            final count = contacts.length;
            return Column(
              children: [
                Expanded(
                  child: contacts.isEmpty
                      ? Center(
                          child: Text(
                            'No emergency contacts yet. Add up to 3 trusted guardians.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: contacts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.pink.shade100.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.pink.shade50,
                                    child: Text(
                                      contact.name.isNotEmpty
                                          ? contact.name[0].toUpperCase()
                                          : 'G',
                                      style: TextStyle(
                                        color: Colors.pink.shade700,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contact.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          contact.relation,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          contact.phone,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Calling ${contact.name}...'),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.call,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _showEditContactDialog(contact),
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _removeContact(contact.id),
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.shade100.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              count < 3
                                  ? 'Add a trusted guardian'
                                  : 'Contact limit reached',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              count < 3
                                  ? 'They will be notified immediately if you trigger an alert.'
                                  : 'You can only add up to 3 trusted contacts.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: count < 3
                            ? () => _showAddContactDialog(count)
                            : null,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: count < 3
                                ? Colors.pink.shade400
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: StreamBuilder<List<Contact>>(
        stream: _contactsStream(),
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return FloatingActionButton(
            onPressed: count < 3 ? () => _showAddContactDialog(count) : null,
            backgroundColor:
                count < 3 ? Colors.pink.shade600 : Colors.grey.shade400,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
