import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/notification_service.dart';

class PTCreateChallengeScreen extends StatefulWidget {
  const PTCreateChallengeScreen({super.key});

  @override
  State<PTCreateChallengeScreen> createState() => _PTCreateChallengeScreenState();
}

class _PTCreateChallengeScreenState extends State<PTCreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _title = "";
  String _description = "";
  String _imageUrl = "https://cdn-icons-png.flaticon.com/512/2964/2964514.png";
  String _difficulty = "Bình thường";
  
  double _hours = 2; // Dành cho Bình thường và Khó
  DateTime? _customEndTime; // Dành cho Rất khó
  bool _isUploading = false;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    if (_selectedImage == null) return _imageUrl;

    try {
      var uri = Uri.parse('https://api.cloudinary.com/v1_1/dkjq5ojmn/image/upload');
      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = 'challenge_video_upload'; // Có thể dùng chung preset
      request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      }
    } catch (e) {
      debugPrint("Lỗi upload ảnh: $e");
    }
    return null;
  }

  Future<void> _createChallenge() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() { _isUploading = true; });

      try {
        String? finalImageUrl = await _uploadImageToCloudinary();
        if (finalImageUrl == null) {
          throw Exception("Không thể tải ảnh lên. Vui lòng thử lại.");
        }

        DateTime now = DateTime.now();
        DateTime endTime;

        if (_difficulty == "Rất khó" && _customEndTime != null) {
          endTime = _customEndTime!;
        } else {
          endTime = now.add(Duration(hours: _hours.toInt(), minutes: ((_hours - _hours.toInt()) * 60).toInt()));
        }

        // Tính điểm cơ bản
        int basePoints = 50;
        if (_difficulty == "Khó") basePoints += 5;
        if (_difficulty == "Rất khó") basePoints += 10;

        await FirebaseFirestore.instance.collection('challenges').add({
          'title': _title,
          'description': _description,
          'imageUrl': finalImageUrl,
          'points': basePoints,
          'creatorId': user.uid,
          'difficulty': _difficulty,
          'startTime': Timestamp.fromDate(now),
          'endTime': Timestamp.fromDate(endTime),
          'rating': 0.0,
          'ratingCount': 0,
        });

        // Tăng đếm số thử thách của PT
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'challengeCount': FieldValue.increment(1),
        });

        // Lập lịch nhắc nhở PT khi thử thách kết thúc
        await NotificationService().scheduleChallengeEndNotification(_title, endTime);

        if (mounted) {
          setState(() { _isUploading = false; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo thử thách thành công!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() { _isUploading = false; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _pickCustomTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _customEndTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  Widget _buildTextField(String label, IconData icon, Function(String?) onSave, {int maxLines = 1}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade600, width: 2)),
      ),
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? "Không được để trống" : null,
      onSaved: onSave,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _difficulty,
      decoration: InputDecoration(
        labelText: "Độ khó",
        prefixIcon: Icon(Icons.bar_chart, color: Colors.green.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.green.shade600, width: 2)),
      ),
      items: ["Bình thường", "Khó", "Rất khó"].map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _difficulty = newValue!;
          if (_difficulty == "Bình thường") _hours = 2;
          else if (_difficulty == "Khó") _hours = 8;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Tạo Thử Thách", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTextField("Tên thử thách", Icons.title, (val) => _title = val!),
              const SizedBox(height: 16),
              _buildTextField("Mô tả chi tiết", Icons.description, (val) => _description = val!, maxLines: 3),
              const SizedBox(height: 16),
              
              // KHU VỰC CHỌN ẢNH
              const Text("Ảnh đại diện thử thách", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade600, style: BorderStyle.solid, width: 1.5),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.green.shade400),
                            const SizedBox(height: 8),
                            Text("Bấm để tải ảnh từ thư viện", style: TextStyle(color: Colors.green.shade700)),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              const Text("Độ khó", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildDropdown(),
              const SizedBox(height: 24),
              
              if (_difficulty == "Bình thường") ...[
                Text("Thời hạn: ${_hours.toStringAsFixed(1)} giờ", style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _hours,
                  min: 0.5,
                  max: 5.0,
                  divisions: 9,
                  label: _hours.toStringAsFixed(1),
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => _hours = val),
                ),
              ] else if (_difficulty == "Khó") ...[
                Text("Thời hạn: ${_hours.toStringAsFixed(1)} giờ", style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _hours,
                  min: 6.0,
                  max: 12.0,
                  divisions: 12,
                  label: _hours.toStringAsFixed(1),
                  activeColor: Colors.orange,
                  onChanged: (val) => setState(() => _hours = val),
                ),
              ] else ...[
                const Text("Thời hạn: Do PT tự định đoạt", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green.shade600),
                    foregroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _pickCustomTime, 
                  icon: const Icon(Icons.calendar_month),
                  label: Text(_customEndTime == null 
                    ? "Chọn Thời Gian Kết Thúc" 
                    : "Hạn chót: ${_customEndTime!.day}/${_customEndTime!.month} - ${_customEndTime!.hour}:${_customEndTime!.minute}"),
                ),
                if (_customEndTime == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text("Vui lòng chọn thời gian", style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
              ],
              
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50), 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: Colors.green.withOpacity(0.5),
                ),
                onPressed: () {
                  if (_difficulty == "Rất khó" && _customEndTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn thời hạn!'), backgroundColor: Colors.red));
                    return;
                  }
                  _createChallenge();
                },
                label: const Text("TẠO THỬ THÁCH", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
    );
  }
}
