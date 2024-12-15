import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/excel_service.dart';

class FileDetailScreen extends StatefulWidget {
  final String fileName;
  final ExcelService excelService;

  const FileDetailScreen({required this.fileName, required this.excelService, Key? key}) : super(key: key);

  @override
  _FileDetailScreenState createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  String currentDate = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() {
    // Load data for selected file and date
    final attendanceByDate = widget.excelService.studentRecords[widget.fileName] ?? {};
    if (attendanceByDate[currentDate] == null) {
      widget.excelService.studentRecords[widget.fileName]![currentDate] = attendanceByDate['default'] ?? [];
    }
  }

  void recordAttendance(String date, int index, bool isPresent) {
    final studentsForDate = widget.excelService.studentRecords[widget.fileName]?[date] ?? [];
    if (index < studentsForDate.length) {
      studentsForDate[index].setAttendance(date, isPresent);
      widget.excelService.saveLocally(widget.fileName, widget.excelService.studentRecords[widget.fileName]!);
    }
  }

  Future<void> downloadFile() async {
    final fileBytes = await widget.excelService.exportToExcel(widget.fileName);
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "${widget.fileName}.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final attendanceByDate = widget.excelService.studentRecords[widget.fileName] ?? {};
    final students = attendanceByDate[currentDate] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final isPresent = student.getAttendance(currentDate);

                return ListTile(
                  title: Text(student.name),
                  subtitle: Text("Roll No: ${student.rollNo}"),
                  trailing: Switch(
                    value: isPresent,
                    onChanged: (value) {
                      setState(() {
                        recordAttendance(currentDate, index, value);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final currentStudents = widget.excelService.studentRecords[widget.fileName]?[currentDate] ?? [];
                  await widget.excelService.updateAttendanceForDate(widget.fileName, currentDate, currentStudents);
                },
                child: const Text("Save Changes"),
              ),
              ElevatedButton(
                onPressed: downloadFile,
                child: const Text("Download"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
