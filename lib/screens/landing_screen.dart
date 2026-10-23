import 'package:flutter/material.dart';
import '../app_state.dart';
import '../app_theme.dart';
import '../widgets/common_widgets.dart';
import 'access_screen.dart';

const _heroImage = 'assets/event_photos/salao_evento.jpg';
const _spaces = [
  {'name': 'Salões elegantes', 'category': 'Casamentos', 'image': 'assets/event_photos/salao_evento.jpg'},
  {'name': 'Ao ar livre', 'category': 'Cerimônias', 'image': 'assets/event_photos/mesa_decorada.jpg'},
  {'name': 'Jantares & festas', 'category': 'Celebrações', 'image': 'assets/event_photos/detalhes_convite.jpg'},
];

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _openAccess(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccessScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final state = UpAppState.instance;
    return Scaffold(
      appBar: AppBar(
        title: const UpLogo(height: 42),
        actions: [
          IconButton(tooltip: state.isDarkMode ? 'Modo claro' : 'Modo escuro', onPressed: () => state.setDarkMode(!state.isDarkMode), icon: Icon(state.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined)),
          Padding(padding: const EdgeInsets.only(right: 12), child: FilledButton(onPressed: () => _openAccess(context), child: const Text('Entrar'))),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _HeroSection(onEnter: () => _openAccess(context)),
          Padding(padding: const EdgeInsets.fromLTRB(22, 42, 22, 24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1120), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const UpSectionTitle(eyebrow: 'Bem-vindo à UP Eventos', title: 'Grandes momentos |merecem um grande cenário.', subtitle: 'Encontre espaços, escolha os detalhes e organize suas ideias em um só lugar.'),
            const SizedBox(height: 25),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 520 ? 2 : 1;
              return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _spaces.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: columns == 1 ? 1.65 : 1.0), itemBuilder: (context, index) {
                final item = _spaces[index];
                return InkWell(borderRadius: BorderRadius.circular(18), onTap: () => _openAccess(context), child: Card(clipBehavior: Clip.antiAlias, child: Stack(fit: StackFit.expand, children: [RemotePhoto(url: item['image']!, borderRadius: BorderRadius.zero), DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: .85)]))), Positioned(left: 16, right: 12, bottom: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['category']!.toUpperCase(), style: const TextStyle(color: upGold, fontSize: 10, letterSpacing: 1.2)), const SizedBox(height: 5), Text(item['name']!, style: const TextStyle(color: Colors.white, fontFamily: 'Georgia', fontSize: 22)), const SizedBox(height: 7), const Text('Explorar espaço  ↗', style: TextStyle(color: Colors.white70, fontSize: 12))]))])));
              });
            }),
            const SizedBox(height: 42),
            const UpSectionTitle(eyebrow: 'Cada detalhe conta', title: 'Uma celebração, |mil possibilidades.', subtitle: 'Buffet, decoração, DJ, iluminação, paleta de cores e cerimonial.'),
            const SizedBox(height: 18),
            Wrap(spacing: 10, runSpacing: 10, children: ['Buffet & gastronomia', 'Decoração & flores', 'DJ & música', 'Som & iluminação', 'Casamentos', 'Eventos especiais'].map((s) => Chip(avatar: const Icon(Icons.auto_awesome, size: 16), label: Text(s))).toList()),
            const SizedBox(height: 35),
            SectionCard(child: LayoutBuilder(builder: (context, constraints) => Flex(direction: constraints.maxWidth > 600 ? Axis.horizontal : Axis.vertical, crossAxisAlignment: CrossAxisAlignment.center, children: [const ExpandedIfWide(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Eyebrow('Vamos planejar?'), SizedBox(height: 8), Text('O próximo momento pode ser o seu.', style: TextStyle(fontFamily: 'Georgia', fontSize: 27)), SizedBox(height: 8), Text('Entre para guardar referências, consultar datas e montar seu orçamento.')])) , const SizedBox(width: 16, height: 16), FilledButton.icon(onPressed: () => _openAccess(context), icon: const Icon(Icons.arrow_forward), label: const Text('Entrar na plataforma'))]))),
            const SizedBox(height: 25),
            Center(child: Column(children: [const UpLogo(height: 55), const SizedBox(height: 12), TextButton.icon(onPressed: () => openWhatsApp(context), icon: const Icon(Icons.chat_outlined), label: const Text('WhatsApp · (11) 96966-3554')), Text('Protótipo demonstrativo · UP Eventos', style: Theme.of(context).textTheme.bodySmall)])),
          ])))),
        ]),
      ),
    );
  }

}

class ExpandedIfWide extends StatelessWidget {
  const ExpandedIfWide({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width > 600 ? Expanded(child: child) : child;
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onEnter});
  final VoidCallback onEnter;
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 700;
    return SizedBox(height: wide ? 560 : 530, width: double.infinity, child: Stack(fit: StackFit.expand, children: [
      RemotePhoto(url: _heroImage, borderRadius: BorderRadius.zero),
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.black.withValues(alpha: .88), Colors.black.withValues(alpha: .42), Colors.black.withValues(alpha: .12)]))),
      Padding(padding: EdgeInsets.symmetric(horizontal: wide ? 70 : 25, vertical: 42), child: Align(alignment: Alignment.centerLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CELEBRE · CONECTE · VIVA MOMENTOS', style: TextStyle(color: upGold, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 17),
        Text.rich(TextSpan(children: const [TextSpan(text: 'Seu momento.\n', style: TextStyle(color: Colors.white)), TextSpan(text: 'Do seu jeito.', style: TextStyle(color: upRose, fontStyle: FontStyle.italic))]), style: TextStyle(fontFamily: 'Georgia', fontSize: wide ? 64 : 43, height: 1.12)),
        const SizedBox(height: 18),
        const Text('Espaços, sabores e detalhes pensados para celebrar histórias únicas.', style: TextStyle(color: Colors.white, height: 1.7, fontSize: 15)),
        const SizedBox(height: 25),
        FilledButton.icon(onPressed: onEnter, icon: const Icon(Icons.arrow_forward), label: const Text('Planeje seu evento')),
      ])))),
    ]));
  }
}
