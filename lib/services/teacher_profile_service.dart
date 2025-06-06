import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:achiver_app/services/auth_service.dart';

class TeacherProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch Teacher Profile by ID
  Future<Map<String, dynamic>?> getTeacherProfileById(String userId) async {
    try {
      final user = await AuthService.getUserId();
      if (user == null) {
        throw 'User not logged in';
      }

      final teacherDoc = await _firestore.collection('teachers').doc(userId).get();
      if (!teacherDoc.exists) {
        return null;
      }

      final teacherData = teacherDoc.data()!;
      teacherData['userId'] = teacherDoc.id;

      // Get leave appointments if any
      if (teacherData['leave_appointments'] != null) {
        final leaveAppointments = List<String>.from(teacherData['leave_appointments']);
        if (leaveAppointments.isNotEmpty) {
          final leaveDocs = await _firestore
              .collection('leave_applications')
              .where(FieldPath.documentId, whereIn: leaveAppointments)
              .get();
          
          teacherData['leave_appointments_details'] = leaveDocs.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        }
      }

      return teacherData;
    } catch (e) {
      print('Error getting teacher profile: $e');
      rethrow;
    }
  }

  // Fetch Teacher Profile by Employee ID (legacy method)
  Future<Map<String, dynamic>?> getTeacherProfile(String employeeId) async {
    try {
      final doc = await _firestore.collection('teachers').doc(employeeId).get();

      if (!doc.exists) {
        throw 'Teacher with employee ID $employeeId not found';
      }
      print('Fetched Teacher Profile: ${doc.data()}');
      return doc.data();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching teacher profile: $e');
      return null;
    }
  }

  // Update Teacher's Class and Section (legacy, for single class/section)
  Future<void> updateTeacherClassSection({
    required String teacherId,
    required String className,
    required String section,
  }) async {
    try {
      await _firestore.collection('teachers').doc(teacherId).update({
        'class': className,
        'section': section,
      });
      Fluttertoast.showToast(msg: 'Class and section updated successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating class/section: $e');
      rethrow;
    }
  }

  // Add a class/section to the teacher's classes list
  Future<void> addTeacherClass({
    required String teacherId,
    required String className,
    required String section,
  }) async {
    try {
      await _firestore.collection('teachers').doc(teacherId).update({
        'classes': FieldValue.arrayUnion([
          {'class': className, 'section': section}
        ])
      });
      Fluttertoast.showToast(msg: 'Class added successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error adding class: $e');
      rethrow;
    }
  }

  // Remove a class/section from the teacher's classes list
  Future<void> removeTeacherClass({
    required String teacherId,
    required String className,
    required String section,
  }) async {
    try {
      await _firestore.collection('teachers').doc(teacherId).update({
        'classes': FieldValue.arrayRemove([
          {'class': className, 'section': section}
        ])
      });
      Fluttertoast.showToast(msg: 'Class removed successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error removing class: $e');
      rethrow;
    }
  }
}
