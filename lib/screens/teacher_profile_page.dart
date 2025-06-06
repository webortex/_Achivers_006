import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/teacher_profile_service.dart';
import '../services/LeaveService.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? teacherData;
  bool isLoading = true;
  final ProfileService _profileService = ProfileService();
  final LeaveService _leaveService = LeaveService();
  Map<String, dynamic>? _teacherProfile;
  bool _isLoading = true;
  List<Map<String, dynamic>>? _leaveAppointments;

  // Dropdown state
  String? _selectedClass;
  String? _selectedSection;
  final List<String> _classes = [
    '6', '7', '8', '9', '10', '11', '12'
  ];
  final List<String> _sections = ['A', 'B', 'C', 'D'];
  bool _isUpdatingClassSection = false;
  bool _isEditingClassSection = false;

  // Add state for add-class UI
  bool _isAddingClass = false;
  String? _newClass;
  String? _newSection;

  // Sample teacher data - in a real app, this would come from a database
  // final Map<String, dynamic> teacherData = {
  //   'name': 'Mrs. Lakshmi',
  //   'subject': 'Mathematics',
  //   'experience': '15 years',
  //   'education': 'M.Sc., B.Ed.',
  //   'email': 'lakshmi@school.edu',
  //   'phone': '+91 9876543210',
  //   'classes': ['10-A', '9-B', '11-A'],
  //   'achievements': [
  //     'Best Teacher Award 2022',
  //     'Published 3 academic papers',
  //     'Mentored winning team in Math Olympiad'
  //   ]
  // };

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
    _loadLeaveAppointments();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId != null) {
        final profile = await _profileService.getTeacherProfileById(userId);
        setState(() {
          _teacherProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading teacher profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
<<<<<<< Updated upstream
    final profile = await TeacherProfileService().getTeacherProfile(teacherId);
    setState(() {
      teacherData = profile;
      isLoading = false;
      // Set initial dropdown values if available
      _selectedClass = profile?['class']?.toString();
      _selectedSection = profile?['section']?.toString();
    });
=======
  }

  Future<void> _loadLeaveAppointments() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId != null) {
        final appointments = await _leaveService.getLeavesForClassTeacher(userId);
        setState(() {
          _leaveAppointments = appointments;
        });
      }
    } catch (e) {
      print('Error loading leave appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading leave appointments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
>>>>>>> Stashed changes
  }

  Future<void> _updateClassSection() async {
    final String? teacherId = await AuthService.getUserId();
    if (teacherId == null || _selectedClass == null || _selectedSection == null) return;
    setState(() => _isUpdatingClassSection = true);
    try {
      await TeacherProfileService().updateTeacherClassSection(
        teacherId: teacherId,
        className: _selectedClass!,
        section: _selectedSection!,
      );
      // Optionally refresh profile
      await fetchTeacherProfile();
    } catch (e) {
      // Error handled in service
    } finally {
      setState(() => _isUpdatingClassSection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        title: const Text(
          'Teacher Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildInfoSection(),
                  const SizedBox(height: 20),
                  _buildClassesSection(),
                  const SizedBox(height: 20),
                  _buildAchievementsSection(),
                  const SizedBox(height: 20),
                  _buildMenuSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final String teacherName = teacherData?['name'] ?? 'Teacher';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade100, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? Icon(Icons.person,
                              size: 50, color: Colors.blue.shade300)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            teacherName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${teacherData?['subject']} • ${teacherData?['experience']} experience',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal Information', Icons.info_outline),
            const SizedBox(height: 16),
            _buildInfoItem('Education', teacherData?['education'], Icons.school),
            _buildInfoItem('Email', teacherData?['email'], Icons.email),
            _buildInfoItem('Phone', teacherData?['phone'], Icons.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesSection() {
    final List classesList = teacherData?['classes'] ?? [];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with edit icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Classes Teaching', Icons.class_),
                IconButton(
                  icon: Icon(_isAddingClass ? Icons.close : Icons.add, color: Colors.blue[700]),
                  tooltip: _isAddingClass ? 'Cancel' : 'Add Class',
                  onPressed: () {
                    setState(() {
                      _isAddingClass = !_isAddingClass;
                      _newClass = null;
                      _newSection = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Show chips for all classes
            if (classesList.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...classesList.map<Widget>((cls) {
                    final className = cls['class']?.toString() ?? '';
                    final section = cls['section']?.toString() ?? '';
                    return Chip(
                      label: Text('Class $className - Section $section'),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                      deleteIcon: Icon(Icons.close, color: Colors.red),
                      onDeleted: () async {
                        final teacherId = await AuthService.getUserId();
                        if (teacherId == null) return;
                        await TeacherProfileService().removeTeacherClass(
                          teacherId: teacherId,
                          className: className,
                          section: section,
                        );
                        await fetchTeacherProfile();
                      },
                    );
                  }).toList(),
                ],
              ),
            if (classesList.isEmpty)
              const Text('No classes assigned yet.', style: TextStyle(color: Colors.grey)),
            // Add class form
            if (_isAddingClass)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _newClass,
                      hint: const Text('Class'),
                      items: _classes.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('Class $c'),
                      )).toList(),
                      onChanged: (val) => setState(() => _newClass = val),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _newSection,
                      hint: const Text('Section'),
                      items: _sections.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('Section $s'),
                      )).toList(),
                      onChanged: (val) => setState(() => _newSection = val),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _newClass == null || _newSection == null
                          ? null
                          : () async {
                              final teacherId = await AuthService.getUserId();
                              if (teacherId == null) return;
                              await TeacherProfileService().addTeacherClass(
                                teacherId: teacherId,
                                className: _newClass!,
                                section: _newSection!,
                              );
                              setState(() {
                                _isAddingClass = false;
                                _newClass = null;
                                _newSection = null;
                              });
                              await fetchTeacherProfile();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Achievements', Icons.emoji_events),
            const SizedBox(height: 16),
            ...List.generate(
              teacherData?['achievements'].length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        teacherData?['achievements'][index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem('Leave Appointments', Icons.event_busy, onTap: () {
          _showLeaveAppointmentsDialog(context);
        }),
        _buildMenuItem('Edit Profile', Icons.edit),
        _buildMenuItem('Teaching Resources', Icons.book),
        _buildMenuItem('Help & Support', Icons.help_outline),
        const SizedBox(height: 10),
        _buildMenuItem(
          'Logout',
          Icons.logout,
          color: Colors.red,
          onTap: () {
            // Show confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to login screen
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showLeaveAppointmentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Leave Applications'),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _leaveAppointments = null;
                });
                _loadLeaveAppointments();
              },
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: _leaveAppointments == null
              ? Center(child: CircularProgressIndicator())
              : _leaveAppointments!.isEmpty
                  ? Center(
                      child: Text(
                        'No pending leave applications',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: _leaveAppointments!
                          .map((leave) => _buildLeaveAppointmentTile(leave))
                          .toList(),
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveAppointmentTile(Map<String, dynamic> leave) {
    final fromDate = (leave['fromDate'] as Timestamp).toDate();
    final toDate = (leave['toDate'] as Timestamp).toDate();
    final appliedAt = (leave['appliedAt'] as Timestamp).toDate();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          '${leave['childRollNumber']} - ${leave['class']}${leave['section']}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leave Type: ${leave['leaveType']}'),
            Text('Applied Date: ${DateFormat('MMM dd, yyyy hh:mm a').format(appliedAt)}'),
            Text('Parent: ${leave['parentName']}'),
            Text('Phone: ${leave['parentPhone']}'),
            Text(
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
                          _leaveAppointments = null;
                        });
                        _loadLeaveAppointments();
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
                          _leaveAppointments = null;
                        });
                        _loadLeaveAppointments();
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
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[700], size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon,
      {VoidCallback? onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? Colors.blue.shade700),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontSize: 14,
            fontWeight: color != null ? FontWeight.w500 : null,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.shade400),
      ),
    );
  }
}
