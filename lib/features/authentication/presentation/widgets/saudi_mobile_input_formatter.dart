import 'package:flutter/services.dart';
import '../../../../core/widgets/digits_input_formatter.dart';
import '../../domain/entities/saudi_mobile_number.dart';

/// Keeps the editable national number separate from the visible +966 prefix.
class SaudiMobileInputFormatter extends TextInputFormatter {
  const SaudiMobileInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = const DigitsInputFormatter().formatEditUpdate(
      oldValue,
      newValue,
    );
    final mobile = SaudiMobileNumber.tryParse(digits.text);
    if (mobile != null && digits.text != mobile.nationalNumber) {
      return TextEditingValue(
        text: mobile.nationalNumber,
        selection: TextSelection.collapsed(
          offset: mobile.nationalNumber.length,
        ),
      );
    }
    return LengthLimitingTextInputFormatter(
      9,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    ).formatEditUpdate(oldValue, digits);
  }
}
