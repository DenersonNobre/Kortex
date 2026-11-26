import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.actions,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.alignment = MainAxisAlignment.end,
  });

  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      color: backgroundColor,
      child: Wrap(
        alignment: switch (alignment) {
          MainAxisAlignment.start => WrapAlignment.start,
          MainAxisAlignment.end => WrapAlignment.end,
          MainAxisAlignment.center => WrapAlignment.center,
          MainAxisAlignment.spaceBetween => WrapAlignment.spaceBetween,
          MainAxisAlignment.spaceAround => WrapAlignment.spaceAround,
          MainAxisAlignment.spaceEvenly => WrapAlignment.spaceEvenly,
        },
        spacing: 8,
        runSpacing: 8,
        children: actions,
      ),
    );
  }
}
