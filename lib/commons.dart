import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_math_fork/flutter_math.dart';

// Function to parse text with LaTeX
List<InlineSpan> parseTextWithLatex(String text) {
  final regex = RegExp(r'(\\\(.+?\\\))|(\\\[.+?\\\])', dotAll: true);
  final matches = regex.allMatches(text);

  int currentIndex = 0;
  List<InlineSpan> spans = [];

  for (final match in matches) {
    if (match.start > currentIndex) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex, match.start),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      );
    }
    final latex = text.substring(match.start + 2, match.end - 2);
    spans.add(
      WidgetSpan(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Math.tex(
            latex,
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
    currentIndex = match.end;
  }

  if (currentIndex < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(currentIndex),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
        ),
      ),
    );
  }

  return spans;
}

// Format the recognized text by eliminating extra spaces and new lines
String formatText(String text) {
  // Replace multiple new lines with a single new line
  String formattedText = text.replaceAll(RegExp(r'\s+'), ' ');

  // Trim leading and trailing whitespace
  formattedText = formattedText.trim();

  return formattedText;
}
