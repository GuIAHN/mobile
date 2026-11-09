/// Details return ordered photo records; older endpoints only return a cover.
List<String> requestPhotoUrls(Map<String, dynamic> json) {
  final photos = (json['photos'] as List? ?? const [])
      .whereType<Map>()
      .where((p) => p['url'] is String && (p['url'] as String).isNotEmpty)
      .toList()
    ..sort((a, b) => ((a['position'] as num?)?.toInt() ?? 0)
        .compareTo((b['position'] as num?)?.toInt() ?? 0));
  if (photos.isNotEmpty) {
    return List.unmodifiable(photos.map((p) => p['url'] as String).toSet());
  }
  final cover = (json['photoUrl'] ?? json['fotoUrl'])?.toString();
  return cover == null || cover.isEmpty ? const [] : List.unmodifiable([cover]);
}
