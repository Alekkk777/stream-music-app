// Modifica a search_result_item.dart per aggiungere funzionalità di coda

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/models/song.dart';
import 'package:music_stream_app/theme.dart';
import 'package:music_stream_app/providers/app_state.dart';

class SearchResultItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onPlay; // Callback per la riproduzione diretta

  const SearchResultItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 70,
                height: 70,
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
                    ? const Icon(Icons.music_note, size: 30, color: Colors.white70)
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Info
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
              
              // Pulsanti di azione
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsante Play per lo streaming diretto
                  IconButton(
                    icon: const Icon(
                      Icons.play_circle_outline,
                      color: AppTheme.accentColor,
                    ),
                    onPressed: onPlay,
                    tooltip: 'Riproduci',
                    iconSize: 30,
                  ),
                  
                  // Nuovo pulsante: Aggiungi a coda
                  IconButton(
                    icon: const Icon(
                      Icons.queue_music,
                      color: AppTheme.accentColor,
                    ),
                    onPressed: () => _addToQueue(context),
                    tooltip: 'Aggiungi a coda',
                    iconSize: 26,
                  ),
                  
                  // Pulsante Download per le opzioni di download
                  IconButton(
                    icon: const Icon(
                      Icons.download,
                      color: AppTheme.secondaryColor,
                    ),
                    onPressed: onTap,
                    tooltip: 'Download',
                    iconSize: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Metodo per aggiungere alla coda di riproduzione
  void _addToQueue(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      // Prima converti il brano in streaming se necessario
      appState.addStreamingSong(song).then((streamingSong) {
        // Poi aggiungilo alla coda
        appState.addToQueue(streamingSong);
        
        // Mostra notifica
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${song.title} aggiunto alla coda'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}