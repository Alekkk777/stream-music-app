// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/providers/app_state.dart';
import 'package:music_stream_app/screens/home_screen.dart';
import 'package:music_stream_app/theme.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializza just_audio_background
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.musicstreamapp.audio',
    androidNotificationChannelName: 'Music Stream',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
  
  // Imposta lo stile della status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  // Imposta l'orientamento preferito
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'Music Stream',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.dark, // Imposta il tema scuro come predefinito
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}