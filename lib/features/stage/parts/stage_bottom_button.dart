import 'package:flutter/material.dart';

import '../../../app/ui_kit/app_button.dart';

enum StageBottomButtonVariant { primary, secondary }

class StageBottomButton extends StatelessWidget {
  const StageBottomButton({
    super.key,
    required this.variant,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final StageBottomButtonVariant variant;
  final String label;
  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == StageBottomButtonVariant.primary;
    return AppButton(
      label: label,
      onPressed: onTap,
      size: AppButtonSize.large,
      variant: isPrimary ? AppButtonVariant.primary : AppButtonVariant.card,
      leadingIconAsset: isPrimary ? null : icon,
      trailingIconAsset: isPrimary ? icon : null,
    );
  }
}
