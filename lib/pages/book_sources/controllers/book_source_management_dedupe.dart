part of 'book_source_management_controller.dart';

typedef _InstalledDedupeSnapshot = ({
  BookSourceDedupeResult result,
  Map<int, String> sourceIdsByIndex,
});

_InstalledDedupeSnapshot _prepareAndAnalyzeInstalledSources(
  ({
    List<RegisteredBookSource> sources,
    BookSourceDedupeMode mode,
    Set<String>? sourceIds,
    Set<String> referencedSourceIds,
  })
  request,
) {
  final candidates = <BookSourceDedupeCandidate>[];
  final ids = <int, String>{};
  for (final source in request.sources) {
    if (source.sourceProtocol != BookSourceProtocolKind.readingSource ||
        (request.sourceIds != null &&
            !request.sourceIds!.contains(source.id))) {
      continue;
    }
    final raw = source.sourceConfig;
    if (raw == null || '${raw['bookSourceUrl'] ?? ''}'.trim().isEmpty) continue;
    final index = candidates.length;
    ids[index] = source.id;
    candidates.add(
      BookSourceDedupeCandidate(
        index: index,
        rawConfig: {...raw, 'enabled': source.enabled},
        installedSourceId: source.id,
        isReferenced: request.referencedSourceIds.contains(source.id),
        isHealthy: sourceHealthCheckResultOf(source)?.fullyAvailable == true,
        runnableCapabilities: source.capabilities.length,
        compatibilityRank: source.capabilities.isEmpty ? 0 : 1,
      ),
    );
  }
  return (
    result: const BookSourceDedupeEngine().analyze(
      candidates,
      mode: request.mode,
    ),
    sourceIdsByIndex: ids,
  );
}
