import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/schueler_home_screen.dart';
import '../../features/home/presentation/trainer_home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../auth/auth_providers.dart';
import '../auth/nutzer_model.dart';
import '../config/dev_config.dart';
import 'app_routes.dart';
import 'go_router_refresh_stream.dart';

/// go_router-Instanz mit rollenbasierter Redirect-Logik:
///  - nicht eingeloggt            -> /login
///  - eingeloggt, keine nutzer-Zeile -> /onboarding
///  - eingeloggt als Trainer      -> /trainer
///  - eingeloggt als Schüler      -> /schueler
///
/// Ist [kDevBypassAuth] aktiv, werden alle Redirects übersprungen und die
/// App startet direkt auf dem Trainer-Startscreen (UI-Vorschau ohne Login
/// und ohne Backend).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: kDevBypassAuth ? AppRoutes.trainerHome : AppRoutes.login,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) async {
      if (kDevBypassAuth) return null;

      final loggedIn = authRepository.currentSession != null;
      final location = state.matchedLocation;

      final onAuthPages =
          location == AppRoutes.login || location == AppRoutes.signup;

      if (!loggedIn) {
        return onAuthPages ? null : AppRoutes.login;
      }

      // Eingeloggt: Rolle aus `nutzer` laden (gecacht über Riverpod,
      // invalidiert automatisch bei Auth-Änderungen).
      final nutzer = await ref.read(currentNutzerProvider.future);

      if (nutzer == null) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      final zielRoute = nutzer.rolle == NutzerRolle.trainer
          ? AppRoutes.trainerHome
          : AppRoutes.schuelerHome;

      if (onAuthPages || location == AppRoutes.onboarding) {
        return zielRoute;
      }

      final istTrainerBereich = location.startsWith(AppRoutes.trainerHome);
      final istSchuelerBereich = location.startsWith(AppRoutes.schuelerHome);

      if (istTrainerBereich && nutzer.rolle != NutzerRolle.trainer) {
        return AppRoutes.schuelerHome;
      }
      if (istSchuelerBereich && nutzer.rolle != NutzerRolle.schueler) {
        return AppRoutes.trainerHome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.trainerHome,
        builder: (context, state) => const TrainerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.schuelerHome,
        builder: (context, state) => const SchuelerHomeScreen(),
      ),
    ],
  );
});
