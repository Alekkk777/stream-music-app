// lib/models/song.dart (modifiche)
class Song {
  final int? id;
  final String videoId;
  final String title;
  final String? thumbnailUrl;
  final String? cloudUrl;
  final String? localPath;
  final String? channelTitle;
  final Map<String, dynamic>? metadata;
  final bool isLocalOnly;
  final bool isStreamingOnly;

  Song({
    this.id,
    required this.videoId,
    required this.title,
    this.thumbnailUrl,
    this.cloudUrl,
    this.localPath,
    this.channelTitle,
    this.metadata,
    this.isLocalOnly = false,
    this.isStreamingOnly = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      videoId: json['video_id'],
      title: json['title'],
      thumbnailUrl: json['thumbnail'] ?? (json['metadata'] != null ? 
                     json['metadata']['thumbnail'] : null),
      cloudUrl: json['cloud_url'],
      localPath: json['local_path'],
      channelTitle: json['channel'] ?? (json['metadata'] != null ? 
                     json['metadata']['channel'] : null),
      metadata: json['metadata'],
      isLocalOnly: json['is_local_only'] == 1 || json['is_local_only'] == true,
      isStreamingOnly: json['is_streaming_only'] == 1 || json['is_streaming_only'] == true,
    );
  }

  factory Song.fromSearchResult(Map<String, dynamic> json) {
    return Song(
      videoId: json['video_id'],
      title: json['title'],
      thumbnailUrl: json['thumbnail'],
      channelTitle: json['channel'],
      isStreamingOnly: true,
    );
  }

  // Crea una copia di Song con valori aggiornati
  Song copyWith({
    int? id,
    String? videoId,
    String? title,
    String? thumbnailUrl,
    String? cloudUrl,
    String? localPath,
    String? channelTitle,
    Map<String, dynamic>? metadata,
    bool? isLocalOnly,
    bool? isStreamingOnly,
  }) {
    return Song(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      localPath: localPath ?? this.localPath,
      channelTitle: channelTitle ?? this.channelTitle,
      metadata: metadata ?? this.metadata,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      isStreamingOnly: isStreamingOnly ?? this.isStreamingOnly,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_id': videoId,
      'title': title,
      'thumbnail': thumbnailUrl,
      'cloud_url': cloudUrl,
      'local_path': localPath,
      'channel': channelTitle,
      'metadata': metadata,
      'is_local_only': isLocalOnly,
      'is_streaming_only': isStreamingOnly,
    };
  }
}