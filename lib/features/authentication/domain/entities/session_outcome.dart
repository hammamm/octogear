import '../../../../core/api/api_failure.dart';
import 'app_user.dart';

sealed class SessionOutcome {
  const SessionOutcome();
}

class SignedOutSession extends SessionOutcome {
  const SignedOutSession();
}

class AuthenticatedSession extends SessionOutcome {
  const AuthenticatedSession(this.user);

  final AppUser user;
}

class UnavailableSession extends SessionOutcome {
  const UnavailableSession(this.failure);

  final ApiFailure failure;
}
