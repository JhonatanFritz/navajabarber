import 'package:flutter/material.dart';

class NewsItem {
  final String title;
  final String subtitle;
  final String? imageUrl; // si es null, se usa un fondo oscuro con ícono
  final IconData? icon;

  const NewsItem({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.icon,
  });
}