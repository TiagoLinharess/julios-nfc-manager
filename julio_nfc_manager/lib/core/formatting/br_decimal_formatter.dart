String formatBrDecimal(String value) {
  final parsed = parseBrDecimal(value);

  if (parsed == null) {
    return '';
  }

  return parsed.toStringAsFixed(2).replaceAll('.', ',');
}

double? parseBrDecimal(String value) {
  final trimmed = value.trim();
  final normalized = trimmed.contains(',')
      ? trimmed.replaceAll('.', '').replaceAll(',', '.')
      : trimmed;

  if (normalized.isEmpty) {
    return null;
  }

  return double.tryParse(normalized);
}
