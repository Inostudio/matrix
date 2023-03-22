import 'package:matrix_sdk/src/event/room/room_event.dart';

class SearchResponse {
  final int count;
  final Map<String, dynamic> groups;
  final List<String> highlights;
  final String nextBatch;
  final List<SearchResult> results;
  final Map<String, dynamic> state;

  const SearchResponse({
    required this.count,
    required this.groups,
    required this.highlights,
    required this.nextBatch,
    required this.results,
    required this.state,
  });

  static SearchResponse? fromJson(Map<String, dynamic>? content) {
    if (content == null) {
      return null;
    }
    return SearchResponse(
      count: content['count'],
      groups: content['groups'],
      highlights: content['highlights'],
      nextBatch: content['next_batch'],
      results: content['results'].map(SearchResult.fromJson).toList(),
      state: content['state'],
    );
  }
}

class SearchResult {
  final double rank;
  final RoomEvent? result;

  const SearchResult({
    required this.rank,
    this.result,
  });

  static SearchResult? fromJson(Map<String, dynamic>? content) {
    if (content == null) {
      return null;
    }
    return SearchResult(
      rank: content['rank'],
      result: RoomEvent.fromJson(content['result']),
    );
  }
}
