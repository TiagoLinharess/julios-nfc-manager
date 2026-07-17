import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/formatting/br_decimal_formatter.dart';
import '../../nfc/domain/nfc_product_snapshot.dart';
import '../../nfc/domain/nfc_record.dart';
import '../data/nfc_returns_repository.dart';
import '../domain/nfc_return_product_snapshot.dart';
import '../domain/nfc_return_record.dart';

class NfcReturnFormPage extends StatefulWidget {
  const NfcReturnFormPage({
    required this.nfc,
    required this.returns,
    required this.repository,
    this.nfcReturn,
    super.key,
  });

  final NfcRecord nfc;
  final List<NfcReturnRecord> returns;
  final NfcReturnsRepository repository;
  final NfcReturnRecord? nfcReturn;

  @override
  State<NfcReturnFormPage> createState() => _NfcReturnFormPageState();
}

class _NfcReturnFormPageState extends State<NfcReturnFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp('[0-9]')},
  );

  late final TextEditingController _codeController;
  late final TextEditingController _dateController;
  late final TextEditingController _totalValueController;
  late final Map<String, TextEditingController> _quantityControllers;

  bool _isSaving = false;
  bool _hasTriedSubmit = false;
  bool _isCustomTotalValue = false;

  bool get _isEditing => widget.nfcReturn != null;

  @override
  void initState() {
    super.initState();
    final nfcReturn = widget.nfcReturn;
    final returnedQuantities = {
      for (final product
          in nfcReturn?.products ?? const <NfcReturnProductSnapshot>[])
        product.productId: product.quantityKg,
    };

    _codeController = TextEditingController(text: nfcReturn?.code ?? '');
    _dateController = TextEditingController(
      text: _dateFormatter.maskText(nfcReturn?.date ?? ''),
    );
    _totalValueController = TextEditingController(
      text: nfcReturn?.totalValue ?? '',
    );
    _quantityControllers = {
      for (final product in widget.nfc.products)
        product.productId: TextEditingController(
          text: returnedQuantities[product.productId] ?? '',
        ),
    };
    _isCustomTotalValue =
        nfcReturn != null && !_matchesReturnProductsTotal(nfcReturn);
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

  Future<void> _submit() async {
    if (!_hasTriedSubmit) {
      setState(() {
        _hasTriedSubmit = true;
      });
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final products = <NfcReturnProductSnapshot>[];

    for (final product in widget.nfc.products) {
      final quantity = _quantityControllers[product.productId]?.text ?? '';
      final parsedQuantity = parseBrDecimal(quantity) ?? 0;

      if (parsedQuantity <= 0) {
        continue;
      }

      products.add(
        NfcReturnProductSnapshot.fromNfcProduct(product, quantityKg: quantity),
      );
    }

    if (products.isEmpty) {
      _showError('Informe a quantidade de pelo menos um produto.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final nfcReturn = widget.nfcReturn;

      if (nfcReturn == null) {
        await widget.repository.create(
          nfcId: widget.nfc.id,
          code: _codeController.text,
          date: _dateController.text,
          totalValue: formatBrDecimal(_totalValueController.text),
          products: products,
        );
      } else {
        await widget.repository.update(
          nfcId: widget.nfc.id,
          id: nfcReturn.id,
          code: _codeController.text,
          date: _dateController.text,
          totalValue: formatBrDecimal(_totalValueController.text),
          products: products,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Não foi possível salvar a devolução.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _recalculateTotalValue() {
    if (_isCustomTotalValue) {
      return;
    }

    var total = 0.0;

    for (final product in widget.nfc.products) {
      final price = parseBrDecimal(product.pricePerKg);
      final quantity = parseBrDecimal(
        _quantityControllers[product.productId]?.text ?? '',
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

  bool _matchesReturnProductsTotal(NfcReturnRecord nfcReturn) {
    var total = 0.0;

    for (final product in nfcReturn.products) {
      final price = parseBrDecimal(product.pricePerKg);
      final quantity = parseBrDecimal(product.quantityKg);

      if (price == null || quantity == null) {
        continue;
      }

      total += price * quantity;
    }

    final savedTotal = parseBrDecimal(nfcReturn.totalValue);

    if (savedTotal == null) {
      return false;
    }

    return (savedTotal - total).abs() < 0.01;
  }

  double _returnedQuantityFor(String productId) {
    var total = 0.0;

    for (final nfcReturn in widget.returns) {
      if (nfcReturn.id == widget.nfcReturn?.id) {
        continue;
      }

      for (final product in nfcReturn.products) {
        if (product.productId != productId) {
          continue;
        }

        total += parseBrDecimal(product.quantityKg) ?? 0;
      }
    }

    return total;
  }

  double _returnedTotalExcludingCurrent() {
    var total = 0.0;

    for (final nfcReturn in widget.returns) {
      if (nfcReturn.id == widget.nfcReturn?.id) {
        continue;
      }

      total += parseBrDecimal(nfcReturn.totalValue) ?? 0;
    }

    return total;
  }

  double _availableTotalValue() {
    final nfcTotal = parseBrDecimal(widget.nfc.totalValue) ?? 0;
    return nfcTotal - _returnedTotalExcludingCurrent();
  }

  double _availableQuantityFor(NfcProductSnapshot product) {
    final originalQuantity = parseBrDecimal(product.quantityKg) ?? 0;
    final available =
        originalQuantity - _returnedQuantityFor(product.productId);
    return available < 0 ? 0 : available;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabledValueColor = colorScheme.onSurface.withValues(alpha: 0.38);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar devolução' : 'Nova devolução'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _hasTriedSubmit
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'NFC ${widget.nfc.code}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Número da devolução',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o código.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateController,
              inputFormatters: [_dateFormatter],
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
                  return 'Informe uma data válida.';
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
                    controller: _totalValueController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9,]')),
                    ],
                    readOnly: !_isCustomTotalValue,
                    enableInteractiveSelection: _isCustomTotalValue,
                    style: !_isCustomTotalValue
                        ? TextStyle(color: disabledValueColor)
                        : null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Valor da devolução',
                      filled: !_isCustomTotalValue,
                      fillColor: !_isCustomTotalValue
                          ? colorScheme.surfaceContainerHighest
                          : null,
                      prefixIcon: Icon(
                        Icons.paid_outlined,
                        color: !_isCustomTotalValue ? disabledValueColor : null,
                      ),
                      prefixText: 'R\$ ',
                      prefixStyle: !_isCustomTotalValue
                          ? TextStyle(color: disabledValueColor)
                          : null,
                    ),
                    validator: (value) {
                      final rawValue = value ?? '';
                      final totalValue = parseBrDecimal(rawValue);

                      if (rawValue.trim().isEmpty) {
                        return 'Informe produtos para calcular a devolução.';
                      }

                      if (totalValue == null || totalValue <= 0) {
                        return 'Informe um valor válido.';
                      }

                      final availableTotal = _availableTotalValue();

                      if (totalValue - availableTotal > 0.01) {
                        final availableText = availableTotal
                            .toStringAsFixed(2)
                            .replaceAll('.', ',');
                        return 'Máx R\$ $availableText';
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
                            value: _isCustomTotalValue,
                            onChanged: (value) {
                              setState(() {
                                _isCustomTotalValue = value ?? false;

                                if (!_isCustomTotalValue) {
                                  _recalculateTotalValue();
                                }
                              });
                            },
                          ),
                          const Flexible(
                            child: Text('Editar valor', maxLines: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Produtos devolvidos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (widget.nfc.products.isEmpty)
              const Text('Esta NFC não possui produtos.')
            else
              ...widget.nfc.products.map((product) {
                final controller = _quantityControllers[product.productId];
                final available = _availableQuantityFor(product);
                final availableText = available
                    .toStringAsFixed(2)
                    .replaceAll('.', ',');

                if (controller == null) {
                  return const SizedBox.shrink();
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.name),
                  subtitle: Text(
                    'Disponível: $availableText kg | R\$ ${product.pricePerKg}/kg',
                  ),
                  trailing: SizedBox(
                    width: 112,
                    child: TextFormField(
                      controller: controller,
                      enabled: available > 0,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9,]')),
                      ],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Kg',
                        suffixText: 'kg',
                      ),
                      onChanged: (_) => _recalculateTotalValue(),
                      validator: (value) {
                        final rawValue = value ?? '';
                        final quantity = parseBrDecimal(rawValue);

                        if (rawValue.trim().isEmpty) {
                          return null;
                        }

                        if (quantity == null || quantity <= 0) {
                          return 'Inválido';
                        }

                        if (quantity > available) {
                          return 'Max $availableText';
                        }

                        return null;
                      },
                    ),
                  ),
                );
              }),
          ],
        ),
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
