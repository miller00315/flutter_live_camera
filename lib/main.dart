import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

late List<CameraDescription> _cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController cameraController;

  @override
  void initState() {
    super.initState();

    cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.high,
    );

    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera');
            break;
          default:
            print('Another error');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraPreview(
        cameraController,
      ),
    );
  }
}
