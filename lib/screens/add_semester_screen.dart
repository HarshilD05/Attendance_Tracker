import 'package:flutter/material.dart';
import '../services/semester_service.dart';
import '../services/auth_service.dart';
import '../models/semester.dart';
import 'package:intl/intl.dart';

class AddSemesterScreen extends StatefulWidget {
  const AddSemesterScreen({super.key});

  @override
  State<AddSemesterScreen> createState() => _AddSemesterScreenState();
}

class _AddSemesterScreenState extends State<AddSemesterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  
  final SemesterService _semesterService = SemesterService();
  final AuthService _authService = AuthService();
  
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add New Semester'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues( alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.primaryColor.withValues( alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.school,
                      size: 48,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create Your Semester',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up a new academic semester to track your attendance',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues( alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Form Fields
              _buildSectionTitle('Basic Information', theme),
              const SizedBox(height: 16),
              
              // Semester Name Field
              _buildTextFormField(
                controller: _nameController,
                label: 'Semester Name',
                hint: 'e.g., Fall 2024, Spring 2025',
                icon: Icons.bookmark,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter semester name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
                theme: theme,
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionTitle('Duration', theme),
              const SizedBox(height: 16),
              
              // Date Fields Row
              Row(
                children: [
                  Expanded(
                    child: _buildDateFormField(
                      controller: _startDateController,
                      label: 'Start Date',
                      icon: Icons.calendar_today,
                      onTap: () => _selectStartDate(),
                      validator: (value) {
                        if (_selectedStartDate == null) {
                          return 'Please select start date';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateFormField(
                      controller: _endDateController,
                      label: 'End Date',
                      icon: Icons.event,
                      onTap: () => _selectEndDate(),
                      validator: (value) {
                        if (_selectedEndDate == null) {
                          return 'Please select end date';
                        }
                        if (_selectedStartDate != null && 
                            _selectedEndDate!.isBefore(_selectedStartDate!)) {
                          return 'End date must be after start date';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Duration Info Card
              if (_selectedStartDate != null && _selectedEndDate != null)
                _buildDurationInfoCard(theme),
              
              const SizedBox(height: 40),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createSemester,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create Semester'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues( alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildDateFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required String? Function(String?) validator,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        suffixIcon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues( alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildDurationInfoCard(ThemeData theme) {
    final duration = _selectedEndDate!.difference(_selectedStartDate!);
    final totalDays = duration.inDays + 1;
    final weeks = (totalDays / 7).ceil();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues( alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues( alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Semester Duration',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDurationItem('Total Days', '$totalDays', theme),
              _buildDurationItem('Weeks', '$weeks', theme),
              _buildDurationItem('Months', '${(totalDays / 30).ceil()}', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues( alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedStartDate = date;
        _startDateController.text = DateFormat('MMM dd, yyyy').format(date);
        
        // Reset end date if it's before the new start date
        if (_selectedEndDate != null && _selectedEndDate!.isBefore(date)) {
          _selectedEndDate = null;
          _endDateController.clear();
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final initialDate = _selectedEndDate ?? 
        (_selectedStartDate?.add(const Duration(days: 120)) ?? DateTime.now());
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedEndDate = date;
        _endDateController.text = DateFormat('MMM dd, yyyy').format(date);
      });
    }
  }

  Future<void> _createSemester() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if semester name already exists
      final nameExists = await _semesterService.semesterNameExists(_nameController.text.trim());
      if (nameExists) {
        throw 'A semester with this name already exists. Please choose a different name.';
      }

      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      // Create semester
      final semester = Semester.create(
        name: _nameController.text.trim(),
        semStartDate: _selectedStartDate!,
        semEndDate: _selectedEndDate!,
        userId: user.uid,
      );

      // Save to Firestore
      await _semesterService.createSemester(semester);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Semester "${semester.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating semester: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
