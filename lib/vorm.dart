// Tekent het icoon van een contact:
// cirkel = chirurg, vierkant = tandarts, driehoek = labo.

import 'package:flutter/material.dart';

import 'contact.dart';

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
    // De rand: dik en blauw als het contact aangeklikt is.
    Border rand = Border.all(color: Colors.black87, width: 1);
    if (geselecteerd) {
      rand = Border.all(color: Colors.blue.shade800, width: 3);
    }

    if (soort == Soort.chirurg) {
      return Container(
        width: grootte,
        height: grootte,
        decoration: BoxDecoration(color: kleur, shape: BoxShape.circle, border: rand),
      );
    }

    if (soort == Soort.tandarts) {
      return Container(
        width: grootte,
        height: grootte,
        decoration: BoxDecoration(color: kleur, border: rand),
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

    Paint vulling = Paint();
    vulling.color = kleur;
    canvas.drawPath(driehoek, vulling);

    Paint rand = Paint();
    rand.style = PaintingStyle.stroke;
    rand.color = Colors.black87;
    rand.strokeWidth = 1;
    if (geselecteerd) {
      rand.color = Colors.blue.shade800;
      rand.strokeWidth = 3;
    }
    canvas.drawPath(driehoek, rand);
  }

  @override
  bool shouldRepaint(DriehoekTekenaar oud) {
    return true;
  }
}
