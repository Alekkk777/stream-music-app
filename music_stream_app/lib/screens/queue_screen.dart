// Modifica alla QueueScreen per supportare il riordinamento tramite drag and drop

// lib/screens/queue_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/providers/app_state.dart';

import 'package:music_stream_app/theme.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coda di riproduzione'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Pulisci coda',
            onPressed: () => _showClearQueueConfirmation(context),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final queue = appState.currentPlaybackQueue;
          final currentIndex = appState.currentIndex;
          
          if (queue.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music, size: 72, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('La coda di riproduzione è vuota'),
                  SizedBox(height: 8),
                  Text(
                    'Aggiungi brani alla coda dalle altre sezioni dell\'app',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // Indicazioni per l'utente
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.drag_handle, size: 16, color: Colors.white.withAlpha(150)),
                        const SizedBox(width: 8),
                        Text(
                          'Trascina per riordinare i brani',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swipe_left, size: 16, color: Colors.white.withAlpha(150)),
                        const SizedBox(width: 8),
                        Text(
                          'Scorri per rimuovere dalla coda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Lista riordinabile
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    // Se il brano in riproduzione è coinvolto, non permettere lo spostamento
                    if (oldIndex == currentIndex) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Non puoi spostare il brano attualmente in riproduzione'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    
                    // Se inserendo dopo l'elemento rimosso, decrementa newIndex
                    if (newIndex > oldIndex) newIndex--;
                    
                    // Se tentiamo di spostare un brano prima di quello in riproduzione
                    if (newIndex <= currentIndex && oldIndex > currentIndex) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Non puoi inserire brani prima di quello in riproduzione'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    
                    // Esegui il riordinamento
                    appState.reorderQueue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isCurrentSong = index == currentIndex;
                    
                    return Dismissible(
                      key: Key('queue-item-${song.id}-$index'),
                      direction: isCurrentSong 
                          ? DismissDirection.none // Non permettere di eliminare il brano in riproduzione
                          : DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        // Non permettere di rimuovere il brano in riproduzione
                        if (isCurrentSong) return false;
                        
                        // Non chiedere conferma per la rimozione dalla coda
                        return true;
                      },
                      onDismissed: (direction) {
                        appState.removeFromQueue(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${song.title} rimosso dalla coda'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrentSong 
                              ? AppTheme.primaryColor.withAlpha(60) 
                              : null,
                        ),
                        child: Column(
                          key: Key('queue-column-${song.id}-$index'),
                          children: [
                            // Badge per brano corrente
                            if (isCurrentSong)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      appState.isPlaying 
                                          ? Icons.pause_circle_filled 
                                          : Icons.play_circle_filled,
                                      color: AppTheme.accentColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'In riproduzione',
                                      style: TextStyle(
                                        color: AppTheme.accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Widget del brano
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icona di drag
                                  if (!isCurrentSong)
                                    const Icon(Icons.drag_handle, color: Colors.white38, size: 20),
                                  
                                  const SizedBox(width: 8),
                                  
                                  // Thumbnail
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: song.thumbnailUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(song.thumbnailUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: AppTheme.cardColor,
                                    ),
                                    child: song.thumbnailUrl == null
                                        ? const Icon(Icons.music_note, color: Colors.white70)
                                        : null,
                                  ),
                                ],
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                song.channelTitle ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.play_circle_outline),
                                onPressed: () => appState.playSong(song, queue: queue, index: index),
                                color: AppTheme.accentColor,
                                iconSize: 32,
                              ),
                              onTap: () => appState.playSong(song, queue: queue, index: index),
                            ),
                            
                            if (index < queue.length - 1)
                              const Divider(height: 1, indent: 70),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showClearQueueConfirmation(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pulisci coda'),
        content: const Text('Vuoi rimuovere tutti i brani dalla coda di riproduzione? Il brano attualmente in riproduzione non verrà interrotto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.clearQueue();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coda di riproduzione svuotata'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Pulisci'),
          ),
        ],
      ),
    );
  }
}