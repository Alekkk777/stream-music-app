// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/providers/app_state.dart';
import 'package:music_stream_app/screens/search_screen.dart';
import 'package:music_stream_app/screens/library_screen.dart';
import 'package:music_stream_app/widgets/mini_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const LibraryScreen(),
    const SearchScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    // Carica la libreria musicale all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadLibrary();
    });
  }

  // In home_screen.dart, modifica la struttura del widget build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Sfondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
          ),
          
          // Gestione dello spazio per il MiniPlayer
          Column(
            children: [
              // Schermata corrente con spazio per MiniPlayer
              Expanded(
                child: SafeArea(
                  bottom: false, // Non considerare lo spazio in basso
                  child: _screens[_currentIndex],
                ),
              ),
              
              // Spazio riservato per MiniPlayer
              Consumer<AppState>(
                builder: (context, appState, _) {
                  // Mostra lo spazio per il mini player solo se c'è una canzone corrente
                  return SizedBox(height: appState.currentSong != null ? 74 : 0);
                },
              ),
            ],
          ),
          
          // Mini player in posizione fissa
          Positioned(
            left: 0,
            right: 0,
            bottom: kBottomNavigationBarHeight,
            child: Consumer<AppState>(
              builder: (context, appState, _) {
                // Mostra il mini player solo se c'è una canzone corrente
                if (appState.currentSong == null) {
                  return const SizedBox.shrink();
                }
                return const MiniPlayer();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Libreria',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Cerca',
          ),
        ],
      ),
    );
  }
}