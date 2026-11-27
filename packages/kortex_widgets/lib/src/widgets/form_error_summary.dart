import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_forms/kortex_forms.dart';

/// Visible anchor of one form field inside a [FormErrorSummary].
///
/// SRP: map a field label to the [GlobalKey] of its on-screen anchor (pure
/// mapping, without business rule). The caller owns every key.
class FormErrorTarget {
  /// Creates the anchor mapping [label] to [fieldKey].
  const FormErrorTarget({required this.label, required this.fieldKey});

  /// Row title shown in the summary (pure label, without business rule).
  final String label;

  /// Key of the scrolled-to field anchor (owned by the caller).
  final GlobalKey fieldKey;
}

/// Receives the field the summary just scrolled to.
typedef FormErrorTapCallback = void Function(KortexField<dynamic> field);

/// One failing field read from the form (label, message and anchor).
class _FormErrorEntry {
  const _FormErrorEntry({
    required this.field,
    required this.target,
    required this.message,
  });

  final KortexField<dynamic> field;
  final FormErrorTarget target;
  final String message;
}

/// Reactive error list with tap-to-scroll over a caller-owned form (`UC-12.05`).
///
/// SRP: read each mapped field `error` signal under [KortexWatch] and render
/// one tappable row per failing field; a tap scrolls the matching anchor
/// into view with [Scrollable.ensureVisible]. It does NOT validate, own nor
/// dispose [form] (the caller creates and disposes it; unmount keeps it alive).
class FormErrorSummary extends StatelessWidget {
  /// Creates the summary over an externally owned [form].
  const FormErrorSummary({
    super.key,
    required this.form,
    required this.targets,
    this.title = 'Please fix the following errors',
    this.scrollDuration = const Duration(milliseconds: 200),
    this.onErrorTap,
  });

  /// Validated form (owned and disposed by the caller).
  final KortexForm form;

  /// Field-to-anchor mapping (keys owned by the caller; unmapped fields
  /// never render, even when failing).
  final Map<KortexField<dynamic>, FormErrorTarget> targets;

  /// Heading shown above the error rows.
  final String title;

  /// Duration of the tap-to-scroll animation.
  final Duration scrollDuration;

  /// Receives the field after the summary scrolls to it.
  final FormErrorTapCallback? onErrorTap;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, _) {
        final entries = _visibleEntries();
        if (entries.isEmpty) {
          return const SizedBox.shrink(
            key: ValueKey<String>('form_error_empty'),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                key: const ValueKey<String>('form_error_title'),
              ),
            ),
            for (final entry in entries)
              ListTile(
                key: ValueKey<String>('form_error_item_${entry.target.label}'),
                title: Text(entry.target.label),
                subtitle: Text(entry.message),
                trailing: const Icon(Icons.arrow_downward),
                onTap: () => _scrollTo(entry.field, entry.target),
              ),
          ],
        );
      },
    );
  }

  List<_FormErrorEntry> _visibleEntries() {
    final entries = <_FormErrorEntry>[];
    for (final field in form.fields) {
      final target = targets[field];
      if (target == null) continue;
      final message = field.error.value;
      if (message == null) continue;
      entries.add(
        _FormErrorEntry(field: field, target: target, message: message),
      );
    }
    return entries;
  }

  void _scrollTo(KortexField<dynamic> field, FormErrorTarget target) {
    final targetContext = target.fieldKey.currentContext;
    if (targetContext == null) return;
    unawaited(
      Scrollable.ensureVisible(targetContext, duration: scrollDuration),
    );
    onErrorTap?.call(field);
  }
}
