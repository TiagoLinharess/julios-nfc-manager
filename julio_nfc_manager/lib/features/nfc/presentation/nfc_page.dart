import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/firestore/user_firestore.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/domain/customer.dart';
import '../../products/data/products_repository.dart';
import '../../nfc_returns/data/nfc_returns_repository.dart';
import '../../nfc_returns/domain/nfc_return_record.dart';
import '../../nfc_returns/domain/nfc_return_summary.dart';
import '../data/nfc_repository.dart';
import '../domain/nfc_record.dart';
import 'nfc_details_page.dart';
import 'nfc_form_page.dart';

class NfcPage extends StatefulWidget {
  const NfcPage({
    required this.user,
    super.key,
  });

  final User user;

  @override
  State<NfcPage> createState() => _NfcPageState();
}

class _NfcPageState extends State<NfcPage> {
  late final NfcRepository _nfcRepository;
  late final NfcReturnsRepository _nfcReturnsRepository;
  late final CustomersRepository _customersRepository;
  late final ProductsRepository _productsRepository;

  @override
  void initState() {
    super.initState();
    final store = UserFirestore(uid: widget.user.uid);
    _nfcRepository = NfcRepository(store);
    _nfcReturnsRepository = NfcReturnsRepository(store);
    _customersRepository = CustomersRepository(store);
    _productsRepository = ProductsRepository(store);
  }

  Future<void> _openNfcForm([NfcRecord? nfc]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return NfcFormPage(
            nfc: nfc,
            nfcRepository: _nfcRepository,
            customersRepository: _customersRepository,
            productsRepository: _productsRepository,
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(NfcRecord nfc) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir NFC'),
          content: Text('Deseja excluir ${nfc.code}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return false;
    }

    try {
      await _nfcRepository.delete(nfc.id);
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a NFC.')),
      );
      return false;
    }
  }

  Future<void> _openNfcDetails(NfcRecord nfc) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return NfcDetailsPage(
            nfcId: nfc.id,
            nfcRepository: _nfcRepository,
            customersRepository: _customersRepository,
            nfcReturnsRepository: _nfcReturnsRepository,
            onEdit: _openNfcForm,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Customer>>(
        stream: _customersRepository.watchAll(),
        builder: (context, customersSnapshot) {
          return StreamBuilder<List<NfcRecord>>(
            stream: _nfcRepository.watchAll(),
            builder: (context, nfcSnapshot) {
              final colorScheme = Theme.of(context).colorScheme;

              if (customersSnapshot.connectionState ==
                      ConnectionState.waiting ||
                  nfcSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (nfcSnapshot.hasError) {
                return _EmptyState(
                  icon: Icons.error_outline,
                  title: 'Não foi possível carregar as NFCs.',
                  subtitle: nfcSnapshot.error.toString(),
                );
              }

              final customers = customersSnapshot.data ?? const <Customer>[];
              final customerNames = {
                for (final customer in customers) customer.id: customer.name,
              };
              final records = nfcSnapshot.data ?? const <NfcRecord>[];

              if (records.isEmpty) {
                return const _EmptyState(
                  icon: Icons.nfc_outlined,
                  title: 'Nenhuma NFC cadastrada',
                  subtitle: 'Toque no botão + para criar a primeira NFC.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: records.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final nfc = records[index];
                  final customerName =
                      customerNames[nfc.customerId] ?? 'Cliente não encontrado';

                  return StreamBuilder<List<NfcReturnRecord>>(
                    stream: _nfcReturnsRepository.watchAll(nfc.id),
                    builder: (context, returnsSnapshot) {
                      final returns =
                          returnsSnapshot.data ?? const <NfcReturnRecord>[];
                      final status = calculateNfcReturnStatus(
                        nfc,
                        returns,
                      );
                      final returnPercentage =
                          calculateNfcReturnPercentage(nfc, returns);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: const Icon(Icons.nfc),
                        ),
                        title: _NfcListTitle(
                          customerName: customerName,
                          date: nfc.date,
                        ),
                        subtitle: _NfcListSubtitle(
                          nfc: nfc,
                          status: returnsSnapshot.connectionState ==
                                  ConnectionState.waiting
                              ? null
                              : status,
                          returnPercentage: returnPercentage,
                        ),
                        trailing: IconButton(
                          onPressed: () => _confirmDelete(nfc),
                          tooltip: 'Excluir',
                          icon: const Icon(Icons.delete_outline),
                        ),
                        onTap: () => _openNfcDetails(nfc),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNfcForm(),
        icon: const Icon(Icons.add),
        label: const Text('NFC'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NfcListTitle extends StatelessWidget {
  const _NfcListTitle({
    required this.customerName,
    required this.date,
  });

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
          Text(
            '${nfc.code} | R\$ ${nfc.totalValue}',
            style: textStyle,
          ),
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
              ),
        ),
      ),
    );
  }
}

String _formatNfcListPercentage(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
