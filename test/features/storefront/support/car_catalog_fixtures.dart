import 'package:octogear/features/storefront/domain/entities/marketplace_store.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_car_catalog.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_store_car.dart';
import 'package:octogear/features/storefront/domain/repositories/storefront_car_catalog_repository.dart';

const catalogKey = (storeId: 14, carId: 7);
const catalogCar = StorefrontCarDetails(
  car: StorefrontStoreCar(
    id: 7,
    manufacturingYear: 2020,
    carName: StorefrontReference(id: 1, name: 'Camry'),
    color: StorefrontReference(id: 2, name: 'White'),
    fuelType: StorefrontReference(id: 3, name: 'Petrol'),
    componentsCount: 2,
    pictures: [],
  ),
  store: StorefrontReference(id: 14, name: 'Al Faris'),
  company: StorefrontReference(id: 2, name: 'Toyota'),
  sections: [
    StorefrontCarSection(
      id: 1,
      name: 'Engine',
      condition: StorefrontSectionCondition.okay,
    ),
  ],
);

StorefrontCarComponent catalogPart(
  int id, {
  int stock = 2,
  int? warranty = 3,
}) => StorefrontCarComponent(
  id: id,
  component: StorefrontReference(
    id: id,
    name: id == 1 ? 'Alternator' : 'Starter Motor',
  ),
  section: const StorefrontReference(id: 1, name: 'Engine'),
  priceMinor: 52025,
  currency: 'SAR',
  priceScale: 100,
  stockQuantity: stock,
  partNumber: 'ALT-20',
  description: 'Tested original part from this car.',
  warrantyMonths: warranty,
);

StorefrontComponentsPage catalogPage(
  int page, {
  bool last = false,
  List<StorefrontCarComponent>? parts,
}) => StorefrontComponentsPage(
  components: parts ?? [catalogPart(page)],
  currentPage: page,
  lastPage: last ? page : 2,
  total: 2,
);

Map<String, Object?> catalogCarJson() => {
  'id': 7,
  'manufacturing_year': 2020,
  'car_name': {'id': 1, 'name': 'Camry'},
  'color': {'id': 2, 'name': 'White'},
  'fuel_type': {'id': 3, 'name': 'Petrol'},
  'components_count': 2,
  'pictures': [],
  'store': {'id': 14, 'name': 'Al Faris'},
  'company': {'id': 2, 'name': 'Toyota'},
  'sections': [
    {'section_id': 1, 'name': 'Engine', 'condition': 'damaged'},
  ],
};

Map<String, Object?> catalogPartJson() => {
  'id': 1,
  'component': {'id': 1, 'name': 'Alternator'},
  'section': {'id': 1, 'name': 'Engine'},
  'price': 52025,
  'currency': 'SAR',
  'price_scale': 100,
  'stock_quantity': 0,
  'part_number': 'ALT-20',
  'description': null,
  'warranty_months': null,
};

class FakeCarCatalogRepository implements StorefrontCarCatalogRepository {
  Future<StorefrontCarDetails> Function(StorefrontCarKey)? details;
  Future<StorefrontComponentsPage> Function(StorefrontCarKey, int)? components;
  final List<({StorefrontCarKey key, int page})> calls = [];
  @override
  Future<StorefrontCarDetails> getCarDetails(StorefrontCarKey key) async =>
      details == null ? catalogCar : await details!(key);
  @override
  Future<StorefrontComponentsPage> getComponents(
    StorefrontCarKey key, {
    required int page,
  }) async {
    calls.add((key: key, page: page));
    return components == null
        ? catalogPage(page)
        : await components!(key, page);
  }
}
