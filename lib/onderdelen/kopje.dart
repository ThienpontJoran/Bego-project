// Een tussentitel in formulieren en panelen.

import 'package:flutter/material.dart';

Widget kopje(BuildContext context, String tekst) {
  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      tekst,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
