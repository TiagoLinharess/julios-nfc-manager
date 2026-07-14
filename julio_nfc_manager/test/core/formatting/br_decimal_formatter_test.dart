import 'package:flutter_test/flutter_test.dart';
import 'package:julio_nfc_manager/core/formatting/br_decimal_formatter.dart';

void main() {
  group('formatBrDecimal', () {
    test('adds two decimal places when none are informed', () {
      expect(formatBrDecimal('12'), '12,00');
    });

    test('pads one decimal place', () {
      expect(formatBrDecimal('12,3'), '12,30');
    });

    test('rounds to two decimal places', () {
      expect(formatBrDecimal('12,345'), '12,35');
    });

    test('keeps comma as decimal separator', () {
      expect(formatBrDecimal('12.5'), '12,50');
    });
  });
}
