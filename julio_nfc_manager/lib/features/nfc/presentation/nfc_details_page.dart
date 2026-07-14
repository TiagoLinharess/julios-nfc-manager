import 'package:flutter/material.dart';

import '../data/nfc_repository.dart';
import '../domain/nfc_record.dart';

class NfcDetailsPage extends StatelessWidget {
  const NfcDetailsPage({
    required this.nfcId,
    required this.nfcRepository,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final String nfcId;
  final NfcRepository nfcRepository;
  final Future<void> Function(NfcRecord nfc) onEdit;
  final Future<bool> Function(NfcRecord nfc) onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NfcRecord?>(
      stream: nfcRepository.watchById(nfcId),
      builder: (context, snapshot) {
        final nfc = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('NFC'),
            actions: [
              IconButton(
                onPressed: nfc == null ? null : () => onEdit(nfc),
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: nfc == null
                    ? null
                    : () async {
                        final deleted = await onDelete(nfc);

                        if (deleted && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: _buildBody(context, snapshot, nfc),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<NfcRecord?> snapshot,
    NfcRecord? nfc,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return const _NfcDetailsMessage(
        icon: Icons.error_outline,
        title: 'Nao foi possivel carregar a NFC.',
      );
    }

    if (nfc == null) {
      return const _NfcDetailsMessage(
        icon: Icons.nfc_outlined,
        title: 'NFC nao encontrada.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _NfcHeader(nfc: nfc),
        const SizedBox(height: 24),
        _DetailTile(
          icon: Icons.confirmation_number_outlined,
          label: 'Codigo',
          value: nfc.code,
        ),
        _DetailTile(
          icon: Icons.event_outlined,
          label: 'Data',
          value: nfc.date,
        ),
        _DetailTile(
          icon: Icons.paid_outlined,
          label: 'Valor da nota',
          value: 'R\$ ${nfc.totalValue}',
        ),
        _DetailTile(
          icon: Icons.person_outline,
          label: 'Cliente',
          value: nfc.customerId,
        ),
        const SizedBox(height: 16),
        Text(
          'Produtos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (nfc.products.isEmpty)
          const Text('Nenhum produto vinculado.')
        else
          ...nfc.products.map((product) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(product.name),
              subtitle: Text(
                '${product.quantityKg} kg | R\$ ${product.pricePerKg}/kg',
              ),
            );
          }),
      ],
    );
  }
}

class _NfcHeader extends StatelessWidget {
  const _NfcHeader({required this.nfc});

  final NfcRecord nfc;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.primaryContainer,
          child: const Icon(Icons.nfc, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          nfc.code,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'R\$ ${nfc.totalValue}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
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

class _NfcDetailsMessage extends StatelessWidget {
  const _NfcDetailsMessage({
    required this.icon,
    required this.title,
  });

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
