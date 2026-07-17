import 'package:flutter/material.dart';

import '../../../core/presentation/app_refresh_indicator.dart';
import '../../nfc/data/nfc_repository.dart';
import '../../nfc/domain/nfc_record.dart';
import '../../nfc/presentation/nfc_details_page.dart';
import '../../nfc/presentation/nfc_form_page.dart';
import '../../nfc/presentation/widgets/nfc_list_tile.dart';
import '../../nfc_returns/data/nfc_returns_repository.dart';
import '../../products/data/products_repository.dart';
import '../data/customers_repository.dart';
import '../domain/customer.dart';

class CustomerDetailsPage extends StatelessWidget {
  const CustomerDetailsPage({
    required this.customerId,
    required this.customersRepository,
    required this.nfcRepository,
    required this.nfcReturnsRepository,
    required this.productsRepository,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final String customerId;
  final CustomersRepository customersRepository;
  final NfcRepository nfcRepository;
  final NfcReturnsRepository nfcReturnsRepository;
  final ProductsRepository productsRepository;
  final Future<void> Function(Customer customer) onEdit;
  final Future<bool> Function(Customer customer) onDelete;

  Future<void> _openNfcForm(BuildContext context, [NfcRecord? nfc]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return NfcFormPage(
            nfc: nfc,
            nfcRepository: nfcRepository,
            customersRepository: customersRepository,
            productsRepository: productsRepository,
          );
        },
      ),
    );
  }

  Future<void> _openNfcDetails(BuildContext context, NfcRecord nfc) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return NfcDetailsPage(
            nfcId: nfc.id,
            nfcRepository: nfcRepository,
            customersRepository: customersRepository,
            nfcReturnsRepository: nfcReturnsRepository,
            onEdit: (nfc) => _openNfcForm(context, nfc),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteNfc(BuildContext context, NfcRecord nfc) async {
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
      return;
    }

    try {
      await nfcRepository.delete(nfc.id);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a NFC.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Customer?>(
      stream: customersRepository.watchById(customerId),
      builder: (context, snapshot) {
        final customer = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cliente'),
            actions: [
              IconButton(
                onPressed: customer == null ? null : () => onEdit(customer),
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: customer == null
                    ? null
                    : () async {
                        final deleted = await onDelete(customer);

                        if (deleted && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: _buildBody(context, snapshot, customer),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<Customer?> snapshot,
    Customer? customer,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return const _CustomerDetailsMessage(
        icon: Icons.error_outline,
        title: 'Não foi possível carregar o cliente.',
      );
    }

    if (customer == null) {
      return const _CustomerDetailsMessage(
        icon: Icons.person_off_outlined,
        title: 'Cliente não encontrado.',
      );
    }

    return AppRefreshIndicator(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _CustomerHeader(customer: customer),
          const SizedBox(height: 24),
          _DetailTile(
            icon: Icons.business_outlined,
            label: 'Nome',
            value: customer.name,
          ),
          _DetailTile(
            icon: Icons.badge_outlined,
            label: 'CNPJ',
            value: customer.cnpj,
          ),
          const SizedBox(height: 24),
          _CustomerNfcSection(
            customer: customer,
            nfcRepository: nfcRepository,
            nfcReturnsRepository: nfcReturnsRepository,
            onOpenNfc: (nfc) => _openNfcDetails(context, nfc),
            onDeleteNfc: (nfc) => _confirmDeleteNfc(context, nfc),
          ),
        ],
      ),
    );
  }
}

class _CustomerNfcSection extends StatelessWidget {
  const _CustomerNfcSection({
    required this.customer,
    required this.nfcRepository,
    required this.nfcReturnsRepository,
    required this.onOpenNfc,
    required this.onDeleteNfc,
  });

  final Customer customer;
  final NfcRepository nfcRepository;
  final NfcReturnsRepository nfcReturnsRepository;
  final void Function(NfcRecord nfc) onOpenNfc;
  final void Function(NfcRecord nfc) onDeleteNfc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NfcRecord>>(
      stream: nfcRepository.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NFCs', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Não foi possível carregar as NFCs deste cliente.'),
            ],
          );
        }

        final records = (snapshot.data ?? const <NfcRecord>[])
            .where((nfc) => nfc.customerId == customer.id)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NFCs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (records.isEmpty)
              const Text('Nenhuma NFC cadastrada para este cliente.')
            else
              ...List.generate(records.length, (index) {
                final nfc = records[index];

                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1),
                    NfcListTile(
                      nfc: nfc,
                      customerName: customer.name,
                      returnsRepository: nfcReturnsRepository,
                      onTap: () => onOpenNfc(nfc),
                      onDelete: () => onDeleteNfc(nfc),
                    ),
                  ],
                );
              }),
          ],
        );
      },
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = customer.name.trim().isEmpty
        ? '?'
        : customer.name.trim().substring(0, 1).toUpperCase();

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            initial,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          customer.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
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

class _CustomerDetailsMessage extends StatelessWidget {
  const _CustomerDetailsMessage({required this.icon, required this.title});

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
