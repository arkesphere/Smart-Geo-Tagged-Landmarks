
class Landmark {
  Landmark({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    required this.image,
    required this.visitCount,
    required this.avgDistance,
    required this.score,
  });

  final int id;
  final String title;
  final double lat;
  final double lon;
  final String image;
  final int visitCount;
  final double avgDistance;
  final double score;


  String? get imageUrl =>
      image.trim().isEmpty ? null : 'https://labs.anontech.info/cse489/exm3/$image';


  bool get isPlottable => lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;

  factory Landmark.fromJson(Map<String, dynamic> j) => Landmark(
        id: _int(j['id']),
        title: (j['title']?.toString().trim().isNotEmpty ?? false)
            ? j['title'].toString().trim()
            : 'Untitled',
        lat: _double(j['lat']),
        lon: _double(j['lon']),
        image: j['image']?.toString() ?? '',
        visitCount: _int(j['visit_count']),
        avgDistance: _double(j['avg_distance']),
        score: _double(j['score']),
      );

  factory Landmark.fromDb(Map<String, Object?> r) => Landmark(
        id: r['id']! as int,
        title: r['title'] as String? ?? 'Untitled',
        lat: _double(r['lat']),
        lon: _double(r['lon']),
        image: r['image'] as String? ?? '',
        visitCount: _int(r['visit_count']),
        avgDistance: _double(r['avg_distance']),
        score: _double(r['score']),
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'title': title,
        'lat': lat,
        'lon': lon,
        'image': image,
        'visit_count': visitCount,
        'avg_distance': avgDistance,
        'score': score,
      };

  // The API sends numbers as int or double depending on the row.
  static int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  static double _double(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
}


enum VisitStatus { queued, pending, done, failed }

class VisitRecord {
  VisitRecord({
    required this.localId,
    required this.landmarkId,
    required this.landmarkTitle,
    required this.userLat,
    required this.userLon,
    required this.createdAt,
    required this.status,
    this.jobId,
    this.distance,
    this.error,
    this.attempts = 0,
  });

  final int localId;
  final int landmarkId;
  final String landmarkTitle;
  final double userLat;
  final double userLon;
  final DateTime createdAt;
  final VisitStatus status;
  final int? jobId;
  final double? distance;
  final String? error;
  final int attempts;

  bool get isFinished =>
      status == VisitStatus.done || status == VisitStatus.failed;

  factory VisitRecord.fromDb(Map<String, Object?> r) => VisitRecord(
        localId: r['local_id']! as int,
        landmarkId: r['landmark_id']! as int,
        landmarkTitle: r['landmark_title'] as String? ?? 'Landmark',
        userLat: (r['user_lat'] as num? ?? 0).toDouble(),
        userLon: (r['user_lon'] as num? ?? 0).toDouble(),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int? ?? 0),
        status: VisitStatus.values.firstWhere(
          (s) => s.name == r['status'],
          orElse: () => VisitStatus.queued,
        ),
        jobId: r['job_id'] as int?,
        distance: (r['distance'] as num?)?.toDouble(),
        error: r['error'] as String?,
        attempts: r['attempts'] as int? ?? 0,
      );
}
