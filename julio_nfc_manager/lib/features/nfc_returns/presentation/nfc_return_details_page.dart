import 'package:flutter/material.dart';

import '../../../core/formatting/br_decimal_formatter.dart';
import '../../../core/presentation/app_refresh_indicator.dart';
import '../../nfc/domain/nfc_record.dart';
import '../data/nfc_returns_repository.dart';
import '../domain/nfc_return_product_snapshot.dart';
import '../domain/nfc_return_record.dart';
import 'nfc_return_form_page.dart';

class NfcReturnDetailsPage extends StatelessWidget {
  const NfcReturnDetailsPage({
    required this.nfc,
    required this.returnId,
    required this.returns,
    required this.repository,
    super.key,
  });

  final NfcRecord nfc;
  final String returnId;
  final List<NfcReturnRecord> returns;
  final NfcReturnsRepository repository;

  Future<void> _openEditForm(
    BuildContext context,
    NfcReturnRecord nfcReturn,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return NfcReturnFormPage(
            nfc: nfc,
            returns: returns,
            repository: repository,
            nfcReturn: nfcReturn,
          );
        },
      ),
    );
  }

  Future<void> _deleteReturn(
    BuildContext context,
    NfcReturnRecord nfcReturn,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir devolução'),
          content: Text('Deseja excluir ${nfcReturn.code}?'),
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
      return;
    }

    try {
      await repository.delete(nfcId: nfc.id, id: nfcReturn.id);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a devolução.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NfcReturnRecord?>(
      stream: repository.watchById(nfcId: nfc.id, id: returnId),
      builder: (context, snapshot) {
        final nfcReturn = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Devolução'),
            actions: [
              IconButton(
                onPressed: nfcReturn == null
                    ? null
                    : () async {
                        await _openEditForm(context, nfcReturn);
                      },
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: nfcReturn == null
                    ? null
                    : () async {
                        await _deleteReturn(context, nfcReturn);
                      },
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: _buildBody(context, snapshot, nfcReturn),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<NfcReturnRecord?> snapshot,
    NfcReturnRecord? nfcReturn,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return const _NfcReturnDetailsMessage(
        icon: Icons.error_outline,
        title: 'Não foi possível carregar a devolução.',
      );
    }

    if (nfcReturn == null) {
      return const _NfcReturnDetailsMessage(
        icon: Icons.assignment_return_outlined,
        title: 'Devolução não encontrada.',
      );
    }

    return AppRefreshIndicator(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _NfcReturnHeader(nfcReturn: nfcReturn),
          const SizedBox(height: 24),
          _DetailTile(
            icon: Icons.confirmation_number_outlined,
            label: 'Número da devolução',
            value: nfcReturn.code,
          ),
          _DetailTile(
            icon: Icons.event_outlined,
            label: 'Data',
            value: nfcReturn.date,
          ),
          _DetailTile(
            icon: Icons.paid_outlined,
            label: 'Valor da devolução',
            value: 'R\$ ${nfcReturn.totalValue}',
          ),
          const SizedBox(height: 16),
          Text('Produtos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (nfcReturn.products.isEmpty)
            const Text('Nenhum produto devolvido.')
          else
            ...nfcReturn.products.map((product) {
              return _NfcReturnProductTile(product: product);
            }),
        ],
      ),
    );
  }
}

class _NfcReturnHeader extends StatelessWidget {
  const _NfcReturnHeader({required this.nfcReturn});

  final NfcReturnRecord nfcReturn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.primaryContainer,
          child: const Icon(Icons.assignment_return_outlined, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          nfcReturn.code,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          nfcReturn.date,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'R\$ ${nfcReturn.totalValue}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _NfcReturnProductTile extends StatelessWidget {
  const _NfcReturnProductTile({required this.product});

  final NfcReturnProductSnapshot product;

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal(product);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(product.name),
      subtitle: Text('${product.quantityKg} kg | R\$ ${product.pricePerKg}/kg'),
      trailing: Text(
        subtotal == null ? '-' : 'R\$ $subtotal',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

String? _calculateSubtotal(NfcReturnProductSnapshot product) {
  final price = parseBrDecimal(product.pricePerKg);
  final quantity = parseBrDecimal(product.quantityKg);

  if (price == null || quantity == null) {
    return null;
  }

  return (price * quantity).toStringAsFixed(2).replaceAll('.', ',');
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _NfcReturnDetailsMessage extends StatelessWidget {
  const _NfcReturnDetailsMessage({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
