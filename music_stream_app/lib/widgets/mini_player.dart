// lib/widgets/mini_player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/providers/app_state.dart' as app_provider;
import 'package:music_stream_app/screens/player_screen.dart';
import 'package:music_stream_app/theme.dart';
import 'package:music_stream_app/screens/queue_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_provider.AppState>(
      builder: (context, appState, _) {
        final song = appState.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          child: Container(
            height: 70,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: appState.progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                  minHeight: 2,
                ),
                
                // Player controls
                Expanded(
                  child: Row(
                    children: [
                      // Thumbnail
                      Hero(
                        tag: 'mini_player_cover_${song.id}',
                        child: Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: song.thumbnailUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(song.thumbnailUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: song.thumbnailUrl == null
                              ? const Icon(Icons.music_note, color: Colors.white70)
                              : null,
                        ),
                      ),
                      
                      // Song info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (song.channelTitle != null)
                                Text(
                                  song.channelTitle!,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(179),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              // Aggiungi qui l'informazione sulla coda
                              if (appState.currentPlaybackQueue.length > 1)
                                Text(
                                  'In coda: ${appState.currentPlaybackQueue.length - 1} brani',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withAlpha(150),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Pulsanti di controllo (coda e play/pause)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsante per la coda
                          IconButton(
                            icon: const Icon(
                              Icons.queue_music,
                              color: AppTheme.accentColor,
                              size: 24,
                            ),
                            onPressed: () => _openQueueScreen(context),
                            tooltip: 'Coda di riproduzione',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          // Play/Pause button
                          IconButton(
                            icon: Icon(
                              appState.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppTheme.accentColor,
                            ),
                            onPressed: () => appState.togglePlay(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Metodo per aprire la schermata della coda
  void _openQueueScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QueueScreen(),
      ),
    );
  }
}