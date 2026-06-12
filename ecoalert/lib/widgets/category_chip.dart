import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Map<String, Color> _categoryColors = {
    'waste': Color(0xFFFF8A65), // orange
    'drainage': Color(0xFF64B5F6), // blue
    'pollution': Color(0xFF9575CD), // purple
    'electrical': Color(0xFFFFCA28), // amber
    'complaint': Color(0xFFF06292), // pink
    'other': Color(0xFF81C784), // green
  };

  @override
  Widget build(BuildContext context) {
    final color =
        _categoryColors[label.toLowerCase()] ?? const Color(0xFF7ECBA9);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),

            const SizedBox(height: 12),

            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
