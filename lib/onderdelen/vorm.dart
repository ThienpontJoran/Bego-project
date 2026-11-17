// Tekent het icoon van een contact:
// cirkel = chirurg, vierkant = tandarts, driehoek = labo.

import 'package:flutter/material.dart';

import '../models/contact.dart';

class Vorm extends StatelessWidget {
  final Soort soort;
  final Color kleur;
  final double grootte;
  final bool geselecteerd;

  const Vorm({
    super.key,
    required this.soort,
    required this.kleur,
    this.grootte = 20,
    this.geselecteerd = false,
  });

  @override
  Widget build(BuildContext context) {
    // Rand: wit, of dik en donker als het contact aangeklikt is.
    Border rand = Border.all(color: Colors.white, width: 2);
    if (geselecteerd) {
      rand = Border.all(color: const Color(0xFF263238), width: 3);
    }
    List<BoxShadow> schaduw = [
      BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 3, offset: const Offset(0, 1)),
    ];

    if (soort == Soort.chirurg) {
      return Container(
        width: grootte,
        height: grootte,
        decoration: BoxDecoration(color: kleur, shape: BoxShape.circle, border: rand, boxShadow: schaduw),
      );
    }

    if (soort == Soort.tandarts) {
      return Container(
        width: grootte,
        height: grootte,
        decoration: BoxDecoration(
          color: kleur,
          border: rand,
          boxShadow: schaduw,
          borderRadius: BorderRadius.circular(grootte / 6),
        ),
      );
    }

    // Labo: een driehoek. Daar bestaat geen kant-en-klare vorm voor, dus tekenen we hem zelf.
    return CustomPaint(
      size: Size(grootte, grootte),
      painter: DriehoekTekenaar(kleur, geselecteerd),
    );
  }
}

class DriehoekTekenaar extends CustomPainter {
  final Color kleur;
  final bool geselecteerd;

  DriehoekTekenaar(this.kleur, this.geselecteerd);

  @override
  void paint(Canvas canvas, Size size) {
    Path driehoek = Path();
    driehoek.moveTo(size.width / 2, 0); // punt bovenaan
    driehoek.lineTo(size.width, size.height); // rechtsonder
    driehoek.lineTo(0, size.height); // linksonder
    driehoek.close();

    canvas.drawShadow(driehoek, Colors.black, 2, false);

    Paint vulling = Paint();
    vulling.color = kleur;
    canvas.drawPath(driehoek, vulling);

    Paint rand = Paint();
    rand.style = PaintingStyle.stroke;
    rand.strokeJoin = StrokeJoin.round;
    rand.color = Colors.white;
    rand.strokeWidth = 2;
    if (geselecteerd) {
      rand.color = const Color(0xFF263238);
      rand.strokeWidth = 3;
    }
    canvas.drawPath(driehoek, rand);
  }

  @override
  bool shouldRepaint(DriehoekTekenaar oud) {
    return true;
  }
}
