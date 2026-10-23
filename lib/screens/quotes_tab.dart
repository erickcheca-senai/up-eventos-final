import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart' as xf;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../widgets/common_widgets.dart';

const _quoteServices = ['Espaço', 'Buffet & gastronomia', 'Decoração & flores', 'DJ & música', 'Iluminação', 'Cerimonial', 'Fotografia'];

class QuotesTab extends StatefulWidget {
  const QuotesTab({super.key});
  @override
  State<QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<QuotesTab> {
  final _formKey = GlobalKey<FormState>();
  final _guests = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  String? _type;
  String? _budget;
  DateTime? _date;
  final Set<String> _services = {};
  bool _busy = false;

  @override
  void initState() { super.initState(); _services.addAll(UpAppState.instance.selectedServices); }
  @override
  void dispose() { _guests.dispose(); _phone.dispose(); _notes.dispose(); super.dispose(); }

  String _dateIso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _dateText(String? value) { if (value == null || value.isEmpty) return 'A combinar'; try { final p = value.split('-'); return '${p[2]}/${p[1]}/${p[0]}'; } catch (_) { return value; } }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(context: context, initialDate: _date ?? now, firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(now.year + 5), helpText: 'Data desejada do evento');
    if (result != null && mounted) setState(() => _date = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final date = _date;
    if (date != null && date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escolha uma data de hoje em diante.'))); return;
    }
    setState(() => _busy = true);
    await UpAppState.instance.addQuote({
      'ownerName': UpAppState.instance.userName,
      'ownerEmail': UpAppState.instance.currentUser?['email'] ?? '',
      'type': _type ?? 'Outra celebração',
      'guests': _guests.text.trim(),
      'date': date == null ? '' : _dateIso(date),
      'budget': _budget ?? 'Ainda não definido',
      'phone': _phone.text.trim(),
      'services': _services.toList(),
      'notes': _notes.text.trim(),
    });
    if (!mounted) return;
    setState(() { _busy = false; _type = null; _budget = null; _date = null; _services.clear(); _guests.clear(); _phone.clear(); _notes.clear(); });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitação demonstrativa salva neste aparelho.')));
  }

  List<Map<String, dynamic>> _visibleQuotes() {
    final state = UpAppState.instance;
    if (state.isOrganizer) return state.quotes;
    final email = state.currentUser?['email'] ?? '';
    return state.quotes.where((q) => (q['ownerEmail'] ?? '') == email).toList();
  }

  String _csvCell(Object? value) {
    final escaped = (value ?? '').toString().replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> _exportCsv() async {
    final quotes = _visibleQuotes();
    if (quotes.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ainda não há orçamentos para exportar.'))); return; }
    final rows = <List<String>>[
      ['Cliente', 'Tipo de evento', 'Data', 'Convidados', 'Serviços', 'Faixa de orçamento', 'Contato', 'Status'],
      ...quotes.map((q) => [q['ownerName']?.toString() ?? '', q['type']?.toString() ?? '', q['date']?.toString() ?? '', q['guests']?.toString() ?? '', (q['services'] as List? ?? []).join('; '), q['budget']?.toString() ?? '', q['phone']?.toString() ?? '', q['status']?.toString() ?? 'Recebido'])
    ];
    final csv = '\uFEFF${rows.map((row) => row.map(_csvCell).join(';')).join('\r\n')}';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/up-eventos-orcamentos.csv');
    await file.writeAsString(csv, flush: true);
    await Share.shareXFiles([xf.XFile(file.path, mimeType: 'text/csv')], subject: 'Orçamentos UP Eventos', text: 'Exportação demonstrativa de orçamentos.');
  }

  Future<void> _exportPdf() async {
    final quotes = _visibleQuotes();
    if (quotes.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ainda não há orçamentos para exportar.'))); return; }
    final document = pw.Document();
    document.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(32), build: (context) => [
      pw.Text('UP EVENTOS', style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#9C7145'))),
      pw.SizedBox(height: 5),
      pw.Text(UpAppState.instance.isOrganizer ? 'Relatório de solicitações' : 'Minhas solicitações de orçamento', style: const pw.TextStyle(fontSize: 17)),
      pw.SizedBox(height: 8),
      pw.Text('Gerado em ${DateTime.now().toString().substring(0, 16)} · Documento demonstrativo, sem preços oficiais.'),
      pw.SizedBox(height: 18),
      ...quotes.map((q) {
        final eventType = q['type']?.toString() ?? 'Evento';
        final ownerName = q['ownerName']?.toString() ?? 'Cliente';
        final dateText = _dateText(q['date']?.toString());
        final guestCount = q['guests']?.toString() ?? '—';
        final serviceText = (q['services'] as List? ?? []).join(', ');
        final budgetText = q['budget']?.toString() ?? 'A combinar';
        final statusText = q['status']?.toString() ?? 'Recebido';
        final notesText = q['notes']?.toString() ?? '';
        return pw.Container(margin: const pw.EdgeInsets.only(bottom: 14), padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromHex('#D6A16C'))), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('$eventType · $ownerName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('Data: $dateText  |  Convidados: $guestCount'),
          pw.Text('Serviços: $serviceText'),
          pw.Text('Faixa de orçamento: $budgetText  |  Status: $statusText'),
          if (notesText.isNotEmpty) pw.Text('Observações: $notesText'),
        ]));
      }),
      pw.SizedBox(height: 10),
      pw.Text('Os registros acima são locais e demonstrativos. Este arquivo não é uma proposta comercial oficial.', style: const pw.TextStyle(fontSize: 9)),
    ]));
    await Printing.layoutPdf(name: 'up-eventos-orcamentos.pdf', onLayout: (_) async => document.save());
  }

  @override
  Widget build(BuildContext context) {
    final state = UpAppState.instance;
    final quotes = _visibleQuotes();
    if (state.isOrganizer) return _buildOrganizer(context, quotes);
    final wide = MediaQuery.sizeOf(context).width > 800;
    return ListView(padding: EdgeInsets.all(wide ? 30 : 16), children: [
      const UpSectionTitle(eyebrow: 'Vamos planejar', title: 'Seu |orçamento', subtitle: 'Preencha o essencial. Seus dados serão salvos neste aparelho para a demonstração.'),
      const SizedBox(height: 20),
      SectionCard(child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Tipo de evento', prefixIcon: Icon(Icons.celebration_outlined)), items: const ['Casamento', 'Aniversário', 'Debutante', 'Evento corporativo', 'Formatura', 'Outra celebração'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _type = v), validator: (v) => v == null ? 'Escolha o tipo de evento.' : null),
        const SizedBox(height: 14),
        TextFormField(controller: _guests, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Número aproximado de convidados', prefixIcon: Icon(Icons.groups_outlined), hintText: 'Ex.: 120'), validator: (v) { final n = int.tryParse(v ?? ''); if (n == null || n < 1 || n > 10000) return 'Informe um número entre 1 e 10.000.'; return null; }),
        const SizedBox(height: 14),
        InkWell(onTap: _chooseDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Data desejada (opcional)', prefixIcon: Icon(Icons.calendar_month_outlined)), child: Text(_date == null ? 'A combinar' : _dateText(_dateIso(_date!))))),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: _budget, decoration: const InputDecoration(labelText: 'Faixa de orçamento (opcional)', prefixIcon: Icon(Icons.payments_outlined)), items: const ['Até R\$ 5.000', 'R\$ 5.000 a R\$ 15.000', 'R\$ 15.000 a R\$ 30.000', 'Acima de R\$ 30.000', 'Ainda não definido'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _budget = v)),
        const SizedBox(height: 14),
        TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone para contato', prefixIcon: Icon(Icons.phone_outlined), hintText: '(11) 99999-9999'), validator: (v) => (v == null || v.trim().length < 8) ? 'Informe um contato para demonstração.' : null),
        const SizedBox(height: 18), Text('Serviços de interesse', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 5), Wrap(spacing: 8, runSpacing: 6, children: _quoteServices.map((service) => FilterChip(label: Text(service), selected: _services.contains(service), onSelected: (selected) => setState(() { selected ? _services.add(service) : _services.remove(service); }))).toList()),
        const SizedBox(height: 14),
        TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Observações (opcional)', hintText: 'Cores, estilo ou alguma ideia que você tem.')),
        const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : _submit, icon: const Icon(Icons.send_outlined), label: Text(_busy ? 'Salvando…' : 'Salvar solicitação demonstrativa'))),
        const SizedBox(height: 8), Text('Não são enviados pedidos reais nem calculados preços oficiais.', style: Theme.of(context).textTheme.bodySmall),
      ]))),
      const SizedBox(height: 25),
      Row(children: [Expanded(child: Text('Minhas solicitações (${quotes.length})', style: const TextStyle(fontFamily: 'Georgia', fontSize: 23))), IconButton(tooltip: 'Exportar CSV', onPressed: quotes.isEmpty ? null : _exportCsv, icon: const Icon(Icons.table_view_outlined)), IconButton(tooltip: 'Salvar PDF', onPressed: quotes.isEmpty ? null : _exportPdf, icon: const Icon(Icons.picture_as_pdf_outlined))]),
      if (quotes.isEmpty) const SectionCard(child: Text('Você ainda não salvou uma solicitação.')) else ...quotes.map((q) => _quoteCard(context, q, organizer: false)),
    ]);
  }

  Widget _buildOrganizer(BuildContext context, List<Map<String, dynamic>> quotes) {
    final state = UpAppState.instance;
    return ListView(padding: const EdgeInsets.all(22), children: [
      const UpSectionTitle(eyebrow: 'Área do organizador', title: 'Solicitações de |orçamento', subtitle: 'Consulte as solicitações guardadas neste aparelho e atualize o status para a demonstração.'),
      const SizedBox(height: 18),
      Wrap(spacing: 10, runSpacing: 8, children: [OutlinedButton.icon(onPressed: quotes.isEmpty ? null : _exportCsv, icon: const Icon(Icons.table_view_outlined), label: const Text('Exportar CSV')), OutlinedButton.icon(onPressed: quotes.isEmpty ? null : _exportPdf, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Gerar PDF'))]),
      const SizedBox(height: 18),
      if (quotes.isEmpty) const SectionCard(child: Text('Ainda não há solicitações neste aparelho. Crie uma solicitação entrando como cliente para testar esse fluxo.')) else ...quotes.map((q) => _quoteCard(context, q, organizer: true)),
      const SizedBox(height: 12), Text('As solicitações são locais e não sincronizam entre aparelhos.', style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _quoteCard(BuildContext context, Map<String, dynamic> q, {required bool organizer}) {
    final state = UpAppState.instance;
    final id = q['id'].toString();
    final status = (q['status'] as String?) ?? 'Recebido';
    final services = (q['services'] as List? ?? []).join(', ');
    final serviceLabel = services.isEmpty ? 'A definir' : services;
    final eventType = q['type']?.toString() ?? 'Evento';
    final ownerName = q['ownerName']?.toString() ?? 'Cliente';
    final eventLabel = organizer ? '$eventType · $ownerName' : eventType;
    final guestCount = q['guests']?.toString() ?? '—';
    final dateText = _dateText(q['date']?.toString());
    final budget = q['budget']?.toString() ?? '';
    final notes = q['notes']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(eventLabel, style: const TextStyle(fontFamily: 'Georgia', fontSize: 19))),
            _StatusPill(status: status),
          ]),
          const SizedBox(height: 8),
          Text('$guestCount convidados · Data: $dateText'),
          const SizedBox(height: 4),
          Text('Serviços: $serviceLabel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (budget.isNotEmpty) Text('Faixa de orçamento: $budget', style: Theme.of(context).textTheme.bodySmall),
          if (notes.trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Observações: $notes')),
          if (organizer)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Atualizar status'),
                items: const ["Recebido", "Em análise", "Em contato", "Concluído"].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    await state.updateQuoteStatus(id, value);
                    if (mounted) setState(() {});
                  }
                },
              ),
            ),
        ]),
      ),
    );
  }

}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .13), borderRadius: BorderRadius.circular(30)), child: Text(status, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w700)));
}
