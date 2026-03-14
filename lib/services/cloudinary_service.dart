import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const cloudName = "duhxd8nte";
  static const uploadPreset = "pt_booking";

  static Future<String?> uploadImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) return null;

      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", file.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final res = await response.stream.bytesToString();

        final imageUrl = RegExp(r'"secure_url":"(.*?)"')
            .firstMatch(res)
            ?.group(1)
            ?.replaceAll(r'\/', '/');

        return imageUrl;
      }

      return null;
    } catch (e) {
      print("Upload lỗi: $e");
      return null;
    }
  }
}