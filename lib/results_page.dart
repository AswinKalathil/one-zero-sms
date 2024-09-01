import 'package:flutter/material.dart';

class ClassDetailPage extends StatefulWidget {
  final String className;
  final int classIndex;

  ClassDetailPage({required this.className, required this.classIndex});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  String? _selectedcriteria;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _selectedcriteria = 'Student';
  }

  void _onSelected(String criteria) {
    setState(() {
      _selectedcriteria = criteria;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2, // 30% of the width
          child: Material(
            elevation: 2,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by $_selectedcriteria',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.all(15.0),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text("Class"),
                  leading: Checkbox(
                    value: _selectedcriteria == 'Class',
                    onChanged: (bool? value) {
                      _onSelected('Class');
                    },
                  ),
                  onTap: () => _onSelected('Class'),
                ),
                ListTile(
                  title: const Text("Subject"),
                  leading: Checkbox(
                    value: _selectedcriteria == "Subject",
                    onChanged: (bool? value) {
                      _onSelected("Subject");
                    },
                  ),
                  onTap: () => _onSelected("Subject"),
                ),
                ListTile(
                  title: const Text("Student"),
                  leading: Checkbox(
                    value: _selectedcriteria == "Student",
                    onChanged: (bool? value) {
                      _onSelected("Student");
                    },
                  ),
                  onTap: () => _onSelected("Student"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 8, // 80% of the width
          child: Container(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                GradeCard(
                  studentName: "John Doe",
                  className: "10th Grade",
                  currentMonth: "September",
                  photoUrl: "assets/ml.jpg",
                  subjects: [
                    {'subject': 'Mathematics', 'marks': '85', 'grade': 'A'},
                    {'subject': 'Science', 'marks': '78', 'grade': 'B+'},
                    {'subject': 'English', 'marks': '92', 'grade': 'A+'},
                    {'subject': 'Mathematics', 'marks': '85', 'grade': 'A'},
                    {'subject': 'Science', 'marks': '78', 'grade': 'B+'},
                    {'subject': 'English', 'marks': '92', 'grade': 'A+'},
                    {'subject': 'Mathematics', 'marks': '85', 'grade': 'A'},
                    {'subject': 'Science', 'marks': '78', 'grade': 'B+'},
                    {'subject': 'English', 'marks': '92', 'grade': 'A+'},
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GradeCard extends StatelessWidget {
  final String studentName;
  final String className;
  final String currentMonth;
  final String photoUrl;
  final List<Map<String, String>>
      subjects; // Each map contains 'subject', 'marks', 'grade'

  GradeCard({
    required this.studentName,
    required this.className,
    required this.currentMonth,
    required this.photoUrl,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Center(
        child: AspectRatio(
          aspectRatio: 210 / 297, // A4 aspect ratio (210mm x 297mm)
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 130,
                      child: Image.asset(
                        photoUrl,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold), // Reduced font size
                          ),
                          Text(
                            'Class: $className',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Month: $currentMonth',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Grades',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold), // Reduced font size
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: Table(
                    border: TableBorder.all(color: Colors.black),
                    columnWidths: {
                      0: const FlexColumnWidth(2),
                      1: const FlexColumnWidth(1),
                      2: const FlexColumnWidth(1),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(6.0), // Reduced padding
                            child: Text(
                              'Subject',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Text(
                              'Marks',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Text(
                              'Grade',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      ...subjects.map(
                        (subject) => TableRow(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.all(6.0), // Reduced padding
                              child: Text(subject['subject'] ?? ''),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(subject['marks'] ?? ''),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(subject['grade'] ?? ''),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text("One Zero")
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: GradeCard(
      studentName: "John Doe",
      className: "10th Grade",
      currentMonth: "September",
      photoUrl: "https://example.com/photo.jpg",
      subjects: [
        {'subject': 'Mathematics', 'marks': '85', 'grade': 'A'},
        {'subject': 'Science', 'marks': '78', 'grade': 'B+'},
        {'subject': 'English', 'marks': '92', 'grade': 'A+'},
      ],
    ),
  ));
}
