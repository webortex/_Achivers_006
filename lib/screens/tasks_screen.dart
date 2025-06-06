import 'package:flutter/material.dart';
import 'vocal_page.dart';
import 'vocal_testing_page';
import '../services/TestService.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mcq_page2.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  TasksScreenState createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  final TestService _testService = TestService();
  List<Map<String, dynamic>> _taskItems = [];
  final List<Map<String, dynamic>> _recentTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final tests = await _testService.getTestsForClassAndSection();

      // Convert tests to recent tasks format for upcoming tasks section
      final recentTasks = tests.map((test) {
        final testDate = test['date'] as Timestamp?;
        final dueDate = testDate != null
            ? DateFormat('MMM dd, yyyy').format(testDate.toDate())
            : 'Test Available';

        return {
          'title': test['testName']?.toString() ??
              '${test['subject']?.toString() ?? 'Test'}',
          'subject': test['subject']?.toString() ?? 'Unknown Subject',
          'dueDate': dueDate,
          'status': test['status']?.toString() ?? 'pending',
          'color': _getSubjectColor(test['subject']?.toString() ?? ''),
          'testId': test['testId']?.toString() ?? '',
          'date': testDate,
          'time': test['time']?.toString() ?? '',
          'duration': test['duration'] ?? 0,
          'maxMarks': test['maxMarks'] ?? 0,
        };
      }).toList();

      // Sort recent tasks by date
      recentTasks.sort((a, b) {
        final dateA = a['date'] as Timestamp?;
        final dateB = b['date'] as Timestamp?;
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });

      // Group tests by subject for task items
      final Map<String, List<Map<String, dynamic>>> subjectGroups = {};
      for (var test in tests) {
        final subject = test['subject']?.toString() ?? 'Unknown Subject';
        if (!subjectGroups.containsKey(subject)) {
          subjectGroups[subject] = [];
        }
        subjectGroups[subject]!.add(test);
      }

      // Create task items from grouped tests
      final taskItems = subjectGroups.entries.map((entry) {
        final subject = entry.key;
        final subjectTests = entry.value;

        // Calculate subject statistics
        final totalTests = subjectTests.length;
        final completedTests = subjectTests.where((test) {
          final status = test['status']?.toString().toLowerCase();
          return status == 'completed';
        }).length;

        // Get upcoming tests (not completed and future date)
        final now = DateTime.now();
        final upcomingTests = subjectTests.where((test) {
          final status = test['status']?.toString().toLowerCase();
          final testDate = (test['date'] as Timestamp?)?.toDate();
          return status != 'completed' &&
              testDate != null &&
              testDate.isAfter(now);
        }).toList();

        // Get recent tests for this subject
        final recentSubjectTests = subjectTests.map((test) {
          final testDate = test['date'] as Timestamp?;
          return {
            'title': test['testName']?.toString() ??
                '${test['subject']?.toString() ?? 'Test'}',
            'subject': test['subject']?.toString() ?? 'Unknown Subject',
            'status': test['status']?.toString() ?? 'pending',
            'date': testDate,
            'time': test['time']?.toString() ?? '',
            'testId': test['testId']?.toString() ?? '',
          };
        }).toList();

        return {
          'title': subject,
          'subtitle': 'Tests and Assignments',
          'icon': _getSubjectIcon(subject),
          'color': _getSubjectColor(subject),
          'progress': totalTests == 0 ? 0.0 : completedTests / totalTests,
          'tasks': totalTests,
          'completed': completedTests,
          'upcoming': upcomingTests.length,
          'recentTests': recentSubjectTests,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _recentTasks.clear();
          _recentTasks.addAll(recentTasks);
          _taskItems = taskItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading tests: $e'); // Add this for debugging
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tests: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSubjectIcon(String subject) {
    if (subject.isEmpty) return 'https://img.icons8.com/isometric/50/book.png';

    switch (subject.toLowerCase()) {
      case 'mathematics':
        return 'https://img.icons8.com/isometric/50/calculator.png';
      case 'science':
        return 'https://img.icons8.com/isometric/50/test-tube.png';
      case 'english':
        return 'https://img.icons8.com/isometric/50/literature.png';
      case 'history':
        return 'https://img.icons8.com/isometric/50/globe.png';
      case 'computer science':
        return 'https://img.icons8.com/isometric/50/laptop.png';
      default:
        return 'https://img.icons8.com/isometric/50/book.png';
    }
  }

  Color _getSubjectColor(String subject) {
    if (subject.isEmpty) return Colors.grey;

    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Colors.blue;
      case 'science':
        return Colors.green;
      case 'english':
        return Colors.purple;
      case 'history':
        return Colors.orange;
      case 'computer science':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            const Text(
              'Your Tasks Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track and manage your academic tasks',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming tasks section
            const Text(
              'Upcoming Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: _recentTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No upcoming tasks',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentTasks.length,
                      itemBuilder: (context, index) {
                        final item = _recentTasks[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to MCQ page for upcoming tasks
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => McqPage(
                                  subjectData: {
                                    'title': item['subject'],
                                    'color': _getSubjectColor(item['subject']),
                                  },
                                  topicData: {
                                    'title': item['title'],
                                    'testId': item['testId'],
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: item['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: item['color'].withOpacity(0.3)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title']?.toString() ??
                                          'Untitled Task',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      item['subject']?.toString() ??
                                          'Unknown Subject',
                                      style: TextStyle(
                                        color: item['color'],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['dueDate']?.toString() ??
                                              'No due date',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (item['time'] != null &&
                                            item['time'].toString().isNotEmpty)
                                          Text(
                                            'Time: ${item['time']}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item['status']
                                                    ?.toString()
                                                    .toLowerCase() ==
                                                'completed'
                                            ? Colors.green
                                            : item['color'],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (item['status']?.toString() ??
                                                'pending')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 32),

            // All subjects section
            const Text(
              'Tasks by Subject',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _taskItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.subject_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No subjects available',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _taskItems.length,
                    itemBuilder: (context, index) {
                      final item = _taskItems[index];
                      return _buildTaskCard(item, context);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> item, BuildContext context) {
    void _navigateToTask(Map<String, dynamic> task) {
      // Check if this is an upcoming task
      if (task['date'] != null && task['date'] is Timestamp) {
        final taskDate = (task['date'] as Timestamp).toDate();
        if (taskDate.isAfter(DateTime.now())) {
          // Navigate to MCQ page for upcoming tasks
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => McqPage(
                subjectData: {
                  'title': task['subject'],
                  'color': _getSubjectColor(task['subject']),
                },
                topicData: {
                  'title': task['title'],
                  'testId': task['testId'],
                },
              ),
            ),
          );
          return;
        }
      }

      // For non-upcoming tasks, use the existing navigation
      if (task['isVocalTesting'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const KeywordMatchPage(),
          ),
        );
      } else if (task['isVocal'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const STTKeywordMatcher(),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => McqPage(
              subjectData: {
                'title': task['subject'],
                'color': _getSubjectColor(task['subject']),
              },
              topicData: {
                'title': task['title'],
                'testId': task['testId'],
              },
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () => _navigateToTask(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: item['progress'],
              backgroundColor: item['color'].withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(item['color']),
              minHeight: 8,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item['color'].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Image.network(
                          item['icon'],
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress text
                  Text(
                    '${item['completed']} of ${item['tasks']} tasks completed',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Progress percentage
                  Text(
                    '${(item['progress'] * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: item['color'],
                    ),
                  ),
                  if (item['recentTests'] != null &&
                      item['recentTests'].isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // Recent tests preview
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Tests:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...item['recentTests']
                            .take(2)
                            .map((test) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.assignment,
                                        size: 14,
                                        color: item['color'],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          test['title']?.toString() ??
                                              'Untitled Test',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // View all button
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: item['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Task detail screen that shows tasks for the selected subject
class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final String subject;
  final String studentId;
  final Function(bool) onStatusChanged;

  const TaskDetailScreen({
    Key? key,
    required this.task,
    required this.subject,
    required this.studentId,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late bool _isCompleted;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Convert the status to boolean
    _isCompleted =
        widget.task['status']?.toString().toLowerCase() == 'completed';
  }

  Future<void> _updateTestStatus() async {
    setState(() => _isLoading = true);
    try {
      final testId = widget.task['testId'];
      if (testId == null) {
        throw Exception('Test ID not found');
      }

      final testService = TestService();
      await testService.updateTestStatus(
        testId: testId,
        studentId: widget.studentId,
        status: _isCompleted ? 'completed' : 'pending',
      );

      widget.onStatusChanged(_isCompleted);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isCompleted
                ? 'Test marked as completed'
                : 'Test marked as pending'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update test status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task['title']?.toString() ?? 'Task Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task['title']?.toString() ?? 'Untitled Task',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.task['description']?.toString() ??
                          'No description available',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${widget.task['dueDate']?.toString() ?? 'No due date'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.subject, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Subject: ${widget.subject}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isCompleted ? 'Completed' : 'Pending',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  _isCompleted ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isCompleted,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _isCompleted = value);
                                  _updateTestStatus();
                                },
                          activeColor: Colors.green,
                        ),
                      ],
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
}
