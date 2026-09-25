enum AppUserRole {
  customer(apiValue: 'customer'),
  provider(apiValue: 'service provider');

  const AppUserRole({required this.apiValue});

  final String apiValue;

  static AppUserRole? fromApiValue(String value) {
    for (final role in AppUserRole.values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }
}

class AppCity {
  const AppCity({required this.id, required this.name});

  final int id;
  final String name;
}

/// The shared profile returned by `GET /profile`.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.role,
    this.city,
  });

  final int id;
  final String fullName;
  final String mobile;
  final AppUserRole role;
  final AppCity? city;
}
