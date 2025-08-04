import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'authentication.dart';
import 'login_screen.dart';
import 'screens/home_screen.dart';
import 'models/bp_record.dart';
import 'models/signal_quality.dart';
import 'services/storage_service.dart';
// You might need to add these for the generated adapters

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // FIXED: Initialize Firebase using the platform-specific configuration files.
  // This is the correct and secure way for mobile apps.
  await Firebase.initializeApp();

  // --- The rest of your initialization is correct ---
  await Hive.initFlutter();
  Hive.registerAdapter(BPRecordAdapter());
  Hive.registerAdapter(SignalQualityAdapter());

  await StorageService().init();

  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Error initializing cameras: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contactless BP Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: _authService.userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasData) {
            return HomeScreen();
          } else {
            return LoginScreen(authService: _authService);
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}