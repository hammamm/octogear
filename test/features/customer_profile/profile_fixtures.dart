import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_profile/domain/entities/update_customer_profile_command.dart';
import 'package:octogear/features/customer_profile/domain/repositories/customer_profile_repository.dart';

const profileUser = AppUser(
  id: 1,
  fullName: 'Original Name',
  mobile: '+966500000001',
  role: AppUserRole.customer,
  city: AppCity(id: 1, name: 'Riyadh'),
);

AppUser savedProfile(UpdateCustomerProfileCommand command) => AppUser(
  id: profileUser.id,
  fullName: command.fullName,
  mobile: profileUser.mobile,
  role: profileUser.role,
  city: AppCity(
    id: command.cityId,
    name: command.cityId == 1 ? 'Riyadh' : 'Jeddah',
  ),
);

class FakeProfileRepository implements CustomerProfileRepository {
  final commands = <UpdateCustomerProfileCommand>[];
  Future<AppUser> Function(UpdateCustomerProfileCommand)? onUpdate;
  @override
  Future<AppUser> update(UpdateCustomerProfileCommand command) async {
    commands.add(command);
    return onUpdate == null ? savedProfile(command) : await onUpdate!(command);
  }
}

class ProfileSession extends SessionController {
  @override
  Future<SessionOutcome> build() async =>
      const AuthenticatedSession(profileUser);
  void replace(SessionOutcome value) => state = AsyncData(value);
}
