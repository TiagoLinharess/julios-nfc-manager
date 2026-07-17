import 'package:flutter/material.dart';

import '../../../nfc_returns/data/nfc_returns_repository.dart';
import '../../../nfc_returns/domain/nfc_return_record.dart';
import '../../../nfc_returns/domain/nfc_return_summary.dart';
import '../../domain/nfc_record.dart';

class NfcListTile extends StatelessWidget {
  const NfcListTile({
    required this.nfc,
    required this.customerName,
    required this.returnsRepository,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final NfcRecord nfc;
  final String customerName;
  final NfcReturnsRepository returnsRepository;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<NfcReturnRecord>>(
      stream: returnsRepository.watchAll(nfc.id),
      builder: (context, returnsSnapshot) {
        final returns = returnsSnapshot.data ?? const <NfcReturnRecord>[];
        final status = calculateNfcReturnStatus(nfc, returns);
        final returnPercentage = calculateNfcReturnPercentage(nfc, returns);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: const Icon(Icons.receipt_long),
          ),
          title: _NfcListTitle(customerName: customerName, date: nfc.date),
          subtitle: _NfcListSubtitle(
            nfc: nfc,
            status: returnsSnapshot.connectionState == ConnectionState.waiting
                ? null
                : status,
            returnPercentage: returnPercentage,
          ),
          trailing: IconButton(
            onPressed: onDelete,
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
          ),
          onTap: onTap,
        );
      },
    );
  }
}

class _NfcListTitle extends StatelessWidget {
  const _NfcListTitle({required this.customerName, required this.date});

  final String customerName;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Text('$customerName | $date');
  }
}

class _NfcListSubtitle extends StatelessWidget {
  const _NfcListSubtitle({
    required this.nfc,
    required this.status,
    required this.returnPercentage,
  });

  final NfcRecord nfc;
  final NfcReturnStatus? status;
  final double returnPercentage;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    if (isLandscape) {
      return Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${nfc.code} | R\$ ${nfc.totalValue}', style: textStyle),
          if (status != null)
            _NfcListReturnStatusChip(
              status: status!,
              percentage: returnPercentage,
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(nfc.code, style: textStyle),
        Text('R\$ ${nfc.totalValue}', style: textStyle),
        if (status != null) ...[
          const SizedBox(height: 4),
          _NfcListReturnStatusChip(
            status: status!,
            percentage: returnPercentage,
          ),
        ],
      ],
    );
  }
}

class _NfcListReturnStatusChip extends StatelessWidget {
  const _NfcListReturnStatusChip({
    required this.status,
    required this.percentage,
  });

  final NfcReturnStatus status;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      NfcReturnStatus.none => ('Sem devolução', colorScheme.outline),
      NfcReturnStatus.partiallyReturned => (
        'Parcialmente devolvida',
        colorScheme.primary,
      ),
      NfcReturnStatus.fullyReturned => (
        'Totalmente devolvida',
        colorScheme.tertiary,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          '$label · ${_formatNfcListPercentage(percentage)}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}

String _formatNfcListPercentage(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
