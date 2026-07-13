import 'package:flutter_test/flutter_test.dart';
import 'package:julio_nfc_manager/core/validation/cnpj_validator.dart';

void main() {
  group('isValidCnpj', () {
    test('accepts valid formatted CNPJ', () {
      expect(isValidCnpj('11.222.333/0001-81'), isTrue);
    });

    test('accepts valid unformatted CNPJ', () {
      expect(isValidCnpj('11222333000181'), isTrue);
    });

    test('rejects invalid check digits', () {
      expect(isValidCnpj('11.222.333/0001-82'), isFalse);
    });

    test('rejects repeated digits', () {
      expect(isValidCnpj('00.000.000/0000-00'), isFalse);
    });

    test('rejects values with fewer than 14 digits', () {
      expect(isValidCnpj('12.345.678/0001'), isFalse);
    });
  });
}
