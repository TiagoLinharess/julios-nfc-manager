String onlyDigits(String value) {
  return value.replaceAll(RegExp('[^0-9]'), '');
}

bool isValidCnpj(String value) {
  final digits = onlyDigits(value);

  if (digits.length != 14) {
    return false;
  }

  if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) {
    return false;
  }

  final numbers = digits.split('').map(int.parse).toList();
  final firstDigit = _calculateCnpjDigit(numbers.take(12).toList());
  final secondDigit = _calculateCnpjDigit(numbers.take(13).toList());

  return numbers[12] == firstDigit && numbers[13] == secondDigit;
}

int _calculateCnpjDigit(List<int> numbers) {
  final weights = numbers.length == 12
      ? const [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      : const [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  var sum = 0;

  for (var index = 0; index < numbers.length; index++) {
    sum += numbers[index] * weights[index];
  }

  final remainder = sum % 11;
  return remainder < 2 ? 0 : 11 - remainder;
}
