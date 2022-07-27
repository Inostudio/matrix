import 'package:flutter/foundation.dart';
import 'package:matrix_sdk/matrix_sdk.dart';

MyUser merge(MergeIsolatedModel data) {
  return data.first.merge(data.second);
}

class MergeIsolatedModel {
  final MyUser first;
  final MyUser second;

  MergeIsolatedModel(this.first, this.second);
}

Future<MyUser> runComputeMerge(MyUser first, MyUser second) async {
  return compute<MergeIsolatedModel, MyUser>(
    merge,
    MergeIsolatedModel(first, second),
  );
}
