import 'package:flutter/material.dart';

String closeIconAssetFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light
      ? 'assets/icons/close-icon-light.svg'
      : 'assets/icons/close-icon-black.svg';
}
