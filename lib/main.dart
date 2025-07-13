import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(RaceCamApp());
}

class RaceCamApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RaceCam',
      home: RaceHomePage(),
    );
  }
}

class RaceHomePage extends StatefulWidget {
  @override
  _RaceHomePageState createState() => _RaceHomePageState();
}

class _RaceHomePageState extends State<RaceHomePage> {
  late CameraController _cameraController;
  bool _isRecording = false;
  double _speed = 0.0;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startLocationTracking();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {});
  }

  void _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      setState(() {
        _speed = position.speed * 3.6;
      });
    });
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _cameraController.stopVideoRecording();
      _stopwatch.stop();
      _timer?.cancel();
    } else {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      _stopwatch.reset();
      _stopwatch.start();
      _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));
    }
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          Positioned(
            top: 40,
            left: 20,
            child: Text('Speed: ${_speed.toStringAsFixed(1)} km/h',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          Positioned(
            top: 70,
            left: 20,
            child: Text('Time: ${_stopwatch.elapsed.inSeconds}s',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleRecording,
        child: Icon(_isRecording ? Icons.stop : Icons.videocam),
      ),
    );
  }
}
