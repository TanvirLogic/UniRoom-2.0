import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/registration_options_model.dart';
import '../providers/auth_provider.dart';
import 'verify_email_screen.dart';

/// Registration Screen
/// Students, CRs, and Faculty sign up from this screen.
/// Universities, Departments, Batches, and Sections are loaded dynamically from the backend.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Input Controllers
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _facultyIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Default role: STUDENT (STUDENT, CR, FACULTY)
  String _selectedRole = 'STUDENT';
  bool _obscurePassword = true;

  // Cascading dropdown state variables (University -> Department -> Batch -> Section)
  String? _selectedUniversityId;
  String? _selectedDepartmentId;
  String? _selectedBatchName;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();

    // Initialize with local fallback data first
    final fallback = RegistrationOptionsModel.fallback();
    _initializeSelections(fallback);

    // Fetch latest options from backend database
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.loadRegistrationOptions();
      if (mounted && auth.registrationOptions != null) {
        _syncSelectionsWithLatestData(auth.registrationOptions!);
      }
    });
  }

  void _initializeSelections(RegistrationOptionsModel options) {
    if (options.universities.isEmpty) return;
    final uni = options.universities.first;
    final dept = uni.departments.isNotEmpty ? uni.departments.first : null;
    final batch = (dept != null && dept.batches.isNotEmpty) ? dept.batches.first : null;
    final sec = (batch != null && batch.sections.isNotEmpty) ? batch.sections.first : null;

    _selectedUniversityId = uni.id;
    _selectedDepartmentId = dept?.id;
    _selectedBatchName = batch?.name;
    _selectedSection = sec;
  }

  void _syncSelectionsWithLatestData(RegistrationOptionsModel options) {
    setState(() {
      // 1. Validate University
      final uni = options.universities.firstWhere(
        (u) => u.id == _selectedUniversityId,
        orElse: () => options.universities.first,
      );
      _selectedUniversityId = uni.id;

      // 2. Validate Department
      final depts = uni.departments;
      final dept = depts.firstWhere(
        (d) => d.id == _selectedDepartmentId,
        orElse: () => depts.isNotEmpty
            ? depts.first
            : DepartmentOption(id: '', code: '', name: '', batches: []),
      );
      _selectedDepartmentId = dept.id.isNotEmpty ? dept.id : null;

      // 3. Validate Batch
      final batches = dept.batches;
      final batch = batches.firstWhere(
        (b) => b.name == _selectedBatchName,
        orElse: () => batches.isNotEmpty
            ? batches.first
            : AcademicBatchOption(id: '', name: '', sections: []),
      );
      _selectedBatchName = batch.name.isNotEmpty ? batch.name : null;

      // 4. Validate Section
      final secs = batch.sections;
      if (_selectedSection == null || !secs.contains(_selectedSection)) {
        _selectedSection = secs.isNotEmpty ? secs.first : null;
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _facultyIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Cascading Selection Handlers
  // ===========================================================================

  void _onUniversityChanged(String newUniId, RegistrationOptionsModel options) {
    final uni = options.universities.firstWhere((u) => u.id == newUniId);
    final firstDept = uni.departments.isNotEmpty ? uni.departments.first : null;
    final firstBatch = (firstDept != null && firstDept.batches.isNotEmpty) ? firstDept.batches.first : null;
    final firstSec = (firstBatch != null && firstBatch.sections.isNotEmpty) ? firstBatch.sections.first : null;

    setState(() {
      _selectedUniversityId = newUniId;
      _selectedDepartmentId = firstDept?.id;
      _selectedBatchName = firstBatch?.name;
      _selectedSection = firstSec;
    });
  }

  void _onDepartmentChanged(String newDeptId, List<DepartmentOption> departments) {
    final dept = departments.firstWhere((d) => d.id == newDeptId);
    final firstBatch = dept.batches.isNotEmpty ? dept.batches.first : null;
    final firstSec = (firstBatch != null && firstBatch.sections.isNotEmpty) ? firstBatch.sections.first : null;

    setState(() {
      _selectedDepartmentId = newDeptId;
      _selectedBatchName = firstBatch?.name;
      _selectedSection = firstSec;
    });
  }

  void _onBatchChanged(String newBatchName, List<AcademicBatchOption> batches) {
    final batch = batches.firstWhere((b) => b.name == newBatchName);
    final firstSec = batch.sections.isNotEmpty ? batch.sections.first : null;

    setState(() {
      _selectedBatchName = newBatchName;
      _selectedSection = firstSec;
    });
  }

  // ===========================================================================
  // Submit Registration
  // ===========================================================================
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final isStudentOrCr = _selectedRole == 'STUDENT' || _selectedRole == 'CR';

    final success = await auth.register(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _fullNameController.text,
      universityId: _selectedUniversityId ?? 'UU',
      departmentId: _selectedDepartmentId ?? 'CSE',
      role: _selectedRole,
      studentId: isStudentOrCr ? _studentIdController.text : null,
      batch: isStudentOrCr ? _selectedBatchName : null,
      section: isStudentOrCr ? _selectedSection : null,
      facultyId: (_selectedRole == 'FACULTY') ? _facultyIdController.text : null,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(auth.errorMessage ?? 'Registration failed. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStudentOrCr = _selectedRole == 'STUDENT' || _selectedRole == 'CR';

    final options = auth.registrationOptions ?? RegistrationOptionsModel.fallback();

    final selectedUni = options.universities.firstWhere(
      (u) => u.id == _selectedUniversityId,
      orElse: () => options.universities.first,
    );

    final availableDepartments = selectedUni.departments;
    final selectedDept = availableDepartments.firstWhere(
      (d) => d.id == _selectedDepartmentId,
      orElse: () => availableDepartments.isNotEmpty
          ? availableDepartments.first
          : DepartmentOption(id: '', code: '', name: '', batches: []),
    );

    final availableBatches = selectedDept.batches;
    final selectedBatch = availableBatches.firstWhere(
      (b) => b.name == _selectedBatchName,
      orElse: () => availableBatches.isNotEmpty
          ? availableBatches.first
          : AcademicBatchOption(id: '', name: '', sections: []),
    );

    final availableSections = selectedBatch.sections;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join UniRoom-Live',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select your institutional role to continue',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // 1. Role Tabs (Student | CR | Faculty)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildRoleTab('STUDENT', 'Student'),
                      _buildRoleTab('CR', 'CR (Class Rep)'),
                      _buildRoleTab('FACULTY', 'Faculty'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                const Text(
                  'Full Name',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Md Tanvir Ahmed',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 20),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 16),

                // University Dropdown
                const Text(
                  'University',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const ValueKey('dropdown_university'),
                  initialValue: _selectedUniversityId,
                  isExpanded: true,
                  items: options.universities.map((uni) {
                    return DropdownMenuItem(
                      value: uni.id,
                      child: Text('${uni.name} (${uni.code})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _onUniversityChanged(val, options);
                    }
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined, color: AppColors.textMuted, size: 20),
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? 'Please select your university' : null,
                ),
                const SizedBox(height: 16),

                // Department Dropdown
                const Text(
                  'Department',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey('dropdown_dept_$_selectedUniversityId'),
                  initialValue: _selectedDepartmentId,
                  isExpanded: true,
                  items: availableDepartments.map((dept) {
                    return DropdownMenuItem(
                      value: dept.id,
                      child: Text('${dept.code} - ${dept.name}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _onDepartmentChanged(val, availableDepartments);
                    }
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.textMuted, size: 20),
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? 'Please select your department' : null,
                ),
                const SizedBox(height: 16),

                // Student ID (Student & CR)
                if (isStudentOrCr) ...[
                  const Text(
                    'Student ID Number',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _studentIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 2241081422',
                      prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your student ID / roll number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Batch & Section Dropdowns (2 columns)
                  Row(
                    children: [
                      // Batch Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Batch',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey('dropdown_batch_$_selectedDepartmentId'),
                              initialValue: _selectedBatchName,
                              isExpanded: true,
                              items: availableBatches.map((b) {
                                return DropdownMenuItem(
                                  value: b.name,
                                  child: Text('Batch ${b.name}'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  _onBatchChanged(val, availableBatches);
                                }
                              },
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.layers_outlined, color: AppColors.textMuted, size: 20),
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? 'Please select your batch' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Section Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Section',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey('dropdown_sec_${_selectedDepartmentId}_$_selectedBatchName'),
                              initialValue: _selectedSection,
                              isExpanded: true,
                              items: availableSections.map((sec) {
                                return DropdownMenuItem(
                                  value: sec,
                                  child: Text('Section $sec'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSection = val);
                                }
                              },
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.group_work_outlined, color: AppColors.textMuted, size: 20),
                              ),
                              validator: (val) => (val == null || val.isEmpty) ? 'Please select your section' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Faculty Initials / ID
                if (_selectedRole == 'FACULTY') ...[
                  const Text(
                    'Faculty Code / Initials',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _facultyIdController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'e.g. DNS, FAC-102',
                      prefixIcon: Icon(Icons.co_present_outlined, color: AppColors.textMuted, size: 20),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter faculty code / initials' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Address
                const Text(
                  'Email Address',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'e.g. yourname@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your email';
                    if (!val.contains('@')) return 'Please enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.key_outlined, color: AppColors.textMuted, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter a password';
                    if (val.length < 6) return 'Password must be at least 6 characters long';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRegister,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Segmented role selection tab
  Widget _buildRoleTab(String role, String label) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primarySky : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
