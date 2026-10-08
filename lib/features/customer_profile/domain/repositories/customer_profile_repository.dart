import '../../../authentication/domain/entities/app_user.dart';
import '../entities/update_customer_profile_command.dart';

abstract interface class CustomerProfileRepository {
  Future<AppUser> update(UpdateCustomerProfileCommand command);
}
