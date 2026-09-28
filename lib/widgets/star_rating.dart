import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;

  const StarRating({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < fullStars ? Icons.star : Icons.star_border,
          color: index < fullStars ? Colors.amber : Colors.grey[400],
          size: size,
        );
      }),
    );
  }
}