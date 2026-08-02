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
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/home/presentation/screens/search_results_screen.dart';
import '../features/practice/presentation/screens/quiz_setup_screen.dart';
import '../features/practice/presentation/screens/quiz_taking_screen.dart';
import '../features/practice/presentation/screens/code_editor_screen.dart';
import '../features/learning_path/presentation/screens/lesson_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userProfileState = ref.watch(userProfileStreamProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup' || state.matchedLocation == '/forgot-password';
      final isDeletedRoute = state.matchedLocation == '/account-deleted';

      if (authState.isLoading) return null;

      // Only redirect if the profile has fully loaded AND is explicitly marked deleted
      if (isLoggedIn && userProfileState.hasValue && !userProfileState.isLoading) {
        final profileData = userProfileState.value;
        if (profileData != null && profileData['_deleted'] == true && !isDeletedRoute) {
          return '/account-deleted';
        }
      }

      if (!isLoggedIn && !isAuthRoute && !isDeletedRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      // Force users with no Firestore profile to complete setup (can't skip)
      if (isLoggedIn && userProfileState.hasValue && !userProfileState.isLoading) {
        final profileData = userProfileState.value;
        final isSetupRoute = state.matchedLocation == '/setup' || state.matchedLocation == '/welcome';
        if (profileData == null && !isSetupRoute && !isDeletedRoute) {
          return '/setup';
        }
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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchResultsScreen(query: query);
        },
      ),
      GoRoute(
        path: '/lesson',
        builder: (context, state) => const VideoLessonScreen(),
      ),
      GoRoute(
        path: '/quiz-setup',
        builder: (context, state) {
          final topic = state.uri.queryParameters['topic'] ?? 'General';
          return QuizSetupScreen(topic: topic);
        },
      ),
      GoRoute(
        path: '/take-quiz',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final topic = extra?['topic'] as String? ?? 'Quiz';
          final quizData = extra?['quizData'] as List<Map<String, dynamic>>? ?? [];
          return QuizTakingScreen(topic: topic, quizData: quizData);
        },
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) {
          final challenge = state.extra as Map<String, dynamic>? ?? {};
          return CodeEditorScreen(challenge: challenge);
        },
      ),
      GoRoute(
        path: '/lesson-detail',
        builder: (context, state) {
          final lessonData = state.extra as Map<String, dynamic>? ?? {};
          return LessonDetailScreen(lessonData: lessonData);
        },
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
