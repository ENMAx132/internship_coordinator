import 'package:flutter/material.dart';

import '../models/items.dart';
import '../models/sector.dart';
import '../widgets/sector_card.dart';
import '../widgets/item_tile.dart';
import '../widgets/search_history_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchHistory = [];

  void _addToHistory(String term) {
    final t = term.trim();
    if (t.isEmpty) return;
    setState(() {
      _searchHistory.remove(t);
      _searchHistory.insert(0, t);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  final List<Sector> sectors = [
    Sector(
      id: 'recepcion',
      name: 'Recepción',
      icon: '🏢',
      description: 'Entrada principal y atención al cliente',
    ),
    Sector(
      id: 'sistemas',
      name: 'Sala de Sistemas',
      icon: '💻',
      description: 'Servidores, respaldos y equipos IT',
    ),
    Sector(
      id: 'gerencia',
      name: 'Gerencia',
      icon: '📊',
      description: 'Oficina directiva y de planeación',
    ),
    Sector(
      id: 'almacen',
      name: 'Almacén / Archivo',
      icon: '📦',
      description: 'Papelería, suministros y archivo muerto',
    ),
    Sector(
      id: 'reuniones',
      name: 'Sala de Juntas',
      icon: '🤝',
      description: 'Espacio para conferencias y equipo audiovisual',
    ),
  ];

  List<Item> items = [
    Item(
      id: '1',
      name: 'Router Wi-Fi Principal',
      category: 'Equipos',
      sectorId: 'sistemas',
      description: 'Cisco Catalyst de alta velocidad',
    ),
    Item(
      id: '2',
      name: 'Proyector Epson',
      category: 'Equipos',
      sectorId: 'reuniones',
      description: 'Full HD para presentaciones',
    ),
    Item(
      id: '3',
      name: 'Resma de Papel A4',
      category: 'Papelería',
      sectorId: 'almacen',
      description: 'Caja con 5 paquetes de 500 hojas',
    ),
    Item(
      id: '4',
      name: 'Escritorio Ejecutivos',
      category: 'Mobiliario',
      sectorId: 'gerencia',
      description: 'Madera oscura con cajonera',
    ),
  ];

  String searchQuery = '';
  String selectedCategoryFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    List<Item> filteredItems = items.where((item) {
      final sector = sectors.firstWhere(
            (s) => s.id == item.sectorId,
        orElse: () => Sector(id: '', name: '', icon: '', description: ''),
      );
      final matchesQuery =
          searchQuery.isEmpty ||
              item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              item.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
              item.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
              sector.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCat =
          selectedCategoryFilter == 'Todos' ||
              item.category == selectedCategoryFilter;
      return matchesQuery && matchesCat;
    }).toList();

    List<Item> suggestedItems = [];
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      final list =
      items.map((item) {
        final sector = sectors.firstWhere(
              (s) => s.id == item.sectorId,
          orElse: () => Sector(id: '', name: '', icon: '', description: ''),
        );
        int score = 0;
        final nameLower = item.name.toLowerCase();
        final descLower = item.description.toLowerCase();
        final catLower = item.category.toLowerCase();
        final sectorLower = sector.name.toLowerCase();
        if (nameLower == q) score += 10;
        if (nameLower.startsWith(q)) score += 5;
        if (nameLower.contains(q)) score += 3;
        if (sectorLower.contains(q)) score += 2;
        if (catLower.contains(q)) score += 2;
        if (descLower.contains(q)) score += 1;
        return (item: item, sector: sector, score: score);
      }).where((e) => e.score > 0).toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      suggestedItems = list.take(6).map((e) => e.item).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Inventario de Oficina',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: Color(0xFF6366F1),
              size: 28,
            ),
            onPressed: () => _showAddItemModal(context),
            tooltip: 'Agregar Objeto',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (val) => setState(() => searchQuery = val),
              onSubmitted: (val) {
                _addToHistory(val);
                _searchFocusNode.unfocus();
              },
              decoration: InputDecoration(
                hintText: 'Buscar objeto...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon:
                searchQuery.isNotEmpty || _searchFocusNode.hasFocus
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                    _searchFocusNode.unfocus();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 12),

            Builder(
              builder: (context) {
                final isFocused = _searchFocusNode.hasFocus;
                if (isFocused && searchQuery.isEmpty) {
                  return SearchHistoryView(
                    searchHistory: _searchHistory,
                    onTermSelected: (term) {
                      _searchController.text = term;
                      setState(() => searchQuery = term);
                      _addToHistory(term);
                      _searchFocusNode.unfocus();
                    },
                  );
                }

                if (searchQuery.isNotEmpty) {
                  if (suggestedItems.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No se encontraron objetos para esta búsqueda.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Objetos encontrados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children:
                          suggestedItems.map((item) {
                            final sector = sectors.firstWhere(
                                  (s) => s.id == item.sectorId,
                              orElse:
                                  () => Sector(
                                id: '',
                                name: 'Desconocido',
                                icon: '❓',
                                description: '',
                              ),
                            );
                            return ListTile(
                              leading: Text(
                                sector.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${item.category}\n${sector.name}',
                              ),
                              onTap: () {
                                _addToHistory(searchQuery);
                                _searchController.text = item.name;
                                setState(() => searchQuery = item.name);
                                _searchFocusNode.unfocus();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Espacios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF6366F1),
                          ),
                          tooltip: 'Agregar espacio',
                          onPressed: () => _showAddSectorModal(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Usando nuestro componente SectorCard limpio
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: sectors.length,
                      itemBuilder: (context, index) {
                        final sector = sectors[index];
                        final count =
                            items
                                .where((i) => i.sectorId == sector.id)
                                .length;
                        return SectorCard(
                          sector: sector,
                          itemCount: count,
                          onTap: () => _showSectorDetailModal(context, sector),
                          onLongPress:
                              () => _showEditSectorModal(
                            context,
                            sector,
                            index,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    ExpansionTile(
                      initiallyExpanded: true,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                      childrenPadding: const EdgeInsets.only(top: 12),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Todos los Objetos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${filteredItems.length} encontrados',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      children: [
                        filteredItems.isEmpty
                            ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No se encontraron objetos registrados.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final sector = sectors.firstWhere(
                                  (s) => s.id == item.sectorId,
                              orElse:
                                  () => Sector(
                                id: '',
                                name: 'Desconocido',
                                icon: '❓',
                                description: '',
                              ),
                            );
                            // Usando nuestro componente ItemTile limpio
                            return ItemTile(
                              item: item,
                              sector: sector,
                              onEdit:
                                  () => _showEditItemModal(context, item),
                              onDelete: () {
                                setState(() {
                                  items.removeWhere(
                                        (i) => i.id == item.id,
                                  );
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Modales
  void _showSectorDetailModal(BuildContext context, Sector sector) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final sectorItems =
            items.where((i) => i.sectorId == sector.id).toList();
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(sector.icon, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sector.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            sector.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Objetos en este lugar:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child:
                    sectorItems.isEmpty
                        ? const Center(
                      child: Text(
                        'No hay objetos registrados en este sector.',
                      ),
                    )
                        : ListView.builder(
                      itemCount: sectorItems.length,
                      itemBuilder: (context, index) {
                        final item = sectorItems[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF6366F1),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${item.category}\n${item.description}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF6366F1),
                                  size: 18,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showEditItemModal(context, item);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    items.removeWhere(
                                          (i) => i.id == item.id,
                                    );
                                  });
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditSectorModal(context, sector),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar espacio'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddItemModal(
                              context,
                              preselectedSectorId: sector.id,
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar objeto'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSectorModal(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final iconController = TextEditingController(text: '🏢');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agregar Espacio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconController,
                  decoration: InputDecoration(
                    labelText: 'Icono (emoji)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del espacio',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    setState(() {
                      sectors.add(
                        Sector(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          icon:
                          iconController.text.trim().isEmpty
                              ? '🏢'
                              : iconController.text.trim(),
                          description: descController.text.trim(),
                        ),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Guardar Espacio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSectorModal(BuildContext context, Sector sector, [int? index]) {
    final nameController = TextEditingController(text: sector.name);
    final descController = TextEditingController(text: sector.description);
    final iconController = TextEditingController(text: sector.icon);
    int idx = index ?? sectors.indexWhere((s) => s.id == sector.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar Espacio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconController,
                  decoration: InputDecoration(
                    labelText: 'Icono (emoji)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del espacio',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty || idx < 0) return;
                    setState(() {
                      sectors[idx] = Sector(
                        id: sector.id,
                        name: nameController.text.trim(),
                        icon:
                        iconController.text.trim().isEmpty
                            ? sector.icon
                            : iconController.text.trim(),
                        description: descController.text.trim(),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditItemModal(BuildContext context, Item item) {
    final nameController = TextEditingController(text: item.name);
    final descController = TextEditingController(text: item.description);
    String selectedCategory = item.category;
    String selectedSector = item.sectorId;

    final categories = [
      'Equipos',
      'Papelería',
      'Mobiliario',
      'Documentos',
      'Herramientas',
      'Otros',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar Objeto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del objeto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSector,
                  decoration: InputDecoration(
                    labelText: 'Sector / Lugar de la oficina',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                  sectors.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.icon} ${s.name}'),
                    );
                  }).toList(),
                  onChanged: (val) => selectedSector = val!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                  categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) => selectedCategory = val!,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Descripción o notas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    setState(() {
                      item.name = nameController.text.trim();
                      item.category = selectedCategory;
                      item.sectorId = selectedSector;
                      item.description = descController.text.trim();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddItemModal(BuildContext context, {String? preselectedSectorId}) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Equipos';
    String selectedSector = preselectedSectorId ?? sectors.first.id;

    final categories = [
      'Equipos',
      'Papelería',
      'Mobiliario',
      'Documentos',
      'Herramientas',
      'Otros',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agregar Nuevo Objeto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del objeto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSector,
                  decoration: InputDecoration(
                    labelText: 'Sector / Lugar de la oficina',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                  sectors.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.icon} ${s.name}'),
                    );
                  }).toList(),
                  onChanged: (val) => selectedSector = val!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                  categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) => selectedCategory = val!,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Descripción o notas opcionales',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    setState(() {
                      items.add(
                        Item(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          category: selectedCategory,
                          sectorId: selectedSector,
                          description: descController.text.trim(),
                        ),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Guardar Objeto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}