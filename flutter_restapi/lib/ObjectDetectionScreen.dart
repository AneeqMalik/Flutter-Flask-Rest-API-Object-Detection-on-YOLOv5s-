import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class BoundingBox {
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;
  final double confidence;
  final String name;

  BoundingBox({
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
    required this.confidence,
    required this.name,
  });
}

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late List<BoundingBox> _boundingBoxes = [];
  File? _image;
  final picker = ImagePicker();

  Future<List<BoundingBox>> detectObjects(File image) async {
    final url =
        "https://flask-restapi-yolov5s.azurewebsites.net/v1/object-detection/yolov5";
    final request = await http.MultipartRequest("POST", Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath("image", image.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final jsonStr = await response.stream.bytesToString();
      final jsonResponse = json.decode(jsonStr);
      print(jsonResponse);
      return List<BoundingBox>.from(jsonResponse.map((bbox) => BoundingBox(
            xMin: bbox["xmin"],
            yMin: bbox["ymin"],
            xMax: bbox["xmax"],
            yMax: bbox["ymax"],
            confidence: bbox["confidence"],
            name: bbox["name"],
          )));
    } else {
      throw Exception('Failed to detect objects');
    }
  }

  Future<void> getImage(ImageSource source) async {
    final pickedFile =
        await picker.pickImage(source: source, maxWidth: 340, maxHeight: 340);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      final bboxes = await detectObjects(_image!);
      setState(() {
        _boundingBoxes = bboxes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Object Detection Using Flask Rest Api'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _image == null
                    ? const Text('No image selected.')
                    : Stack(
                        children: [
                          Image.file(_image!),
                          ..._boundingBoxes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final bbox = entry.value;
                            final xMin = bbox.xMin;
                            final yMin = bbox.yMin;
                            final xMax = bbox.xMax;
                            final yMax = bbox.yMax;
                            final confidence = bbox.confidence;
                            final name = bbox.name;

                            final left = xMin;
                            final top = yMin;
                            final width = xMax - xMin;
                            final height = yMax - yMin;

                            Color color;
                            if (index % 3 == 0) {
                              color = Colors.green;
                            } else if (index % 3 == 1) {
                              color = Colors.yellow;
                            } else {
                              color = Colors.red;
                            }

                            return Positioned(
                              left: left,
                              top: top,
                              width: width,
                              height: height,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: color,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "$name ${(confidence * 100).toStringAsFixed(0)}%",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                ElevatedButton(
                  onPressed: () => getImage(ImageSource.camera),
                  child: const Text("Take a Picture"),
                ),
                ElevatedButton(
                  onPressed: () => getImage(ImageSource.gallery),
                  child: const Text("Choose from Gallery"),
                ),
              ],
            ),
          ),
        ));
  }
}
