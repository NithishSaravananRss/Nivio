class DetailRouteArgs {
  final String mediaType;
  final int mediaId;

  const DetailRouteArgs({
    required this.mediaType,
    required this.mediaId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetailRouteArgs &&
          runtimeType == other.runtimeType &&
          mediaType == other.mediaType &&
          mediaId == other.mediaId;

  @override
  int get hashCode => mediaType.hashCode ^ mediaId.hashCode;

  @override
  String toString() => '$mediaType:$mediaId';
}
