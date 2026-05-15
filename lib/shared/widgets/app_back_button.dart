import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.icon = Icons.arrow_back_ios_new,
    this.color,
    this.size,
    this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final Color? color;
  final double? size;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: Icon(icon, color: color, size: size),
    );
  }
}
