import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    final isNewUser = await ref.read(authControllerProvider.notifier).signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    
    if (mounted) {
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        String errorMessage = authState.error.toString();
        if (errorMessage.contains('] ')) {
          errorMessage = errorMessage.split('] ').last;
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        if (isNewUser) {
          context.go('/welcome');
        } else {
          context.go('/home');
        }
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    final isNewUser = await ref.read(authControllerProvider.notifier).signInWithGoogle();
    
    if (mounted) {
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        String errorMessage = authState.error.toString();
        if (errorMessage.contains('] ')) {
          errorMessage = errorMessage.split('] ').last;
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        if (isNewUser) {
          context.go('/welcome');
        } else {
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveWrapper(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or Icon
                Icon(
                  Icons.laptop_chromebook_rounded,
                  size: 80,
                  color: AppTheme.primary,
                ),
                SizedBox(height: 24),
                
                // Welcome Text
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Sign in to continue your learning journey',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.appTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      context.go('/forgot-password');
                    },
                    child: Text('Forgot Password?'),
                  ),
                ),
                SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: ref.watch(authControllerProvider).isLoading ? null : _login,
                  child: ref.watch(authControllerProvider).isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Log In',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.grey.shade500)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                SizedBox(height: 24),
                
                // Google Sign In Button
                OutlinedButton.icon(
                  onPressed: ref.watch(authControllerProvider).isLoading ? null : _loginWithGoogle,
                  icon: SvgPicture.asset('assets/images/google_logo.svg', height: 24, width: 24),
                  label: Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: context.appTextSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
