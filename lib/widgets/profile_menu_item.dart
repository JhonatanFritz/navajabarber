import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showArrow;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 15)),
            ),
            if (showArrow) const Icon(Icons.arrow_forward, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}