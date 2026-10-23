import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/common_widgets.dart';

const _spaces = <Map<String, String>>[
  {'id': 'sala_jardins', 'name': 'Salão Jardins', 'category': 'Casamento', 'guests': '250', 'capacity': 'Até 250 convidados', 'description': 'Ambiente elegante para cerimônias e recepções.', 'image': 'assets/event_photos/salao_evento.jpg'},
  {'id': 'vista_verde', 'name': 'Vista Verde', 'category': 'Ao ar livre', 'guests': '180', 'capacity': 'Até 180 convidados', 'description': 'Um cenário ao ar livre para celebrações com luz natural.', 'image': 'assets/event_photos/mesa_decorada.jpg'},
  {'id': 'terraco', 'name': 'Terraço Imperial', 'category': 'Festas', 'guests': '120', 'capacity': 'Até 120 convidados', 'description': 'Espaço acolhedor para aniversários e jantares especiais.', 'image': 'assets/event_photos/detalhes_convite.jpg'},
  {'id': 'celebre', 'name': 'Celebre Corporativo', 'category': 'Corporativo', 'guests': '300', 'capacity': 'Até 300 convidados', 'description': 'Estrutura flexível para encontros e eventos de equipe.', 'image': 'assets/event_photos/salao_evento.jpg'},
];
const _services = <Map<String, String>>[
  {'name': 'Buffet & gastronomia', 'desc': 'Menus, comidas e bebidas', 'icon': 'restaurant_menu'},
  {'name': 'Decoração & flores', 'desc': 'Cores, arranjos e ambientação', 'icon': 'local_florist_outlined'},
  {'name': 'DJ & música', 'desc': 'Som para cada momento', 'icon': 'music_note'},
  {'name': 'Iluminação', 'desc': 'Luz, palco e atmosfera', 'icon': 'light_mode_outlined'},
  {'name': 'Cerimonial', 'desc': 'Organização e acompanhamento', 'icon': 'event_available_outlined'},
  {'name': 'Fotografia', 'desc': 'Registros da celebração', 'icon': 'photo_camera_outlined'},
];

class SpacesServicesTab extends StatefulWidget {
  const SpacesServicesTab({super.key});
  @override
  State<SpacesServicesTab> createState() => _SpacesServicesTabState();
}

class _SpacesServicesTabState extends State<SpacesServicesTab> {
  final _searchController = TextEditingController();
  String _filter = 'Todos';
  String _capacityFilter = 'Todas as capacidades';
  bool _favoritesOnly = false;
  final Set<String> _selected = {};

  @override
  void initState() { super.initState(); _selected.addAll(UpAppState.instance.selectedServices); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = UpAppState.instance;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _spaces.where((space) { final guests = int.tryParse(space['guests'] ?? '0') ?? 0; final categoryMatch = _filter == 'Todos' || space['category'] == _filter; final capacityMatch = _capacityFilter == 'Todas as capacidades' || (_capacityFilter == 'Até 150 convidados' ? guests <= 150 : guests > 150); final favoriteMatch = !_favoritesOnly || state.favoriteSpaces.contains(space['id']); final searchMatch = '${space['name']} ${space['category']} ${space['description']}'.toLowerCase().contains(query); return categoryMatch && capacityMatch && favoriteMatch && searchMatch; }).toList();
    final wide = MediaQuery.sizeOf(context).width > 760;
    return ListView(padding: EdgeInsets.all(wide ? 30 : 18), children: [
      const UpSectionTitle(eyebrow: 'Descubra possibilidades', title: 'Espaços & |serviços', subtitle: 'Pesquise cenários, guarde favoritos e selecione o que deseja incluir no evento.'),
      const SizedBox(height: 22),
      TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Pesquisar espaços e categorias', suffixIcon: Icon(Icons.tune))),
      const SizedBox(height: 10),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['Todos', 'Casamento', 'Ao ar livre', 'Festas', 'Corporativo'].map((name) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(name), selected: _filter == name, onSelected: (_) => setState(() => _filter = name)))).toList())),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4, children: [ChoiceChip(label: const Text('Todas as capacidades'), selected: _capacityFilter == 'Todas as capacidades', onSelected: (_) => setState(() => _capacityFilter = 'Todas as capacidades')), ChoiceChip(label: const Text('Até 150 convidados'), selected: _capacityFilter == 'Até 150 convidados', onSelected: (_) => setState(() => _capacityFilter = 'Até 150 convidados')), ChoiceChip(label: const Text('Mais de 150'), selected: _capacityFilter == 'Mais de 150 convidados', onSelected: (_) => setState(() => _capacityFilter = 'Mais de 150 convidados')), FilterChip(label: const Text('Só favoritos'), selected: _favoritesOnly, onSelected: (value) => setState(() => _favoritesOnly = value))]),
      const SizedBox(height: 18),
      if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(25), child: Center(child: Text('Nenhum espaço encontrado. Tente outra pesquisa.'))),
      LayoutBuilder(builder: (context, constraints) { final columns = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 570 ? 2 : 1; return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filtered.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: columns == 1 ? 1.5 : .91), itemBuilder: (context, index) => _SpaceCard(space: filtered[index])); }),
      const SizedBox(height: 34),
      const UpSectionTitle(eyebrow: 'Cada detalhe conta', title: 'Serviços para |personalizar', subtitle: 'Marque os serviços que combinam com sua celebração.'),
      const SizedBox(height: 14),
      ..._services.map((service) => CheckboxListTile(dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), value: _selected.contains(service['name']), onChanged: (value) => setState(() { if (value == true) { _selected.add(service['name']!); } else { _selected.remove(service['name']); } }), title: Text(service['name']!), subtitle: Text(service['desc']!), secondary: Icon(_iconFor(service['icon']!), color: Theme.of(context).colorScheme.primary), controlAffinity: ListTileControlAffinity.trailing)),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: () async { await state.setSelectedServices(_selected.toList()); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serviços salvos. Você pode usá-los no orçamento.'))); }, icon: const Icon(Icons.save_outlined), label: const Text('Salvar minhas escolhas')),
      const SizedBox(height: 20),
    ]);
  }

  IconData _iconFor(String value) {
    switch (value) { case 'restaurant_menu': return Icons.restaurant_menu; case 'local_florist_outlined': return Icons.local_florist_outlined; case 'music_note': return Icons.music_note; case 'light_mode_outlined': return Icons.light_mode_outlined; case 'event_available_outlined': return Icons.event_available_outlined; default: return Icons.photo_camera_outlined; }
  }
}

class _SpaceCard extends StatefulWidget {
  const _SpaceCard({required this.space});
  final Map<String, String> space;
  @override
  State<_SpaceCard> createState() => _SpaceCardState();
}

class _SpaceCardState extends State<_SpaceCard> {
  @override
  Widget build(BuildContext context) {
    final state = UpAppState.instance;
    final space = widget.space;
    final favorite = state.favoriteSpaces.contains(space['id']);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RemotePhoto(url: space['image']!, borderRadius: BorderRadius.zero),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton.filledTonal(
                    onPressed: () async {
                      await state.toggleFavorite(space['id']!);
                      if (mounted) setState(() {});
                    },
                    icon: Icon(favorite ? Icons.favorite : Icons.favorite_border),
                    tooltip: favorite ? 'Remover favorito' : 'Favoritar',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(space['category']!.toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, letterSpacing: 1.2)),
                const SizedBox(height: 5),
                Text(space['name']!, style: const TextStyle(fontSize: 20, fontFamily: 'Georgia')),
                const SizedBox(height: 4),
                Text(space['capacity']!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (sheetContext) => SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RemotePhoto(url: space['image']!, height: 190, width: double.infinity),
                              const SizedBox(height: 14),
                              Text(space['name']!, style: const TextStyle(fontFamily: 'Georgia', fontSize: 24)),
                              Text('${space['category']} · ${space['capacity']}'),
                              const SizedBox(height: 8),
                              Text(space['description']!),
                              const SizedBox(height: 14),
                              const Text('Espaço demonstrativo. Consulte a equipe sobre disponibilidade e preços.'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => Navigator.of(sheetContext).pop(),
                                icon: const Icon(Icons.check),
                                label: const Text('Entendi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Ver detalhes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
