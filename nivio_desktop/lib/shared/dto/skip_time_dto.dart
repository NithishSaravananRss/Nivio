class SkipTimeDto {
  final Duration startTime;
  final Duration endTime;
  final String type; // op, ed, recap, preview

  const SkipTimeDto({
    required this.startTime,
    required this.endTime,
    required this.type,
  });

  factory SkipTimeDto.fromJson(Map<String, dynamic> json) {
    return SkipTimeDto(
      startTime: Duration(milliseconds: (json['start_time_ms'] as num?)?.toInt() ?? 0),
      endTime: Duration(milliseconds: (json['end_time_ms'] as num?)?.toInt() ?? 0),
      type: json['type'] as String? ?? 'unknown',
    );
  }
}
