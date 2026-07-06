import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegister = false;
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_isRegister && _displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isRegister) {
      success = await auth.register(
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await auth.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'An error occurred'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark950,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(LucideIcons.wifi, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'LocalLink',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Peer-to-peer • No server required',
                    style: TextStyle(color: AppColors.dark400, fontSize: 14),
                  ),
                  const SizedBox(height: 48),

                  // Title
                  Text(
                    _isRegister ? 'Create Profile' : 'Welcome Back',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegister
                        ? 'Set up your local network identity'
                        : 'Sign in to your local profile',
                    style: const TextStyle(color: AppColors.dark400),
                  ),
                  const SizedBox(height: 32),

                  // Form
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: AppColors.dark400),
                      prefixIcon: Icon(LucideIcons.user, color: AppColors.dark500),
                    ),
                  ),
                  if (_isRegister) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _displayNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: TextStyle(color: AppColors.dark400),
                        prefixIcon: Icon(LucideIcons.atSign, color: AppColors.dark500),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: AppColors.dark400),
                      prefixIcon: const Icon(LucideIcons.lock, color: AppColors.dark500),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: AppColors.dark500,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_isRegister ? 'Create Profile' : 'Sign In'),
                                const SizedBox(width: 8),
                                const Icon(LucideIcons.arrowRight, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegister ? 'Already have a profile?' : 'First time here?',
                        style: const TextStyle(color: AppColors.dark400),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isRegister = !_isRegister),
                        child: Text(_isRegister ? 'Sign in' : 'Create one'),
                      ),
                    ],
                  ),

                  // Info
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dark900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.dark800),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.shield, color: AppColors.success, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'All data is stored locally on your device',
                                style: TextStyle(color: AppColors.dark300, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(LucideIcons.wifi, color: AppColors.primary400, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Communicates directly with other devices on your network',
                                style: TextStyle(color: AppColors.dark300, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
