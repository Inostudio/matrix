class SearchCategories {
  final RoomEvents roomEvents;

  const SearchCategories(this.roomEvents);

  factory SearchCategories.from({
    required String roomID,
    required String searchTerm,
  }) {
    return SearchCategories(RoomEvents(
      searchTerm: searchTerm,
      filter: Filter(rooms: [roomID]),
    ));
  }

  Map<String, dynamic> toJson() {
    return {
      'room_events': roomEvents.toJson(),
    };
  }

  @override
  String toString() => toJson().toString();
}

class RoomEvents {
  final String searchTerm;
  final Filter? filter;

  ///Requests the server return the current state for each room returned.
  final IncludeState? includeState;

  ///Requests that the server partitions the result set based on the
  ///provided list of keys
  final Groupings? groupings;

  ///The keys to search. Default value: all
  final List<String>? keys;

  ///The order in which to search for results. Default value: rank
  final String? orderBy;

  const RoomEvents({
    required this.searchTerm,
    this.filter,
    this.includeState,
    this.groupings,
    this.keys,
    this.orderBy,
  });

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'search_term': searchTerm,
    };
    if (filter != null) {
      result["filter"] = filter!.toJson();
    }
    if (groupings != null) {
      result["groupings"] = groupings!.toJson();
    }
    if (keys != null) {
      result["keys"] = keys!;
    }
    if (orderBy != null) {
      result["order_by"] = orderBy!;
    }
    if (includeState != null) {
      result["include_state"] = includeState!.toJson();
    }
    return result;
  }

  @override
  String toString() => toJson().toString();
}

class IncludeState {
  ///How many events after the result are returned
  final int afterLimit;

  ///How many events before the result are returned
  final int beforeLimit;

  ///Requests that the server returns the historic profile
  ///information for the users that sent the events that were returned
  final bool includeProfile;

  const IncludeState({
    this.afterLimit = 5,
    this.beforeLimit = 5,
    this.includeProfile = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'after_limit': afterLimit,
      'before_limit': beforeLimit,
      'include_profile': includeProfile,
    };
  }

  @override
  String toString() => toJson().toString();
}

class Filter {
  ///If true, includes only events with a url key in their content.
  ///If false, excludes those events.
  ///If omitted, url key is not considered for filtering
  final bool? containsURL;

  ///If true, sends all membership events for all events, even if they
  ///have already been sent to the client.
  ///Does not apply unless lazy_load_members is true
  final bool includeRedundantMembers;

  ///If true, enables lazy-loading of membership events
  final bool lazyLoadMembers;

  ///The maximum number of events to return
  final int limit;

  ///A list of room IDs to exclude. If this list is absent then no rooms are excluded.
  ///A matching room will be excluded even if it is listed in the 'rooms' filter.
  final List<String> notRooms;

  ///A list of sender IDs to exclude. If this list is absent then no senders are excluded.
  ///A matching sender will be excluded even if it is listed in the 'senders' filter.
  final List<String> notSenders;

  ///A list of event types to exclude. If this list is absent then no event types are excluded.
  ///A matching type will be excluded even if it is listed in the 'types' filter.
  ///A ‘*’ can be used as a wildcard to match any sequence of characters.
  final List<String> notTypes;

  ///A list of room IDs to include.
  ///If this list is absent then all rooms are included.
  final List<String>? rooms;

  ///A list of senders IDs to include.
  ///If this list is absent then all senders are included.
  final List<String>? senders;

  ///A list of event types to include.
  ///If this list is absent then all event types are included.
  ///A '*' can be used as a wildcard to match any sequence of characters.
  final List<String>? types;

  const Filter({
    this.containsURL,
    this.includeRedundantMembers = false,
    this.lazyLoadMembers = false,
    this.limit = 150,
    this.notRooms = const <String>[],
    this.notSenders = const <String>[],
    this.notTypes = const <String>[],
    this.rooms,
    this.senders,
    this.types,
  });

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'include_redundant_members': includeRedundantMembers,
      'lazy_load_members': lazyLoadMembers,
      'limit': limit,
      'not_rooms': notRooms,
      'not_senders': notSenders,
      'not_types': notTypes,
    };
    if (containsURL != null) {
      result['contains_url'] = containsURL;
    }
    if (rooms != null) {
      result['rooms'] = rooms;
    }
    if (senders != null) {
      result['senders'] = senders;
    }
    if (types != null) {
      result['types'] = types;
    }
    return result;
  }

  @override
  String toString() => toJson().toString();
}

class Groupings {
  final List<String> keys;

  const Groupings({
    required this.keys,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupings': keys.map((e) => {"key": e}).toList(),
    };
  }

  @override
  String toString() => toJson().toString();
}
