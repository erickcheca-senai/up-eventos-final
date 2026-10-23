import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado local do protótipo. Não substitui autenticação ou banco de dados reais.
class UpAppState extends ChangeNotifier {
  UpAppState._();
  static final UpAppState instance = UpAppState._();

  late SharedPreferences _prefs;
  bool isDarkMode = true;
  Map<String, dynamic>? currentUser;
  List<Map<String, dynamic>> _accounts = [];
  List<String> photos = [];
  List<Map<String, dynamic>> photoDetails = [];
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> quotes = [];
  List<String> favoriteSpaces = [];
  List<String> selectedServices = [];

  bool get isLoggedIn => currentUser != null;
  String get userName => (currentUser?['name'] as String?) ?? 'Visitante';
  String get userRole => (currentUser?['role'] as String?) ?? 'cliente';
  bool get isOrganizer => userRole == 'organizador';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    isDarkMode = _prefs.getBool('up_dark_mode') ?? true;
    _accounts = _readMapList('up_accounts');
    currentUser = _readMap('up_current_user');
    photos = _readStringList('up_photos');
    photoDetails = _readMapList('up_photo_details');
    // Migra fotos criadas em uma versão anterior sem metadados.
    final knownPhotoPaths = photoDetails.map((item) => item['path']?.toString() ?? '').toSet();
    for (final path in photos) {
      if (!knownPhotoPaths.contains(path)) {
        photoDetails.add({'path': path, 'event': '', 'space': '', 'category': 'Referência', 'favorite': false, 'createdAt': DateTime.now().toIso8601String()});
      }
    }
    await _prefs.setString('up_photo_details', jsonEncode(photoDetails));
    appointments = _readMapList('up_appointments');
    quotes = _readMapList('up_quotes');
    favoriteSpaces = _readStringList('up_favorite_spaces');
    selectedServices = _readStringList('up_selected_services');
    notifyListeners();
  }

  Map<String, dynamic>? _readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try { return Map<String, dynamic>.from(jsonDecode(raw) as Map); } catch (_) { return null; }
  }

  List<Map<String, dynamic>> _readMapList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try { return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(); } catch (_) { return []; }
  }

  List<String> _readStringList(String key) {
    final raw = _prefs.getStringList(key);
    return raw ?? [];
  }

  Future<void> setDarkMode(bool value) async {
    isDarkMode = value;
    await _prefs.setBool('up_dark_mode', value);
    notifyListeners();
  }

  /// Registra uma conta local ou valida uma conta criada neste dispositivo.
  /// Senhas locais são apenas para demonstração escolar, nunca para produção.
  Future<String?> authenticate({required String name, required String email, required String password, required String role, required bool register}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.length < 4) return 'Informe um e-mail e uma senha com pelo menos 4 caracteres.';
    final existingIndex = _accounts.indexWhere((a) => (a['email'] as String).toLowerCase() == normalizedEmail);
    if (register) {
      if (name.trim().length < 2) return 'Informe seu nome completo.';
      if (existingIndex >= 0) return 'Este e-mail já possui uma conta. Escolha Entrar.';
      _accounts.add({'name': name.trim(), 'email': normalizedEmail, 'password': password, 'role': role});
      await _prefs.setString('up_accounts', jsonEncode(_accounts));
      currentUser = {'name': name.trim(), 'email': normalizedEmail, 'role': role};
    } else {
      if (existingIndex < 0) return 'Conta não encontrada. Escolha Criar conta.';
      final account = _accounts[existingIndex];
      if (account['password'] != password) return 'Senha incorreta.';
      if (account['role'] != role) return 'Esta conta está registrada como ${account['role'] == 'organizador' ? 'organizador' : 'cliente'}. Selecione o perfil correto.';
      currentUser = {'name': account['name'], 'email': normalizedEmail, 'role': account['role']};
    }
    await _prefs.setString('up_current_user', jsonEncode(currentUser));
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    currentUser = null;
    await _prefs.remove('up_current_user');
    notifyListeners();
  }

  Map<String, dynamic> photoMetadataFor(String path) {
    for (final item in photoDetails) {
      if (item['path']?.toString() == path) return Map<String, dynamic>.from(item);
    }
    return {'path': path, 'event': '', 'space': '', 'category': 'Referência', 'favorite': false};
  }

  Future<void> addPhoto(
    String path, {
    String event = '',
    String space = '',
    String category = 'Referência',
  }) async {
    photos = [path, ...photos.where((item) => item != path)];
    photoDetails = [
      {
        'path': path,
        'event': event.trim(),
        'space': space.trim(),
        'category': category,
        'favorite': false,
        'createdAt': DateTime.now().toIso8601String(),
      },
      ...photoDetails.where((item) => item['path']?.toString() != path),
    ];
    await _prefs.setStringList('up_photos', photos);
    await _prefs.setString('up_photo_details', jsonEncode(photoDetails));
    notifyListeners();
  }

  Future<void> updatePhotoMetadata(
    String path, {
    required String event,
    required String space,
    required String category,
  }) async {
    var found = false;
    photoDetails = photoDetails.map((item) {
      if (item['path']?.toString() != path) return item;
      found = true;
      return {...item, 'event': event.trim(), 'space': space.trim(), 'category': category};
    }).toList();
    if (!found) {
      photoDetails.add({'path': path, 'event': event.trim(), 'space': space.trim(), 'category': category, 'favorite': false, 'createdAt': DateTime.now().toIso8601String()});
    }
    await _prefs.setString('up_photo_details', jsonEncode(photoDetails));
    notifyListeners();
  }

  Future<void> togglePhotoFavorite(String path) async {
    photoDetails = photoDetails.map((item) {
      if (item['path']?.toString() != path) return item;
      return {...item, 'favorite': !(item['favorite'] == true)};
    }).toList();
    await _prefs.setString('up_photo_details', jsonEncode(photoDetails));
    notifyListeners();
  }

  Future<void> removePhoto(String path) async {
    photos.remove(path);
    photoDetails.removeWhere((item) => item['path']?.toString() == path);
    await _prefs.setStringList('up_photos', photos);
    await _prefs.setString('up_photo_details', jsonEncode(photoDetails));
    notifyListeners();
  }

  Future<void> clearPhotos() async {
    photos = [];
    photoDetails = [];
    await _prefs.setStringList('up_photos', photos);
    await _prefs.setString('up_photo_details', jsonEncode(photoDetails));
    notifyListeners();
  }

  Future<bool> addAppointment(Map<String, dynamic> item) async {
    final conflict = appointments.any((e) => e['date'] == item['date'] && e['time'] == item['time']);
    if (conflict) return false;
    appointments = [item, ...appointments];
    appointments.sort((a, b) => '${a['date']}${a['time']}'.compareTo('${b['date']}${b['time']}'));
    await _prefs.setString('up_appointments', jsonEncode(appointments));
    notifyListeners();
    return true;
  }

  Future<void> removeAppointment(String id) async {
    appointments.removeWhere((e) => e['id'].toString() == id);
    await _prefs.setString('up_appointments', jsonEncode(appointments));
    notifyListeners();
  }

  Future<void> addQuote(Map<String, dynamic> item) async {
    quotes = [{'id': DateTime.now().microsecondsSinceEpoch.toString(), 'status': 'Recebido', 'createdAt': DateTime.now().toIso8601String(), ...item}, ...quotes];
    await _prefs.setString('up_quotes', jsonEncode(quotes));
    notifyListeners();
  }

  Future<void> updateQuoteStatus(String id, String status) async {
    quotes = quotes.map((e) => e['id'].toString() == id ? {...e, 'status': status} : e).toList();
    await _prefs.setString('up_quotes', jsonEncode(quotes));
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    if (favoriteSpaces.contains(id)) {
      favoriteSpaces.remove(id);
    } else {
      favoriteSpaces.add(id);
    }
    await _prefs.setStringList('up_favorite_spaces', favoriteSpaces);
    notifyListeners();
  }

  Future<void> setSelectedServices(List<String> values) async {
    selectedServices = values.toSet().toList();
    await _prefs.setStringList('up_selected_services', selectedServices);
    notifyListeners();
  }
}
