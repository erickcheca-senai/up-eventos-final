import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart' as xf;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../widgets/common_widgets.dart';

class CameraGalleryTab extends StatefulWidget {
  const CameraGalleryTab({super.key});
  @override
  State<CameraGalleryTab> createState() => _CameraGalleryTabState();
}

class _CameraGalleryTabState extends State<CameraGalleryTab> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  xf.XFile? _pendingPhoto;
  bool _loadingCameras = true;
  bool _busy = false;
  String? _cameraError;
  int _selectedCamera = 0;
  String _eventFilter = 'Todos';
  String _spaceFilter = 'Todos';
  String _categoryFilter = 'Todas';
  bool _favoritesOnly = false;
  final _picker = ImagePicker();
  static const List<String> _categories = [
    'Decoração', 'Espaço', 'Buffet', 'Iluminação', 'DJ e música',
    'Cerimônia', 'Mesa posta', 'Fotografia', 'Referência', 'Outro',
  ];

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _loadCameras(); }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose(); _controller = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      setState(() {
        _cameras = cameras; _loadingCameras = false;
        final backIndex = cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.back);
        _selectedCamera = backIndex >= 0 ? backIndex : 0;
        if (cameras.isEmpty) _cameraError = 'Este dispositivo não informou uma câmera. Você ainda pode selecionar fotos da galeria.';
      });
    } catch (_) {
      if (mounted) setState(() { _loadingCameras = false; _cameraError = 'Não foi possível encontrar a câmera. Verifique as permissões do dispositivo.'; });
    }
  }

  Future<void> _openCamera() async {
    if (_cameras.isEmpty) { setState(() => _cameraError = 'Nenhuma câmera disponível. Use “Adicionar imagens” como alternativa.'); return; }
    setState(() { _busy = true; _cameraError = null; _pendingPhoto = null; });
    try {
      await _controller?.dispose();
      final description = _cameras[_selectedCamera.clamp(0, _cameras.length - 1).toInt()];
      final controller = CameraController(description, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      _controller = controller;
      await controller.initialize();
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      _controller = null;
      if (mounted) setState(() => _cameraError = e.code == 'CameraAccessDenied' ? 'Permissão negada. Ative a câmera nas configurações do Android.' : 'Não foi possível abrir a câmera. Tente outra câmera ou escolha uma imagem.');
    } catch (_) {
      if (mounted) setState(() => _cameraError = 'Ocorreu um erro ao abrir a câmera.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _switchCamera(int? index) async {
    if (index == null || index == _selectedCamera) return;
    setState(() => _selectedCamera = index);
    await _openCamera();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) return;
    try {
      setState(() => _busy = true);
      _pendingPhoto = await controller.takePicture();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _cameraError = 'Não foi possível tirar a foto. Tente novamente.');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<String> _copyToAppFolder(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final source = File(sourcePath);
    final filename = sourcePath.split(Platform.pathSeparator).last;
    final extension = filename.contains('.') ? filename.split('.').last.toLowerCase() : 'jpg';
    final safeExtension = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension) ? extension : 'jpg';
    final destination = '${directory.path}/up_eventos_${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
    await source.copy(destination);
    return destination;
  }

  Future<Map<String, String>?> _askPhotoDetails({Map<String, dynamic>? initial, int count = 1}) async {
    final eventController = TextEditingController(text: (initial?['event'] ?? '').toString());
    final spaceController = TextEditingController(text: (initial?['space'] ?? '').toString());
    final oldCategory = (initial?['category'] ?? 'Referência').toString();
    String selectedCategory = _categories.contains(oldCategory) ? oldCategory : 'Referência';
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(count > 1 ? 'Associar $count imagens' : 'Associar referência'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(alignment: Alignment.centerLeft, child: Text('Salve cada registro associado a um evento ou espaço.')),
          const SizedBox(height: 14),
          TextField(controller: eventController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nome do evento', hintText: 'Ex.: Casamento Ana e Lucas')),
          const SizedBox(height: 10),
          TextField(controller: spaceController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Espaço', hintText: 'Ex.: Salão principal ou jardim')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(value: selectedCategory, isExpanded: true, decoration: const InputDecoration(labelText: 'Categoria'), items: _categories.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) { if (value != null) setDialogState(() => selectedCategory = value); }),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(null), child: const Text('Cancelar')),
          FilledButton.icon(onPressed: () => Navigator.of(dialogContext).pop({'event': eventController.text.trim(), 'space': spaceController.text.trim(), 'category': selectedCategory}), icon: const Icon(Icons.save_outlined), label: const Text('Salvar referência')),
        ],
      )),
    );
    eventController.dispose(); spaceController.dispose();
    return result;
  }

  Future<void> _savePending() async {
    final pending = _pendingPhoto;
    if (pending == null) return;
    final details = await _askPhotoDetails();
    if (details == null) return;
    try {
      setState(() => _busy = true);
      final path = await _copyToAppFolder(pending.path);
      await UpAppState.instance.addPhoto(path, event: details['event']!, space: details['space']!, category: details['category']!);
      if (mounted) setState(() { _pendingPhoto = null; _cameraError = null; });
      _message('Foto salva no moodboard.');
    } catch (_) { _message('Não foi possível salvar. Verifique o espaço disponível.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _pickImages() async {
    try {
      final selected = await _picker.pickMultiImage(imageQuality: 88, maxWidth: 1800);
      if (selected.isEmpty) return;
      final details = await _askPhotoDetails(count: selected.length);
      if (details == null) return;
      setState(() => _busy = true);
      for (final image in selected) {
        final path = await _copyToAppFolder(image.path);
        await UpAppState.instance.addPhoto(path, event: details['event']!, space: details['space']!, category: details['category']!);
      }
      if (mounted) setState(() {});
      _message('${selected.length} imagem(ns) adicionada(s) ao moodboard.');
    } catch (_) { _message('Não foi possível adicionar estas imagens.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _editPhotoDetails(String path) async {
    final details = await _askPhotoDetails(initial: UpAppState.instance.photoMetadataFor(path));
    if (details == null) return;
    await UpAppState.instance.updatePhotoMetadata(path, event: details['event']!, space: details['space']!, category: details['category']!);
    if (mounted) setState(() {});
  }

  Future<void> _deletePhoto(String path) async {
    await UpAppState.instance.removePhoto(path);
    try { final file = File(path); if (await file.exists()) await file.delete(); } catch (_) {}
    if (mounted) setState(() {});
  }

  void _showPhoto(String path) {
    final metadata = UpAppState.instance.photoMetadataFor(path);
    final eventValue = (metadata['event'] ?? '').toString().trim();
    final spaceValue = (metadata['space'] ?? '').toString().trim();
    final categoryValue = (metadata['category'] ?? 'Referência').toString();
    final eventLabel = eventValue.isNotEmpty ? eventValue : 'Evento não informado';
    final spaceLabel = spaceValue.isNotEmpty ? spaceValue : 'Espaço não informado';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 850, maxHeight: MediaQuery.sizeOf(context).height * 0.88),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.58),
                  child: InteractiveViewer(
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 60),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(eventLabel, style: Theme.of(context).textTheme.titleMedium),
                Text('$spaceLabel · $categoryValue', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _editPhotoDetails(path);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar associação'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await UpAppState.instance.togglePhotoFavorite(path);
                        if (mounted) setState(() {});
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      },
                      icon: Icon(metadata['favorite'] == true ? Icons.favorite : Icons.favorite_border),
                      label: const Text('Favoritar'),
                    ),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fechar')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _valuesFor(UpAppState state, String key) {
    final values = state.photoDetails.map((item) => (item[key] ?? '').toString().trim()).where((value) => value.isNotEmpty).toSet().toList()..sort();
    return values;
  }

  List<String> _filteredPhotos(UpAppState state) {
    return state.photos.where((path) {
      final meta = state.photoMetadataFor(path);
      if (_eventFilter != 'Todos' && meta['event'] != _eventFilter) return false;
      if (_spaceFilter != 'Todos' && meta['space'] != _spaceFilter) return false;
      if (_categoryFilter != 'Todas' && meta['category'] != _categoryFilter) return false;
      if (_favoritesOnly && meta['favorite'] != true) return false;
      return true;
    }).toList();
  }

  Widget _filterDropdown({required String label, required String value, required List<String> values, required ValueChanged<String?> onChanged}) {
    return SizedBox(width: 190, child: DropdownButtonFormField<String>(value: value, isExpanded: true, decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)), items: values.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged));
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = UpAppState.instance;
    final controller = _controller;
    final initialized = controller != null && controller.value.isInitialized;
    final wide = MediaQuery.sizeOf(context).width > 800;
    final events = _valuesFor(state, 'event');
    final spaces = _valuesFor(state, 'space');
    final eventOptions = ['Todos', ...events];
    final spaceOptions = ['Todos', ...spaces];
    final categoryOptions = ['Todas', ..._categories.where((category) => state.photoDetails.any((item) => item['category'] == category))];
    if (!eventOptions.contains(_eventFilter)) _eventFilter = 'Todos';
    if (!spaceOptions.contains(_spaceFilter)) _spaceFilter = 'Todos';
    if (!categoryOptions.contains(_categoryFilter)) _categoryFilter = 'Todas';
    final filteredPhotos = _filteredPhotos(state);

    return ListView(padding: EdgeInsets.all(wide ? 30 : 16), children: [
      const UpSectionTitle(eyebrow: 'Referências no momento em que aparecem', title: 'Uma câmera para capturar possibilidades', subtitle: 'Abra a câmera, registre detalhes e associe cada foto a um evento ou espaço.'),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final steps = [
          ('01', 'Abra', 'Abra a câmera e veja a imagem em tempo real.', Icons.photo_camera_outlined),
          ('02', 'Registre', 'Fotografe espaços, decoração e referências.', Icons.camera_alt_outlined),
          ('03', 'Associe', 'Organize por evento, espaço e categoria.', Icons.bookmark_add_outlined),
        ];
        return Wrap(spacing: 10, runSpacing: 10, children: steps.map((item) => SizedBox(width: compact ? constraints.maxWidth : (constraints.maxWidth - 20) / 3, child: SectionCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(item.$4, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$1, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary)), Text(item.$2, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), Text(item.$3, style: Theme.of(context).textTheme.bodySmall)]))])))).toList());
      }),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (context, constraints) {
        final vertical = constraints.maxWidth < 760;
        final cameraPane = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 4 / 3, child: Stack(fit: StackFit.expand, children: [
            if (_pendingPhoto != null) Image.file(File(_pendingPhoto!.path), fit: BoxFit.cover)
            else if (initialized) CameraPreview(controller!)
            else Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.photo_camera_outlined, size: 42, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 10), const Text('Sua câmera aparecerá aqui'), const SizedBox(height: 5), Text(_loadingCameras ? 'Procurando câmeras…' : 'Permita o acesso quando solicitado', style: Theme.of(context).textTheme.bodySmall)]))),
            if (_busy) const Center(child: CircularProgressIndicator()),
          ]))),
          if (_cameras.length > 1 && _pendingPhoto == null) Padding(padding: const EdgeInsets.only(top: 10), child: DropdownButtonFormField<int>(value: _selectedCamera, decoration: const InputDecoration(labelText: 'Escolher câmera'), items: List.generate(_cameras.length, (i) => DropdownMenuItem(value: i, child: Text('${_cameras[i].lensDirection.name} · câmera ${i + 1}'))), onChanged: _switchCamera)),
          if (_cameraError != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_cameraError!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: _pendingPhoto != null ? [FilledButton.icon(onPressed: _busy ? null : _savePending, icon: const Icon(Icons.save_outlined), label: const Text('Associar e salvar')), OutlinedButton.icon(onPressed: () => setState(() { _pendingPhoto = null; _cameraError = null; }), icon: const Icon(Icons.refresh), label: const Text('Tirar outra')), OutlinedButton.icon(onPressed: () => Share.shareXFiles([_pendingPhoto!], text: 'Referência UP Eventos'), icon: const Icon(Icons.ios_share), label: const Text('Compartilhar'))] : [FilledButton.icon(onPressed: _busy || _loadingCameras ? null : _openCamera, icon: const Icon(Icons.camera_alt_outlined), label: Text(initialized ? 'Reabrir câmera' : 'Abrir câmera')), OutlinedButton.icon(onPressed: initialized && !_busy ? _capture : null, icon: const Icon(Icons.circle_outlined), label: const Text('Tirar foto')), OutlinedButton.icon(onPressed: initialized ? () async { await controller!.dispose(); if (mounted) setState(() => _controller = null); } : null, icon: const Icon(Icons.stop_circle_outlined), label: const Text('Parar'))]),
        ]);
        final helpPane = SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.primary, size: 28), const SizedBox(height: 10), const Text('Seu moodboard pessoal para cada evento', style: TextStyle(fontFamily: 'Georgia', fontSize: 22)), const SizedBox(height: 8), Text('Adicione imagens do aparelho ou tire novas fotos. Associe cada referência a um evento, espaço e categoria.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 16), OutlinedButton.icon(onPressed: _pickImages, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Adicionar imagens')), const SizedBox(height: 10), Text('As fotos e associações ficam guardadas neste dispositivo.', style: Theme.of(context).textTheme.bodySmall)]));
        return vertical ? Column(children: [cameraPane, const SizedBox(height: 16), helpPane]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: cameraPane), const SizedBox(width: 18), Expanded(flex: 2, child: helpPane)]);
      }),
      const SizedBox(height: 28),
      Row(children: [Expanded(child: Text('Seu moodboard (${state.photos.length})', style: const TextStyle(fontFamily: 'Georgia', fontSize: 24))), TextButton.icon(onPressed: state.photos.isEmpty ? null : () async { final shouldClear = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Limpar moodboard?'), content: const Text('As fotos e suas associações serão removidas do aplicativo.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir tudo'))])); if (shouldClear == true) { for (final path in List<String>.from(state.photos)) { try { final f = File(path); if (await f.exists()) await f.delete(); } catch (_) {} } await state.clearPhotos(); if (mounted) setState(() { _eventFilter = 'Todos'; _spaceFilter = 'Todos'; _categoryFilter = 'Todas'; _favoritesOnly = false; }); } }, icon: const Icon(Icons.delete_outline), label: const Text('Limpar'))]),
      const SizedBox(height: 6),
      Text('Todas as fotos tiradas ou enviadas, organizadas por evento, espaço, categoria e favoritos.', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _filterDropdown(label: 'Evento', value: _eventFilter, values: eventOptions, onChanged: (value) => setState(() => _eventFilter = value ?? 'Todos')),
        _filterDropdown(label: 'Espaço', value: _spaceFilter, values: spaceOptions, onChanged: (value) => setState(() => _spaceFilter = value ?? 'Todos')),
        _filterDropdown(label: 'Categoria', value: _categoryFilter, values: categoryOptions, onChanged: (value) => setState(() => _categoryFilter = value ?? 'Todas')),
        FilterChip(label: const Text('Favoritos'), selected: _favoritesOnly, avatar: Icon(_favoritesOnly ? Icons.favorite : Icons.favorite_border, size: 18), onSelected: (value) => setState(() => _favoritesOnly = value)),
      ]),
      const SizedBox(height: 14),
      if (filteredPhotos.isEmpty) SectionCard(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(state.photos.isEmpty ? 'As fotos tiradas e imagens selecionadas aparecerão aqui.' : 'Nenhuma foto corresponde a esses filtros.')))) else LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 650 ? 3 : 2;
        return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filteredPhotos.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .63), itemBuilder: (context, index) {
          final path = filteredPhotos[index];
          final metadata = state.photoMetadataFor(path);
          final event = (metadata['event'] ?? '').toString();
          final space = (metadata['space'] ?? '').toString();
          final category = (metadata['category'] ?? 'Referência').toString();
          final favorite = metadata['favorite'] == true;
          return Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: InkWell(onTap: () => _showPhoto(path), child: Image.file(File(path), width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 42))))),
            Padding(padding: const EdgeInsets.fromLTRB(10, 9, 10, 3), child: Text(event.isNotEmpty ? event : 'Evento não informado', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(space.isNotEmpty ? space : 'Espaço não informado', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
            Padding(padding: const EdgeInsets.fromLTRB(10, 5, 10, 2), child: Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)), child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onPrimaryContainer))))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              IconButton(tooltip: favorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos', onPressed: () async { await state.togglePhotoFavorite(path); if (mounted) setState(() {}); }, icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? Colors.redAccent : null, size: 19)),
              IconButton(tooltip: 'Editar evento, espaço e categoria', onPressed: () => _editPhotoDetails(path), icon: const Icon(Icons.edit_outlined, size: 19)),
              IconButton(tooltip: 'Compartilhar foto', onPressed: () => Share.shareXFiles([xf.XFile(path)], text: 'Referência UP Eventos'), icon: const Icon(Icons.ios_share, size: 19)),
              IconButton(tooltip: 'Excluir foto', onPressed: () => _deletePhoto(path), icon: const Icon(Icons.delete_outline, size: 19)),
            ])),
          ]));
        });
      }),
    ]);
  }
}
