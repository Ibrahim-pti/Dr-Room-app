import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'core/providers/order_provider.dart';
import 'core/providers/checkout_provider.dart';
import 'core/providers/favorite_provider.dart';
import 'core/utils/ckb_localizations.dart';
import 'core/utils/api_client.dart';
import 'core/providers/health_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/admin_order_provider.dart';
import 'core/providers/payment_provider.dart';
import 'core/providers/appointment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider, Provider, Consumer;
import 'features/auth/splash_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/home/main_shell.dart';
import 'features/admin/admin_dashboard_shell.dart';
import 'features/setup/language_selection_screen.dart';
import 'features/setup/health_profile_screen.dart';
import 'features/setup/medical_history_screen.dart';

/// Lets code without a BuildContext (notably [ApiClient]) drive navigation.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // A rejected token used to fail silently on every subsequent call. Now it
  // tears the session down and returns the user to login.
  ApiClient.onUnauthorized = () {
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppFlow(startAtLogin: true)),
      (route) => false,
    );
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('ckb')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('ckb'),
        child: const DrRoomApp(),
      ),
    ),
  );
}

class DrRoomApp extends StatelessWidget {
  const DrRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AdminOrderProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeProvider().themeModeNotifier,
        builder: (context, themeMode, child) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'DrRoom',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            localizationsDelegates: [
              ...context.localizationDelegates,
              const CkbMaterialLocalizations(),
              const CkbWidgetLocalizations(),
              const CkbCupertinoLocalizations(),
            ],
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: const AppFlow(),
          );
        },
      ),
    );
  }
}

/// Manages the app flow: Splash → Onboarding → Login ↔ Register → Home
class AppFlow extends StatefulWidget {
  final bool startAtLogin;
  const AppFlow({super.key, this.startAtLogin = false});

  @override
  State<AppFlow> createState() => AppFlowState();
}

class AppFlowState extends State<AppFlow> {
  _FlowState _state = _FlowState.splash;
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    if (widget.startAtLogin) {
      _state = _FlowState.login;
    }
  }

  void _goTo(_FlowState state) {
    setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_state) {
      case _FlowState.splash:
        return SplashScreen(
          key: const ValueKey('splash'),
          onFinished: (bool isLoggedIn, String role, bool isFirstTime) {
            if (isFirstTime) {
              _goTo(_FlowState.onboarding);
            } else if (isLoggedIn) {
              if (role == 'admin') {
                _goTo(_FlowState.admin);
              } else {
                _goTo(_FlowState.home);
              }
            } else {
              _goTo(_FlowState.login);
            }
          },
        );

      case _FlowState.setup:
        return LanguageSelectionScreen(
          key: const ValueKey('setup_language'),
          onFinished: () => _goTo(_FlowState.health_profile),
        );

      case _FlowState.health_profile:
        return HealthProfileScreen(
          key: const ValueKey('health_profile'),
          onFinished: () => _goTo(_FlowState.medical_history),
        );

      case _FlowState.medical_history:
        return MedicalHistoryScreen(
          key: const ValueKey('medical_history'),
          onFinished: () => _goTo(_FlowState.login),
        );

      case _FlowState.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onFinished: () => _goTo(_FlowState.setup),
        );

      case _FlowState.login:
        return LoginScreen(
          key: const ValueKey('login'),
          onOtpSent: (String phone) {
            _phoneNumber = phone;
            _goTo(_FlowState.otp);
          },
          onSignUp: () => _goTo(_FlowState.register),
        );

      case _FlowState.register:
        return RegisterScreen(
          key: const ValueKey('register'),
          onOtpSent: (String phone) {
            _phoneNumber = phone;
            _goTo(_FlowState.otp);
          },
          onLogin: () => _goTo(_FlowState.login),
        );

      case _FlowState.otp:
        return OtpScreen(
          key: const ValueKey('otp'),
          phoneNumber: _phoneNumber,
          onVerified: (String role) {
            if (role == 'admin') {
              _goTo(_FlowState.admin);
            } else {
              _goTo(_FlowState.home);
            }
          },
          onBack: () => _goTo(_FlowState.login),
        );

      case _FlowState.home:
        return const MainShell(key: ValueKey('home'));

      case _FlowState.admin:
        return const AdminDashboardShell(key: ValueKey('admin'));
    }
  }
}

enum _FlowState {
  splash,
  setup,
  health_profile,
  medical_history,
  onboarding,
  login,
  register,
  otp,
  home,
  admin,
}
