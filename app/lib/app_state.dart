import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'api.dart';
import 'background_sync.dart';
import 'models.dart';
import 'repository.dart';


Future<Position> getCurrentLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw AppException('Location is turned off. Enable GPS and try again.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw AppException('Location permission denied.');
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  } on Exception {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return last;
    throw AppException('Could not get a GPS fix.');
  }
}

class AppState extends ChangeNotifier {
  final LandmarkRepository _repo = LandmarkRepository();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription? _connectivitySub;
  Timer? _watcher;

  List<Landmark> landmarks = [];
  List<VisitRecord> visits = [];
  List<DeletedLandmark> deleted = [];

  bool loading = true;
  bool online = true;
  String? error;


  int tab = 0;


  final MapController mapController = MapController();


  Landmark? focused;

  void setTab(int value) {
    tab = value;
    notifyListeners();
  }

  void showOnMap(Landmark landmark) {
    focused = landmark;
    tab = 0;
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        mapController.move(LatLng(landmark.lat, landmark.lon), 17);
      } on Exception {

      }
    });
  }


  bool sortHighToLow = true;
  double? minScore;

  /// The list the Landmarks tab shows.
  List<Landmark> get visibleLandmarks {
    var list = landmarks;
    if (minScore != null) {
      list = list.where((l) => l.score >= minScore!).toList();
    } else {
      list = List.of(list);
    }
    list.sort((a, b) =>
        sortHighToLow ? b.score.compareTo(a.score) : a.score.compareTo(b.score));
    return list;
  }

  /// Lowest and highest score in the cache, used to colour the map markers
  /// against the real data instead of an assumed 0-100 range.
  double get lowestScore =>
      landmarks.isEmpty ? 0 : landmarks.map((l) => l.score).reduce((a, b) => a < b ? a : b);

  double get highestScore =>
      landmarks.isEmpty ? 0 : landmarks.map((l) => l.score).reduce((a, b) => a > b ? a : b);

  int get unfinishedVisits => visits.where((v) => !v.isFinished).length;

  /// Called once at startup.
  Future<void> start() async {
    await loadFromCache(); // show cached data before touching the network
    loading = false;
    notifyListeners();

    online = _isOnline(await _connectivity.checkConnectivity());
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    await BackgroundSync.schedulePeriodicSync();
    await BackgroundSync.requestSync();

    if (online) await refresh();
  }

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOffline = !online;
    online = _isOnline(results);
    notifyListeners();

    // Requirement 8: sync the queue as soon as the internet comes back.
    if (online && wasOffline) {
      BackgroundSync.requestSync();
      refresh();
    }
  }

  /// Local read. Cheap, works offline.
  Future<void> loadFromCache() async {
    landmarks = await _repo.cachedLandmarks();
    visits = await _repo.visits();
    deleted = await _repo.deletedLandmarks();
    notifyListeners();
    _watchForBackgroundResults();
  }

  /// While a visit is unfinished, re-read the database every 3 seconds so the
  /// distance written by the background isolate shows up on its own.
  /// This is a local database read, not network polling.
  void _watchForBackgroundResults() {
    if (visits.every((v) => v.isFinished)) {
      _watcher?.cancel();
      _watcher = null;
      return;
    }
    _watcher ??= Timer.periodic(const Duration(seconds: 3), (timer) async {
      visits = await _repo.visits();
      landmarks = await _repo.cachedLandmarks();
      notifyListeners();
      if (visits.every((v) => v.isFinished)) {
        timer.cancel();
        _watcher = null;
      }
    });
  }

  /// Pull to refresh. Never throws - failures keep the cached data on screen.
  Future<void> refresh() async {
    error = null;
    try {
      landmarks = await _repo.refresh();
    } on AppException catch (e) {
      error = e.message;
      landmarks = await _repo.cachedLandmarks();
    }
    visits = await _repo.visits();
    deleted = await _repo.deletedLandmarks();
    notifyListeners();
  }

  void setSort(bool highToLow) {
    sortHighToLow = highToLow;
    notifyListeners();
  }

  void setMinScore(double? value) {
    minScore = value;
    notifyListeners();
  }

  /// Requirement 3: save the visit, then let WorkManager do the rest.
  Future<void> visitLandmark(Landmark landmark, double lat, double lon) async {
    await _repo.queueVisit(landmark, lat, lon);
    await BackgroundSync.requestSync();
    await loadFromCache();
  }

  Future<int> createLandmark({
    required String title,
    required double lat,
    required double lon,
    File? image,
  }) async {
    final id = await _repo.createLandmark(
        title: title, lat: lat, lon: lon, image: image);
    await loadFromCache();
    return id;
  }

  Future<void> deleteLandmark(Landmark landmark) async {
    await _repo.deleteLandmark(landmark);
    await loadFromCache();
  }

  Future<void> restoreLandmark(int id) async {
    await _repo.restoreLandmark(id);
    await loadFromCache();
  }

  @override
  void dispose() {
    mapController.dispose();
    _watcher?.cancel();
    _connectivitySub?.cancel();
    _repo.dispose();
    super.dispose();
  }
}
