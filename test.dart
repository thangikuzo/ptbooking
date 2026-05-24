import 'dart:io'; 
import 'dart:typed_data';
void main() { 
  final b = File('assets/frame_chat/chatborder.png').readAsBytesSync(); 
  print('Size: ${b.length} bytes');
}
