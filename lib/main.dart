import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/transfer_provider.dart';
import 'providers/call_provider.dart';
import 'providers/network_provider.dart';
import 'services/database_service.dart';
import 'services/p2p_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize database
  await DatabaseService.instance.init();
  
  // Initialize P2P service
  final p2pService = P2PService();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<P2PService>.value(value: p2pService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => NetworkProvider(p2pService)),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => TransferProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: const LocalLinkApp(),
    ),
  );
}
