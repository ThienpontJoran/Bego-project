// Een klein gekleurd "pilletje" met tekst, bv. de interesse of de ketenstatus.

import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  final String tekst;
  final Color kleur;

  const Label({super.key, required this.tekst, required this.kleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kleur.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: kleur, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(tekst, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
