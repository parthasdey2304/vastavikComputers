import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Cannot go back from welcome screen
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: SafeArea(
          child: ResponsiveWrapper(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Spacer(),

                      // SVG Illustration
                      SvgPicture.asset(
                        'assets/images/welcome_illustration.svg',
                        height: 220,
                      ),
                      SizedBox(height: 32),

                      // Headline
                      Text(
                        'Welcome to Vastavik Computers! 🚀',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Computer Science is not just about writing code — it\'s about learning how to think, solve problems, and build the future.\n\nEvery great innovation starts with a single line of code. Are you ready to begin your journey?',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: context.appTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Spacer(),

                      // Arrow button → goes to profile setup
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Set up your profile to continue',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.appTextSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 12),
                            InkWell(
                              onTap: () => context.go('/setup'),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primary, Color(0xFF5C33F6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: context.appSurface,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
