import 'package:flutter/foundation.dart';
import 'package:matrix_sdk/matrix_sdk.dart';

MyUser merge(MergeIsolatedModel data) {
  try{
  return data.first.merge(data.second);

  }catch(e){
    // Log.setLogger(LoggerVariant.dev);
    // Log.writer.log("mergemergeERRERERERERE $e");
    rethrow;
  }
}

class MergeIsolatedModel {
  final MyUser first;
  final MyUser second;

  MergeIsolatedModel(this.first, this.second);
}

Future<MyUser> runComputeMerge(MyUser first, MyUser second) async {
  // print("computing f: $first,\n s: $second");
  try {
    // return merge( MergeIsolatedModel(first, second));
    return compute<MergeIsolatedModel, MyUser>(
        merge, MergeIsolatedModel(first, second),
        debugLabel: "runComputeMerge ${first.hashCode} ${second.hashCode}");
  } catch (e) {
    // Log.setLogger(LoggerVariant.dev);
    // Log.writer.log("MERGE_ERRROR $e");
    rethrow;
  }
}
