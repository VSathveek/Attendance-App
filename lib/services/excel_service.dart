import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';

class ExcelService {
  Map<String, Map<String, List<Student>>> studentRecords = {};

  Future<void> loadFile(String fileName, Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    List<Student> students = [];

    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet != null) {
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        
        if (row.length > 1) {
          final name = row[0]?.value.toString() ?? '';
          final rollNo = row[1]?.value.toString() ?? '';
          
          students.add(Student(
            name: name,
            rollNo: rollNo,
          ));
        }
      }
    }

    studentRecords[fileName] = { 'default': students };
    await saveLocally(fileName, studentRecords[fileName]!);
  }

  Future<void> saveLocally(String fileName, Map<String, List<Student>> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(records.map((date, students) => MapEntry(
      date,
      students.map((s) => s.toJson()).toList(),
    )));
    prefs.setString(fileName, jsonData);
  }

  Future<void> loadFromLocalStorage(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(fileName);

    if (jsonData != null) {
      Map<String, dynamic> data = jsonDecode(jsonData);
      studentRecords[fileName] = data.map((date, students) => MapEntry(
        date,
        List<Student>.from(students.map((s) => Student.fromJson(s))),
      ));
    }
  }

  Future<void> removeFile(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(fileName); // Remove the file's data from SharedPreferences
    studentRecords.remove(fileName); // Also remove it from the in-memory map
  }

  Future<Uint8List> exportToExcel(String fileName) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    final fileRecords = studentRecords[fileName] ?? {};
    final allDates = fileRecords.keys.toList();

    sheet.appendRow(['Name', 'Roll No', ...allDates]);

    final students = fileRecords[allDates[0]] ?? [];
    for (var student in students) {
      List<String> row = [student.name, student.rollNo];
      for (var date in allDates) {
        final attendance = fileRecords[date]?.firstWhere((s) => s.rollNo == student.rollNo)?.getAttendance(date) ?? false;
        row.add(attendance ? 'Present' : 'Absent');
      }
      sheet.appendRow(row);
    }

    final List<int> encodedData = excel.encode()!;
    return Uint8List.fromList(encodedData);
  }

  Future<void> updateAttendanceForDate(String fileName, String date, List<Student> updatedStudents) async {
    if (studentRecords[fileName] == null) {
      studentRecords[fileName] = {};
    }
    studentRecords[fileName]![date] = updatedStudents;
    await saveLocally(fileName, studentRecords[fileName]!);
  }
}
