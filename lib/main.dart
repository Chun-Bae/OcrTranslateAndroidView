import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(),
    ),
  );
}

class TakePictureScreen extends StatefulWidget {
  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isUploading = false;
  Timer? _timer;

  bool isButton1On = false;
  bool isButton2On = false;
  bool isButton3On = false;
  bool isButton4On = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploading) {
      print('An upload is already in progress, please wait.');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _image = image;
        });

        _uploadImage(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to pick image: $e'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebviewPage(),
      ),
    );
    print("Uploading image from path: $imagePath");
    setState(() {
      _isUploading = true;
    });

    final uri = Uri.parse('http://118.32.168.245:22222/upload/');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imagePath));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print('Image uploaded successfully!');
      } else {
        print('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred during image upload: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('번역기')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _image == null
                ? Center(child: Text('이미지를 선택하세요.'))
                : Image.file(File(_image!.path)),
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
                  child: Column(
                    children: [
                      FloatingActionButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        heroTag: 'camera',
                        child: Icon(Icons.camera_alt),
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        heroTag: 'gallery',
                        child: Icon(Icons.photo),
                      ),
                    ],
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

class WebviewPage extends StatefulWidget {
  const WebviewPage({super.key});

  @override
  State<WebviewPage> createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage> {
  late final WebViewController _controller;
  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('http://118.32.168.245:3000/loading')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('http://118.32.168.245:3000/loading'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(
          controller: _controller,
        ),
      ),
    );
  }
}
