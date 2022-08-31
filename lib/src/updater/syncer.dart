import 'package:async/async.dart';
import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:matrix_sdk/src/model/sync_token.dart';

import '../util/logger.dart';

class Syncer {
  final Updater _updater;

  Homeserver get _homeserver => _updater.homeServer;

  MyUser get _user => _updater.user;

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Syncer(this._updater);

  Future<void>? _syncFuture;
  CancelableOperation<Map<String, dynamic>>? _cancelableSyncOnceResponse;

  String? _syncToken;
  String? _syncOnceToken;

  /// Syncs data with the user's [_homeserver].
  void start({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
    String? syncToken,
  }) {
    if (_user.isLoggedOut ?? false) {
      throw StateError('The user can not be logged out');
    }

    if (_syncFuture != null) {
      return;
    }
    _syncToken = syncToken;

    _syncFuture = _startSync(
      maxRetryAfter: maxRetryAfter,
      timelineLimit: timelineLimit,
    );
  }

  bool _shouldStopSync = false;

  Future<void> _startSync({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
  }) async {
    try {
      _shouldStopSync = false;
      _isSyncing = true;

      // This var is used to implements exponential backoff
      // until it reaches maxRetryAfter
      var retryAfter = 1000;

      while (!_shouldStopSync) {
        final body = await _sync(
          timeout: Duration(seconds: 10),
          timelineLimit: timelineLimit,
          syncToken: _syncToken,
        );

        if (_shouldStopSync) {
          return;
        }

        if (body == null) {
          await Future.delayed(Duration(milliseconds: retryAfter));

          // ignore: invariant_booleans
          if (_shouldStopSync) {
            return;
          }

          retryAfter = (retryAfter * 1.5).floor();
          if (retryAfter > maxRetryAfter.inMilliseconds) {
            retryAfter = maxRetryAfter.inMilliseconds;
          }
        } else {
          // on sync once was triggered - start syncing from syncOnceToken
          if (_syncOnceToken != null && _syncOnceToken!.isNotEmpty) {
            _syncToken = _syncOnceToken;
            _syncOnceToken = null;
          }
          //standard sync token incrementing
          else {
            _syncToken = body['next_batch'];
          }
          await _updater.processSync(body);

          // Reset exponential backoff.
          retryAfter = 1000;

          await Future.delayed(Duration(milliseconds: retryAfter));
        }
      }
    } catch (e) {
      Log.writer.log(e);
      print("Sync Error :$e");
      await Future.delayed(Duration(seconds: 5));
      start(
        maxRetryAfter: maxRetryAfter,
        timelineLimit: timelineLimit,
        syncToken: _syncToken,
      );
    }
  }

  Future<Map<String, dynamic>?> _sync({
    timeout = Duration.zero,
    int timelineLimit = 30,
    bool fullState = false,
    String? syncToken,
  }) async {
    if (_user.isLoggedOut ?? false) {
      throw StateError('The user can not be logged out');
    }

    if (_shouldStopSync) {
      return null;
    }

    try {
      final cancelable = CancelableOperation.fromFuture(
        _homeserver.api.sync(
          accessToken: _user.accessToken ?? '',
          since: syncToken ?? _user.syncToken ?? '',
          fullState: fullState,
          filter: {
            'room': {
              'state': {
                'lazy_load_members': true,
              },
              'timeline': {
                'limit': timelineLimit,
              },
            },
          },
          timeout: timeout.inMilliseconds,
        ),
      );

      _cancelableSyncOnceResponse = cancelable;

      final body = await cancelable.valueOrCancellation();

      // We're cancelled
      if (body == null) {
        return null;
      }

      if (_shouldStopSync == true) {
        return null;
      }

      return body;
    } on Exception catch (e) {
      Log.writer.log(e);
      _updater.inError.add(ErrorWithStackTraceString(
        e.toString(),
        StackTrace.current.toString(),
      ));

      return null;
    }
  }

  Future<SyncToken?> runSyncOnce({
    required SyncFilter filter,
  }) async {
    if (_user.isLoggedOut ?? false) {
      throw StateError('The user can not be logged out');
    }

    if (_shouldStopSync) {
      return null;
    }

    try {
      final cancelable = CancelableOperation.fromFuture(
        _homeserver.api.sync(
          accessToken: _user.accessToken ?? '',
          since: filter.syncToken,
          fullState: filter.fullState,
          filter: filter.toMap(),
          timeout: 0,
        ),
      );

      _cancelableSyncOnceResponse = cancelable;
      final body = await cancelable.valueOrCancellation();

      // We're cancelled
      if (body == null) {
        return null;
      }

      if (_shouldStopSync == true) {
        return null;
      }

      _syncOnceToken = body['next_batch'];
      await _updater.processSync(body);
      return SyncToken(body['next_batch']);
    } catch (error) {
      if (error is MatrixException) {
        final statusCode = error.body["status_code"];
        if (statusCode is int && statusCode >= 500) {
          return Future.delayed(const Duration(milliseconds: 500),
              () => runSyncOnce(filter: filter));
        }
      } else {
        _updater.inError.add(ErrorWithStackTraceString(
          error.toString(),
          StackTrace.current.toString(),
        ));
      }
    }
    return null;
  }

  Future<void> stop() async {
    _shouldStopSync = true;
    await _cancelableSyncOnceResponse?.cancel();
    await _syncFuture;
    _isSyncing = false;
  }
}
