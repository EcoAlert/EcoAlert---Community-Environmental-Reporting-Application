import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
Widget build(BuildContext context) {
  return Material(
    color: Colors.transparent,

    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      splashColor: const Color(0xFF7ECBA9),
      highlightColor: Colors.transparent,
      onTap: onTap,
      hoverColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: const Color(0xFFEAF8F1),
          borderRadius: BorderRadius.circular(18),
        ),

        child: Row(
          children: [

            Material(
  color: const Color(0xFF7ECBA9),
  borderRadius: BorderRadius.circular(14),

  child: InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,

    child: Padding(
      padding: const EdgeInsets.all(14),

      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    ),
  ),
),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}
}