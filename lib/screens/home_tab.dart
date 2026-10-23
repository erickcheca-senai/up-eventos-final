import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/common_widgets.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = UpAppState.instance;
    final name = state.userName.trim().split(RegExp(r'\s+')).first;
    final wide = MediaQuery.sizeOf(context).width > 700;
    final quickActions = [
      _QuickAction(icon: Icons.apartment_outlined, number: '01', title: 'Explorar espaços', subtitle: 'Encontre um cenário para seu evento', onTap: () => onNavigate(1)),
      _QuickAction(icon: Icons.photo_camera_outlined, number: '02', title: 'Guardar referências', subtitle: 'Tire fotos ou envie imagens', onTap: () => onNavigate(2)),
      _QuickAction(icon: Icons.calendar_month_outlined, number: '03', title: 'Agendar uma visita', subtitle: 'Escolha data e horário', onTap: () => onNavigate(3)),
      _QuickAction(icon: Icons.request_quote_outlined, number: '04', title: state.isOrganizer ? 'Acompanhar pedidos' : 'Solicitar orçamento', subtitle: state.isOrganizer ? 'Atualize o status das solicitações' : 'Conte o que está imaginando', onTap: () => onNavigate(4)),
    ];
    return SingleChildScrollView(padding: EdgeInsets.all(wide ? 34 : 18), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Eyebrow('Seu espaço de planejamento'),
      const SizedBox(height: 8),
      Text('Olá, $name.', style: const TextStyle(fontFamily: 'Georgia', fontSize: 35)),
      const SizedBox(height: 8),
      Text(state.isOrganizer ? 'Aqui estão as solicitações e os próximos passos dos eventos.' : 'Organize suas ideias para criar um evento inesquecível.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 26),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 820 ? 4 : constraints.maxWidth > 520 ? 2 : 1;
        return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: quickActions.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: columns == 1 ? 2.5 : 1.15), itemBuilder: (context, index) => _QuickCard(action: quickActions[index]));
      }),
      const SizedBox(height: 24),
      SectionCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome_outlined, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(state.isOrganizer ? 'Visão do organizador' : 'Seu evento, suas escolhas', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(state.isOrganizer ? 'As solicitações criadas neste aparelho aparecem em Orçamentos. Os dados são demonstrativos.' : 'Guarde referências, escolha serviços e registre a data desejada. Seus dados ficam salvos neste aparelho.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45))]))])),
      const SizedBox(height: 22),
      Row(children: [Expanded(child: _StatCard(label: 'Fotos salvas', value: '${state.photos.length}', icon: Icons.photo_library_outlined)), const SizedBox(width: 10), Expanded(child: _StatCard(label: 'Agendamentos', value: '${state.appointments.length}', icon: Icons.event_available_outlined)), const SizedBox(width: 10), Expanded(child: _StatCard(label: state.isOrganizer ? 'Solicitações' : 'Orçamentos', value: '${state.quotes.length}', icon: Icons.receipt_long_outlined))]),
    ]))));
  }
}

class _QuickAction { const _QuickAction({required this.icon, required this.number, required this.title, required this.subtitle, required this.onTap}); final IconData icon; final String number,title,subtitle; final VoidCallback onTap; }
class _QuickCard extends StatelessWidget { const _QuickCard({required this.action}); final _QuickAction action; @override Widget build(BuildContext context) => InkWell(onTap: action.onTap, borderRadius: BorderRadius.circular(18), child: Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(action.icon, color: Theme.of(context).colorScheme.primary, size: 25), Text(action.number, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.4))]), const SizedBox(height: 12), Text(action.title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 18)), Text(action.subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)), const Align(alignment: Alignment.bottomRight, child: Icon(Icons.arrow_outward, size: 17))])))); }
class _StatCard extends StatelessWidget { const _StatCard({required this.label,required this.value,required this.icon}); final String label,value; final IconData icon; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text(value, style: const TextStyle(fontFamily: 'Georgia', fontSize: 25)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant))]))); }
