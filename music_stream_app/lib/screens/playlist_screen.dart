// lib/screens/playlist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/providers/app_state.dart';
import 'package:music_stream_app/models/playlist.dart';
import 'package:music_stream_app/models/song.dart';
import 'package:music_stream_app/widgets/song_list_item.dart';
import 'package:music_stream_app/screens/song_detail_screen.dart';
import 'package:music_stream_app/theme.dart';
import 'package:music_stream_app/widgets/mini_player.dart';



class PlaylistScreen extends StatelessWidget {
  final Playlist playlist;
  

  const PlaylistScreen({
    super.key,
    required this.playlist,
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
        actions: [
          // Aggiungiamo un pulsante di opzioni alla playlist
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(102),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert),
            ),
            onPressed: () => _showPlaylistOptions(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Theme.of(context).colorScheme.secondary.withAlpha(179),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              children: [
                // Intestazione della playlist
                _buildPlaylistHeader(context),
                
                // Lista dei brani
                _buildSongsList(context),
              ],
            ),
          ),
          
          // Aggiungi MiniPlayer in fondo
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Consumer<AppState>(
              builder: (context, appState, _) {
                // Mostra il mini player solo se c'è una canzone in riproduzione
                if (appState.currentSong == null) {
                  return const SizedBox.shrink();
                }
                return const MiniPlayer();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSongDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlaylistHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icona della playlist
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(77),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.queue_music,
              size: 80,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Titolo della playlist
          Text(
            playlist.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Informazioni sulla playlist
          Text(
            '${playlist.songs.length} brani',style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          
          // Pulsanti azione
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: playlist.songs.isEmpty
                    ? null
                    : () {
                        // Riproduci il primo brano della playlist
                        if (playlist.songs.isNotEmpty) {
                          Provider.of<AppState>(context, listen: false)
                              .playPlaylist(playlist);
                        }
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Riproduci'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _showAddSongDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList(BuildContext context) {
    if (playlist.songs.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Nessun brano in questa playlist\nAggiungi brani per iniziare',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Indicazione visiva per lo swipe
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.swipe_left_alt, size: 16, color: Colors.white54),
                  const SizedBox(width: 8),
                  Text(
                    'Scorri verso sinistra per rimuovere un brano',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista brani con dismissible
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: playlist.songs.length,
                  itemBuilder: (context, index) {
                    final song = playlist.songs[index];
                    return Dismissible(
                      key: Key('song-$song.id-$playlist.id-$index'),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) => _confirmRemoveSong(context, song),
                      onDismissed: (direction) => _removeSongFromPlaylist(context, song),
                      child: SongListItem(
                        song: song,
                        onTap: () => Provider.of<AppState>(context, listen: false)
                            .playPlaylist(playlist, startIndex: index),
                        showIndex: true,
                        index: index + 1,
                        onLongPress: () => _showSongOptions(context, song, index),
                        showPlaybackSourceIcon: true,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Metodo per mostrare le opzioni del brano
  void _showSongOptions(BuildContext context, Song song, int index) {
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
          
          // Intestazione con titolo del brano
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              song.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const Divider(),
          
          // Opzioni del menu
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Riproduci'),
            onTap: () {
              Navigator.pop(context);
              Provider.of<AppState>(context, listen: false)
                  .playPlaylist(playlist, startIndex: index);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Aggiungi a coda'),
            onTap: () {
              Navigator.pop(context);
              final appState = Provider.of<AppState>(context, listen: false);
              _addToQueue(context, appState, song);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Dettagli brano'),
            onTap: () {
              Navigator.pop(context);
              _showSongDetailScreen(context, song);
            },
          ),
          
          // Opzione rimuovi dalla playlist
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
            title: const Text('Rimuovi dalla playlist', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmRemoveSong(context, song).then((confirmed) {
                if (confirmed) {
                  _removeSongFromPlaylist(context, song);
                }
              });
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddSongDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddSongsToPlaylistSheet(playlist: playlist),
    );
  }

  void _addToQueue(BuildContext context, AppState appState, Song song) {
    try {
      // Aggiungi il brano alla coda
      appState.addToQueue(song);
      
      // Mostra conferma
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${song.title} aggiunto alla coda'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Gestisci eventuali errori
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Nuovo metodo per visualizzare i dettagli del brano
  void _showSongDetailScreen(BuildContext context, Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongDetailScreen(song: song),
      ),
    );
  }

  Future<bool> _confirmRemoveSong(BuildContext context, Song song) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi brano'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vuoi rimuovere "${song.title}" da questa playlist?'),
            const SizedBox(height: 8),
            const Text(
              'Nota: il brano rimarrà nella tua libreria e sarà disponibile in altre playlist.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Nuovo metodo per rimuovere un brano dalla playlist
  void _removeSongFromPlaylist(BuildContext context, Song song) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      appState.removeSongFromPlaylist(playlist, song);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${song.title} rimosso dalla playlist'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
          label: 'Annulla',
          onPressed: () {
            // Aggiungi nuovamente il brano alla playlist
            appState.addSongToPlaylist(playlist, song).then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Brano ripristinato'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            });
          },
        ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Metodo per eliminare una playlist
  void _showDeletePlaylistConfirmation(BuildContext context, AppState appState, Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina playlist'),
        content: Text('Sei sicuro di voler eliminare la playlist "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Chiudi il dialog
              
              // Mostra indicatore di caricamento
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Eliminazione playlist in corso...'),
                    duration: Duration(seconds: 1),
                  )
                );
              }
              
              try {
                // Chiama il metodo deletePlaylist nel provider AppState
                await appState.deletePlaylist(playlist);
                
                if (context.mounted) {
                  // Mostra conferma di successo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playlist eliminata con successo'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Torna alla schermata precedente
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  // Mostra messaggio di errore
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

  // Nuovo metodo per mostrate le opzioni della playlist
  void _showPlaylistOptions(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
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
            leading: const Icon(Icons.sort),
            title: const Text('Ordina per titolo'),
            onTap: () {
              Navigator.pop(context);
              // Implementazione da fare
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.shuffle),
            title: const Text('Riproduzione casuale'),
            onTap: () {
              Navigator.pop(context);
              if (playlist.songs.isNotEmpty) {
                final appState = Provider.of<AppState>(context, listen: false);
                
                // Crea una copia della lista e la mescola
                final shuffledSongs = List<Song>.from(playlist.songs)..shuffle();
                
                // Riproduci la playlist mescolata
                appState.playSong(shuffledSongs.first, queue: shuffledSongs, index: 0);
              }
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rinomina playlist'),
            onTap: () {
              Navigator.pop(context);
              // Implementazione da fare
            },
          ),
          
          // Pulsante di eliminazione playlist
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Elimina playlist', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeletePlaylistConfirmation(context, appState, playlist);
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AddSongsToPlaylistSheet extends StatelessWidget {
  final Playlist playlist;

  const _AddSongsToPlaylistSheet({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Consumer<AppState>(
          builder: (context, appState, _) {
            // Filtra i brani che non sono già nella playlist
            final songsToAdd = appState.songs.where((song) {
              return !playlist.songs.any((s) => s.id == song.id);
            }).toList();

            if (songsToAdd.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: Colors.white70),
                      const SizedBox(height: 16),
                      const Text(
                        'Tutti i brani sono già stati aggiunti a questa playlist',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Chiudi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Intestazione
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: [
                      // Indicatore di trascinamento
                      Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aggiungi brani a "${playlist.name}"',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Barra di ricerca semplice
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cerca tra i tuoi brani...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: (value) {
                      // Implementazione filtro da fare
                    },
                  ),
                ),
                
                Divider(color: Colors.white.withAlpha(26)),
                
                // Lista brani
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: songsToAdd.length,
                    itemBuilder: (context, index) {
                      final song = songsToAdd[index];
                      return _AddSongListItem(
                        song: song,
                        onAdd: () => _addSongToPlaylist(context, appState, song),
                        onView: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SongDetailScreen(song: song),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> _addSongToPlaylist(BuildContext context, AppState appState, Song song) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Mostra un messaggio di caricamento
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
            const SizedBox(width: 16),
            const Text('Aggiunta alla playlist e download su cloud...'),
          ],
        ),
        duration: const Duration(seconds: 30), // Durata lunga perché viene chiuso manualmente
      ),
    );
    
    try {
      // Il metodo addSongToPlaylist ora scarica automaticamente su cloud
      await appState.addSongToPlaylist(playlist, song);
      
      if (context.mounted) {
        // Nascondi lo snackbar di caricamento
        scaffoldMessenger.hideCurrentSnackBar();
        
        // Mostra un messaggio di successo
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${song.title} aggiunto a ${playlist.name} e salvato su cloud'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Chiudi il bottom sheet
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        // Nascondi lo snackbar di caricamento
        scaffoldMessenger.hideCurrentSnackBar();
        
        // Mostra un messaggio di errore
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _AddSongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onAdd;
  final VoidCallback onView;

  const _AddSongListItem({
    required this.song,
    required this.onAdd,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          // Testo del canale
          Expanded(
            child: Text(
              song.channelTitle ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Indicatore tipo di storage
          _buildStorageTypeIndicator(song),
        ],
      ),
      leading: GestureDetector(
        onTap: onView,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
            image: song.thumbnailUrl != null
                ? DecorationImage(
                    image: NetworkImage(song.thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: song.thumbnailUrl == null
              ? const Icon(Icons.music_note, color: Colors.white70)
              : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: onAdd,
        tooltip: 'Aggiungi alla playlist',
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildStorageTypeIndicator(Song song) {
    IconData icon;
    Color color;
    String tooltip;
    
    if (song.cloudUrl != null) {
      icon = Icons.cloud;
      color = AppTheme.primaryColor;
      tooltip = 'Salvato su cloud';
    } else if (song.localPath != null && song.isLocalOnly) {
      icon = Icons.storage;
      color = AppTheme.secondaryColor;
      tooltip = 'Salvato in locale';
    } else if (song.isStreamingOnly) {
      icon = Icons.stream;
      color = AppTheme.accentColor;
      tooltip = 'Solo streaming';
    } else {
      return const SizedBox.shrink();
    }
    
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
}