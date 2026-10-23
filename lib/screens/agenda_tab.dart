import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/common_widgets.dart';

class AgendaTab extends StatefulWidget {
  const AgendaTab({super.key});
  @override
  State<AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<AgendaTab> {
  DateTime? _date;
  String? _time;
  String _eventType = 'Casamento';
  final _notes = TextEditingController();
  final _times = const ['09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00', '17:00'];

  @override
  void dispose() { _notes.dispose(); super.dispose(); }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _date ?? now, firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(now.year + 3), helpText: 'Escolha a data da visita');
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_date == null || _time == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escolha uma data e um horário.'))); return; }
    final item = {'id': DateTime.now().microsecondsSinceEpoch.toString(), 'date': '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}', 'time': _time!, 'type': _eventType, 'notes': _notes.text.trim(), 'owner': UpAppState.instance.userName};
    final success = await UpAppState.instance.addAppointment(item);
    if (!mounted) return;
    if (!success) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esse horário já foi escolhido neste aparelho. Selecione outro horário.'))); return; }
    setState(() { _date = null; _time = null; _notes.clear(); });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento demonstrativo salvo neste aparelho.')));
  }

  DateTime? _parseDate(String raw) { try { final p = raw.split('-'); return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2])); } catch (_) { return null; } }

  @override
  Widget build(BuildContext context) {
    final state = UpAppState.instance;
    final wide = MediaQuery.sizeOf(context).width > 800;
    return ListView(padding: EdgeInsets.all(wide ? 30 : 16), children: [
      const UpSectionTitle(eyebrow: 'Escolha o melhor momento', title: 'Agendamento de |visita', subtitle: 'Selecione uma data e um horário para registrar uma visita demonstrativa.'),
      const SizedBox(height: 20),
      SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('Sua solicitação'), const SizedBox(height: 15),
        InkWell(onTap: _chooseDate, borderRadius: BorderRadius.circular(12), child: InputDecorator(decoration: const InputDecoration(labelText: 'Data desejada', prefixIcon: Icon(Icons.calendar_month_outlined)), child: Text(_date == null ? 'Escolher data' : _formatDate(_date!)))),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: _time, decoration: const InputDecoration(labelText: 'Horário', prefixIcon: Icon(Icons.schedule)), items: _times.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (value) => setState(() => _time = value)),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: _eventType, decoration: const InputDecoration(labelText: 'Tipo de evento', prefixIcon: Icon(Icons.celebration_outlined)), items: const ['Casamento', 'Aniversário', 'Debutante', 'Evento corporativo', 'Formatura', 'Outra celebração'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (value) => setState(() => _eventType = value ?? 'Casamento')),
        const SizedBox(height: 14), TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Observações (opcional)', hintText: 'Uma ideia ou necessidade importante')),
        const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.event_available_outlined), label: const Text('Salvar agendamento'))),
        const SizedBox(height: 10), Text('Protótipo: o agendamento fica neste aparelho e não confirma uma reserva real.', style: Theme.of(context).textTheme.bodySmall),
      ])),
      const SizedBox(height: 26),
      const Text('Agendamentos registrados', style: TextStyle(fontFamily: 'Georgia', fontSize: 25)), const SizedBox(height: 10),
      if (state.appointments.isEmpty) const SectionCard(child: Text('Você ainda não tem agendamentos.')) else ...state.appointments.map((item) {
        final date = _parseDate(item['date']?.toString() ?? '');
        final dateText = date == null ? item['date']?.toString() ?? '' : _formatDate(date);
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: SectionCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.calendar_month_outlined, color: Theme.of(context).colorScheme.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['type']?.toString() ?? 'Visita', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('$dateText · ${item['time'] ?? ''}'), if ((item['notes'] as String? ?? '').isNotEmpty) Text(item['notes'] as String, style: Theme.of(context).textTheme.bodySmall), Text('Solicitado por ${item['owner'] ?? 'cliente'} · demonstração', style: Theme.of(context).textTheme.bodySmall)])), IconButton(tooltip: 'Cancelar', onPressed: () async { await state.removeAppointment(item['id'].toString()); if (mounted) setState(() {}); }, icon: const Icon(Icons.delete_outline))])));
      }),
    ]);
  }
}
