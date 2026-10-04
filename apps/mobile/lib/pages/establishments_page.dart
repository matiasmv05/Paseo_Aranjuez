import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_filter_chip.dart';
import 'package:paseo_mobile/design_system/molecules/establishment_list_card.dart';
import 'package:paseo_mobile/design_system/templates/client_scaffold_template.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Pantalla 11: Directorio oficial de establecimientos participantes.
class EstablishmentsPage extends StatefulWidget {
  /// Crea la pantalla de establecimientos.
  const new({super.key});

  @override
  State<EstablishmentsPage> createState() => _EstablishmentsPageState();
}

class _EstablishmentsPageState extends State<EstablishmentsPage> {
  final _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  final _categories = ['Todos', 'Ropa', 'Gastronomía', 'Entretenimiento'];

  List<MockEstablishment> get _filteredEstablishments {
    final query = _searchController.text.toLowerCase().trim();
    return MockData.establishments.where((est) {
      final matchesQuery =
          query.isEmpty ||
          est.name.toLowerCase().contains(query) ||
          est.location.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryIndex == 0 ||
          est.category == _categories[_selectedCategoryIndex];
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
    final list = _filteredEstablishments;

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
          'Establecimientos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: PaseoColors.textDarkPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Buscador y filtro
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                          hintText: 'Buscar establecimientos...',
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
                            content: Text('Filtro por piso y categoría.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 2. Fila de chips de categorías
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
            const SizedBox(height: 12),

            // 3. Lista de establecimientos
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay establecimientos en esta categoría.',
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
                        final est = list[index];
                        return EstablishmentListCard(
                          establishment: est,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${est.name}: ${est.location} (${est.hours})',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
