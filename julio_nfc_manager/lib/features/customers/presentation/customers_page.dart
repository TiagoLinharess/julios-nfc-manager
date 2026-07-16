import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/firestore/user_firestore.dart';
import '../../../core/presentation/responsive_form_dialog.dart';
import '../../../core/validation/cnpj_validator.dart';
import '../data/customers_repository.dart';
import '../domain/customer.dart';
import 'customer_details_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({
    required this.user,
    super.key,
  });

  final User user;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late final CustomersRepository _customersRepository;

  @override
  void initState() {
    super.initState();
    _customersRepository = CustomersRepository(
      UserFirestore(uid: widget.user.uid),
    );
  }

  Future<void> _showCustomerForm([Customer? customer]) async {
    final result = await showDialog<_CustomerFormResult>(
      context: context,
      builder: (context) => _CustomerFormDialog(customer: customer),
    );

    if (result == null) {
      return;
    }

    try {
      if (customer == null) {
        await _customersRepository.create(
          name: result.name,
          cnpj: result.cnpj,
        );
      } else {
        await _customersRepository.update(
          id: customer.id,
          name: result.name,
          cnpj: result.cnpj,
        );
      }
    } on DuplicateCustomerCnpjException {
      if (!mounted) {
        return;
      }

      _showError('Ja existe um cliente com este CNPJ.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Não foi possível salvar o cliente.');
    }
  }

  Future<bool> _confirmDelete(Customer customer) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir cliente'),
          content: Text('Deseja excluir ${customer.name}?'),
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
      await _customersRepository.delete(customer.id);
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      _showError('Não foi possível excluir o cliente.');
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openCustomerDetails(Customer customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return CustomerDetailsPage(
            customerId: customer.id,
            customersRepository: _customersRepository,
            onEdit: _showCustomerForm,
            onDelete: _confirmDelete,
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
        builder: (context, snapshot) {
          final colorScheme = Theme.of(context).colorScheme;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              title: 'Não foi possível carregar os clientes.',
              subtitle: snapshot.error.toString(),
            );
          }

          final customers = snapshot.data ?? const <Customer>[];

          if (customers.isEmpty) {
            return const _EmptyState(
              icon: Icons.people_outline,
              title: 'Nenhum cliente cadastrado',
              subtitle: 'Toque no botão + para criar o primeiro cliente.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: customers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final customer = customers[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    customer.name.trim().isEmpty
                        ? '?'
                        : customer.name.trim().substring(0, 1).toUpperCase(),
                  ),
                ),
                title: Text(customer.name),
                subtitle: Text(customer.cnpj),
                trailing: PopupMenuButton<_CustomerAction>(
                  tooltip: 'Acoes',
                  onSelected: (action) {
                    switch (action) {
                      case _CustomerAction.edit:
                        _showCustomerForm(customer);
                      case _CustomerAction.delete:
                        _confirmDelete(customer);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _CustomerAction.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _CustomerAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Excluir'),
                      ),
                    ),
                  ],
                ),
                onTap: () => _openCustomerDetails(customer),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerForm(),
        icon: const Icon(Icons.add),
        label: const Text('Cliente'),
      ),
    );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  const _CustomerFormDialog({this.customer});

  final Customer? customer;

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp('[0-9]')},
  );

  late final TextEditingController _nameController;
  late final TextEditingController _cnpjController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _cnpjController = TextEditingController(
      text: _cnpjFormatter.maskText(widget.customer?.cnpj ?? ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _CustomerFormResult(
        name: _nameController.text,
        cnpj: _cnpjController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return ResponsiveFormDialog(
      title: Text(isEditing ? 'Editar cliente' : 'Novo cliente'),
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
                prefixIcon: Icon(Icons.business_outlined),
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
              controller: _cnpjController,
              inputFormatters: [_cnpjFormatter],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CNPJ',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o CNPJ.';
                }

                if (_cnpjFormatter.getUnmaskedText().length != 14) {
                  return 'Informe os 14 digitos do CNPJ.';
                }

                if (!isValidCnpj(value)) {
                  return 'Informe um CNPJ válido.';
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

class _CustomerFormResult {
  const _CustomerFormResult({
    required this.name,
    required this.cnpj,
  });

  final String name;
  final String cnpj;
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

enum _CustomerAction {
  edit,
  delete,
}
