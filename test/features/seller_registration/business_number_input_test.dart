import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/widgets/digits_input_formatter.dart';
import 'package:octogear/features/authentication/presentation/widgets/saudi_mobile_input_formatter.dart';
import 'package:octogear/features/seller_registration/domain/entities/seller_application.dart';

void main() {
  const phone = SaudiMobileInputFormatter();
  TextEditingValue edit(String text) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );

  test('mobile paste normalizes supported prefixes and Arabic digits', () {
    for (final input in [
      '500000002',
      '0500000002',
      '+966 500 000 002',
      '966500000002',
      '+٩٦٦ ٥٠٠٠٠٠٠٠٢',
      '۰۵۰۰۰۰۰۰۰۲',
    ]) {
      final result = phone.formatEditUpdate(
        TextEditingValue.empty,
        edit(input),
      );
      expect(result.text, '500000002', reason: input);
      expect(result.selection.extentOffset, 9);
    }
  });

  test('typing and pasting cannot exceed nine national mobile digits', () {
    expect(
      phone.formatEditUpdate(edit('500000002'), edit('5000000023')).text,
      '500000002',
    );
    expect(
      phone
          .formatEditUpdate(TextEditingValue.empty, edit('50000000234567'))
          .text,
      '500000002',
    );
    expect(
      phone.formatEditUpdate(edit('500000002'), edit('50000000')).text,
      '50000000',
    );
    expect(
      phone.formatEditUpdate(edit('500000002'), TextEditingValue.empty).text,
      isEmpty,
    );
  });

  test(
    'digits retain leading zero and selection when Arabic text is filtered',
    () {
      final result = const DigitsInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        edit('٠١٢abc٣۴۵'),
      );
      expect(result.text, '012345');
      expect(result.selection.extentOffset, 6);
    },
  );

  test('commercial registration requires exactly ten digits in the draft', () {
    for (final input in ['', '123', '123456789', '12345678901', '12345abc90']) {
      expect(validCommercialRegistrationNumber(input), isFalse);
    }
    expect(validCommercialRegistrationNumber('0123456789'), isTrue);
    SellerApplicationDraft draft(String registration) => SellerApplicationDraft(
      name: 'Store',
      nickname: 'Store',
      employeeName: 'Owner',
      location: 'https://maps.example.test/store',
      cityId: 1,
      registrationNumber: registration,
    );
    expect(draft('123').isValid, isFalse);
    expect(draft('0123456789').isValid, isTrue);
  });
}
