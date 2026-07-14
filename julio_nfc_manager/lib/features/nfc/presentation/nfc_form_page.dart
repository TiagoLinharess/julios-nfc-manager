import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/formatting/br_decimal_formatter.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/domain/customer.dart';
import '../../products/data/products_repository.dart';
import '../../products/domain/product.dart';
import '../data/nfc_repository.dart';
import '../domain/nfc_product_snapshot.dart';
import '../domain/nfc_record.dart';

class NfcFormPage extends StatefulWidget {
  const NfcFormPage({
    required this.nfcRepository,
    required this.customersRepository,
    required this.productsRepository,
    this.nfc,
    super.key,
  });

  final NfcRepository nfcRepository;
  final CustomersRepository customersRepository;
  final ProductsRepository productsRepository;
  final NfcRecord? nfc;

  @override
  State<NfcFormPage> createState() => _NfcFormPageState();
}

class _NfcFormPageState extends State<NfcFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp('[0-9]')},
  );

  late final TextEditingController _codeController;
  late final TextEditingController _dateController;
  late final TextEditingController _totalValueController;
  final Set<String> _selectedProductIds = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  Future<_NfcFormData>? _formDataFuture;

  String? _selectedCustomerId;
  String? _productToAddId;
  bool _isSaving = false;
  bool _isCustomTotalValue = false;
  bool _hasTriedSubmit = false;

  bool get _isEditing => widget.nfc != null;

  @override
  void initState() {
    super.initState();
    final nfc = widget.nfc;

    _codeController = TextEditingController(text: nfc?.code ?? '');
    _dateController = TextEditingController(
      text: _dateFormatter.maskText(nfc?.date ?? ''),
    );
    _totalValueController = TextEditingController(text: nfc?.totalValue ?? '');
    _selectedCustomerId = nfc?.customerId;
    _selectedProductIds.addAll(
      (nfc?.products ?? const <NfcProductSnapshot>[]).map(
        (product) => product.productId,
      ),
    );
    _quantityControllers.addAll({
      for (final product in nfc?.products ?? const <NfcProductSnapshot>[])
        product.productId: TextEditingController(text: product.quantityKg),
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _dateController.dispose();
    _totalValueController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(List<Product> products) async {
    if (!_hasTriedSubmit) {
      setState(() {
        _hasTriedSubmit = true;
      });
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomerId == null) {
      _showError('Selecione um cliente.');
      return;
    }

    if (_selectedProductIds.isEmpty) {
      _showError('Selecione pelo menos um produto.');
      return;
    }

    final snapshots = products
        .where((product) => _selectedProductIds.contains(product.id))
        .map((product) {
          final quantity = _quantityControllers[product.id]?.text ?? '';

          return NfcProductSnapshot.fromProduct(
            product,
            quantityKg: quantity,
          );
        })
        .toList();

    if (snapshots.isEmpty) {
      _showError('Selecione pelo menos um produto disponivel.');
      return;
    }

    final hasInvalidQuantity = snapshots.any((product) {
      final quantity = parseBrDecimal(product.quantityKg);
      return quantity == null || quantity <= 0;
    });

    if (hasInvalidQuantity) {
      _showError('Informe uma quantidade valida para cada produto.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final nfc = widget.nfc;
      final totalValue = formatBrDecimal(_totalValueController.text);

      if (nfc == null) {
        await widget.nfcRepository.create(
          code: _codeController.text,
          date: _dateController.text,
          customerId: _selectedCustomerId!,
          products: snapshots,
          totalValue: totalValue,
        );
      } else {
        await widget.nfcRepository.update(
          id: nfc.id,
          code: _codeController.text,
          date: _dateController.text,
          customerId: _selectedCustomerId!,
          products: snapshots,
          totalValue: totalValue,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Nao foi possivel salvar a NFC.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<_NfcFormData> _loadFormData() async {
    final customers = await widget.customersRepository.getAll();
    final products = await widget.productsRepository.getAll();

    return _NfcFormData(
      customers: customers,
      products: products,
    );
  }

  void _addProduct(Product product, List<Product> products) {
    setState(() {
      _selectedProductIds.add(product.id);
      _quantityControllers.putIfAbsent(
        product.id,
        () => TextEditingController(text: '1,00'),
      );
      _productToAddId = null;
      _recalculateTotalValue(products);
    });
  }

  void _removeProduct(String productId, List<Product> products) {
    setState(() {
      _selectedProductIds.remove(productId);
      final controller = _quantityControllers.remove(productId);
      controller?.dispose();
      _recalculateTotalValue(products);
    });
  }

  void _onQuantityChanged(List<Product> products) {
    if (_isCustomTotalValue) {
      return;
    }

    _recalculateTotalValue(products);
  }

  void _recalculateTotalValue(List<Product> products) {
    if (_isCustomTotalValue) {
      return;
    }

    var total = 0.0;

    for (final product in products) {
      if (!_selectedProductIds.contains(product.id)) {
        continue;
      }

      final price = parseBrDecimal(product.pricePerKg);
      final quantity = parseBrDecimal(
        _quantityControllers[product.id]?.text ?? '',
      );

      if (price == null || quantity == null) {
        continue;
      }

      total += price * quantity;
    }

    _totalValueController.text = total == 0
        ? ''
        : total.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NfcFormData>(
      future: _formDataFuture ??= _loadFormData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final customers = data?.customers ?? const <Customer>[];
        final products = data?.products ?? const <Product>[];

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Editar NFC' : 'Nova NFC'),
            actions: [
              TextButton(
                onPressed: _isSaving || isLoading ? null : () => _submit(products),
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _NfcFormBody(
                  formKey: _formKey,
                  codeController: _codeController,
                  dateController: _dateController,
                  totalValueController: _totalValueController,
                  dateFormatter: _dateFormatter,
                  customers: customers,
                  products: products,
                  productToAddId: _productToAddId,
                  selectedCustomerId: _selectedCustomerId,
                  selectedProductIds: _selectedProductIds,
                  quantityControllers: _quantityControllers,
                  isCustomTotalValue: _isCustomTotalValue,
                  autovalidateMode: _hasTriedSubmit
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  onCustomerChanged: (customerId) {
                    setState(() {
                      _selectedCustomerId = customerId;
                    });
                  },
                  onProductToAddChanged: (productId) {
                    setState(() {
                      _productToAddId = productId;
                    });
                  },
                  onAddProduct: (product) => _addProduct(product, products),
                  onRemoveProduct: (productId) {
                    _removeProduct(productId, products);
                  },
                  onQuantityChanged: () => _onQuantityChanged(products),
                  onCustomTotalValueChanged: (isCustom) {
                    setState(() {
                      _isCustomTotalValue = isCustom;

                      if (!isCustom) {
                        _recalculateTotalValue(products);
                      }
                    });
                  },
                ),
        );
      },
    );
  }
}

class _NfcFormData {
  const _NfcFormData({
    required this.customers,
    required this.products,
  });

  final List<Customer> customers;
  final List<Product> products;
}

class _NfcFormBody extends StatelessWidget {
  const _NfcFormBody({
    required this.formKey,
    required this.codeController,
    required this.dateController,
    required this.totalValueController,
    required this.dateFormatter,
    required this.customers,
    required this.products,
    required this.productToAddId,
    required this.selectedCustomerId,
    required this.selectedProductIds,
    required this.quantityControllers,
    required this.isCustomTotalValue,
    required this.autovalidateMode,
    required this.onCustomerChanged,
    required this.onProductToAddChanged,
    required this.onAddProduct,
    required this.onRemoveProduct,
    required this.onQuantityChanged,
    required this.onCustomTotalValueChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final TextEditingController dateController;
  final TextEditingController totalValueController;
  final MaskTextInputFormatter dateFormatter;
  final List<Customer> customers;
  final List<Product> products;
  final String? productToAddId;
  final String? selectedCustomerId;
  final Set<String> selectedProductIds;
  final Map<String, TextEditingController> quantityControllers;
  final bool isCustomTotalValue;
  final AutovalidateMode autovalidateMode;
  final ValueChanged<String?> onCustomerChanged;
  final ValueChanged<String?> onProductToAddChanged;
  final ValueChanged<Product> onAddProduct;
  final ValueChanged<String> onRemoveProduct;
  final VoidCallback onQuantityChanged;
  final ValueChanged<bool> onCustomTotalValueChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabledValueColor = colorScheme.onSurface.withValues(alpha: 0.38);

    return Form(
      key: formKey,
      autovalidateMode: autovalidateMode,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TextFormField(
            controller: codeController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Codigo',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o codigo.';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: dateController,
            inputFormatters: [dateFormatter],
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Data',
              hintText: 'dd/mm/aaaa',
              prefixIcon: Icon(Icons.event_outlined),
            ),
            validator: (value) {
              final date = value?.trim() ?? '';

              if (date.isEmpty) {
                return 'Informe a data.';
              }

              if (date.replaceAll('/', '').length != 8) {
                return 'Informe a data completa.';
              }

              if (!_isValidBrDate(date)) {
                return 'Informe uma data valida.';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: totalValueController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9,]')),
                  ],
                  readOnly: !isCustomTotalValue,
                  enableInteractiveSelection: isCustomTotalValue,
                  style: !isCustomTotalValue
                      ? TextStyle(color: disabledValueColor)
                      : null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Valor da nota',
                    filled: !isCustomTotalValue,
                    fillColor: !isCustomTotalValue
                        ? colorScheme.surfaceContainerHighest
                        : null,
                    prefixIcon: Icon(
                      Icons.paid_outlined,
                      color: !isCustomTotalValue ? disabledValueColor : null,
                    ),
                    prefixText: 'R\$ ',
                    prefixStyle: !isCustomTotalValue
                        ? TextStyle(color: disabledValueColor)
                        : null,
                  ),
                  validator: (value) {
                    final rawValue = value ?? '';
                    final totalValue = parseBrDecimal(rawValue);

                    if (rawValue.trim().isEmpty) {
                      return 'Informe o valor da nota.';
                    }

                    if (totalValue == null || totalValue <= 0) {
                      return 'Informe um valor valido.';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 124,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Tooltip(
                    message: 'Permitir editar o valor calculado',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isCustomTotalValue,
                          onChanged: (value) {
                            onCustomTotalValueChanged(value ?? false);
                          },
                        ),
                        const Flexible(
                          child: Text(
                            'Editar valor',
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: customers.any((customer) => customer.id == selectedCustomerId)
                ? selectedCustomerId
                : null,
            items: customers.map((customer) {
              return DropdownMenuItem(
                value: customer.id,
                child: Text(customer.name),
              );
            }).toList(),
            decoration: const InputDecoration(
              labelText: 'Cliente',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: customers.isEmpty ? null : onCustomerChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecione um cliente.';
              }

              return null;
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Produtos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            const Text('Cadastre produtos antes de criar uma NFC.')
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: products.any(
                      (product) =>
                          product.id == productToAddId &&
                          !selectedProductIds.contains(product.id),
                    )
                        ? productToAddId
                        : null,
                    items: products
                        .where((product) => !selectedProductIds.contains(product.id))
                        .map((product) {
                      return DropdownMenuItem(
                        value: product.id,
                        child: Text(product.name),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Produto',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    onChanged: onProductToAddChanged,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: productToAddId == null
                      ? null
                      : () {
                          final product = products.firstWhere(
                            (product) => product.id == productToAddId,
                          );
                          onAddProduct(product);
                        },
                  tooltip: 'Adicionar produto',
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedProductIds.isEmpty)
              const Text('Nenhum produto selecionado.')
            else
              ...products
                  .where((product) => selectedProductIds.contains(product.id))
                  .map((product) {
                final controller = quantityControllers[product.id];

                if (controller == null) {
                  return const SizedBox.shrink();
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.name),
                  subtitle: Text('R\$ ${product.pricePerKg}/kg'),
                  trailing: SizedBox(
                    width: 148,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp('[0-9,]'),
                              ),
                            ],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Kg',
                              suffixText: 'kg',
                            ),
                            onChanged: (_) => onQuantityChanged(),
                            validator: (value) {
                              final quantity = parseBrDecimal(value ?? '');

                              if (quantity == null || quantity <= 0) {
                                return 'Valor invalido';
                              }

                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () => onRemoveProduct(product.id),
                          tooltip: 'Remover',
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

bool _isValidBrDate(String value) {
  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);

  if (match == null) {
    return false;
  }

  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);

  if (day == null || month == null || year == null) {
    return false;
  }

  final date = DateTime(year, month, day);

  return date.day == day && date.month == month && date.year == year;
}
