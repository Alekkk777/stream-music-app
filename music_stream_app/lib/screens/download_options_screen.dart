// lib/screens/download_options_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/models/song.dart';
import 'package:music_stream_app/providers/app_state.dart';
import 'package:music_stream_app/screens/song_detail_screen.dart';
import 'package:music_stream_app/theme.dart';

class DownloadOptionsScreen extends StatelessWidget {
  final Song song;

  const DownloadOptionsScreen({
  super.key,
  required this.song,
  });

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Opzioni di download'),
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
    ),
    body: Consumer<AppState>(
      builder: (context, appState, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.surfaceColor,
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informazioni sul brano
                  _buildSongInfoCard(context),
                  
                  const SizedBox(height: 24),
                  
                  // Opzioni di download
                  Text(
                    'Come vuoi salvare questa canzone?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Card opzioni
                  _buildOptionCard(
                    context,
                    'Cloud Storage',
                    'Salva su Oracle Cloud per accedervi da qualsiasi dispositivo. Consigliato per un accesso ovunque.',
                    Icons.cloud_upload,
                    AppTheme.primaryColor,
                    () => _downloadToCloud(context, appState),
                  ),
                  
                  _buildOptionCard(
                    context,
                    'Storage Locale',
                    'Salva sul dispositivo attuale. Ideale per risparmiare dati quando ascolti offline.',
                    Icons.save_alt,
                    AppTheme.secondaryColor,
                    () => _downloadLocally(context, appState),
                  ),
                  
                  _buildOptionCard(
                    context,
                    'Solo Streaming',
                    'Non scaricare, ascolta solo in streaming. Ottimo per risparmiare spazio.',
                    Icons.stream,
                    AppTheme.accentColor,
                    () => _addToStreamingLibrary(context, appState),
                  ),
                  
                  const SizedBox(height: 50), // Aggiungi spazio in fondo
                  
                  // Pulsante annulla
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Annulla'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildSongInfoCard(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                image: song.thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(song.thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: song.thumbnailUrl == null
                  ? const Icon(Icons.music_note, size: 40, color: Colors.white70)
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Info brano
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (song.channelTitle != null)
                    Text(
                      song.channelTitle!,
                      style: TextStyle(
                        color: Colors.white.withAlpha(179),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icona
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Testo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withAlpha(179),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Freccia
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadToCloud(BuildContext context, AppState appState) async {
  Navigator.pop(context);
  
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  try {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Downloading ${song.title}...'),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );
    
    // Assicurati che questo metodo restituisca una Song o null
    await appState.downloadSong(song);
    
    if (context.mounted) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Download completato con successo'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Vai alla schermata di dettaglio del brano, usa sempre song
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SongDetailScreen(song: song),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Errore durante il download: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  }

  Future<void> _downloadLocally(BuildContext context, AppState appState) async {
  Navigator.pop(context);
  
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  try {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Downloading locally ${song.title}...'),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );
    
    // Assicurati che questo metodo restituisca una Song o null
    await appState.downloadSongLocally(song);
    
    if (context.mounted) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Download locale completato con successo'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Vai alla schermata di dettaglio del brano, usa song
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SongDetailScreen(song: song),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Errore durante il download locale: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Future<void> _addToStreamingLibrary(BuildContext context, AppState appState) async {
    Navigator.pop(context);
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Aggiunta alla libreria di streaming...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      final streamingSong = await appState.addStreamingSong(song);
      
      if (context.mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Brano aggiunto alla libreria di streaming'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Vai alla schermata di dettaglio del brano
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SongDetailScreen(song: streamingSong),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'aggiunta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}