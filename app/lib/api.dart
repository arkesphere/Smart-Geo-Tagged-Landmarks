import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';


class AppException implements Exception {
  AppException(this.message, {this.statusCode = 0});

  final String message;
  final int statusCode;

  bool get isPermanent => statusCode >= 400 && statusCode < 500;

  @override
  String toString() => message;
}

class JobStatus {
  JobStatus(this.status, this.distance);

  final String status; // pending | done | failed
  final double? distance;
}


class LandmarkApi {
  static const String key = '22201670';
  static const String base = 'https://labs.anontech.info/cse489/exm3/api.php';

  final http.Client _client = http.Client();

  Uri _url(String action, [Map<String, String> extra = const {}]) =>
      Uri.parse(base).replace(
        queryParameters: {'action': action, 'key': key, ...extra},
      );


  Future<List<Landmark>> getLandmarks() async {
    final body = await _send(() => _client.get(_url('get_landmarks')));
    if (body is! List) throw AppException('Expected a list of landmarks.');
    return body
        .whereType<Map<String, dynamic>>()
        .map(Landmark.fromJson)
        .toList();
  }


  Future<int> visitLandmark(int landmarkId, double lat, double lon) async {
    final body = await _send(
      () => _client.post(
        _url('visit_landmark'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'landmark_id': landmarkId,
          'user_lat': lat,
          'user_lon': lon,
        }),
      ),
    );
    if (body is! Map || body['job_id'] == null) {
      throw AppException('No job_id in the response.');
    }
    return (body['job_id'] as num).toInt();
  }

  Future<JobStatus> getJobStatus(int jobId) async {
    final body =
        await _send(() => _client.get(_url('get_job_status', {'job_id': '$jobId'})));
    if (body is! Map) throw AppException('Bad job status response.');
    return JobStatus(
      body['status']?.toString() ?? 'pending',
      (body['distance'] as num?)?.toDouble(),
    );
  }


  Future<int> createLandmark({
    required String title,
    required double lat,
    required double lon,
    File? image,
  }) async {
    final request = http.MultipartRequest('POST', _url('create_landmark'))
      ..fields['title'] = title
      ..fields['lat'] = '$lat'
      ..fields['lon'] = '$lon';

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final body = await _send(() async {
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    });

    if (body is! Map || body['id'] == null) {
      throw AppException('No id in the response.');
    }
    return int.parse(body['id'].toString());
  }


  Future<void> deleteLandmark(int id) async {
    await _send(() => _client.post(_url('delete_landmark'), body: {'id': '$id'}));
  }


  Future<void> restoreLandmark(int id) async {
    await _send(() => _client.post(_url('restore_landmark'), body: {'id': '$id'}));
  }


  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 20));
    } on SocketException {
      throw AppException('No internet connection.');
    } on TimeoutException {
      throw AppException('The server took too long to respond.');
    } on http.ClientException {
      throw AppException('The connection was interrupted.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return {};
      return jsonDecode(response.body);
    }

    if (response.statusCode == 403) {
      throw AppException(
        'API key rejected (invalid_or_expired_key).',
        statusCode: 403,
      );
    }
    if (response.statusCode == 404) {
      throw AppException('Not found on the server.', statusCode: 404);
    }
    throw AppException(
      'Request failed (HTTP ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  void close() => _client.close();
}
