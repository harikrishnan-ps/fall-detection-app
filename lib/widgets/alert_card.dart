import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../utils/theme.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.onResolve,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor();
    final IconData statusIcon = _getStatusIcon();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.personName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(alert.timestamp),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Location info
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Lat: ${alert.location.latitude.toStringAsFixed(4)}, '
                    'Lng: ${alert.location.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              // Acknowledgment info
              if (alert.acknowledgedBy != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Acknowledged at ${_formatTimestamp(alert.acknowledgedAt!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],

              // Action buttons
              if (alert.status == AlertStatus.pending && onAcknowledge != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAcknowledge,
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Acknowledge'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (alert.status == AlertStatus.acknowledged && onResolve != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onResolve,
                        icon: const Icon(Icons.done_all, size: 20),
                        label: const Text('Mark Resolved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final Color statusColor = _getStatusColor();
    String statusText = '';

    switch (alert.status) {
      case AlertStatus.pending:
        statusText = 'PENDING';
        break;
      case AlertStatus.acknowledged:
        statusText = 'ACKNOWLEDGED';
        break;
      case AlertStatus.resolved:
        statusText = 'RESOLVED';
        break;
      case AlertStatus.cancelled:
        statusText = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (alert.status) {
      case AlertStatus.pending:
        return AppTheme.accentColor;
      case AlertStatus.acknowledged:
        return AppTheme.warningColor;
      case AlertStatus.resolved:
        return AppTheme.successColor;
      case AlertStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (alert.status) {
      case AlertStatus.pending:
        return Icons.warning_amber_rounded;
      case AlertStatus.acknowledged:
        return Icons.info_outline;
      case AlertStatus.resolved:
        return Icons.check_circle_outline;
      case AlertStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy h:mm a').format(timestamp);
    }
  }
}
