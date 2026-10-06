import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/beneficiary_batch_provider.dart';
import 'providers/beneficiary_provider.dart';
import 'providers/app_security_provider.dart';
import 'screens/app_lock_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BarqSmsApp());
}

class BarqSmsApp extends StatelessWidget {
  const BarqSmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppSecurityProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => BeneficiaryProvider()..loadBeneficiaries(),
        ),
        ChangeNotifierProvider(
          create: (_) => BeneficiaryBatchProvider()..loadBatches(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (
          context,
          themeProvider,
          child,
        ) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Barq SMS',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) => AppLockGate(
              child: child ?? const SizedBox.shrink(),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
