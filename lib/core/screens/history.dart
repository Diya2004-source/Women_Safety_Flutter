import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_migration.dart';

class HistoryRecord {
  final String title;
  final String date;
  final String location;
  final String status;
  final String subtitle;

  HistoryRecord({
    required this.title,
    required this.date,
    required this.location,
    required this.status,
    required this.subtitle,
  });

  factory HistoryRecord.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HistoryRecord(
      title: data['title'] as String? ?? 'SOS Alerts',
      date: data['date'] as String? ?? 'Unknown date',
      location: data['location'] as String? ?? 'Unknown location',
      status: data['status'] as String? ?? 'Pending',
      subtitle: data['subtitle'] as String? ?? 'No details available.',
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _hasMigrated = false;

  @override
  void initState() {
    super.initState();
    _migrateOldHistory();
  }

  Future<void> _migrateOldHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _hasMigrated) {
      return;
    }

    _hasMigrated = true;
    await FirestoreMigrationService.migrateHistory(user.uid);
  }

  CollectionReference<Map<String, dynamic>> _historyRef(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('sos_history');
  }

  Stream<List<HistoryRecord>> _historyStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _historyRef(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HistoryRecord.fromDocument(doc))
            .toList());
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.grey.shade600;
      case 'pending':
      default:
        return Colors.pink.shade600;
    }
  }

  Future<void> _showSosDialog(BuildContext context) async {
    final locationController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trigger SOS Alert button'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
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
                  final now = DateTime.now();
                  final dateString =
                      '${now.month}/${now.day}/${now.year} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

                  await _historyRef(user.uid).add({
                    'title': 'Emergency SOS',
                    'date': dateString,
                    'location': locationController.text.trim(),
                    'status': 'Pending',
                    'subtitle': noteController.text.trim().isEmpty
                        ? 'SOS alert triggered.'
                        : noteController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('SOS alert added to history.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade600,
              ),
              child: const Text('Send SOS'),
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
              'SOS History',
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
              Icons.notifications_none,
              color: Colors.pink.shade700,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
        child: StreamBuilder<List<HistoryRecord>>(
          stream: _historyStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load history. Please try again.',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              );
            }

            final records = snapshot.data ?? [];
            final total = records.length;
            final resolved = records
                .where((r) => r.status.toLowerCase() == 'resolved')
                .length;
            final pending = records
                .where((r) => r.status.toLowerCase() == 'pending')
                .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review your recent safety alerts and status.',
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSummaryCard('Total', total.toString(),
                        Colors.pink.shade50, Colors.pink.shade700),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Resolved', resolved.toString(),
                        Colors.green.shade50, Colors.green.shade700),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Pending', pending.toString(),
                        Colors.white, Colors.pink.shade700),
                  ],
                ),
                const SizedBox(height: 20),
                if (records.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No history records found yet. Trigger an SOS alert to see them here.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.shade100.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    record.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(record.status)
                                          .withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      record.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(record.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                record.date,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                record.location,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                record.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.pink.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'View Details',
                                    style: TextStyle(color: Colors.pink),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Load Older History',
                    style: TextStyle(
                      color: Colors.pink.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSosDialog(context),
        backgroundColor: Colors.pink.shade600,
        child: const Text('SOS'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color background, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
