import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

class LocalLinkApp extends StatelessWidget {
  const LocalLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.dark950,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary500),
                    SizedBox(height: 16),
                    Text(
                      'Starting LocalLink...',
                      style: TextStyle(color: AppColors.dark400),
                    ),
                  ],
                ),
              ),
            );
          }
          
          if (auth.isAuthenticated) {
            return const HomeScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
