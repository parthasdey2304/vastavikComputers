import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize Firebase and Supabase here in bootstrap phase
  
  runApp(const ProviderScope(child: VastavikApp()));
}
