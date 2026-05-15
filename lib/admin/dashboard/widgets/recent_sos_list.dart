import 'package:flutter/material.dart';
import '../../../core/models/sos_model.dart';

class RecentSOSList extends StatelessWidget {
  final List<SOSModel> alerts;
  final VoidCallback? onViewMore;

  const RecentSOSList({
    Key? key,
    required this.alerts,
    this.onViewMore,
  }) : super(key: key);

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent SOS Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onViewMore != null)
                  TextButton(
                    onPressed: onViewMore,
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
          const Divider(),
          alerts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No recent alerts'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getSeverityColor(alert.severity),
                        ),
                      ),
                      title: Text(alert.userName),
                      subtitle: Text(alert.location),
                      trailing: Chip(
                        label: Text(
                          alert.severity.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: _getSeverityColor(alert.severity),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
