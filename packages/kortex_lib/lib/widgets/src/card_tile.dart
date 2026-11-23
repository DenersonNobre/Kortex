import 'package:flutter/material.dart';

class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    this.color,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.visible = true,
    this.cardfy = false,
    this.checkable = false,
    this.checked = false,
    this.onChanged,
    this.onPressed,
    this.onLongPress,
    this.dense = false,
    this.selected = false,
  });

  final Color? color;
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool visible;
  final bool cardfy;
  final bool checkable;
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool dense;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Card(
      color: color,
      elevation: cardfy ? 1 : 0,
      margin: const EdgeInsets.all(1),
      child: ListTile(
        dense: dense,
        selected: selected,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onLongPress: onLongPress,
        onTap: checkable && onChanged != null
            ? () => onChanged!(!checked)
            : onPressed,
      ),
    );
  }
}
