import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final String location;
  final String status;
  final String date;

  const ReportCard({
    super.key,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.date,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.teal;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'task_completed':
        return Colors.purpleAccent;
      case 'waiting':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16),

              const SizedBox(width: 4),

              Expanded(child: Text(location)),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            date,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
