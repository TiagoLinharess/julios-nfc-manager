import '../../../core/formatting/br_decimal_formatter.dart';
import '../../nfc/domain/nfc_product_snapshot.dart';
import '../../nfc/domain/nfc_record.dart';
import 'nfc_return_product_snapshot.dart';
import 'nfc_return_record.dart';

enum NfcReturnStatus {
  none,
  partiallyReturned,
  fullyReturned,
}

NfcReturnStatus calculateNfcReturnStatus(
  NfcRecord nfc,
  List<NfcReturnRecord> returns,
) {
  if (nfc.products.isEmpty || returns.isEmpty) {
    return NfcReturnStatus.none;
  }

  var hasReturnedQuantity = false;
  var hasAvailableQuantity = false;

  for (final product in nfc.products) {
    final originalQuantity = parseBrDecimal(product.quantityKg) ?? 0;
    final returnedQuantity = calculateReturnedQuantity(
      product.productId,
      returns,
    );

    if (returnedQuantity > 0) {
      hasReturnedQuantity = true;
    }

    if (originalQuantity - returnedQuantity > 0.0001) {
      hasAvailableQuantity = true;
    }
  }

  if (!hasReturnedQuantity) {
    return NfcReturnStatus.none;
  }

  if (!hasAvailableQuantity) {
    return NfcReturnStatus.fullyReturned;
  }

  return NfcReturnStatus.partiallyReturned;
}

double calculateReturnedQuantity(
  String productId,
  List<NfcReturnRecord> returns,
) {
  var total = 0.0;

  for (final nfcReturn in returns) {
    for (final product in nfcReturn.products) {
      if (product.productId != productId) {
        continue;
      }

      total += parseBrDecimal(product.quantityKg) ?? 0;
    }
  }

  return total;
}

double calculateReturnsTotalValue(List<NfcReturnRecord> returns) {
  var total = 0.0;

  for (final nfcReturn in returns) {
    total += parseBrDecimal(nfcReturn.totalValue) ?? 0;
  }

  return total;
}

double calculateNfcReturnPercentage(
  NfcRecord nfc,
  List<NfcReturnRecord> returns,
) {
  final nfcTotal = parseBrDecimal(nfc.totalValue) ?? 0;

  if (nfcTotal <= 0 || returns.isEmpty) {
    return 0;
  }

  return (calculateReturnsTotalValue(returns) / nfcTotal) * 100;
}

double calculateSingleReturnPercentage(
  NfcRecord nfc,
  NfcReturnRecord nfcReturn,
) {
  final nfcTotal = parseBrDecimal(nfc.totalValue) ?? 0;
  final returnTotal = parseBrDecimal(nfcReturn.totalValue) ?? 0;

  if (nfcTotal <= 0) {
    return 0;
  }

  return (returnTotal / nfcTotal) * 100;
}

double calculateReturnedValueForProduct(
  String productId,
  List<NfcReturnRecord> returns,
) {
  var total = 0.0;

  for (final nfcReturn in returns) {
    for (final product in nfcReturn.products) {
      if (product.productId != productId) {
        continue;
      }

      final price = parseBrDecimal(product.pricePerKg);
      final quantity = parseBrDecimal(product.quantityKg);

      if (price == null || quantity == null) {
        continue;
      }

      total += price * quantity;
    }
  }

  return total;
}

double calculateProductReturnPercentage(
  NfcProductSnapshot? originalProduct,
  NfcReturnProductSnapshot returnedProduct,
) {
  final originalQuantity = parseBrDecimal(originalProduct?.quantityKg ?? '') ?? 0;
  final returnedQuantity = parseBrDecimal(returnedProduct.quantityKg) ?? 0;

  if (originalQuantity <= 0) {
    return 0;
  }

  return (returnedQuantity / originalQuantity) * 100;
}

String? calculateReturnProductSubtotal(NfcReturnProductSnapshot product) {
  final price = parseBrDecimal(product.pricePerKg);
  final quantity = parseBrDecimal(product.quantityKg);

  if (price == null || quantity == null) {
    return null;
  }

  return (price * quantity).toStringAsFixed(2).replaceAll('.', ',');
}
