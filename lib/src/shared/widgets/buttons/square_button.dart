// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:hanahaki_tools/src/core/theme/dimens.dart';
import 'package:hanahaki_tools/src/shared/extensions/context_extensions.dart';

enum ButtonType { primary, neutral, outline }

class SquareButton extends StatelessWidget {
  const SquareButton._({
    super.key,
    required this.title,
    this.onPressed,
    required this.type,
    this.icon,
  });

  factory SquareButton.neutral({
    Key? key,
    required String title,
    Widget? icon,
    VoidCallback? onPressed,
  }) {
    return SquareButton._(
      key: key,
      title: title,
      icon: icon,
      onPressed: onPressed,
      type: ButtonType.neutral,
    );
  }

  factory SquareButton.outline({
    Key? key,
    required String title,
    Widget? icon,
    VoidCallback? onPressed,
  }) {
    return SquareButton._(
      key: key,
      title: title,
      icon: icon,
      onPressed: onPressed,
      type: ButtonType.outline,
    );
  }

  factory SquareButton.primary({
    Key? key,
    required String title,
    Widget? icon,
    VoidCallback? onPressed,
  }) {
    return SquareButton._(
      key: key,
      title: title,
      icon: icon,
      onPressed: onPressed,
      type: ButtonType.primary,
    );
  }

  final String title;
  final Widget? icon;
  final VoidCallback? onPressed;
  final ButtonType type;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      style: context.textTheme.bodyMedium?.copyWith(
        color: (type == ButtonType.primary || type == ButtonType.neutral)
            ? context.colorScheme.surface
            : context.colorScheme.onSurface,
        fontWeight: type == ButtonType.primary
            ? FontWeight.w600
            : FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
    final buttonChild = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) icon!,
        if (icon != null) const SizedBox(height: 6),
        label,
      ],
    );
    final ButtonStyle style = switch (type) {
      ButtonType.primary => ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radius),
        ),
        backgroundColor: context.colorScheme.primary,
      ),
      ButtonType.neutral => ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radius),
        ),
        backgroundColor: context.colorScheme.onSurface,
      ),
      ButtonType.outline => OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radius),
        ),
        side: BorderSide(
          color: context.colorScheme.onSurface.withValues(alpha: .3),
          width: 1.2,
        ),
      ),
    };
    return SizedBox(
      width: double.infinity,
      height: kMinInteractiveDimension,
      child: switch (type) {
        ButtonType.primary => ElevatedButton(
          onPressed: onPressed,
          style: style,
          child: buttonChild,
        ),
        ButtonType.neutral => ElevatedButton(
          onPressed: onPressed,
          style: style,
          child: buttonChild,
        ),
        ButtonType.outline => OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: buttonChild,
        ),
      },
    );
  }
}
