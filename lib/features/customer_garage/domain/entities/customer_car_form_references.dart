import 'customer_car.dart';

/// Localized reference values required before a customer can create a car.
///
/// A selected company is a form-navigation helper only. The backend persists
/// the selected car-name ID, not the company ID.
class CustomerCarFormReferences {
  const CustomerCarFormReferences({
    required this.companies,
    required this.colors,
    required this.fuelTypes,
  });

  final List<CustomerCarReference> companies;
  final List<CustomerCarReference> colors;
  final List<CustomerCarReference> fuelTypes;
}
