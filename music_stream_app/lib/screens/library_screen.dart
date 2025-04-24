// lib/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/providers/app_state.dart';
import 'package:music_stream_app/widgets/song_list_item.dart';
import 'package:music_stream_app/widgets/playlist_item.dart';
import 'package:music_stream_app/screens/playlist_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _playlistNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _playlistNameController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova Playlist'),
        content: TextField(
          controller: _playlistNameController,
          decoration: const InputDecoration(
            hintText: 'Nome playlist',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_playlistNameController.text.isNotEmpty) {
                Provider.of<AppState>(context, listen: false)
                    .createPlaylist(_playlistNameController.text);
                _playlistNameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'La tua musica',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePlaylistDialog,
            tooltip: 'Crea playlist',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Brani'),
            Tab(text: 'Playlist'),
          ],
          indicatorColor: Theme.of(context).colorScheme.secondary,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab Brani
              appState.songs.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun brano nella libreria\nCerca e scarica musica per iniziare',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: appState.songs.length,
                      itemBuilder: (context, index) {
                        final song = appState.songs[index];
                        return SongListItem(
                          song: song,
                          onTap: () => appState.playSong(song),
                        );
                      },
                    ),

              // Tab Playlist
              appState.playlists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Nessuna playlist creata',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _showCreatePlaylistDialog,
                            child: const Text('Crea playlist'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: appState.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = appState.playlists[index];
                        return PlaylistItem(
                          playlist: playlist,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistScreen(playlist: playlist),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ],
          );
        },
      ),
    );
  }
}