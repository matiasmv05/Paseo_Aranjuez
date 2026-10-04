import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_filter_chip.dart';
import 'package:paseo_mobile/design_system/molecules/benefit_list_card.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/pages/benefit_detail_page.dart';

/// Pantalla 5: Catálogo completo de beneficios de Paseo Points.
class BenefitsPage extends StatefulWidget {
  /// Crea la pantalla de beneficios.
  const new({super.key});

  @override
  State<BenefitsPage> createState() => _BenefitsPageState();
}

class _BenefitsPageState extends State<BenefitsPage> {
  final _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  final _categories = ['Todos', 'Gastronomía', 'Moda', 'Entretenimiento'];

  List<MockBenefit> get _filteredBenefits {
    final query = _searchController.text.toLowerCase().trim();
    return MockData.benefits.where((b) {
      final matchesQuery =
          query.isEmpty ||
          b.title.toLowerCase().contains(query) ||
          b.establishment.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryIndex == 0 ||
          b.category == _categories[_selectedCategoryIndex];
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredBenefits;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Título de cabecera
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Beneficios',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PaseoColors.textDarkPrimary,
              ),
            ),
          ),

          // 2. Barra de búsqueda y botón de filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PaseoColors.borderLight,
                        width: 1.1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 14,
                        color: PaseoColors.textDarkPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Buscar beneficios...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: PaseoColors.textPlaceholder,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: PaseoColors.textPlaceholder,
                          size: 20,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PaseoColors.borderLight,
                      width: 1.1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: PaseoColors.textDarkPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Filtros avanzados disponibles en MVP.',
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Fila de chips de categorías
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return PaseoFilterChip(
                  label: _categories[index],
                  isSelected: _selectedCategoryIndex == index,
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 4. Lista de tarjetas de beneficios
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron beneficios en esta categoría.',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaseoColors.textDarkSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return BenefitListCard(
                        benefit: item,
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => BenefitDetailPage(benefit: item),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
