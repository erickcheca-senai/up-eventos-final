import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/common_widgets.dart';
import 'home_tab.dart';
import 'spaces_services_tab.dart';
import 'camera_gallery_tab.dart';
import 'agenda_tab.dart';
import 'quotes_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<IconData> _icons = const [Icons.home_outlined, Icons.apartment_outlined, Icons.photo_camera_outlined, Icons.calendar_month_outlined, Icons.request_quote_outlined];
  final List<IconData> _selectedIcons = const [Icons.home, Icons.apartment, Icons.photo_camera, Icons.calendar_month, Icons.request_quote];
  final List<String> _labels = const ['Início', 'Espaços', 'Câmera', 'Agenda', 'Orçamento'];

  Widget _selectedPage() {
    switch (_selectedIndex) {
      case 1: return const SpacesServicesTab();
      case 2: return const CameraGalleryTab();
      case 3: return const AgendaTab();
      case 4: return const QuotesTab();
      default: return HomeTab(onNavigate: (index) => setState(() => _selectedIndex = index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = UpAppState.instance;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const UpLogo(height: 37),
        actions: [
          if (wide) Padding(padding: const EdgeInsets.only(right: 8), child: Center(child: Text(state.isOrganizer ? 'Área do organizador' : 'Área do cliente', style: Theme.of(context).textTheme.bodySmall))),
          IconButton(tooltip: 'WhatsApp', onPressed: () => openWhatsApp(context), icon: const Icon(Icons.chat_outlined)),
          IconButton(tooltip: state.isDarkMode ? 'Ativar tema claro' : 'Ativar tema escuro', onPressed: () => state.setDarkMode(!state.isDarkMode), icon: Icon(state.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined)),
          PopupMenuButton<String>(
            tooltip: 'Conta',
            onSelected: (value) async { if (value == 'logout') await state.logout(); },
            itemBuilder: (context) => [PopupMenuItem(value: 'profile', enabled: false, child: Text('${state.userName}\n${state.currentUser?['email'] ?? ''}')), const PopupMenuDivider(), const PopupMenuItem(value: 'logout', child: Text('Sair da conta'))],
            child: Padding(padding: const EdgeInsets.only(left: 4, right: 12), child: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.surface, child: Text(state.userName.isEmpty ? 'U' : state.userName[0].toUpperCase()))),
          ),
        ],
      ),
      body: wide
          ? Row(children: [NavigationRail(extended: MediaQuery.sizeOf(context).width > 1100, selectedIndex: _selectedIndex, onDestinationSelected: (i) => setState(() => _selectedIndex = i), destinations: List.generate(_labels.length, (i) => NavigationRailDestination(icon: Icon(_icons[i]), selectedIcon: Icon(_selectedIcons[i]), label: Text(i == 4 && state.isOrganizer ? 'Pedidos' : _labels[i])))), const VerticalDivider(width: 1), Expanded(child: _selectedPage())])
          : _selectedPage(),
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: _selectedIndex, onDestinationSelected: (i) => setState(() => _selectedIndex = i), destinations: List.generate(_labels.length, (i) => NavigationDestination(icon: Icon(_icons[i]), selectedIcon: Icon(_selectedIcons[i]), label: i == 4 && state.isOrganizer ? 'Pedidos' : _labels[i]))),
    );
  }
}
