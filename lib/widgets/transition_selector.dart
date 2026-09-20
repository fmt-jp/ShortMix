import 'package:flutter/material.dart';

import '../models/transition.dart';

/// Transition type + duration picker (spec section 22). MVP applies one
/// choice between every pair of clips ("すべての動画間").
class TransitionSelector extends StatelessWidget {
  const TransitionSelector({
    super.key,
    required this.transition,
    required this.onChanged,
  });

  final Transition transition;
  final ValueChanged<Transition> onChanged;

  static const _durations = [0.3, 0.5, 0.8, 1.0, 1.5];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('トランジション', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        RadioGroup<TransitionType>(
          groupValue: transition.type,
          onChanged: (value) {
            if (value != null) onChanged(transition.copyWith(type: value));
          },
          child: Column(
            children: TransitionType.values
                .map(
                  (type) => RadioListTile<TransitionType>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(type.label),
                    value: type,
                  ),
                )
                .toList(),
          ),
        ),
        if (transition.type != TransitionType.cut) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('時間'),
              const SizedBox(width: 12),
              DropdownButton<double>(
                value: transition.duration,
                items: _durations
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d秒')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(transition.copyWith(duration: value));
                  }
                },
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        const Text('適用: すべての動画間', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
