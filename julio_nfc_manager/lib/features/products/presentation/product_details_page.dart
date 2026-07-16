import 'package:flutter/material.dart';

import '../data/products_repository.dart';
import '../domain/product.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({
    required this.productId,
    required this.productsRepository,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final String productId;
  final ProductsRepository productsRepository;
  final Future<void> Function(Product product) onEdit;
  final Future<bool> Function(Product product) onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: productsRepository.watchById(productId),
      builder: (context, snapshot) {
        final product = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Produto'),
            actions: [
              IconButton(
                onPressed: product == null ? null : () => onEdit(product),
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: product == null
                    ? null
                    : () async {
                        final deleted = await onDelete(product);

                        if (deleted && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: _buildBody(context, snapshot, product),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<Product?> snapshot,
    Product? product,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return const _ProductDetailsMessage(
        icon: Icons.error_outline,
        title: 'Não foi possível carregar o produto.',
      );
    }

    if (product == null) {
      return const _ProductDetailsMessage(
        icon: Icons.inventory_2_outlined,
        title: 'Produto não encontrado.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProductHeader(product: product),
        const SizedBox(height: 24),
        _DetailTile(
          icon: Icons.inventory_2_outlined,
          label: 'Nome',
          value: product.name,
        ),
        _DetailTile(
          icon: Icons.paid_outlined,
          label: 'Valor por kg',
          value: 'R\$ ${product.pricePerKg}/kg',
        ),
      ],
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = product.name.trim().isEmpty
        ? '?'
        : product.name.trim().substring(0, 1).toUpperCase();

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
          product.name,
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

class _ProductDetailsMessage extends StatelessWidget {
  const _ProductDetailsMessage({
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
