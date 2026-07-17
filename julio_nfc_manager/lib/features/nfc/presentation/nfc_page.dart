import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/firestore/user_firestore.dart';
import '../../../core/presentation/app_refresh_indicator.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/domain/customer.dart';
import '../../products/data/products_repository.dart';
import '../../nfc_returns/data/nfc_returns_repository.dart';
import '../data/nfc_repository.dart';
import '../domain/nfc_record.dart';
import 'nfc_details_page.dart';
import 'nfc_form_page.dart';
import 'widgets/nfc_list_tile.dart';

class NfcPage extends StatefulWidget {
  const NfcPage({required this.user, super.key});

  final User user;

  @override
  State<NfcPage> createState() => _NfcPageState();
}

class _NfcPageState extends State<NfcPage> {
  late final NfcRepository _nfcRepository;
  late final NfcReturnsRepository _nfcReturnsRepository;
  late final CustomersRepository _customersRepository;
  late final ProductsRepository _productsRepository;

  String? _customerFilterId;
  String _dateFilter = '';
  int _filterResetVersion = 0;

  @override
  void initState() {
    super.initState();
    final store = UserFirestore(uid: widget.user.uid);
    _nfcRepository = NfcRepository(store);
    _nfcReturnsRepository = NfcReturnsRepository(store);
    _customersRepository = CustomersRepository(store);
    _productsRepository = ProductsRepository(store);
  }

  void _clearFilters() {
    setState(() {
      _customerFilterId = null;
      _dateFilter = '';
      _filterResetVersion++;
    });
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
              final activeCustomerFilter =
                  customers.any((customer) => customer.id == _customerFilterId)
                  ? _customerFilterId
                  : null;
              final dateFilter = _dateFilter;
              final shouldFilterByDate = dateFilter.length == 10;

              if (records.isEmpty) {
                return const _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Nenhuma NFC cadastrada',
                  subtitle: 'Toque no botão + para criar a primeira NFC.',
                );
              }

              final filteredRecords = records.where((nfc) {
                if (activeCustomerFilter != null &&
                    nfc.customerId != activeCustomerFilter) {
                  return false;
                }

                if (shouldFilterByDate && nfc.date != dateFilter) {
                  return false;
                }

                return true;
              }).toList();
              final hasActiveFilters =
                  activeCustomerFilter != null || dateFilter.isNotEmpty;

              return AppRefreshIndicator(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    _NfcFilters(
                      customers: customers,
                      selectedCustomerId: activeCustomerFilter,
                      activeDateFilter: dateFilter,
                      resetVersion: _filterResetVersion,
                      hasActiveFilters: hasActiveFilters,
                      onCustomerChanged: (customerId) {
                        setState(() {
                          _customerFilterId = customerId;
                        });
                      },
                      onDateFilterChanged: (date) {
                        setState(() {
                          _dateFilter = date;
                        });
                      },
                      onClear: _clearFilters,
                    ),
                    const SizedBox(height: 8),
                    if (filteredRecords.isEmpty)
                      const _FilteredEmptyState()
                    else
                      ...List.generate(filteredRecords.length, (index) {
                        final nfc = filteredRecords[index];
                        final customerName =
                            customerNames[nfc.customerId] ??
                            'Cliente não encontrado';

                        return Column(
                          children: [
                            if (index > 0) const Divider(height: 1),
                            NfcListTile(
                              nfc: nfc,
                              customerName: customerName,
                              returnsRepository: _nfcReturnsRepository,
                              onTap: () => _openNfcDetails(nfc),
                              onDelete: () => _confirmDelete(nfc),
                            ),
                          ],
                        );
                      }),
                  ],
                ),
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

class _NfcFilters extends StatefulWidget {
  const _NfcFilters({
    required this.customers,
    required this.selectedCustomerId,
    required this.activeDateFilter,
    required this.resetVersion,
    required this.hasActiveFilters,
    required this.onCustomerChanged,
    required this.onDateFilterChanged,
    required this.onClear,
  });

  final List<Customer> customers;
  final String? selectedCustomerId;
  final String activeDateFilter;
  final int resetVersion;
  final bool hasActiveFilters;
  final ValueChanged<String?> onCustomerChanged;
  final ValueChanged<String> onDateFilterChanged;
  final VoidCallback onClear;

  @override
  State<_NfcFilters> createState() => _NfcFiltersState();
}

class _NfcFiltersState extends State<_NfcFilters> {
  late final TextEditingController _dateController;
  final _dateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp('[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.activeDateFilter);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _NfcFilters oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.resetVersion != widget.resetVersion) {
      _dateController.clear();
      _dateFormatter.clear();
      return;
    }

    if (oldWidget.activeDateFilter != widget.activeDateFilter &&
        widget.activeDateFilter.isNotEmpty &&
        _dateController.text != widget.activeDateFilter) {
      _dateController.text = widget.activeDateFilter;
      _dateFormatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: widget.activeDateFilter),
      );
    }
  }

  void _clearDate() {
    setState(() {
      _dateController.clear();
      _dateFormatter.clear();
    });
    widget.onDateFilterChanged('');
  }

  void _handleDateChanged(String value) {
    setState(() {});

    if (value.isEmpty || value.length == 10) {
      widget.onDateFilterChanged(value);
    } else if (widget.activeDateFilter.isNotEmpty) {
      widget.onDateFilterChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      DropdownButtonFormField<String>(
        initialValue: widget.selectedCustomerId,
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Todos os clientes'),
          ),
          ...widget.customers.map((customer) {
            return DropdownMenuItem<String>(
              value: customer.id,
              child: Text(customer.name),
            );
          }),
        ],
        decoration: const InputDecoration(
          labelText: 'Cliente',
          prefixIcon: Icon(Icons.person_outline),
        ),
        onChanged: widget.onCustomerChanged,
      ),
      TextField(
        controller: _dateController,
        inputFormatters: [_dateFormatter],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Data',
          hintText: 'dd/mm/aaaa',
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: _dateController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _clearDate,
                  tooltip: 'Limpar data',
                  icon: const Icon(Icons.close),
                ),
        ),
        onChanged: _handleDateChanged,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 620) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 12),
                  SizedBox(width: 220, child: fields[1]),
                ],
              );
            }

            return Column(
              children: [fields[0], const SizedBox(height: 12), fields[1]],
            );
          },
        ),
        if (widget.hasActiveFilters) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onClear,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpar filtros'),
          ),
        ],
      ],
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Nenhuma NFC encontrada com estes filtros.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
