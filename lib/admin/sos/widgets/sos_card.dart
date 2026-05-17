import 'package:flutter/material.dart';
import '../../../core/models/sos_model.dart';

class SOSCard extends StatefulWidget {
  final SOSModel alert;
  final VoidCallback onResolve;
  final VoidCallback onViewDetails;
  final Function(String) onStatusChange;

  const SOSCard({
    Key? key,
    required this.alert,
    required this.onResolve,
    required this.onViewDetails,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  State<SOSCard> createState() => _SOSCardState();
}

class _SOSCardState extends State<SOSCard> {
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showStatusChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Alert Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Status: ${widget.alert.status}'),
            const SizedBox(height: 16),
            const Text('Select new status:'),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          if (widget.alert.status != 'active')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onStatusChange('active');
              },
              child: const Text('Active'),
            ),
          if (widget.alert.status != 'pending')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onStatusChange('pending');
              },
              child: const Text('Pending'),
            ),
          if (widget.alert.status != 'resolved')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onStatusChange('resolved');
              },
              child: const Text('Resolved'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.alert.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.alert.userEmail,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(widget.alert.severity),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.alert.severity.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.alert.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.alert.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.alert.location,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (widget.alert.resolvedAt != null)
              Text(
                'Resolved at: ${widget.alert.resolvedAt!.toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onViewDetails,
                  child: const Text('View Location'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _showStatusChangeDialog,
                  child: const Text('Change Status'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.onResolve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Resolve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
