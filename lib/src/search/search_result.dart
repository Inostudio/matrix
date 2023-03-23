import 'package:matrix_sdk/src/event/room/room_event.dart';

class SearchResponse {
  final int count;
  final Map<String, dynamic>? groups;
  final List<String> highlights;
  final String? nextBatch;
  final List<SearchResult> results;
  final Map<String, dynamic>? state;

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
    final categories = content["search_categories"] as Map<String, dynamic>?;
    if (categories != null) {
      final events = categories["room_events"] as Map<String, dynamic>?;
      if (events != null) {
        return SearchResponse(
          count: events['count'],
          groups: events['groups'],
          highlights: List<String>.from(events['highlights'] as List) ,
          nextBatch: events['next_batch'],
          results: List<Map<String, dynamic>>.from(events['results'] as List).map(SearchResult.fromJson).toList(),
          state: events['state'],
        );
      }
    }
    return null;
  }
}

class SearchResult {
  final double rank;
  final RoomEvent? result;

  const SearchResult({
    required this.rank,
    this.result,
  });

  factory SearchResult.fromJson(Map<String, dynamic>? content) {
    if (content == null) {
      return SearchResult(rank: 0, result: null);
    }
    return SearchResult(
      rank: content['rank'],
      result: RoomEvent.fromJson(content['result']),
    );
  }
}
