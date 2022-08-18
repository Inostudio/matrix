import '../message_event.dart';
import 'member_change_event.dart';

enum RoomEventRequestType {
  onlyMembersChange,
  onlyMessages,
  all,
}

extension RoomEventRequestTypeExtension on RoomEventRequestType {
  List<String> getEventLists() {
    switch (this) {
      case RoomEventRequestType.onlyMembersChange:
        return [MemberChangeEvent.matrixType];
      case RoomEventRequestType.onlyMessages:
        return [MessageEvent.matrixType];
      case RoomEventRequestType.all:
        return [];
    }
  }
}
