import 'package:flutter/material.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.hintText,
    this.includeHintAsFirstItem = true,
    this.height = 52,
    this.itemHeight = 56,
    this.menuMaxHeight = 260,
    this.dividerColor = const Color(0xFFD1D5DB),
    this.dividerWidth = 2,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE3E3E3),
    this.borderRadius = 12,
    this.textStyle = const TextStyle(
      color: Color(0xFF1F2937),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    this.hintStyle = const TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    this.iconColor = const Color(0xFF6B7280),
    this.horizontalPadding = 14,
    this.shadow,
  });

  final List<AppDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final bool includeHintAsFirstItem;
  final double height;
  final double itemHeight;
  final double menuMaxHeight;
  final Color dividerColor;
  final double dividerWidth;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final Color iconColor;
  final double horizontalPadding;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final hasHintItem = includeHintAsFirstItem && hintText != null;
    final totalItems = options.length + (hasHintItem ? 1 : 0);
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          itemHeight: itemHeight,
          menuMaxHeight: menuMaxHeight,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: iconColor),
          hint: hintText == null ? null : Text(hintText!, style: hintStyle),
          style: textStyle,
          selectedItemBuilder: (context) {
            final selectedItems = <Widget>[];
            if (hasHintItem) {
              selectedItems.add(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(hintText!, style: hintStyle),
                ),
              );
            }
            selectedItems.addAll(
              options.map(
                (option) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(option.label, style: textStyle),
                ),
              ),
            );
            return selectedItems;
          },
          items: _buildMenuItems(hasHintItem: hasHintItem, totalItems: totalItems),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  List<DropdownMenuItem<T>> _buildMenuItems({
    required bool hasHintItem,
    required int totalItems,
  }) {
    final menuItems = <DropdownMenuItem<T>>[];

    if (hasHintItem) {
      menuItems.add(
        DropdownMenuItem<T>(
          value: null,
          child: _menuItemContainer(
            isLast: totalItems == 1,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hintText!,
                    style: hintStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (value == null)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < options.length; i++) {
      final option = options[i];
      final optionStyle = textStyle.copyWith(
        color: option.enabled ? textStyle.color : const Color(0xFF9CA3AF),
      );
      final visualIndex = i + (hasHintItem ? 1 : 0);
      final isLast = visualIndex == totalItems - 1;
      final selected = value == option.value;

      menuItems.add(
        DropdownMenuItem<T>(
          value: option.value,
          enabled: option.enabled,
          child: _menuItemContainer(
            isLast: isLast,
            child: Row(
              children: [
                if (option.icon != null) ...[
                  Icon(
                    option.icon,
                    size: 18,
                    color: option.enabled
                        ? const Color(0xFFC7985F)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    option.label,
                    style: optionStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return menuItems;
  }

  Widget _menuItemContainer({required bool isLast, required Widget child}) {
    return Container(
      height: itemHeight,
      alignment: Alignment.centerLeft,
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: dividerColor,
                  width: dividerWidth,
                ),
              ),
            ),
      child: child,
    );
  }
}
