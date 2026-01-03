import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'aws_config.dart';
import 'auth_screen.dart';
import 'course_view_screen.dart';

class StudDashboard extends StatefulWidget {
  final String email;
  final String name;
  const StudDashboard({super.key, required this.email, required this.name});

  @override
  State<StudDashboard> createState() => _StudDashboardState();
}

class _StudDashboardState extends State<StudDashboard> with SingleTickerProviderStateMixin {
  List<dynamic> _allCourses = [];
  List<dynamic> _myEnrollments = []; // List of Course IDs
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get User Profile (Using the NEW action, no password needed)
      final profileRes = await http.post(Uri.parse(API_URL),
          body: jsonEncode({'action': 'get_profile', 'email': widget.email}));

      // 2. Get All Courses
      final courseRes = await http.post(Uri.parse(API_URL), body: jsonEncode({'action': 'get_courses'}));

      if (courseRes.statusCode == 200 && profileRes.statusCode == 200) {
        final userData = jsonDecode(profileRes.body);
        final coursesData = jsonDecode(courseRes.body);

        if(mounted) {
          setState(() {
            _allCourses = coursesData['courses'];
            // Safe check for enrollments list
            _myEnrollments = userData['enrolled_courses'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        print("Error: ${profileRes.statusCode} or ${courseRes.statusCode}");
        if(mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching data: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _toggleEnroll(String courseId, bool isEnrolling) async {
    // Optimistic UI Update
    setState(() {
      if (isEnrolling) {
        _myEnrollments.add(courseId);
      } else {
        _myEnrollments.remove(courseId);
      }
    });

    final action = isEnrolling ? 'enroll' : 'unenroll';
    final res = await http.post(Uri.parse(API_URL), body: jsonEncode({
      'action': action, 'email': widget.email, 'course_id': courseId
    }));

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEnrolling ? "Enrolled Successfully" : "Unenrolled"),
        backgroundColor: isEnrolling ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 1),
      ));
    } else {
      // Revert if failed
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action Failed"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter Lists
    final myCoursesList = _allCourses.where((c) => _myEnrollments.contains(c['course_id'])).toList();
    final browseList = _allCourses;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Student Portal", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Welcome, ${widget.name}", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)), onPressed: _fetchData),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()))),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6366F1),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "My Courses"),
            Tab(text: "Browse All"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: MY COURSES
          myCoursesList.isEmpty
              ? _buildEmptyState("You haven't enrolled in any courses yet.", Icons.class_outlined)
              : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: myCoursesList.length,
              itemBuilder: (ctx, i) => _buildCourseCard(myCoursesList[i], true)
          ),

          // TAB 2: BROWSE ALL
          browseList.isEmpty
              ? _buildEmptyState("No courses available in the system.", Icons.search_off)
              : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: browseList.length,
              itemBuilder: (ctx, i) {
                final isEnrolled = _myEnrollments.contains(browseList[i]['course_id']);
                return _buildCourseCard(browseList[i], isEnrolled);
              }
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic course, bool isEnrolled) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: isEnrolled ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(
                isEnrolled ? Icons.check_circle : Icons.school_rounded,
                color: isEnrolled ? const Color(0xFF16A34A) : const Color(0xFF6366F1)
            ),
          ),
          title: Text(course['course_name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text("Instructor: ${course['professor']}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          trailing: isEnrolled
              ? ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseViewScreen(courseId: course['course_id'], courseName: course['course_name']))),
            child: const Text("Open"),
          )
              : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _toggleEnroll(course['course_id'], true),
            child: const Text("Enroll"),
          ),
          onLongPress: isEnrolled
              ? () => _showUnenrollDialog(course)
              : null,
        ),
      ),
    );
  }

  void _showUnenrollDialog(dynamic course) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Unenroll?"),
          content: Text("Stop receiving updates for ${course['course_name']}?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            TextButton(onPressed: () {
              Navigator.pop(ctx);
              _toggleEnroll(course['course_id'], false);
            }, child: const Text("Unenroll", style: TextStyle(color: Colors.red))),
          ],
        )
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(msg, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}