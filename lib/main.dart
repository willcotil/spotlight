import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spotlight/app/app.dart';
import 'package:spotlight/providers/auth_provider.dart';
import 'package:spotlight/providers/chat_provider.dart';
import 'package:spotlight/providers/favorites_provider.dart';
import 'package:spotlight/providers/movies_provider.dart';
import 'package:spotlight/providers/reviews_provider.dart';
import 'package:spotlight/providers/search_provider.dart';
import 'package:spotlight/providers/theme_provider.dart';
import 'package:spotlight/services/app_config.dart';
import 'package:spotlight/services/review_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  ); 
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (ctx) => FavoritesProvider(ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (_) => MoviesProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ReviewsProvider>(
          create: (ctx) =>
              ReviewsProvider(ReviewService(), ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev!..updateAuth(auth),
        ),
      ],
      child: const SpotlightApp(),
    ),
  );
}
