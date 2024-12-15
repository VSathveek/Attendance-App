import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/excel_service.dart';
import 'file_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExcelService excelService = ExcelService();
  List<String> uploadedFiles = [];

  @override
  void initState() {
    super.initState();
    loadStoredFiles();
  }

  Future<void> loadStoredFiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      uploadedFiles = prefs.getKeys().toList();
    });
  }

  Future<void> pickExcelFile() async {
    try {
      if (kIsWeb) {
        final input = html.FileUploadInputElement()..accept = '.xlsx';
        input.click();

        input.onChange.listen((event) async {
          final file = input.files?.first;
          if (file != null) {
            final reader = html.FileReader();
            reader.readAsArrayBuffer(file);

            reader.onLoadEnd.listen((event) async {
              final fileBytes = reader.result as Uint8List;
              await excelService.loadFile(file.name, fileBytes);
              setState(() {
                uploadedFiles.add(file.name);
              });
            });
          }
        });
      } else {
        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
        if (result != null) {
          final fileBytes = result.files.single.bytes;
          final fileName = result.files.single.name;
          if (fileBytes != null) {
            await excelService.loadFile(fileName, fileBytes);
            setState(() {
              uploadedFiles.add(fileName);
            });
          }
        }
      }
    } catch (e) {
      print("Error picking file: $e");
    }
  }

  Future<void> removeFile(String fileName) async {
    // Remove the file data from local storage
    await excelService.removeFile(fileName);
    setState(() {
      uploadedFiles.remove(fileName);
    });
  }

  void openFileDetail(String fileName) async {
    await excelService.loadFromLocalStorage(fileName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileDetailScreen(fileName: fileName, excelService: excelService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
      ),
      body: ListView(
        children: uploadedFiles.map((fileName) {
          return ListTile(
            title: Text(fileName),
            onTap: () => openFileDetail(fileName),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => removeFile(fileName),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickExcelFile,
        child: const Icon(Icons.upload),
      ),
    );
  }
}
