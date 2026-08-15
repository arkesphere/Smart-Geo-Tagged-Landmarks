import 'dart:io';

import 'package:sqflite/sqflite.dart';

import 'api.dart';
import 'database.dart';
import 'models.dart';


class DeletedLandmark {
  DeletedLandmark(this.id, this.title);

  final int id;
  final String title;
}


class LandmarkRepository {
  final LandmarkApi _api = LandmarkApi();

  // === LANDMARKS ===

  Future<List<Landmark>> cachedLandmarks() async {
    final db = await AppDatabase.open();
    final rows = await db.query(AppDatabase.landmarks, orderBy: 'score DESC');
    return rows.map(Landmark.fromDb).toList();
  }


  Future<List<Landmark>> refresh() async {
    final remote = await _api.getLandmarks();
    final db = await AppDatabase.open();
    await db.transaction((txn) async {
      await txn.delete(AppDatabase.landmarks);
      for (final landmark in remote) {
        await txn.insert(AppDatabase.landmarks, landmark.toDb());
      }
    });
    return remote;
  }

  Future<int> createLandmark({
    required String title,
    required double lat,
    required double lon,
    File? image,
  }) async {
    final id = await _api.createLandmark(
      title: title,
      lat: lat,
      lon: lon,
      image: image,
    );
    await refresh();
    return id;
  }

  Future<void> deleteLandmark(Landmark landmark) async {
    await _api.deleteLandmark(landmark.id);
    final db = await AppDatabase.open();
    await db.delete(AppDatabase.landmarks,
        where: 'id = ?', whereArgs: [landmark.id]);
    await db.insert(
      AppDatabase.deleted,
      {'id': landmark.id, 'title': landmark.title},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> restoreLandmark(int id) async {
    await _api.restoreLandmark(id);
    final db = await AppDatabase.open();
    await db.delete(AppDatabase.deleted, where: 'id = ?', whereArgs: [id]);
    await refresh();
  }

  Future<List<DeletedLandmark>> deletedLandmarks() async {
    final db = await AppDatabase.open();
    final rows = await db.query(AppDatabase.deleted);
    return rows
        .map((r) => DeletedLandmark(r['id']! as int, r['title']! as String))
        .toList();
  }




  Future<void> queueVisit(Landmark landmark, double lat, double lon) async {
    final db = await AppDatabase.open();
    await db.insert(AppDatabase.visits, {
      'landmark_id': landmark.id,
      'landmark_title': landmark.title,
      'user_lat': lat,
      'user_lon': lon,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'status': VisitStatus.queued.name,
      'attempts': 0,
    });
  }


  Future<List<VisitRecord>> visits() async {
    final db = await AppDatabase.open();
    final rows =
        await db.query(AppDatabase.visits, orderBy: 'created_at DESC');
    return rows.map(VisitRecord.fromDb).toList();
  }

  void dispose() => _api.close();
}
