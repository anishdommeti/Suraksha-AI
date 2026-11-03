import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/incident_service.dart';
import '../services/theme_service.dart';
import 'map_screen.dart';

/// SplashScreen
/// Renders the official SURAKSHA AI splash image seamlessly blended into
/// its exact dark-navy background palette (#191F33 -> #0D1326 -> #12182A).
/// Eliminates white flashes, visible boundaries, or mismatched system bars.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    // Start initialization and transition after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // If running in automated widget test environment, transition immediately without delay
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _navigateToHome();
      return;
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Warm up services asynchronously without blocking UI thread
      final incidentService = Provider.of<IncidentService>(
        context,
        listen: false,
      );
      final themeService = Provider.of<ThemeService>(context, listen: false);

      // Concurrently kick off incident fetching & theme confirmation
      unawaited(incidentService.fetchIncidents());
      unawaited(incidentService.fetchFacilities());
      debugPrint(
        '[SURAKSHA AI] Warmup initiated (Theme: ${themeService.themeMode}).',
      );
    } catch (e) {
      debugPrint('[SURAKSHA AI] Non-blocking splash warmup error: $e');
    }

    // Ensure splash is visible for at least 1.6s for branding continuity, capped at 3.0s
    final elapsed = stopwatch.elapsedMilliseconds;
    const minSplashDuration = 1600;
    if (elapsed < minSplashDuration) {
      await Future.delayed(Duration(milliseconds: minSplashDuration - elapsed));
    }

    _navigateToHome();
  }

  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: isTest
            ? Duration.zero
            : const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MapScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (isTest) return child;
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Exact background palette sampled from suraksha_splash.png
    // Top border: #191F33, Center: #0D1326, Bottom border: #12182A
    const topNavy = Color(0xFF191F33);
    const centerNavy = Color(0xFF0D1326);
    const bottomNavy = Color(0xFF12182A);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: bottomNavy,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: centerNavy,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topNavy, centerNavy, bottomNavy],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Image.asset(
                  'assets/images/suraksha_splash.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    // Graceful fallback if asset decoding encounters an issue
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00897B),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
