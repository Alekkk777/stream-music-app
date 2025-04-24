// lib/screens/player_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/providers/app_state.dart';
import 'package:music_stream_app/theme.dart';
import 'package:music_stream_app/models/playlist.dart';
import 'package:music_stream_app/screens/queue_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final song = appState.currentSong;
        if (song == null) {
          // Se non c'è nessuna canzone attualmente in riproduzione, torna indietro
          Navigator.pop(context);
          return const SizedBox.shrink();
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(77),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Nuovo pulsante per la coda
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(77),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.queue_music),
                ),
                onPressed: () => _openQueueScreen(context),
                tooltip: 'Coda di riproduzione',
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(77),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert),
                ),
                onPressed: () => _showOptionsBottomSheet(context, appState, song),
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withAlpha(179),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 1),
                    
                    // Copertina del brano
                    Hero(
                      tag: 'song_cover_${song.id}',
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(77),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          image: song.thumbnailUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(song.thumbnailUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: song.thumbnailUrl == null
                            ? const Icon(Icons.music_note, size: 80, color: Colors.white70)
                            : null,
                      ),
                    ),
                    
                    const Spacer(flex: 1),
                    
                    // Informazioni sul brano
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      song.channelTitle ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Slider di avanzamento
                    Slider(
                      value: appState.position.inSeconds.toDouble(),
                      min: 0,
                      max: appState.duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        appState.seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                    
                    // Durata e tempo rimanente
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(appState.position)),
                          Text(_formatDuration(appState.duration)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Controlli di riproduzione
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: appState.hasPrevious
                              ? () => appState.playPreviousSong()
                              : null,
                          iconSize: 40,
                          color: appState.hasPrevious ? Colors.white : Colors.white30,
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withAlpha(128),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              appState.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: () => appState.togglePlay(),
                            iconSize: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: appState.hasNext
                              ? () => appState.playNextSong()
                              : null,
                          iconSize: 40,
                          color: appState.hasNext ? Colors.white : Colors.white30,
                        ),
                      ],
                    ),
                    
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  void _showOptionsBottomSheet(BuildContext context, AppState appState, song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicatore di drag
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          
          const SizedBox(height: 8),
          
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Aggiungi a playlist'),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistDialog(context, appState, song);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Dettagli brano'),
            onTap: () {
              Navigator.pop(context);
              _showSongDetails(context, song);
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, AppState appState, song) {
    final playlists = appState.playlists;
    
    if (playlists.isEmpty) {
      // Se non ci sono playlist, mostra un messaggio e offre di crearne una
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nessuna playlist'),
          content: const Text('Non hai ancora creato nessuna playlist. Vuoi crearne una nuova?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, appState, song);
              },
              child: const Text('Crea'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Altrimenti mostra la lista delle playlist
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        children: [
          // Intestazione
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                const Text(
                  'Scegli una playlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Nuova playlist'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreatePlaylistDialog(context, appState, song);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.white.withAlpha(26)),
          
          // Lista delle playlist
          Expanded(
            child: ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.songs.length} brani'),
                  leading: const Icon(Icons.queue_music),
                  onTap: () async {
                    Navigator.pop(context);
                    await _addSongToPlaylist(context, appState, playlist, song);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openQueueScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QueueScreen(),
      ),
    );
  }
  
  void _showCreatePlaylistDialog(BuildContext context, AppState appState, song) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova Playlist'),
        content: TextField(
          controller: controller,
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
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (controller.text.isNotEmpty) {
                try {
                  // Crea la nuova playlist
                  await appState.createPlaylist(controller.text);
                  
                  // Ottieni l'ultima playlist creata (quella appena creata)
                  if (appState.playlists.isNotEmpty) {
                    final newPlaylist = appState.playlists.last;
                    
                    // Chiudi il dialogo prima di eseguire operazioni asincrone
                    navigator.pop();
                    
                    // Aggiungi il brano alla nuova playlist
                    if (context.mounted) {
                      await _addSongToPlaylist(context, appState, newPlaylist, song);
                    }
                  }
                } catch (e) {
                  // Mostra un errore se qualcosa va storto
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Errore: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    navigator.pop();
                  }
                }
              }
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addSongToPlaylist(BuildContext context, AppState appState, Playlist playlist, song) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      await appState.addSongToPlaylist(playlist, song);
      
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${song.title} aggiunto a ${playlist.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSongDetails(BuildContext context, song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dettagli brano'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Titolo: ${song.title}'),
            const SizedBox(height: 8),
            Text('Canale: ${song.channelTitle ?? "Non disponibile"}'),
            const SizedBox(height: 8),
            Text('ID Video: ${song.videoId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}