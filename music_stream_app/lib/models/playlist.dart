// lib/models/playlist.dart
import 'package:music_stream_app/models/song.dart';

class Playlist {
  final int id;
  final String name;
  final List<Song> songs;
  final String? createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.songs = const [],
    this.createdAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final songsList = (json['songs'] as List?)
        ?.map((songJson) => Song.fromJson(songJson))
        .toList() ??
        [];

    return Playlist(
      id: json['id'],
      name: json['name'],
      songs: songsList,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((song) => song.toJson()).toList(),
      'created_at': createdAt,
    };
  }
}