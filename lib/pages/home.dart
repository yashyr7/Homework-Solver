import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
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

  // Format the recognized text by eliminating extra spaces and new lines
  Future<String> formatText(String text) async {
    // Replace multiple new lines with a single new line
    String formattedText = text.replaceAll(RegExp(r'\s+'), ' ');

    // Trim leading and trailing whitespace
    formattedText = formattedText.trim();

    return formattedText;
  }

  // Recognize text in the image
  Future<void> _recognizeText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textDetector = TextRecognizer();
    final RecognizedText recognisedText =
        await textDetector.processImage(inputImage);
    final cleanQuestion = await formatText(recognisedText.text);

    setState(() {
      _recognizedText = cleanQuestion;
    });
    print(_recognizedText);
    // Close the text detector to release resources
    textDetector.close();
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
                : Image.file(_image!),
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
