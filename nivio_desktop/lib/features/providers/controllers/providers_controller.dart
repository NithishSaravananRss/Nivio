import 'package:flutter/foundation.dart';

import '../models/provider_models.dart';
import '../repositories/providers_repository.dart';

enum ProvidersStatus { initial, loading, loaded, empty, error }

class ProvidersController extends ChangeNotifier {
  ProvidersController({required this.repository});

  final ProvidersRepository repository;

  bool _isDisposed = false;
  bool _initialized = false;
  ProvidersStatus _status = ProvidersStatus.initial;
  String? _errorMessage;
  String _query = '';
  ProviderMediaType _selectedMediaType = ProviderMediaType.tv;
  StreamingProviderItem? _selectedProvider;
  List<StreamingProviderItem> _providers = const [];
  List<ProviderContentSection> _sections = const [];

  ProvidersStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  ProviderMediaType get selectedMediaType => _selectedMediaType;
  StreamingProviderItem? get selectedProvider => _selectedProvider;
  List<ProviderContentSection> get sections => List.unmodifiable(_sections);
  bool get isLoading => _status == ProvidersStatus.loading;

  List<StreamingProviderItem> get filteredProviders {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return List.unmodifiable(_providers);
    return _providers
        .where((provider) => provider.name.toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _providers = repository.getProviders();
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  Future<void> selectProvider(StreamingProviderItem provider) async {
    _selectedProvider = provider;
    await _loadSelectedProvider();
  }

  void showAllProviders() {
    _selectedProvider = null;
    _sections = const [];
    _status = ProvidersStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> selectMediaType(ProviderMediaType mediaType) async {
    if (_selectedMediaType == mediaType) return;
    _selectedMediaType = mediaType;
    await _loadSelectedProvider();
  }

  Future<void> retry() => _loadSelectedProvider(force: true);

  Future<void> _loadSelectedProvider({bool force = false}) async {
    final provider = _selectedProvider;
    if (provider == null || _isDisposed) return;
    if (!force && _status == ProvidersStatus.loading) return;

    _status = ProvidersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final sections = await repository.getProviderContent(
        provider: provider,
        mediaType: _selectedMediaType,
      );
      if (_isDisposed) return;
      _sections = sections;
      _status = sections.isEmpty
          ? ProvidersStatus.empty
          : ProvidersStatus.loaded;
    } catch (_) {
      if (_isDisposed) return;
      _sections = const [];
      _status = ProvidersStatus.error;
      _errorMessage = 'We could not load ${provider.name.trim()} right now.';
    } finally {
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
