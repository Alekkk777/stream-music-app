// lib/widgets/playlist_item.dart
import 'package:flutter/material.dart';
import 'package:music_stream_app/models/playlist.dart';
import 'package:music_stream_app/theme.dart';

class PlaylistItem extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const PlaylistItem({
    super.key,
    required this.playlist,
    required this.onTap,
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
            color: Colors.black.withAlpha(26), // Sostituito withOpacity con withAlpha
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Playlist cover
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(51), // Sostituito withOpacity con withAlpha
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.queue_music,
                size: 40,
                color: AppTheme.accentColor,
              ),
            ),
            
            // Playlist info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.songs.length} brani',
                      style: TextStyle(
                        color: Colors.white.withAlpha(179), // Sostituito withOpacity con withAlpha
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Arrow icon
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(
                Icons.chevron_right,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}