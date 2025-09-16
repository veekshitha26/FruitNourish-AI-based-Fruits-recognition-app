import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PredictionScreen extends StatefulWidget {
  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  String _prediction = "";
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _prediction = "";
      });
    }
  }

  Future<void> _predictImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _prediction = "";
    });

    try {
      var uri = Uri.parse('https://fruitnourish-ai-based-fruits-recognition.onrender.com/predict');
      String mimeType = _image!.path.endsWith('.png') ? 'png' : 'jpeg';

      var request = http.MultipartRequest('POST', uri);
      var file = await http.MultipartFile.fromPath(
        'file',
        _image!.path,
        contentType: MediaType('image', mimeType),
      );
      request.files.add(file);

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        final jsonData = json.decode(responseBody);

        String fruit = jsonData['fruit'];
        double confidence = (jsonData['confidence'] * 100);

        final Map<String, dynamic> nutrition = Map<String, dynamic>.from(jsonData['nutrition'] ?? {});
        final List<dynamic> benefits = List<dynamic>.from(jsonData['benefits'] ?? []);

        // Dynamically format nutrition info
        String nutritionText = nutrition.isEmpty
            ? 'No data available'
            : nutrition.entries.map((entry) => '• ${entry.key}: ${entry.value}').join('\n');

        // Format health benefits
        String benefitsText = benefits.isEmpty
            ? 'No data available'
            : benefits.map((b) => '• $b').join('\n');

        setState(() {
          _prediction = '''
Predicted Fruit: $fruit
Confidence: ${confidence.toStringAsFixed(2)}%

Nutrition per 100g:
$nutritionText

Health Benefits:
$benefitsText
''';
        });
      } else {
        var errorText = await response.stream.bytesToString();
        setState(() {
          _prediction = "Error ${response.statusCode}: $errorText";
        });
      }
    } catch (e) {
      setState(() {
        _prediction = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Know your fruit',style: TextStyle(
          color: Colors.white,
        ),),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/flat-lay-fruit-assortement-with-copy-space.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.white);
              },
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Upload or Capture a Fruit Image",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: Icon(Icons.photo, color: Colors.white),
                                  label: Text("Gallery", style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: Icon(Icons.camera_alt, color: Colors.white),
                                  label: Text("Camera", style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_image != null) ...[
                            SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                File(_image!.path),
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 15),
                            ElevatedButton.icon(
                              onPressed: _predictImage,
                              icon: Icon(Icons.search, color: Colors.white),
                              label: _isLoading
                                  ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text("Predict", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: Size(double.infinity, 50),
                              ),
                            ),
                          ],
                          if (_prediction.isNotEmpty) ...[
                            SizedBox(height: 30),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Text(
                                _prediction,
                                style: TextStyle(fontSize: 18, color: Colors.black87),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
