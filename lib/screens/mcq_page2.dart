import 'dart:io';
import 'package:flutter/material.dart';
import '../services/TestService.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class McqPage extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  final Map<String, dynamic> topicData;

  const McqPage({
    super.key,
    required this.subjectData,
    required this.topicData,
  });

  @override
  McqPageState createState() => McqPageState();
}

class McqPageState extends State<McqPage> {
  List<Map<String, dynamic>> _questions = []; // Initialize with empty list
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];
  bool _hasSubmitted = false;
  bool _showReview = false;
  int _score = 0;
  bool _isLoading = true;
  final TestService _testService = TestService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() => _isLoading = true);

      // Fetch questions from Firestore using testId
      final testId = widget.topicData['testId'];
      if (testId == null) {
        throw Exception('Test ID not found');
      }

      print('Loading questions for test ID: $testId'); // Debug log

      // Get the test document
      final testDoc = await FirebaseFirestore.instance
          .collection('tests')
          .doc(testId)
          .get();

      if (!testDoc.exists) {
        throw Exception('Test document not found');
      }

      print('Test document found: ${testDoc.data()}'); // Debug log

      final testData = testDoc.data();
      if (testData == null || testData['questions'] == null) {
        throw Exception('No questions found in test document');
      }

      // Convert questions array to the required format
      final questionsList =
          List<Map<String, dynamic>>.from(testData['questions']).map((q) {
        return {
          'question': q['question'] ?? 'Question not available',
          'options': List<String>.from(q['options'] ?? []),
          'correctAnswer': q['correctOptions'] != null &&
                  (q['correctOptions'] as List).isNotEmpty
              ? (q['correctOptions'] as List).first
              : 0,
          'explanation':
              'This is a ${q['type'] ?? 'multiple choice'} question from section ${q['section'] ?? 'A'}',
          'type': q['type'] ?? 'multipleChoice',
          'section': q['section'] ?? 'A',
        };
      }).toList();

      if (questionsList.isEmpty) {
        throw Exception('No valid questions found in test document');
      }

      if (mounted) {
        setState(() {
          _questions = questionsList;
          _selectedAnswers = List.filled(_questions.length, null);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading questions: $e'); // Debug log
      if (mounted) {
        setState(() {
          _isLoading = false;
          _questions = [];
          _selectedAnswers = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading questions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get _allQuestionsAnswered {
    return _questions.isNotEmpty &&
        !_selectedAnswers.any((answer) => answer == null);
  }

  Future<void> _submitQuiz() async {
    if (!_allQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please answer all questions before submitting')),
      );
      return;
    }

    try {
      setState(() => _hasSubmitted = true);
      _showReview = false;
      _score = 0;

      // Calculate score
      for (int i = 0; i < _questions.length; i++) {
        if (_selectedAnswers[i] == _questions[i]['correctAnswer']) {
          _score++;
        }
      }

      // Get student ID from AuthService
      final studentId = await AuthService.getUserId();
      if (studentId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate percentage score
      final percentageScore = (_score / _questions.length) * 100;

      // Update test status
      await _testService.updateTestStatus(
        testId: widget.topicData['testId'],
        studentId: studentId,
        status: 'completed',
        score: _score,
        totalQuestions: _questions.length,
        percentageScore: percentageScore,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Test submitted successfully! Score: $_score/${_questions.length} (${percentageScore.toStringAsFixed(1)}%)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error submitting test: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting test: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkAnswers() {
    setState(() {
      _showReview = true;
    });
  }

  Future<void> _downloadReport() async {
    // Show loading indicator
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Generating report...')),
    );

    try {
      // Create a PDF document
      final pdf = pw.Document();

      // Add a page to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  '${widget.topicData['title']} Quiz Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(widget.subjectData['color'].value),
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              // Score Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Quiz Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Score: $_score/${_questions.length} (${(_score / _questions.length * 100).toStringAsFixed(1)}%)',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      'Date: ${DateTime.now().toString().split('.')[0]}',
                      style: const pw.TextStyle(
                          fontSize: 14, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Questions and Answers
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final isCorrect =
                    _selectedAnswers[index] == question['correctAnswer'];
                final userAnswer = _selectedAnswers[index];

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: isCorrect ? PdfColors.green : PdfColors.red,
                      width: 1,
                    ),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Question
                      pw.Text(
                        '${index + 1}. ${question['question']}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 8),

                      // Options
                      ...question['options'].asMap().entries.map((option) {
                        final optionIndex = option.key;
                        final optionText = option.value;
                        final isSelected = userAnswer == optionIndex;
                        final isCorrectOption =
                            question['correctAnswer'] == optionIndex;

                        return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 16,
                                height: 16,
                                margin:
                                    const pw.EdgeInsets.only(right: 8, top: 2),
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  border: pw.Border.all(
                                    color: isCorrectOption
                                        ? PdfColors.green
                                        : isSelected
                                            ? PdfColors.red
                                            : PdfColors.grey,
                                    width: 1.5,
                                  ),
                                ),
                                child: isCorrectOption
                                    ? pw.Center(
                                        child: pw.Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const pw.BoxDecoration(
                                            color: PdfColors.green,
                                            shape: pw.BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : isSelected
                                        ? pw.Center(
                                            child: pw.Container(
                                              width: 8,
                                              height: 8,
                                              decoration:
                                                  const pw.BoxDecoration(
                                                color: PdfColors.red,
                                                shape: pw.BoxShape.circle,
                                              ),
                                            ),
                                          )
                                        : null,
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  optionText,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: isCorrectOption
                                        ? PdfColors.green
                                        : isSelected
                                            ? PdfColors.red
                                            : PdfColors.black,
                                    fontWeight: isCorrectOption || isSelected
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      // Explanation
                      if (!isCorrect) ...[
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'Explanation: ${question['explanation']}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey800,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ),
                      ],

                      pw.SizedBox(height: 8),

                      // Status
                      pw.Text(
                        isCorrect ? 'Correct!' : 'Incorrect',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: isCorrect ? PdfColors.green : PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Footer
              pw.Footer(
                title: pw.Text(
                  'Generated by Achievers Learning App',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ];
          },
        ),
      );

      // Save the PDF to a temporary file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/quiz_report.pdf');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;

      // Show success message
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Report generated successfully!')),
      );

      // Open the file with the device's default PDF viewer
      await OpenFilex.open(file.path);

      // Option to share the file
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'My quiz results from ${widget.topicData['title']} - Score: $_score/${_questions.length}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e')),
      );
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.topicData['title']} MCQs',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: widget.subjectData['color'],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.topicData['title']} MCQs',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: widget.subjectData['color'],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'No questions available for this test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadQuestions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.topicData['title']} MCQs',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: widget.subjectData['color'],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[200],
            valueColor:
                AlwaysStoppedAnimation<Color>(widget.subjectData['color']),
            minHeight: 8,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_hasSubmitted)
                  Text(
                    'Score: $_score/${_questions.length}',
                    style: TextStyle(
                      color: widget.subjectData['color'],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),

          // Question content or review
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child:
                  _showReview ? _buildReviewScreen() : _buildCurrentQuestion(),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: _hasSubmitted &&
                    _currentQuestionIndex == _questions.length - 1
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Quiz Submitted!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.subjectData['color'],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Score: $_score/${_questions.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!_showReview)
                          ElevatedButton(
                            onPressed: _checkAnswers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.subjectData['color'],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                            ),
                            child: const Text('Review Answers'),
                          )
                        else
                          ElevatedButton(
                            onPressed: _downloadReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 8),
                                Text('Download Report'),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back to Topics'),
                        ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _currentQuestionIndex > 0
                            ? _previousQuestion
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Previous'),
                      ),
                      if (_allQuestionsAnswered && !_hasSubmitted)
                        ElevatedButton(
                          onPressed: _submitQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.subjectData['color'],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Submit Quiz'),
                        )
                      else
                        const SizedBox(), // Remove Check Answer button
                      ElevatedButton(
                        onPressed: _currentQuestionIndex < _questions.length - 1
                            ? _nextQuestion
                            : _allQuestionsAnswered && !_hasSubmitted
                                ? _submitQuiz
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.subjectData['color'],
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _currentQuestionIndex == _questions.length - 1
                              ? (_allQuestionsAnswered ? 'Submit' : 'Finish')
                              : 'Next',
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: widget.subjectData['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.subjectData['color']),
          ),
          child: Column(
            children: [
              Text(
                'Quiz Review',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.subjectData['color'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $_score/${_questions.length} (${(_score / _questions.length * 100).toStringAsFixed(0)}%)',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...List.generate(_questions.length, (index) {
          final question = _questions[index];
          final isCorrect =
              _selectedAnswers[index] == question['correctAnswer'];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border.all(
                color: isCorrect ? Colors.green : Colors.red,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Question ${index + 1}${isCorrect ? ' (Correct)' : ' (Incorrect)'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildQuestionReview(question, index),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionReview(
      Map<String, dynamic> question, int questionIndex) {
    final List<String> options = question['options'];
    final int correctAnswer = question['correctAnswer'];
    final int? selectedAnswer = _selectedAnswers[questionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isCorrect = index == correctAnswer;
          final isSelected = selectedAnswer == index;

          Color bgColor = Colors.grey.shade100;
          Color borderColor = Colors.grey.shade300;
          IconData? icon;
          Color? iconColor;

          if (isCorrect) {
            bgColor = Colors.green.shade50;
            borderColor = Colors.green;
            icon = Icons.check_circle;
            iconColor = Colors.green;
          } else if (isSelected) {
            bgColor = Colors.red.shade50;
            borderColor = Colors.red;
            icon = Icons.cancel;
            iconColor = Colors.red;
          }

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected || isCorrect ? Colors.black87 : null,
                      fontWeight:
                          isSelected || isCorrect ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
        if (question['explanation'] != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explanation:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(question['explanation']),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentQuestion() {
    final question = _questions[_currentQuestionIndex];
    final List<String> options = question['options'];
    final int correctAnswer = question['correctAnswer'];
    final String questionType = question['type'] ?? 'multipleChoice';
    final String section = question['section'] ?? 'A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question header with type and section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.subjectData['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                questionType == 'multipleChoice'
                    ? Icons.check_circle_outline
                    : Icons.radio_button_checked,
                size: 16,
                color: widget.subjectData['color'],
              ),
              const SizedBox(width: 8),
              Text(
                '${questionType.toUpperCase()} - Section $section',
                style: TextStyle(
                  color: widget.subjectData['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Question text
        Text(
          question['question'],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        // Options
        ...List.generate(options.length, (index) {
          final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
          final isCorrect = index == correctAnswer;

          Color? backgroundColor;
          Color? borderColor;

          if (_hasSubmitted) {
            if (isSelected && isCorrect) {
              backgroundColor = Colors.green.withOpacity(0.1);
              borderColor = Colors.green;
            } else if (isSelected && !isCorrect) {
              backgroundColor = Colors.red.withOpacity(0.1);
              borderColor = Colors.red;
            } else if (isCorrect) {
              backgroundColor = Colors.green.withOpacity(0.1);
              borderColor = Colors.green;
            } else {
              backgroundColor = Colors.grey.withOpacity(0.1);
              borderColor = Colors.grey;
            }
          } else {
            backgroundColor = isSelected
                ? widget.subjectData['color'].withOpacity(0.1)
                : Colors.grey.withOpacity(0.1);
            borderColor =
                isSelected ? widget.subjectData['color'] : Colors.grey;
          }

          return GestureDetector(
            onTap: _hasSubmitted
                ? null
                : () {
                    setState(() {
                      _selectedAnswers[_currentQuestionIndex] = index;
                    });
                  },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? borderColor : Colors.transparent,
                      border: Border.all(
                        color: borderColor,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      options[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (_hasSubmitted) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explanation:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question['explanation'],
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
