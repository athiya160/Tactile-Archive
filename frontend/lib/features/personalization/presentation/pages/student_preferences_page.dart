import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';
import 'package:libri_flow/core/services/api_service.dart';

class StudentPreferencesPage extends StatefulWidget {
  const StudentPreferencesPage({super.key});

  @override
  State<StudentPreferencesPage> createState() => _StudentPreferencesPageState();
}

class _StudentPreferencesPageState extends State<StudentPreferencesPage> {
  String _selectedDegree = 'Computer Science & Engineering';
  String _academicYear = '1st Year';
  String _currentSemester = 'Semester 1';
  final TextEditingController _customCourseController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _degreeOptions = [
    'Computer Science & Engineering',
    'Information Technology',
    'Electronics & Communication Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'B.Sc (Computer Science / IT)',
    'B.Sc (Physics / Chemistry / Mathematics)',
    'BCA / MCA (Computer Applications)',
    'B.Com / M.Com (Commerce & Finance)',
    'BBA / MBA (Business Administration)',
    'BA / MA (Humanities / Literature)',
    'Medical & Health Sciences',
    'Law / Legal Studies',
    'Other / Custom Degree',
  ];

  final List<String> _academicYearOptions = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year / Final Year',
    'Postgraduate - Year 1',
    'Postgraduate - Year 2',
  ];

  final List<String> _semesterOptions = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String courseValue = _selectedDegree == 'Other / Custom Degree'
        ? (_customCourseController.text.trim().isEmpty ? 'General Studies' : _customCourseController.text.trim())
        : _selectedDegree;

    final success = await ApiService.saveStudentProfile(
      educationLevel: _academicYear,
      course: courseValue,
      examGoal: _currentSemester,
      studyDuration: 60,
      college: _collegeController.text.trim(),
      semester: _currentSemester,
      academicYear: _academicYear,
    );

    if (!mounted) return;

    if (success) {
      context.go('/student');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save academic setup. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _customCourseController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg, vertical: DSSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: DSColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DSRadius.pill),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_rounded, size: 15, color: DSColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'STUDENT ONBOARDING',
                          style: TextStyle(
                            color: DSColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DSSpacing.md),

                  Text(
                    'Set Up Your Academic Hub',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: DSColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Provide your basic academic details to personalize your semester roadmap, study tools, and textbook recommendations.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DSColors.textLight,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: DSSpacing.xl),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(DSSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(DSRadius.md),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                    const SizedBox(height: DSSpacing.lg),
                  ],

                  // 1. Course / Degree Program
                  _buildSectionTitle('1. Course / Degree Program'),
                  const SizedBox(height: DSSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDegree,
                    decoration: _inputDecoration(),
                    items: _degreeOptions
                        .map((deg) => DropdownMenuItem(value: deg, child: Text(deg, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDegree = val);
                    },
                  ),
                  if (_selectedDegree == 'Other / Custom Degree') ...[
                    const SizedBox(height: DSSpacing.sm),
                    TextFormField(
                      controller: _customCourseController,
                      decoration: _inputDecoration(hint: 'Enter your degree or major name'),
                    ),
                  ],
                  const SizedBox(height: DSSpacing.lg),

                  // 2. Academic Year
                  _buildSectionTitle('2. Academic Year'),
                  const SizedBox(height: DSSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _academicYear,
                    decoration: _inputDecoration(),
                    items: _academicYearOptions
                        .map((yr) => DropdownMenuItem(value: yr, child: Text(yr)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _academicYear = val);
                    },
                  ),
                  const SizedBox(height: DSSpacing.lg),

                  // 3. Current Semester
                  _buildSectionTitle('3. Current Semester'),
                  const SizedBox(height: DSSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _currentSemester,
                    decoration: _inputDecoration(),
                    items: _semesterOptions
                        .map((sem) => DropdownMenuItem(value: sem, child: Text(sem)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _currentSemester = val);
                    },
                  ),
                  const SizedBox(height: DSSpacing.lg),

                  // 4. College / Institution (Optional)
                  _buildSectionTitle('4. College / Institution (Optional)'),
                  const SizedBox(height: DSSpacing.xs),
                  TextFormField(
                    controller: _collegeController,
                    decoration: _inputDecoration(hint: 'e.g. Oxford, Stanford, IIT, University of Delhi'),
                  ),
                  const SizedBox(height: DSSpacing.xxl),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DSButton(
                      text: _isLoading ? 'Personalizing Dashboard...' : 'Enter Student Dashboard',
                      onPressed: _isLoading ? null : _handleSave,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: DSColors.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: DSColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: BorderSide(color: DSColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSRadius.md),
        borderSide: BorderSide(color: DSColors.border),
      ),
    );
  }
}
