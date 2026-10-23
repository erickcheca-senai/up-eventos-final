import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/common_widgets.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});
  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = true;
  bool _loading = false;
  String _role = 'cliente';
  String? _error;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final error = await UpAppState.instance.authenticate(name: _name.text, email: _email.text, password: _password.text, role: _role, register: _register);
    if (!mounted) return;
    setState(() { _loading = false; _error = error; });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 600;
    return Scaffold(appBar: AppBar(title: const UpLogo(height: 38), leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back))), body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Card(child: Padding(padding: EdgeInsets.all(wide ? 30 : 20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Center(child: UpLogo(height: 58)), const SizedBox(height: 20),
      const Eyebrow('Área de acesso'), const SizedBox(height: 6),
      Text(_register ? 'Crie sua conta' : 'Entre na sua conta', style: const TextStyle(fontFamily: 'Georgia', fontSize: 29)), const SizedBox(height: 7),
      Text('Escolha seu perfil para continuar.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 18),
      Row(children: [Expanded(child: _RoleCard(title: 'Sou cliente', subtitle: 'Planejar meu evento', icon: Icons.favorite_border, selected: _role == 'cliente', onTap: () => setState(() => _role = 'cliente'))), const SizedBox(width: 10), Expanded(child: _RoleCard(title: 'Sou organizador', subtitle: 'Acompanhar pedidos', icon: Icons.event_available_outlined, selected: _role == 'organizador', onTap: () => setState(() => _role = 'organizador')))]), const SizedBox(height: 16),
      SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Criar conta')), ButtonSegment(value: false, label: Text('Já tenho conta'))], selected: {_register}, onSelectionChanged: (value) => setState(() { _register = value.first; _error = null; })),
      const SizedBox(height: 16),
      if (_register) ...[TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v == null || v.trim().length < 2) ? 'Informe seu nome.' : null), const SizedBox(height: 12)],
      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Informe um e-mail válido.' : null), const SizedBox(height: 12),
      TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha de demonstração', prefixIcon: Icon(Icons.lock_outline)), validator: (v) => (v == null || v.length < 4) ? 'Use pelo menos 4 caracteres.' : null),
      if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
      const SizedBox(height: 18), FilledButton.icon(onPressed: _loading ? null : _submit, icon: _loading ? const SizedBox(width: 18,height: 18,child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward), label: Text(_register ? 'Criar conta e entrar' : 'Entrar')),
      const SizedBox(height: 12), Text('Protótipo escolar: contas ficam salvas neste aparelho. Não use senha real.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ]))))))));
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});
  final String title, subtitle; final IconData icon; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, width: selected ? 2 : 1), color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: .1) : Theme.of(context).colorScheme.surface), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])));
}
