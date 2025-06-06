import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'take_attendance_screen.dart';
import 'grade_assignments_screen.dart';
import 'schedule_event_screen.dart';
import 'create_test_screen.dart';
import 'teacher_profile_page.dart';
import 'student_details_screen.dart';
import '../services/auth_service.dart';
import '../services/teacher_profile_service.dart';
import '../services/LeaveService.dart';
import 'package:intl/intl.dart';
<<<<<<< Updated upstream
import 'package:cloud_firestore/cloud_firestore.dart';
=======
>>>>>>> Stashed changes

void main() {
  runApp(const MaterialApp(
    home: TeacherDashboardScreen(),
  ));
}

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  Map<String, dynamic>? teacherData;
  bool isLoading = true;
  List<Map<String, dynamic>> leaveAppointments = [];
<<<<<<< Updated upstream
  bool isLeaveLoading = true;
=======
  final LeaveService _leaveService = LeaveService();
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    fetchTeacherProfile();
    fetchLeaveApplications();
  }

  Future<void> fetchTeacherProfile() async {
    final String? employeeId = await AuthService.getUserId();
    if (employeeId == null) {
=======
    print('TeacherDashboardScreen initialized'); // Debug log
    _loadTeacherProfile();
    fetchLeaveAppointments();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final String? teacherId = await AuthService.getUserId();
      print('Loading teacher profile for ID: $teacherId'); // Debug log
      
      if (teacherId == null) {
        print('Error: Teacher ID is null in _loadTeacherProfile'); // Debug log
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      final profile = await ProfileService().getTeacherProfile(teacherId);
      print('Teacher profile loaded: $profile'); // Debug log
      
      setState(() {
        teacherData = profile;
        isLoading = false;
      });
    } catch (e) {
      print('Error in _loadTeacherProfile: $e'); // Debug log
>>>>>>> Stashed changes
      setState(() {
        isLoading = false;
      });
    }
<<<<<<< Updated upstream
    final profile = await TeacherProfileService().getTeacherProfile(employeeId);
    setState(() {
      teacherData = profile;
      isLoading = false;
    });
=======
  }

  Future<void> fetchLeaveAppointments() async {
    try {
      print('Starting fetchLeaveAppointments'); // Debug log
      final teacherId = await AuthService.getUserId();
      print('Teacher ID from AuthService: $teacherId'); // Debug log
      
      if (teacherId == null) {
        print('Error: Teacher ID is null in fetchLeaveAppointments'); // Debug log
        return;
      }

      print('Calling LeaveService.getLeavesForClassTeacher with ID: $teacherId'); // Debug log
      final leaves = await LeaveService().getLeavesForClassTeacher(teacherId);
      print('Received leaves from service: ${leaves.length}'); // Debug log
      print('Leaves data: $leaves'); // Debug log
      
      if (mounted) {
        setState(() {
          leaveAppointments = leaves;
          print('Updated leaveAppointments in state: ${leaveAppointments.length}'); // Debug log
        });
      }
    } catch (e) {
      print('Error in fetchLeaveAppointments: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading leave applications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
>>>>>>> Stashed changes
  }

  Future<void> fetchLeaveApplications() async {
    final String? employeeId = await AuthService.getUserId();
    if (employeeId == null) {
      setState(() {
        isLeaveLoading = false;
      });
      return;
    }

    try {
      final leaves = await LeaveService().getLeavesForClassTeacher(employeeId);
      setState(() {
        leaveAppointments = leaves;
        isLeaveLoading = false;
      });
    } catch (e) {
      print('Error fetching leave applications: $e');
      setState(() {
        isLeaveLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading leave applications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue[900],
          title: const Text(
            'Teacher Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20),
<<<<<<< Updated upstream
              _buildLeaveAppointments(context),
              const SizedBox(height: 20),
=======
              _buildLeaveAppointments(),
              const SizedBox(height: 20),
              _buildStudentStats(),
>>>>>>> Stashed changes
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final String teacherName = teacherData?['name'] ?? 'Teacher';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $teacherName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You have 3 classes scheduled for today',
            style: TextStyle(
              color: Colors.blue[50],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.1, // Slightly taller tiles to accommodate the text
      children: [
        // First Row
        _buildActionCard(
          'Take Attendance',
          Icons.how_to_reg,
          Colors.green[400]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TakeAttendanceScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          'Grade Assignments',
          Icons.assignment_turned_in,
          Colors.orange[400]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EnterMarksScreen(),
              ),
            );
          },
        ),

        // Second Row - Send Message
        _buildActionCard(
          'Send Message',
          Icons.message,
          Colors.blue[400]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SendMessageScreen(),
              ),
            );
          },
        ),
        
        // Third Row - Schedule Event
        _buildActionCard(
          'Schedule Event',
          Icons.event_available,
          Colors.purple[400]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SendMessageScreen(),
              ),
            );
          },
        ),

        // Third Row
        _buildActionCard(
          'Create Test',
          Icons.quiz,
          Colors.red[400]!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateTestScreen(),
              ),
            );
          },
        ),

        // Fourth Row - Student Details
        _buildActionCard(
          'Student Details',
          Icons.people,
          Colors.teal[400]!,
          onTap: () {
            // Student data is now handled within StudentDetailsScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentDetailsScreen(),
              ),
            );
            // Note: The StudentDetailsScreen now handles student data internally
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300]!,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _buildLeaveAppointments(BuildContext context) {
    if (isLeaveLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Leave Applications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all leave applications screen
              },
              child: Text(
                'View All',
                style: TextStyle(color: Colors.blue[700]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (leaveAppointments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No pending leave applications',
                  style: TextStyle(color: Colors.grey[600]),
=======
  Widget _buildStudentStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Total Students', '150', Icons.people),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard('Attendance', '92%', Icons.timeline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[700], size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveAppointments() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Leave Applications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
>>>>>>> Stashed changes
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      leaveAppointments = [];
                    });
                    fetchLeaveAppointments();
                  },
                ),
              ],
            ),
<<<<<<< Updated upstream
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leaveAppointments.length > 2
                ? 2
                : leaveAppointments.length, // Show only 2 items in dashboard
            itemBuilder: (context, index) {
              final appointment = leaveAppointments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (appointment['childRollNumber'] ?? '?').toString()[0],
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    'Roll No: ${appointment['childRollNumber']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Class ${appointment['class']} • ${_formatDate(appointment['fromDate'])} to ${_formatDate(appointment['toDate'])}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment['status'])
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment['status'] ?? 'Pending',
                      style: TextStyle(
                        color: _getStatusColor(appointment['status']),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
=======
            SizedBox(height: 8),
            if (leaveAppointments.isEmpty)
              Center(child: CircularProgressIndicator())
            else if (leaveAppointments.isEmpty)
              Center(
                child: Text(
                  'No pending leave applications',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: leaveAppointments.length,
                itemBuilder: (context, index) {
                  final leave = leaveAppointments[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        '${leave['childRollNumber']} - ${leave['class']}${leave['section']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
>>>>>>> Stashed changes
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Leave Type: ${leave['leaveType']}'),
                          Text('Applied Date: ${_formatDate(leave['appliedAt'])}'),
                          Text('Parent: ${leave['parentName']}'),
                          Text('Phone: ${leave['parentPhone']}'),
                          Text(
<<<<<<< Updated upstream
                            'Reason: ${appointment['reason'] ?? ''}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          if (appointment['status'] == 'pending')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _handleLeaveResponse(
                                      appointment, 'rejected'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _handleLeaveResponse(
                                      appointment, 'approved'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
=======
                            'Status: ${leave['status'].toString().toUpperCase()}',
                            style: TextStyle(
                              color: leave['status'] == 'pending'
                                  ? Colors.orange
                                  : leave['status'] == 'approved'
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
>>>>>>> Stashed changes
                        ],
                      ),
                      trailing: leave['status'] == 'pending'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await LeaveService().updateLeaveStatus(
                                        leave['id'],
                                        'rejected',
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Leave application rejected'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      setState(() {
                                        leaveAppointments = [];
                                      });
                                      fetchLeaveAppointments();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error rejecting leave: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    try {
                                      await LeaveService().updateLeaveStatus(
                                        leave['id'],
                                        'approved',
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Leave application approved'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      setState(() {
                                        leaveAppointments = [];
                                      });
                                      fetchLeaveAppointments();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error approving leave: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

<<<<<<< Updated upstream
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _handleLeaveResponse(
      Map<String, dynamic> leave, String status) async {
    try {
      // TODO: Implement leave response handling
      // await LeaveService().updateLeaveStatus(leave['id'], status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave ${status} successfully'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
      // Refresh leave applications
      fetchLeaveApplications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating leave status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is String) return timestamp;
    if (timestamp is DateTime) {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    }
    return '';
=======
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
>>>>>>> Stashed changes
  }
}
