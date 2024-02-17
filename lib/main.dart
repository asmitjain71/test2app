import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Catalog',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CourseListPage(),
    );
  }
}

class CourseListPage extends StatefulWidget {
  @override
  _CourseListPageState createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  List<Course> courses = [];
  List<String> departments = [];
  List<String> years = [];
  String selectedDepartment = 'All';
  String selectedYear = 'All';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    final response = await http.get(Uri.parse('https://smsapp.bits-postman-lab.in/courses'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> courseData = data['courses'];
      setState(() {
        courses = courseData.map((data) => Course.fromJson(data)).toList();
        departments = ['All'] + Set.from(courseData.map((data) => data['department'])).toList().cast<String>();
        years = ['All'] + Set.from(courseData.map((data) => data['year'])).toList().cast<String>();
      });
    } else {
      throw Exception('Failed to load courses');
    }
  }

  List<Course> getFilteredCourses() {
    return courses.where((course) {
      final departmentCondition = selectedDepartment == 'All' || course.department == selectedDepartment;
      final yearCondition = selectedYear == 'All' || course.year == selectedYear;
      final searchCondition = course.name.toLowerCase().contains(searchQuery.toLowerCase());
      return departmentCondition && yearCondition && searchCondition;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Catalog'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final Course? result = await showSearch<Course?>(
                context: context,
                delegate: CourseSearchDelegate(courses),
              );
              // Handle search result
            },
          ),
        ],
      ),
      body: courses.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                DropdownButton<String>(
                  value: selectedDepartment,
                  items: departments.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedDepartment = value!;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: selectedYear,
                  items: years.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedYear = value!;
                    });
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: getFilteredCourses().length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(getFilteredCourses()[index].name),
                        subtitle: Text(getFilteredCourses()[index].code),
                        // Add more details as per the design
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class Course {
  final String department;
  final String year;
  final String code;
  final String name;

  Course({
    required this.department,
    required this.year,
    required this.code,
    required this.name,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      department: json['department'],
      year: json['year'],
      code: json['courseCode'],
      name: json['courseName'],
    );
  }
}

class CourseSearchDelegate extends SearchDelegate<Course?> {
  final List<Course> courses;

  CourseSearchDelegate(this.courses);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(query);
  }

  Widget _buildSearchResults(String query) {
    final searchResults = query.isEmpty
        ? courses
        : courses.where((course) => course.name.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(searchResults[index].name),
          subtitle: Text(searchResults[index].code),
          // Add more details as per the design
        );
      },
    );
  }
}
