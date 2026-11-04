class PageMetadata {
  const PageMetadata(this.page, this.pageSize, this.total);

  final int page;
  final int pageSize;
  final int? total;

  factory PageMetadata.fromResponse(Object? data,
      {required int page, required int pageSize}) {
    final json = data is Map ? data : const {};
    int? integer(Object? value) =>
        value is num ? value.toInt() : int.tryParse('$value');
    final serverPage = integer(json['page']);
    final serverSize = integer(json['pageSize'] ?? json['limit']);
    return PageMetadata(
      serverPage != null && serverPage > 0 ? serverPage : page,
      serverSize != null && serverSize > 0 ? serverSize : pageSize,
      integer(json['total']),
    );
  }
}
