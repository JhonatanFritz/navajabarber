import 'package:flutter/material.dart';
import '../models/service_model.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 165,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          service.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('Ver detalles',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on_outlined, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('S/ ${service.price.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                            const SizedBox(width: 14),
                            const Icon(Icons.access_time, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text('${service.durationMinutes} min',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Image.network(
                service.imageUrl,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.image_not_supported, color: Colors.white38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}