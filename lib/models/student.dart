class Student {
  final String name;
  final String rollNo;
  Map<String, bool> attendanceByDate = {}; // Date-based attendance

  Student({required this.name, required this.rollNo});

  // Convert student to JSON format
  Map<String, dynamic> toJson() => {
        'name': name,
        'rollNo': rollNo,
        'attendanceByDate': attendanceByDate,
      };

  // Create student instance from JSON data
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['name'],
      rollNo: json['rollNo'],
    )..attendanceByDate = Map<String, bool>.from(json['attendanceByDate'] ?? {});
  }

  // Get attendance for a specific date
  bool getAttendance(String date) => attendanceByDate[date] ?? false;

  // Set attendance for a specific date
  void setAttendance(String date, bool isPresent) {
    attendanceByDate[date] = isPresent;
  }
}
