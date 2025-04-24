// lib/widgets/song_list_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_stream_app/models/song.dart';
import 'package:music_stream_app/theme.dart';
import 'package:music_stream_app/providers/app_state.dart';
import 'package:music_stream_app/screens/song_detail_screen.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final bool showIndex;
  final int? index;
  final VoidCallback? onLongPress;
  final bool showPlaybackSourceIcon;
  final bool showMoreOptions; // Nuovo parametro per mostrare il pulsante opzioni

  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    this.showIndex = false,
    this.index,
    this.onLongPress,
    this.showPlaybackSourceIcon = false,
    this.showMoreOptions = true, // Default a true per abilitare le opzioni
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: showIndex && index != null
          ? SizedBox(
              width: 30,
              child: Center(
                child: Text(
                  index.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ),
            )
          : Hero(
              tag: 'song_cover_${song.id}',
              child: Container(
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
            ),
      title: Text(
        song.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          // Testo del canale
          Expanded(
            child: Text(
              song.channelTitle ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withAlpha(179)),
            ),
          ),
          
          // Icona tipo di riproduzione
          if (showPlaybackSourceIcon)
            _buildPlaybackSourceIcon(),
        ],
      ),
      trailing: showMoreOptions 
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.more_vert, size: 22),
                onPressed: () => _showOptionsMenu(context),
                tooltip: 'Opzioni',
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: onTap,
                iconSize: 32,
                color: AppTheme.accentColor,
              ),
            ],
          )
        : IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: onTap,
            iconSize: 32,
            color: AppTheme.accentColor,
          ),
      onTap: onTap,
      onLongPress: onLongPress ?? () => _showOptionsMenu(context),
    );
  }

  // Nuovo metodo per mostrare l'icona della fonte di riproduzione
  Widget _buildPlaybackSourceIcon() {
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
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  // Nuovo metodo per visualizzare il menu delle opzioni
  void _showOptionsMenu(BuildContext context) {
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
              onTap();
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Dettagli brano'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongDetailScreen(song: song),
                ),
              );
            },
          ),
          
          // Opzioni per playlist
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Aggiungi a playlist'),
            onTap: () {
              Navigator.pop(context);
              _showPlaylistOptions(context, appState);
            },
          ),
          
          // Opzioni di eliminazione
          if (song.localPath != null && song.isLocalOnly)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Elimina file locale', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteLocalConfirmation(context, appState);
              },
            ),
            
          if (song.id != null)
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Elimina dalla libreria', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, appState);
              },
            ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Metodo per mostrare le opzioni playlist
  void _showPlaylistOptions(BuildContext context, AppState appState) {
    final playlists = appState.getPlaylistsForSong(song);
    
    if (playlists.isEmpty) {
      // Mostra messaggio se non ci sono playlist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non hai playlist disponibili. Creane una nuova nella sezione Libreria.'),
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
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: playlists.length + 1, // +1 per l'intestazione
        itemBuilder: (context, index) {
          if (index == 0) {
            // Intestazione
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Scegli una playlist',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            );
          }
          
          final playlist = playlists[index - 1];
          return ListTile(
            leading: const Icon(Icons.queue_music),
            title: Text(playlist.name),
            subtitle: Text('${playlist.songs.length} brani'),
            onTap: () async {
              Navigator.pop(context);
              await appState.addSongToPlaylist(playlist, song);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aggiunto a ${playlist.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  // Metodo per confermare l'eliminazione del file locale
  Future<void> _showDeleteLocalConfirmation(BuildContext context, AppState appState) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina file locale'),
        content: Text('Vuoi eliminare il file locale di "${song.title}"? Il brano rimarrà nella libreria ma sarà disponibile solo in streaming.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Nella versione attuale: modifica per usare il metodo appropriato
                await appState.deleteSong(song, localOnly: true);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File locale eliminato con successo'),
                      backgroundColor: Colors.green,
                    ),
                  );
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

  // Metodo per confermare l'eliminazione completa
  Future<void> _showDeleteConfirmation(BuildContext context, AppState appState) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina dalla libreria'),
        content: Text('Vuoi eliminare "${song.title}" dalla libreria? Questa azione rimuoverà il brano da tutte le playlist e dal cloud/locale se presente.'),
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
                      content: Text('Brano eliminato con successo'),
                      backgroundColor: Colors.green,
                    ),
                  );
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