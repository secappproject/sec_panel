

import 'package:flutter/material.dart';

class MentionTextEditingController extends TextEditingController {
  final TextStyle mentionStyle;
  final TextStyle defaultStyle;
  final RegExp pattern;

  MentionTextEditingController()
    : mentionStyle = const TextStyle(
        color: Color(0xFF0066FF), 
        fontWeight: FontWeight.bold,
      ),
      defaultStyle = const TextStyle(
        
        color: Colors.black,
      ),
      
      pattern = RegExp(r"(\B@AI\b)|(\B@\w+\b)"),
      super();

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];
    text.splitMapJoin(
      pattern,
      onMatch: (Match match) {
        children.add(
          TextSpan(
            text: match[0],
            style: (style ?? defaultStyle).merge(mentionStyle),
          ),
        );
        return '';
      },
      onNonMatch: (String nonMatch) {
        children.add(TextSpan(text: nonMatch, style: style ?? defaultStyle));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}
