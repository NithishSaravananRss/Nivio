import 'package:hive/hive.dart';

class LibraryWatchlistItem extends HiveObject {
  LibraryWatchlistItem({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.addedAt,
    this.posterPath,
    this.voteAverage,
    this.releaseDate,
    this.overview,
  });

  final int id;
  final String title;
  final String? posterPath;
  final String mediaType;
  final DateTime addedAt;
  final double? voteAverage;
  final String? releaseDate;
  final String? overview;
}

class LibraryWatchlistItemAdapter extends TypeAdapter<LibraryWatchlistItem> {
  @override
  final int typeId = 5;

  @override
  LibraryWatchlistItem read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return LibraryWatchlistItem(
      id: fields[0] as int,
      title: fields[1] as String,
      posterPath: fields[2] as String?,
      mediaType: fields[3] as String,
      addedAt: fields[4] as DateTime,
      voteAverage: fields[5] as double?,
      releaseDate: fields[6] as String?,
      overview: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LibraryWatchlistItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.posterPath)
      ..writeByte(3)
      ..write(obj.mediaType)
      ..writeByte(4)
      ..write(obj.addedAt)
      ..writeByte(5)
      ..write(obj.voteAverage)
      ..writeByte(6)
      ..write(obj.releaseDate)
      ..writeByte(7)
      ..write(obj.overview);
  }
}

class LibraryNewEpisodeItem extends HiveObject {
  LibraryNewEpisodeItem({
    required this.showId,
    required this.showName,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeName,
    required this.airDate,
    required this.detectedAt,
    this.posterPath,
    this.isRead = false,
  });

  final int showId;
  final String showName;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeName;
  final String? posterPath;
  final DateTime airDate;
  final DateTime detectedAt;
  final bool isRead;

  String get episodeKey => '${showId}_${seasonNumber}_$episodeNumber';

  LibraryNewEpisodeItem copyWith({
    int? showId,
    String? showName,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeName,
    String? posterPath,
    DateTime? airDate,
    DateTime? detectedAt,
    bool? isRead,
  }) {
    return LibraryNewEpisodeItem(
      showId: showId ?? this.showId,
      showName: showName ?? this.showName,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      episodeName: episodeName ?? this.episodeName,
      posterPath: posterPath ?? this.posterPath,
      airDate: airDate ?? this.airDate,
      detectedAt: detectedAt ?? this.detectedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class LibraryNewEpisodeItemAdapter extends TypeAdapter<LibraryNewEpisodeItem> {
  @override
  final int typeId = 7;

  @override
  LibraryNewEpisodeItem read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return LibraryNewEpisodeItem(
      showId: fields[0] as int,
      showName: fields[1] as String,
      seasonNumber: fields[2] as int,
      episodeNumber: fields[3] as int,
      episodeName: fields[4] as String,
      posterPath: fields[5] as String?,
      airDate: fields[6] as DateTime,
      detectedAt: fields[7] as DateTime,
      isRead: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, LibraryNewEpisodeItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.showId)
      ..writeByte(1)
      ..write(obj.showName)
      ..writeByte(2)
      ..write(obj.seasonNumber)
      ..writeByte(3)
      ..write(obj.episodeNumber)
      ..writeByte(4)
      ..write(obj.episodeName)
      ..writeByte(5)
      ..write(obj.posterPath)
      ..writeByte(6)
      ..write(obj.airDate)
      ..writeByte(7)
      ..write(obj.detectedAt)
      ..writeByte(8)
      ..write(obj.isRead);
  }
}

enum LibraryDownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  paused,
  extracting,
}

class LibraryDownloadStatusAdapter extends TypeAdapter<LibraryDownloadStatus> {
  @override
  final int typeId = 4;

  @override
  LibraryDownloadStatus read(BinaryReader reader) {
    return LibraryDownloadStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, LibraryDownloadStatus obj) {
    writer.writeByte(obj.index);
  }
}

class LibraryDownloadItem extends HiveObject {
  LibraryDownloadItem({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.mediaType,
    required this.savePath,
    required this.createdAt,
    this.posterPath,
    this.season,
    this.episode,
    this.status = LibraryDownloadStatus.pending,
    this.progress = 0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.streamUrl,
    this.headers,
    this.selectedAudioLanguage,
    this.selectedSubtitleLanguage,
    this.subtitleUrl,
    this.failureReason,
  });

  String id;
  int mediaId;
  String title;
  String? posterPath;
  String mediaType;
  int? season;
  int? episode;
  String savePath;
  LibraryDownloadStatus status;
  double progress;
  int totalBytes;
  int downloadedBytes;
  DateTime createdAt;
  String? streamUrl;
  Map<String, String>? headers;
  String? selectedAudioLanguage;
  String? selectedSubtitleLanguage;
  String? subtitleUrl;
  String? failureReason;
}

class LibraryDownloadItemAdapter extends TypeAdapter<LibraryDownloadItem> {
  @override
  final int typeId = 6;

  @override
  LibraryDownloadItem read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return LibraryDownloadItem(
      id: fields[0] as String,
      mediaId: fields[1] as int,
      title: fields[2] as String,
      posterPath: fields[3] as String?,
      mediaType: fields[4] as String,
      season: fields[5] as int?,
      episode: fields[6] as int?,
      savePath: fields[7] as String,
      status: fields[8] as LibraryDownloadStatus,
      progress: (fields[9] as num).toDouble(),
      totalBytes: fields[10] as int,
      downloadedBytes: fields[11] as int,
      createdAt: fields[12] as DateTime,
      streamUrl: fields[13] as String?,
      headers: (fields[14] as Map?)?.cast<String, String>(),
      selectedAudioLanguage: fields[15] as String?,
      selectedSubtitleLanguage: fields[16] as String?,
      subtitleUrl: fields[17] as String?,
      failureReason: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LibraryDownloadItem obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mediaId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.posterPath)
      ..writeByte(4)
      ..write(obj.mediaType)
      ..writeByte(5)
      ..write(obj.season)
      ..writeByte(6)
      ..write(obj.episode)
      ..writeByte(7)
      ..write(obj.savePath)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.progress)
      ..writeByte(10)
      ..write(obj.totalBytes)
      ..writeByte(11)
      ..write(obj.downloadedBytes)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.streamUrl)
      ..writeByte(14)
      ..write(obj.headers)
      ..writeByte(15)
      ..write(obj.selectedAudioLanguage)
      ..writeByte(16)
      ..write(obj.selectedSubtitleLanguage)
      ..writeByte(17)
      ..write(obj.subtitleUrl)
      ..writeByte(18)
      ..write(obj.failureReason);
  }
}

class LibraryScheduleItem {
  const LibraryScheduleItem({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.releaseDate,
    this.seasonNumber,
    this.episodeNumber,
    this.posterPath,
    this.hasPreciseTime = false,
  });

  final int id;
  final String title;
  final String mediaType;
  final DateTime releaseDate;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? posterPath;
  final bool hasPreciseTime;
}
