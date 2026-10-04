import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_filter_chip.dart';
import 'package:paseo_mobile/design_system/molecules/transaction_tile.dart';
import 'package:paseo_mobile/design_system/templates/client_scaffold_template.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Pantalla 9: Mis puntos e historial de transacciones del ledger.
class PointsHistoryPage extends StatefulWidget {
  /// Crea la pantalla de historial de puntos.
  const new({super.key});

  @override
  State<PointsHistoryPage> createState() => _PointsHistoryPageState();
}

class _PointsHistoryPageState extends State<PointsHistoryPage> {
  int _selectedFilter = 0; // 0 = Todos, 1 = Ganados, 2 = Canjeados
  final _filters = ['Todos', 'Ganados', 'Canjeados'];

  List<MockTransaction> get _filteredTransactions {
    if (_selectedFilter == 1) {
      return MockData.transactions
          .where((t) => t.type == TransactionType.earned)
          .toList();
    }
    if (_selectedFilter == 2) {
      return MockData.transactions
          .where((t) => t.type == TransactionType.spent)
          .toList();
    }
    return MockData.transactions;
  }

  String _formatPoints(int value) {
    final str = value.toString();
    if (str.length > 3) {
      final prefix = str.substring(0, str.length - 3);
      final suffix = str.substring(str.length - 3);
      return '$prefix.$suffix';
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    const user = MockData.currentUser;
    final txs = _filteredTransactions;

    return ClientScaffoldTemplate(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: PaseoColors.textDarkPrimary,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mis puntos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: PaseoColors.textDarkPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // 1. Tarjeta resumen de saldo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PaseoColors.borderLight, width: 1.1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8C6527),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatPoints(user.balance),
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: PaseoColors.textDarkPrimary,
                        ),
                      ),
                      const Text(
                        'puntos disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: PaseoColors.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Chips de filtro: Todos / Ganados / Canjeados
            Row(
              children: List.generate(_filters.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PaseoFilterChip(
                    label: _filters[index],
                    isSelected: _selectedFilter == index,
                    onTap: () => setState(() => _selectedFilter = index),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // 3. Lista de transacciones agrupadas por fecha
            if (txs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No hay transacciones registradas.',
                    style: TextStyle(
                      fontSize: 13,
                      color: PaseoColors.textDarkSecondary,
                    ),
                  ),
                ),
              )
            else
              ...txs.map((tx) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        bottom: 6,
                        top: 4,
                      ),
                      child: Text(
                        tx.date,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PaseoColors.textPlaceholder,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: PaseoColors.borderLight,
                          width: 1.1,
                        ),
                      ),
                      child: TransactionTile(
                        transaction: tx,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${tx.establishment}: ${tx.points} pts '
                                '(${tx.status})',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}
