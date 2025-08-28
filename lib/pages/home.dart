import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slayschool_assesment/pages/solution.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  final Function saveQuestion;
  const Home({super.key, required this.saveQuestion});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _image;
  String _recognizedText = '';

  final header = {
    "Content-Type": "application/json",
    "app_id": "slayschoolassignment_04ce39_5fbf5c",
    "app_key":
        "API_KEY_HERE"
  };

  Future<void> _pickImage(ImageSource source) async {
    // Pick an image from the gallery or take a picture
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      _cropImage(pickedFile.path);
    } else {
      print('No image selected.');
    }
  }

  // Crop the image to the question
  Future<void> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          lockAspectRatio: false,
          toolbarTitle: 'Cropper',
          cropGridRowCount: 0,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _image = File(croppedFile.path);
      });
    } else {
      print('No image cropped.');
    }
  }

  // Recognize text in the image
  Future<void> _recognizeText(File image) async {
    final baseImage = await image.readAsBytes();
    final String base64Image = base64Encode(baseImage);
    final body = json.encode({
      'src': 'data:image/png;base64,$base64Image',
      'formats': ['text'],
    });

    final http.Response response = await http.post(
      Uri.parse('https://api.mathpix.com/v3/text'),
      headers: header,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        _recognizedText = data['text'];
      });
    } else {
      throw Exception('Failed to get math equation from image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Upload Image",
              style: TextStyle(fontSize: 25),
            ),
            const Text(
              "Make sure to only include 1 question in the image. You'll get an option to crop the image to the question later.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _image == null
                ? const Text('No image selected.')
                : Image.file(
                    _image!,
                    height: 300,
                  ),
            const SizedBox(height: 20),
            _image == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        child: Text('Pick Image from Gallery'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        child: Text('Take a Picture'),
                      )
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await _recognizeText(_image!);
                          widget.saveQuestion(_recognizedText);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return SolutionPage(question: _recognizedText);
                          }));
                        },
                        child: const Text('Process Image'),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _image = null;
                          });
                        },
                        child: const Text('Upload another image'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
