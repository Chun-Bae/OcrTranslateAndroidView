import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Example',
      theme: ThemeData.dark(),
      home: TakePictureScreen(camera: camera),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({super.key, required this.camera});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  bool isButton1On = false;
  bool isButton2On = false;
  bool isButton3On = false;
  bool isButton4On = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;
      await _uploadImage(image.path);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    final uri = Uri.parse('YOUR_SERVER_ENDPOINT');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final response = await request.send();
    if (response.statusCode == 200) {
      print('Image uploaded successfully!');
    } else {
      print('Failed to upload image.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('번역기!')),
      
      body: Column(
        children: <Widget>[
          Expanded(
            child: CameraPreview(_controller), 
          ),
          
          Container(
            padding: EdgeInsets.all(10), 
            color: Colors.black.withOpacity(0.7), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _toggleButton("영어", isButton1On,
                        () => setState(() => isButton1On = !isButton1On)),
                    SizedBox(height: 10),
                    _toggleButton("일본", isButton2On,
                        () => setState(() => isButton2On = !isButton2On)),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _toggleButton("중국어(간체)", isButton3On,
                        () => setState(() => isButton3On = !isButton3On)),
                    SizedBox(height: 10),
                    _toggleButton("중국어(번체)", isButton4On,
                        () => setState(() => isButton4On = !isButton4On)),
                  ],
                ),
                Container(
                  height: 50,
                  child: VerticalDivider(
                      color: Colors.white, thickness: 2, width: 20),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: FloatingActionButton(
                    onPressed: _takePicture,
                    child: Icon(Icons.camera_alt),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, bool isActive, VoidCallback onTap) {
    return Container(
      width: 120,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  Color.fromARGB(255, 222, 203, 255),
                  Color.fromARGB(255, 187, 151, 255)
                ]
              : [Colors.grey, Colors.grey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        
        child: Center(
          
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
