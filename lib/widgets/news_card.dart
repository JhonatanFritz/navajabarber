import 'package:flutter/material.dart';
import '../models/news_item_model.dart';

class NewsCard extends StatelessWidget {
  final NewsItem item;

  const NewsCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: item.imageUrl == null ? Colors.black : null,
        image: item.imageUrl != null
            ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: item.imageUrl == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon ?? Icons.auto_awesome, color: Colors.cyanAccent),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            )
          : null,
    );
  }
}