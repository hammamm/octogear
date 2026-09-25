import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/authentication/domain/entities/saudi_mobile_number.dart';

void main() {
  group('SaudiMobileNumber', () {
    test('accepts the nine-digit in-app format', () {
      final mobile = SaudiMobileNumber.tryParse('500000000');

      expect(mobile?.nationalNumber, '500000000');
      expect(mobile?.displayValue, '+966 500000000');
    });

    test('normalizes common backend-supported Saudi formats', () {
      expect(
        SaudiMobileNumber.tryParse('+966 500000000')?.nationalNumber,
        '500000000',
      );
      expect(
        SaudiMobileNumber.tryParse('0500000000')?.nationalNumber,
        '500000000',
      );
    });

    test('rejects invalid numbers before an OTP request can start', () {
      expect(SaudiMobileNumber.tryParse('400000000'), isNull);
      expect(SaudiMobileNumber.tryParse('50000000'), isNull);
      expect(SaudiMobileNumber.tryParse('5000000000'), isNull);
    });
  });
}
