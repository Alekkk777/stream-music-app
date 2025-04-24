// lib/screens/song_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/models/song.dart';
import 'package:music_stream_app/providers/app_state.dart';
import 'package:music_stream_app/theme.dart';

class SongDetailScreen extends StatelessWidget {
  final Song song;

  const SongDetailScreen({
  super.key,
  required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(102),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return Container(
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Copertina e info principali
                      Center(
                        child: Column(
                          children: [
                            // Copertina
                            Hero(
                              tag: 'song_cover_${song.id}',
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
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
                            const SizedBox(height: 16),
                            
                            // Titolo
                            Text(
                              song.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            
                            // Artista/Canale
                            if (song.channelTitle != null)
                              Text(
                                song.channelTitle!,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            const SizedBox(height: 24),
                            
                            // Pulsanti di azione principali
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Pulsante play
                                ElevatedButton.icon(
                                  onPressed: () => appState.playSong(song),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Riproduci'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Pulsante aggiungi a playlist
                                OutlinedButton.icon(
                                  onPressed: () => _showAddToPlaylistModal(context, appState),
                                  icon: const Icon(Icons.playlist_add),
                                  label: const Text('Aggiungi a playlist'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Sezione di dettaglio
                      _buildDetailSection(context, appState),
                      
                      const SizedBox(height: 24),
                      
                      // Sezione opzioni di riproduzione
                      _buildPlaybackSection(context, appState),
                      
                      const SizedBox(height: 24),
                      
                      // Sezione di storage
                      _buildStorageSection(context, appState),
                      
                      const SizedBox(height: 32),
                      
                      // Pulsante elimina (in rosso, in fondo)
                      if (song.id != null)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDeleteConfirmation(context, appState),
                            icon: const Icon(Icons.delete),
                            label: const Text('Elimina'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, AppState appState) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dettagli',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Dettagli del brano
            _buildDetailRow('ID Video:', song.videoId),
            if (song.id != null) _buildDetailRow('ID Database:', '${song.id}'),
            _buildDetailRow('Disponibilità:', _getAvailabilityText()),
            
            // Mostra dettagli aggiuntivi dai metadati
            if (song.metadata != null && song.metadata!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              ...song.metadata!.entries.map((entry) {
                if (entry.value != null) {
                  String key = entry.key.toString().replaceFirstMapped(
                    RegExp(r'^(\w)'), 
                    (match) => match.group(1)!.toUpperCase()
                  );
                  
                  return _buildDetailRow('$key:', entry.value.toString());
                }
                return const SizedBox.shrink();
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackSection(BuildContext context, AppState appState) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riproduzione',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Opzioni di riproduzione
            _buildPlaybackOptionRow(
              'Velocità di riproduzione:', 
              appState.playbackSpeed, 
              (value) => appState.setPlaybackSpeed(value),
            ),
            
            _buildPlaybackOptionRow(
              'Volume:', 
              appState.volume, 
              (value) => appState.setVolume(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection(BuildContext context, AppState appState) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Archiviazione',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Stato attuale di archiviazione
            Row(
              children: [
                _buildStorageIndicator(
                  'Cloud',
                  song.cloudUrl != null,
                  Icons.cloud,
                  AppTheme.primaryColor,
                ),
                const SizedBox(width: 16),
                _buildStorageIndicator(
                  'Locale',
                  song.localPath != null && song.isLocalOnly,
                  Icons.storage,
                  AppTheme.secondaryColor,
                ),
                const SizedBox(width: 16),
                _buildStorageIndicator(
                  'Streaming',
                  song.isStreamingOnly,
                  Icons.stream,
                  AppTheme.accentColor,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Pulsanti per cambiare lo stato di archiviazione
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Download su cloud
                if (song.cloudUrl == null)
                  _buildStorageButton(
                    'Cloud',
                    Icons.cloud_download,
                    AppTheme.primaryColor,
                    () => _downloadToCloud(context, appState),
                  ),
                
                // Download locale
                if (song.localPath == null || !song.isLocalOnly)
                  _buildStorageButton(
                    'Locale',
                    Icons.download,
                    AppTheme.secondaryColor,
                    () => _downloadLocally(context, appState),
                  ),
                
                // Stream
                if (!song.isStreamingOnly)
                  _buildStorageButton(
                    'Streaming',
                    Icons.stream,
                    AppTheme.accentColor,
                    () => _convertToStreaming(context, appState),
                  ),
                  
                // Pulsante di eliminazione dal dispositivo locale
                if (song.localPath != null && song.isLocalOnly)
                  _buildStorageButton(
                    'Elimina',
                    Icons.delete_forever,
                    Colors.redAccent,
                    () => _showDeleteLocalConfirmation(context, appState),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteLocalConfirmation(BuildContext context, AppState appState) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina file locale'),
        content: Text('Vuoi eliminare "${song.title}" dal dispositivo? Questa azione rimuoverà solo il file locale.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await appState.deleteSong(song);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File locale eliminato con successo'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);  // Torna alla schermata precedente
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante l\'eliminazione: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackOptionRow(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: label.contains('Velocità') ? 0.5 : 0.0,
                  max: label.contains('Velocità') ? 2.0 : 1.0,
                  divisions: label.contains('Velocità') ? 15 : 10,
                  onChanged: onChanged,
                  activeColor: AppTheme.accentColor,
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  label.contains('Velocità') ? '${value.toStringAsFixed(1)}x' : '${(value * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageIndicator(String label, bool isActive, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? color.withAlpha(179) : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white38,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withAlpha(51),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }

  String _getAvailabilityText() {
    List<String> availability = [];
    if (song.cloudUrl != null) availability.add('Cloud');
    if (song.localPath != null && song.isLocalOnly) availability.add('Locale');
    if (song.isStreamingOnly) availability.add('Streaming');
    
    return availability.isEmpty ? 'Non disponibile' : availability.join(', ');
  }

  Future<void> _showAddToPlaylistModal(BuildContext context, AppState appState) async {
    final playlists = appState.getPlaylistsForSong(song);
    
    if (playlists.isEmpty) {
      // Se non ci sono playlist disponibili, offrire di crearne una nuova
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nessuna playlist disponibile'),
          content: const Text('Non hai playlist disponibili o il brano è già presente in tutte le playlist. Vuoi crearne una nuova?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, appState);
              },
              child: const Text('Crea playlist'),
            ),
          ],
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aggiungi a playlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: playlists.length + 1, // +1 per l'opzione "Crea nuova playlist"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "Crea nuova playlist" come prima opzione
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: AppTheme.primaryColor),
                      ),
                      title: const Text('Crea nuova playlist'),
                      onTap: () {
                        Navigator.pop(context);
                        _showCreatePlaylistDialog(context, appState);
                      },
                    );
                  }
                  
                  final playlist = playlists[index - 1];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.queue_music, color: AppTheme.accentColor),
                    ),
                    title: Text(playlist.name),
                    subtitle: Text('${playlist.songs.length} brani'),
                    onTap: () {
                      Navigator.pop(context);
                      _addToPlaylist(context, appState, playlist);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context, AppState appState) async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<void>(
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
              if (controller.text.isNotEmpty) {
                try {
                  await appState.createPlaylist(controller.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    // Ottieni l'ultima playlist creata
                    final newPlaylist = appState.playlists.last;
                    _addToPlaylist(context, appState, newPlaylist);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Errore: $e')),
                    );
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

  Future<void> _addToPlaylist(BuildContext context, AppState appState, playlist) async {
    try {
      await appState.addSongToPlaylist(playlist, song);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${song.title} aggiunto a ${playlist.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadToCloud(BuildContext context, AppState appState) async {
    try {
      await appState.downloadSong(song);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canzone scaricata su cloud con successo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadLocally(BuildContext context, AppState appState) async {
    try {
      await appState.downloadSongLocally(song);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canzone scaricata in locale con successo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il download locale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _convertToStreaming(BuildContext context, AppState appState) async {
    try {
      await appState.addStreamingSong(song);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canzone convertita in modalità streaming'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante la conversione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, AppState appState) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text('Sei sicuro di voler eliminare "${song.title}"? Questa azione rimuoverà la canzone dalla libreria, dalle playlist e dal cloud se presente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await appState.deleteSong(song);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Canzone eliminata con successo'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);  // Torna alla schermata precedente
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante l\'eliminazione: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  
}