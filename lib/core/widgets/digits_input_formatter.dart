import 'package:flutter/services.dart';

/// Accepts Western, Arabic-Indic and Persian digits with a consistent wire value.
class DigitsInputFormatter extends TextInputFormatter {
  const DigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = newValue.text.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (
      match,
    ) {
      final code = match[0]!.codeUnitAt(0);
      return '${code - (code >= 0x06f0 ? 0x06f0 : 0x0660)}';
    });
    return FilteringTextInputFormatter.digitsOnly.formatEditUpdate(
      oldValue,
      newValue.copyWith(text: normalized),
    );
  }
}
