import 'package:flutter_test/flutter_test.dart';
import 'package:libri_flow/core/network/api_client.dart';
import 'package:libri_flow/features/home/data/repositories/remote_catalog_repository.dart';

void main() {
  test('fetch featured books from backend', () async {
    final client = ApiClient(baseUrl: 'http://127.0.0.1:8000');
    final repo = RemoteCatalogRepository(client);

    final featuredResult = await repo.getFeatured();
    if (featuredResult.isFailure) {
      print('Featured Error: ${featuredResult.failure?.message}');
    }
    expect(featuredResult.isSuccess, true, reason: 'Featured books failed');
    print('Featured books count: ${featuredResult.data?.length}');

    final categoriesResult = await repo.getCategories();
    if (categoriesResult.isFailure) {
      print('Categories Error: ${categoriesResult.failure?.message}');
    }
    expect(categoriesResult.isSuccess, true, reason: 'Categories failed');
    print('Categories count: ${categoriesResult.data?.length}');

    final catalogResult = await repo.getCatalog();
    if (catalogResult.isFailure) {
      print('Catalog Error: ${catalogResult.failure?.message}');
    }
    expect(catalogResult.isSuccess, true, reason: 'Catalog failed');
    print('Catalog books count: ${catalogResult.data?.length}');
  });
}
