import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AccountDeletedScreen extends ConsumerStatefulWidget {
  const AccountDeletedScreen({super.key});

  @override
  ConsumerState<AccountDeletedScreen> createState() => _AccountDeletedScreenState();
}

class _AccountDeletedScreenState extends ConsumerState<AccountDeletedScreen> {
  bool _isLoading = false;

  final String _deletedIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <path fill="none" d="M0 0h24v24H0z"/>
  <path fill="#EF4444" d="M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm-1.414-11.414L7.05 7.05 5.636 8.464l3.536 3.536-3.536 3.536 1.414 1.414 3.536-3.536 3.536 3.536 1.414-1.414-3.536-3.536 3.536-3.536-1.414-1.414-3.536 3.536z"/>
</svg>
''';

  Future<void> _handleGoToSignUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // 1. Permanently delete their Auth Credentials to finalize the lockout
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      // Ignore if the token is too old
    } finally {
      // 2. Sign out using the controller (clears Firebase and Google sessions)
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        context.go('/signup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spacer(),
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SvgPicture.string(
                      _deletedIconSvg,
                      height: 100,
                      width: 100,
                    ),
                    SizedBox(height: 32),
                    Text(
                      'Account Removed',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Your data has been removed by the admin. You no longer have access to this application.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: context.appTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoToSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Head over to Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
