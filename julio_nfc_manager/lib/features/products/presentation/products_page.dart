import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatting/br_decimal_formatter.dart';
import '../../../core/firestore/user_firestore.dart';
import '../../../core/presentation/app_refresh_indicator.dart';
import '../../../core/presentation/responsive_form_dialog.dart';
import '../data/products_repository.dart';
import '../domain/product.dart';
import 'product_details_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({required this.user, super.key});

  final User user;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final ProductsRepository _productsRepository;

  @override
  void initState() {
    super.initState();
    _productsRepository = ProductsRepository(
      UserFirestore(uid: widget.user.uid),
    );
  }

  Future<void> _showProductForm([Product? product]) async {
    final result = await showDialog<_ProductFormResult>(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
    );

    if (result == null) {
      return;
    }

    try {
      if (product == null) {
        await _productsRepository.create(
          name: result.name,
          pricePerKg: result.pricePerKg,
        );
      } else {
        await _productsRepository.update(
          id: product.id,
          name: result.name,
          pricePerKg: result.pricePerKg,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Não foi possível salvar o produto.');
    }
  }

  Future<bool> _confirmDelete(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir produto'),
          content: Text('Deseja excluir ${product.name}?'),
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
      await _productsRepository.delete(product.id);
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      _showError('Não foi possível excluir o produto.');
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openProductDetails(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ProductDetailsPage(
            productId: product.id,
            productsRepository: _productsRepository,
            onEdit: _showProductForm,
            onDelete: _confirmDelete,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Product>>(
        stream: _productsRepository.watchAll(),
        builder: (context, snapshot) {
          final colorScheme = Theme.of(context).colorScheme;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              title: 'Não foi possível carregar os produtos.',
              subtitle: snapshot.error.toString(),
            );
          }

          final products = snapshot.data ?? const <Product>[];

          if (products.isEmpty) {
            return const _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nenhum produto cadastrado',
              subtitle: 'Toque no botão + para criar o primeiro produto.',
            );
          }

          return AppRefreshIndicator(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = products[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      product.name.trim().isEmpty
                          ? '?'
                          : product.name.trim().substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text('R\$ ${product.pricePerKg}/kg'),
                  trailing: PopupMenuButton<_ProductAction>(
                    tooltip: 'Acoes',
                    onSelected: (action) {
                      switch (action) {
                        case _ProductAction.edit:
                          _showProductForm(product);
                        case _ProductAction.delete:
                          _confirmDelete(product);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _ProductAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: _ProductAction.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Excluir'),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _openProductDetails(product),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Produto'),
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product});

  final Product? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _pricePerKgController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _pricePerKgController = TextEditingController(
      text: widget.product?.pricePerKg ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pricePerKgController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _ProductFormResult(
        name: _nameController.text,
        pricePerKg: formatBrDecimal(_pricePerKgController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return ResponsiveFormDialog(
      title: Text(isEditing ? 'Editar produto' : 'Novo produto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pricePerKgController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9,]')),
              ],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor por kg',
                prefixIcon: Icon(Icons.paid_outlined),
                prefixText: 'R\$ ',
                suffixText: '/kg',
              ),
              validator: (value) {
                final rawValue = value ?? '';
                final price = parseBrDecimal(rawValue);

                if (rawValue.trim().isEmpty) {
                  return 'Informe o valor por kg.';
                }

                if (price == null || price <= 0) {
                  return 'Informe um valor válido.';
                }

                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}

class _ProductFormResult {
  const _ProductFormResult({required this.name, required this.pricePerKg});

  final String name;
  final String pricePerKg;
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

enum _ProductAction { edit, delete }
