import 'package:flutter/material.dart';
import '../models/barber_model.dart';
import 'star_rating.dart';

class BarberCard extends StatelessWidget {
  final Barber barber;
  final VoidCallback? onTap;

  const BarberCard({super.key, required this.barber, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: barber.photoUrl.isNotEmpty
                    ? Image.network(
                        barber.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              barber.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              barber.specialty,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            StarRating(rating: barber.rating),
          ],
        ),
      ),
    );
  }
}