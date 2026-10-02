import 'api_client.dart';
import 'api_failure.dart';

/// Adapts paginated reference endpoints to the existing list-based selectors.
/// Fixed lists (colors and fuel types) keep their non-paginated contract.
Future<List<T>> loadReferenceList<T>(
  ApiClient api,
  String path, {
  required List<T> Function(Object?) decode,
  bool paginated = true,
}) async {
  final items = <T>[];
  var page = 1;
  while (true) {
    final response = await api.get<List<T>>(
      path,
      queryParameters: paginated ? {'page': page, 'per_page': 50} : null,
      decode: decode,
    );
    final values = response.data;
    final meta = response.pagination;
    if (values == null ||
        (paginated && (meta == null || meta.currentPage != page))) {
      throw const ApiFailure.unexpected();
    }
    items.addAll(values);
    if (!paginated || meta!.currentPage == meta.lastPage) {
      return List.unmodifiable(items);
    }
    if (values.isEmpty) throw const ApiFailure.unexpected();
    page++;
  }
}
