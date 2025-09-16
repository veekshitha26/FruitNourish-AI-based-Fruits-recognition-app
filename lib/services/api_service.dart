import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://fruitnourish-ai-based-fruits-recognition.onrender.com/prediction';

  static Future<Map<String, dynamic>?> predictFruit(File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();
      print("Status code: ${response.statusCode}");

      var responseData = await response.stream.bytesToString();
      print("Response body: $responseData");

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

}
