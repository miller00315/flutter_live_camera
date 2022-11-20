import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

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
  late CameraController _cameraController;
  late ImageLabeler _imageLabeler;
  List<ImageLabel>? _labels;

  bool isProcessingImage = false;

  @override
  void initState() {
    super.initState();

    _cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.high,
    );

    ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.5);

    _imageLabeler = ImageLabeler(options: options);

    _labels = <ImageLabel>[];

    _cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      // Start to send camera image to function that will compute
      // the image label and set the [isProcessingImage] variable to true
      // remenber, arrow functions can execute more than one function
      _cameraController.startImageStream((image) => {
            if (isProcessingImage == false)
              {
                doImageLabeling(image),
                isProcessingImage = true,
              }
          });

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

    _cameraController.stopImageStream();

    _cameraController.dispose();

    _imageLabeler.close();
  }

  InputImage getInputImage(CameraImage img) {
    final WriteBuffer allBytes = WriteBuffer();

    for (final Plane plane in img.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(img.width.toDouble(), img.height.toDouble());

    final camera = _cameras[0];

    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);

    final inputImageFormat = InputImageFormatValue.fromRawValue(img.format.raw);

    final planeData = img.planes
        .map(
          (plane) => InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          ),
        )
        .toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation!,
      inputImageFormat: inputImageFormat!,
      planeData: planeData,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      inputImageData: inputImageData,
    );
  }

  doImageLabeling(CameraImage img) async {
    final InputImage inputImage = getInputImage(img);

    if (_labels?.isNotEmpty ?? false) _labels?.clear();

    final newLabels = await _imageLabeler.processImage(inputImage);

    setState(() {
      _labels = newLabels;
    });

    // set [isProcessingImage] to false,
    // releasing to next frame be processed
    isProcessingImage = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              width: 200,
              child: CameraPreview(
                _cameraController,
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (_labels?.isNotEmpty ?? false)
                    ..._labels!
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${e.label}, ${e.index}, ${e.confidence.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        )
                        .toList()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
