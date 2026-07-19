import '../models/provider_models.dart';

abstract interface class ProvidersRepository {
  List<StreamingProviderItem> getProviders();

  Future<List<ProviderContentSection>> getProviderContent({
    required StreamingProviderItem provider,
    required ProviderMediaType mediaType,
  });
}
