import 'package:daily_meal_flutter_app/app/router/session_route_state.dart';
import 'package:daily_meal_flutter_app/features/auth/domain/app_user.dart';

enum AuthStatus { loading, signedOut, needsOnboarding, user, admin }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.adminEmail,
    this.isBusy = false,
    this.errorMessage,
  });

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.signedOut({String? errorMessage})
    : this(status: AuthStatus.signedOut, errorMessage: errorMessage);

  final AuthStatus status;
  final AppUser? user;
  final String? adminEmail;
  final bool isBusy;
  final String? errorMessage;

  SessionRouteState get routeState => switch (status) {
    AuthStatus.loading => SessionRouteState.loading,
    AuthStatus.signedOut => SessionRouteState.signedOut,
    AuthStatus.needsOnboarding => SessionRouteState.needsOnboarding,
    AuthStatus.user => SessionRouteState.user,
    AuthStatus.admin => SessionRouteState.admin,
  };
}
