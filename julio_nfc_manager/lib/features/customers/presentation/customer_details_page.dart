import 'package:flutter/material.dart';

import '../data/customers_repository.dart';
import '../domain/customer.dart';

class CustomerDetailsPage extends StatelessWidget {
  const CustomerDetailsPage({
    required this.customerId,
    required this.customersRepository,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final String customerId;
  final CustomersRepository customersRepository;
  final Future<void> Function(Customer customer) onEdit;
  final Future<bool> Function(Customer customer) onDelete;

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

    return ListView(
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
      ],
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
  const _CustomerDetailsMessage({
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
