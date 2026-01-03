import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'aws_config.dart';
import 'auth_screen.dart';
@Preview(name: "Professor Screen", group: 'prof Dashboard')
Widget profDashboardPreview() => SizedBox(
  height: 800,
  width: 400,
  child: MaterialApp(home: const ProfDashboard(email: "tayyab@gamil.com", name: "Tayyab")),
);
class ProfDashboard extends StatefulWidget {
  final String email;
  final String name;

  const ProfDashboard({super.key, required this.email, required this.name});

  @override
  State<ProfDashboard> createState() => _ProfDashboardState();
}

class _ProfDashboardState extends State<ProfDashboard>
    with SingleTickerProviderStateMixin {
  List<dynamic> _myCourses = [];
  List<dynamic> _myUploads = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchCourses(), _fetchUploads()]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchCourses() async {
    try {
      final res = await http.post(
        Uri.parse(API_URL),
        body: jsonEncode({'action': 'get_courses'}),
      );
      if (res.statusCode == 200) {
        final all = jsonDecode(res.body)['courses'] as List;
        if (mounted) {
          setState(() {
            _myCourses = all
                .where((c) => c['professor'] == widget.email)
                .toList();
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchUploads() async {
    try {
      final res = await http.post(
        Uri.parse(API_URL),
        body: jsonEncode({'action': 'get_my_uploads', 'email': widget.email}),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _myUploads = jsonDecode(res.body)['videos'];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _createCourse() async {
    TextEditingController nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          25,
          25,
          25,
          MediaQuery.of(ctx).viewInsets.bottom + 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create New Course",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: "Course Name (e.g. Data Structures)",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    await http.post(
                      Uri.parse(API_URL),
                      body: jsonEncode({
                        'action': 'create_course',
                        'email': widget.email,
                        'course_name': nameCtrl.text,
                      }),
                    );
                    _loadAllData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Launch Course"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadVideo(String courseId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 15),
            Text("Uploading..."),
          ],
        ),
        backgroundColor: Color(0xFF6366F1),
        duration: Duration(minutes: 5),
      ),
    );

    try {
      final minio = await AWSConfig.getMinio();
      String fileName =
          "$courseId/${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}";

      Stream<Uint8List> stream;
      if (kIsWeb)
        stream = Stream.value(result.files.first.bytes!);
      else
        stream = File(
          result.files.first.path!,
        ).openRead().map((chunk) => Uint8List.fromList(chunk));

      await minio.putObject(
        BUCKET_NAME,
        fileName,
        stream,
        size: result.files.first.size,
        metadata: {'content-type': 'application/octet-stream'},
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Upload Complete! Students Notified."),
          backgroundColor: Colors.green,
        ),
      );
      _fetchUploads(); // Refresh history
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          "Instructor Hub",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(text: "Manage Courses"),
            Tab(text: "Upload History"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCourse,
        label: const Text("New Course"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: COURSES
                _myCourses.isEmpty
                    ? const Center(
                        child: Text("Create your first course to begin!"),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _myCourses.length,
                        itemBuilder: (ctx, i) {
                          final c = _myCourses[i];
                          return FadeInUp(
                            duration: const Duration(milliseconds: 300),
                            child: Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.folder,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                                title: Text(
                                  c['course_name'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "ID: ${c['course_id']}",
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.cloud_upload_outlined,
                                    color: Color(0xFF6366F1),
                                  ),
                                  tooltip: "Upload Video",
                                  onPressed: () => _uploadVideo(c['course_id']),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                // TAB 2: HISTORY
                _myUploads.isEmpty
                    ? const Center(child: Text("No uploads found."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _myUploads.length,
                        itemBuilder: (ctx, i) {
                          final v = _myUploads[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            color: Colors.white,
                            child: ListTile(
                              leading: const Icon(
                                Icons.movie_creation_outlined,
                                color: Colors.grey,
                              ),
                              title: Text(
                                v['title'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.folder_open,
                                        size: 14,
                                        color: Colors.indigo,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        v['course_name'] ??
                                            'Course ID: ${v['course_id']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(v['timestamp']),
                                    ).toString().split('.')[0],
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
