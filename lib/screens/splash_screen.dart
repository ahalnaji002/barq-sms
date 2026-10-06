import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:barq_sms/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String? _appVersion;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.70,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();

    Future.delayed(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      },
    );
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = packageInfo.version);
    } catch (_) {
      // The splash screen remains usable if package metadata is unavailable.
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBF2),
              Color(0xFFFFF1CE),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0.92,
                            end: 1.05,
                          ),
                          duration: const Duration(milliseconds: 850),
                          curve: Curves.easeInOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          onEnd: () {
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          child: Container(
                            width: 116,
                            height: 116,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300)
                                  .withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFB300,
                                  ).withValues(alpha: 0.28),
                                  blurRadius: 32,
                                  spreadRadius: 7,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              size: 76,
                              color: Color(0xFFFFB300),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 31,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF202020),
                              letterSpacing: 0.2,
                            ),
                            children: [
                              TextSpan(text: 'Barq '),
                              TextSpan(
                                text: 'SMS',
                                style: TextStyle(
                                  color: Color(0xFFFFB300),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 11),
                        const Text(
                          'إدارة وإرسال رسائل المستفيدين',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 38),
                        const SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFFFFB300),
                          ),
                        ),
                        const SizedBox(height: 19),
                        const Text(
                          'سريع • منظم • موثوق',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8A8A8A),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                left: 0,
                bottom: 22,
                child: Text(
                  _appVersion == null ? '' : 'Version $_appVersion',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFAAAAAA),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
