import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

import 'api.dart';
import 'database.dart';
import 'models.dart';


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Needed before using plugins (sqflite) from this isolate.
    WidgetsFlutterBinding.ensureInitialized();

    return syncVisits();
  });
}

class BackgroundSync {
  static const String taskName = 'sync_visits';
  static const String tag = 'sync';


  static final Constraints _online =
      Constraints(networkType: NetworkType.connected);

  static Future<void> initialize() =>
      Workmanager().initialize(callbackDispatcher);


  static Future<void> requestSync() => Workmanager().registerOneOffTask(
        'sync-${DateTime.now().microsecondsSinceEpoch}',
        taskName,
        tag: tag,
        constraints: _online,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(seconds: 15),
      );


  static Future<void> schedulePeriodicSync() =>
      Workmanager().registerPeriodicTask(
        'sync-periodic',
        taskName,
        tag: tag,
        frequency: const Duration(minutes: 15),
        constraints: _online,
      );
}


const int _maxAttempts = 25;


Future<bool> syncVisits() async {
  final db = await AppDatabase.open();
  final api = LandmarkApi();
  bool allDone = true;

  try {
    // === STEP 1: send every visit that is still queued ===
    // This is what empties the offline queue.
    final queued = await db.query(
      AppDatabase.visits,
      where: 'status = ?',
      whereArgs: [VisitStatus.queued.name],
    );

    for (final row in queued) {
      final visit = VisitRecord.fromDb(row);
      try {
        final jobId = await api.visitLandmark(
          visit.landmarkId,
          visit.userLat,
          visit.userLon,
        );
        await _update(db, visit.localId, {
          'status': VisitStatus.pending.name,
          'job_id': jobId,
          'attempts': visit.attempts + 1,
        });
        allDone = false; // accepted, but no distance yet
      } on AppException catch (e) {
        if (e.isPermanent) {
          await _fail(db, visit, e.message);
        } else {
          allDone = false;
          await _update(db, visit.localId, {'attempts': visit.attempts + 1});
        }
      }
    }


    // === STEP 2: check every job that is still pending ===
    // This is the polling: ask the server if the job is done yet.
    final pending = await db.query(
      AppDatabase.visits,
      where: 'status = ? AND job_id IS NOT NULL',
      whereArgs: [VisitStatus.pending.name],
    );

    for (final row in pending) {
      final visit = VisitRecord.fromDb(row);
      try {
        final job = await api.getJobStatus(visit.jobId!);

        if (job.status == 'done') {
          await _update(db, visit.localId, {
            'status': VisitStatus.done.name,
            'distance': job.distance,
            'attempts': visit.attempts + 1,
          });
        } else if (job.status == 'failed') {
          await _fail(db, visit, 'The server could not process this visit.');
        } else if (visit.attempts + 1 >= _maxAttempts) {
          await _fail(db, visit, 'Gave up waiting for the server.');
        } else {
          allDone = false; // still pending - come back later
          await _update(db, visit.localId, {'attempts': visit.attempts + 1});
        }
      } on AppException catch (e) {
        if (e.isPermanent) {
          await _fail(db, visit, e.message);
        } else {
          allDone = false;
          await _update(db, visit.localId, {'attempts': visit.attempts + 1});
        }
      }
    }


    // === STEP 3: refresh the landmark cache while we are online ===
    try {
      final remote = await api.getLandmarks();
      await db.transaction((txn) async {
        await txn.delete(AppDatabase.landmarks);
        for (final landmark in remote) {
          await txn.insert(AppDatabase.landmarks, landmark.toDb());
        }
      });
    } on AppException {
      // Not important enough to fail the visit work.
    }
  } finally {
    api.close();
  }

  // true  = nothing left to do.
  // false = WorkManager runs this again later, with a longer delay
  //         each time. That retry is the polling loop.
  return allDone;
}

Future<void> _update(Database db, int localId, Map<String, Object?> values) =>
    db.update(AppDatabase.visits, values,
        where: 'local_id = ?', whereArgs: [localId]);

Future<void> _fail(Database db, VisitRecord visit, String reason) =>
    _update(db, visit.localId, {
      'status': VisitStatus.failed.name,
      'error': reason,
      'attempts': visit.attempts + 1,
    });
