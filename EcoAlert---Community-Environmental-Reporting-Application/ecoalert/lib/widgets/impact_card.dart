import 'package:flutter/material.dart';

class ImpactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const ImpactCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
    
          const SizedBox(height: 10),
    
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
    
          const SizedBox(height: 4),
    
          Text(title, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
