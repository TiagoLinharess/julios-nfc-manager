import 'package:flutter/material.dart';

import '../../../core/formatting/br_decimal_formatter.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/domain/customer.dart';
import '../../nfc_returns/data/nfc_returns_repository.dart';
import '../../nfc_returns/domain/nfc_return_product_snapshot.dart';
import '../../nfc_returns/domain/nfc_return_record.dart';
import '../../nfc_returns/presentation/nfc_return_details_page.dart';
import '../../nfc_returns/presentation/nfc_return_form_page.dart';
import '../data/nfc_repository.dart';
import '../domain/nfc_product_snapshot.dart';
import '../domain/nfc_record.dart';

class NfcDetailsPage extends StatelessWidget {
  const NfcDetailsPage({
    required this.nfcId,
    required this.nfcRepository,
    required this.customersRepository,
    required this.nfcReturnsRepository,
    required this.onEdit,
    super.key,
  });

  final String nfcId;
  final NfcRepository nfcRepository;
  final CustomersRepository customersRepository;
  final NfcReturnsRepository nfcReturnsRepository;
  final Future<void> Function(NfcRecord nfc) onEdit;

  Future<void> _deleteNfc(
    BuildContext context,
    NfcRecord nfc,
  ) async {
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

      if (context.mounted) {
        Navigator.of(context).pop();
      }
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
                        await _deleteNfc(context, nfc);
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

    return StreamBuilder<Customer?>(
      stream: customersRepository.watchById(nfc.customerId),
      builder: (context, customerSnapshot) {
        final customerName =
            customerSnapshot.data?.name ?? 'Cliente nao encontrado';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _NfcHeader(
              nfc: nfc,
              customerName: customerName,
            ),
            const SizedBox(height: 24),
            _DetailTile(
              icon: Icons.person_outline,
              label: 'Cliente',
              value: customerName,
            ),
            _DetailTile(
              icon: Icons.event_outlined,
              label: 'Data',
              value: nfc.date,
            ),
            _DetailTile(
              icon: Icons.confirmation_number_outlined,
              label: 'Número',
              value: nfc.code,
            ),
            _DetailTile(
              icon: Icons.paid_outlined,
              label: 'Valor da nota',
              value: 'R\$ ${nfc.totalValue}',
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
                return _NfcProductTile(product: product);
              }),
            const SizedBox(height: 24),
            _NfcReturnsSection(
              nfc: nfc,
              repository: nfcReturnsRepository,
            ),
          ],
        );
      },
    );
  }
}

class _NfcReturnsSection extends StatelessWidget {
  const _NfcReturnsSection({
    required this.nfc,
    required this.repository,
  });

  final NfcRecord nfc;
  final NfcReturnsRepository repository;

  Future<void> _openReturnForm(
    BuildContext context,
    List<NfcReturnRecord> returns,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return NfcReturnFormPage(
            nfc: nfc,
            returns: returns,
            repository: repository,
          );
        },
      ),
    );
  }

  Future<void> _openReturnDetails(
    BuildContext context,
    NfcReturnRecord nfcReturn,
    List<NfcReturnRecord> returns,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return NfcReturnDetailsPage(
            nfc: nfc,
            returnId: nfcReturn.id,
            returns: returns,
            repository: repository,
          );
        },
      ),
    );
  }

  Future<bool> _deleteReturn(
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
      return false;
    }

    try {
      await repository.delete(
        nfcId: nfc.id,
        id: nfcReturn.id,
      );
      return true;
    } catch (error) {
      if (!context.mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a devolução.')),
      );
      return false;
    }
  }

  bool _hasAvailableQuantity(List<NfcReturnRecord> returns) {
    for (final product in nfc.products) {
      final originalQuantity = parseBrDecimal(product.quantityKg) ?? 0;
      final returnedQuantity = _returnedQuantityFor(
        product.productId,
        returns,
      );

      if (originalQuantity - returnedQuantity > 0) {
        return true;
      }
    }

    return false;
  }

  double _returnedQuantityFor(
    String productId,
    List<NfcReturnRecord> returns,
  ) {
    var total = 0.0;

    for (final nfcReturn in returns) {
      for (final product in nfcReturn.products) {
        if (product.productId != productId) {
          continue;
        }

        total += parseBrDecimal(product.quantityKg) ?? 0;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NfcReturnRecord>>(
      stream: repository.watchAll(nfc.id),
      builder: (context, snapshot) {
        final returns = snapshot.data ?? const <NfcReturnRecord>[];
        final hasAvailableQuantity = _hasAvailableQuantity(returns);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Devoluções',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: snapshot.connectionState ==
                              ConnectionState.waiting ||
                          !hasAvailableQuantity
                      ? null
                      : () => _openReturnForm(context, returns),
                  icon: const Icon(Icons.add),
                  label: const Text('Devolução'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              const Text('Não foi possível carregar as devoluções.')
            else if (returns.isEmpty)
              const Text('Nenhuma devolução cadastrada.')
            else ...[
              _NfcReturnsOverview(
                nfc: nfc,
                returns: returns,
              ),
              const SizedBox(height: 8),
              ...List.generate(returns.length, (index) {
                final nfcReturn = returns[index];

                return _NfcReturnCard(
                  nfc: nfc,
                  nfcReturn: nfcReturn,
                  onDelete: () async {
                    await _deleteReturn(context, nfcReturn);
                  },
                  onTap: () => _openReturnDetails(
                    context,
                    nfcReturn,
                    returns,
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

class _NfcReturnsOverview extends StatelessWidget {
  const _NfcReturnsOverview({
    required this.nfc,
    required this.returns,
  });

  final NfcRecord nfc;
  final List<NfcReturnRecord> returns;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalReturned = _calculateReturnsTotalValue(returns);
    final nfcTotal = parseBrDecimal(nfc.totalValue) ?? 0;
    final percentage = nfcTotal <= 0 ? 0.0 : (totalReturned / nfcTotal) * 100;
    final progress = nfcTotal <= 0
        ? 0.0
        : (totalReturned / nfcTotal).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geral',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NfcReturnMetric(
                  label: 'Total devolvido',
                  value: 'R\$ ${_formatCurrency(totalReturned)}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _NfcReturnMetric(
                  label: 'Percentual da nota',
                  value: '${_formatPercentage(percentage)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16),
          Text(
            'Por produto',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          ...nfc.products.map((product) {
            final returnedQuantity = _calculateReturnedQuantity(
              product.productId,
              returns,
            );
            final productQuantity = parseBrDecimal(product.quantityKg) ?? 0;
            final productPercentage = productQuantity <= 0
                ? 0.0
                : (returnedQuantity / productQuantity) * 100;
            final productReturnedValue = _calculateReturnedValueForProduct(
              product.productId,
              returns,
            );

            return _NfcReturnsOverviewProduct(
              name: product.name,
              returnedQuantity: returnedQuantity,
              totalQuantity: productQuantity,
              percentage: productPercentage,
              value: productReturnedValue,
            );
          }),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

class _NfcReturnsOverviewProduct extends StatelessWidget {
  const _NfcReturnsOverviewProduct({
    required this.name,
    required this.returnedQuantity,
    required this.totalQuantity,
    required this.percentage,
    required this.value,
  });

  final String name;
  final double returnedQuantity;
  final double totalQuantity;
  final double percentage;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = totalQuantity <= 0
        ? 0.0
        : (returnedQuantity / totalQuantity).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name),
              ),
              const SizedBox(width: 12),
              Text(
                'R\$ ${_formatCurrency(value)}',
                textAlign: TextAlign.end,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_formatQuantity(returnedQuantity)} / '
                '${_formatQuantity(totalQuantity)} kg',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: Text(
                  '${_formatPercentage(percentage)}%',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NfcHeader extends StatelessWidget {
  const _NfcHeader({
    required this.nfc,
    required this.customerName,
  });

  final NfcRecord nfc;
  final String customerName;

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
          customerName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${nfc.date} | ${nfc.code}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
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

class _NfcReturnCard extends StatelessWidget {
  const _NfcReturnCard({
    required this.nfc,
    required this.nfcReturn,
    required this.onDelete,
    required this.onTap,
  });

  final NfcRecord nfc;
  final NfcReturnRecord nfcReturn;
  final Future<void> Function() onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = _calculateReturnPercentage(nfc, nfcReturn);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.assignment_return_outlined,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nota ${nfcReturn.code}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(nfcReturn.date),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        onDelete();
                      },
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    _NfcReturnMetric(
                      label: 'Valor',
                      value: 'R\$ ${nfcReturn.totalValue}',
                    ),
                    _NfcReturnMetric(
                      label: 'Percentual da nota',
                      value: '${_formatPercentage(percentage)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                      child: Column(
                        children: [
                          ...nfcReturn.products.map((product) {
                            final originalProduct = _findNfcProduct(
                              nfc,
                              product.productId,
                            );
                            final productPercentage =
                                _calculateProductReturnPercentage(
                              originalProduct,
                              product,
                            );
                            final subtotal =
                                _calculateReturnProductSubtotal(product);

                            return _NfcReturnProductSummary(
                              product: product,
                              percentage: productPercentage,
                              subtotal: subtotal,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NfcReturnMetric extends StatelessWidget {
  const _NfcReturnMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _NfcReturnProductSummary extends StatelessWidget {
  const _NfcReturnProductSummary({
    required this.product,
    required this.percentage,
    required this.subtotal,
  });

  final NfcReturnProductSnapshot product;
  final double percentage;
  final String? subtotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldWrap = constraints.maxWidth < 280;

          if (shouldWrap) {
            return Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(subtotal == null ? '-' : 'R\$ $subtotal'),
                Text('${product.quantityKg} kg'),
                Text('${_formatPercentage(percentage)}%'),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  subtotal == null ? '-' : 'R\$ $subtotal',
                  textAlign: TextAlign.end,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  '${product.quantityKg} kg',
                  textAlign: TextAlign.end,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  '${_formatPercentage(percentage)}%',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NfcProductTile extends StatelessWidget {
  const _NfcProductTile({required this.product});

  final NfcProductSnapshot product;

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal(product);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(product.name),
      subtitle: Text(
        '${product.quantityKg} kg | R\$ ${product.pricePerKg}/kg',
      ),
      trailing: Text(
        subtotal == null ? '-' : 'R\$ $subtotal',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

String _formatPercentage(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String _formatQuantity(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String _formatCurrency(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

double _calculateReturnsTotalValue(List<NfcReturnRecord> returns) {
  var total = 0.0;

  for (final nfcReturn in returns) {
    total += parseBrDecimal(nfcReturn.totalValue) ?? 0;
  }

  return total;
}

double _calculateReturnedQuantity(
  String productId,
  List<NfcReturnRecord> returns,
) {
  var total = 0.0;

  for (final nfcReturn in returns) {
    for (final product in nfcReturn.products) {
      if (product.productId != productId) {
        continue;
      }

      total += parseBrDecimal(product.quantityKg) ?? 0;
    }
  }

  return total;
}

double _calculateReturnedValueForProduct(
  String productId,
  List<NfcReturnRecord> returns,
) {
  var total = 0.0;

  for (final nfcReturn in returns) {
    for (final product in nfcReturn.products) {
      if (product.productId != productId) {
        continue;
      }

      final price = parseBrDecimal(product.pricePerKg);
      final quantity = parseBrDecimal(product.quantityKg);

      if (price == null || quantity == null) {
        continue;
      }

      total += price * quantity;
    }
  }

  return total;
}

double _calculateReturnPercentage(
  NfcRecord nfc,
  NfcReturnRecord nfcReturn,
) {
  final nfcTotal = parseBrDecimal(nfc.totalValue) ?? 0;
  final returnTotal = parseBrDecimal(nfcReturn.totalValue) ?? 0;

  if (nfcTotal <= 0) {
    return 0;
  }

  return (returnTotal / nfcTotal) * 100;
}

NfcProductSnapshot? _findNfcProduct(NfcRecord nfc, String productId) {
  for (final product in nfc.products) {
    if (product.productId == productId) {
      return product;
    }
  }

  return null;
}

double _calculateProductReturnPercentage(
  NfcProductSnapshot? originalProduct,
  NfcReturnProductSnapshot returnedProduct,
) {
  final originalQuantity = parseBrDecimal(originalProduct?.quantityKg ?? '') ?? 0;
  final returnedQuantity = parseBrDecimal(returnedProduct.quantityKg) ?? 0;

  if (originalQuantity <= 0) {
    return 0;
  }

  return (returnedQuantity / originalQuantity) * 100;
}

String? _calculateReturnProductSubtotal(NfcReturnProductSnapshot product) {
  final price = parseBrDecimal(product.pricePerKg);
  final quantity = parseBrDecimal(product.quantityKg);

  if (price == null || quantity == null) {
    return null;
  }

  return (price * quantity).toStringAsFixed(2).replaceAll('.', ',');
}

String? _calculateSubtotal(NfcProductSnapshot product) {
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
