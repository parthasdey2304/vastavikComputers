import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/video_lesson/presentation/screens/video_lesson_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard.dart';
import '../features/onboarding/presentation/screens/user_setup_screen.dart';
import '../features/onboarding/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/account_deleted_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userProfileState = ref.watch(userProfileStreamProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      final isDeletedRoute = state.matchedLocation == '/account-deleted';

      if (authState.isLoading) return null;

      // Check if user document is deleted
      if (isLoggedIn && userProfileState.hasValue) {
        final profileData = userProfileState.value;
        if (profileData != null && profileData['_deleted'] == true && !isDeletedRoute) {
          final user = FirebaseAuth.instance.currentUser;
          final isNewUser = user != null && 
              user.metadata.creationTime != null && 
              user.metadata.lastSignInTime != null &&
              user.metadata.lastSignInTime!.difference(user.metadata.creationTime!).inSeconds < 5;
              
          if (!isNewUser) {
            return '/account-deleted';
          }
        }
      }

      if (!isLoggedIn && !isAuthRoute && !isDeletedRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/lesson',
        builder: (context, state) => const VideoLessonScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const UserSetupScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/account-deleted',
        builder: (context, state) => const AccountDeletedScreen(),
      ),
    ],
  );
});
