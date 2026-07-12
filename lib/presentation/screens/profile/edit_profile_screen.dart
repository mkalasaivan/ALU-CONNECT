import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _githubController = TextEditingController();
  final _skillController = TextEditingController();

  String? _selectedCampus;
  String? _selectedMajor;
  String? _selectedYear;
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _prefillForm();
  }

  void _prefillForm() {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    _nameController.text = user.displayName;
    _bioController.text = user.bio ?? '';
    _linkedInController.text = user.linkedInUrl ?? '';
    _portfolioController.text = user.portfolioUrl ?? '';
    _githubController.text = user.githubUrl ?? '';
    _skills = List.from(user.skills);
    _selectedCampus = user.campus;
    _selectedMajor = user.major;
    _selectedYear = user.yearOfStudy;
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    final isProfileComplete = _bioController.text.isNotEmpty &&
        _selectedCampus != null &&
        _skills.isNotEmpty;

    final updatedUser = user.copyWith(
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      campus: _selectedCampus,
      major: _selectedMajor,
      yearOfStudy: _selectedYear,
      skills: _skills,
      linkedInUrl: _linkedInController.text.trim().isEmpty
          ? null
          : _linkedInController.text.trim(),
      portfolioUrl: _portfolioController.text.trim().isEmpty
          ? null
          : _portfolioController.text.trim(),
      githubUrl: _githubController.text.trim().isEmpty
          ? null
          : _githubController.text.trim(),
      isProfileComplete: isProfileComplete,
    );

    context.read<AuthBloc>().add(AuthProfileUpdateRequested(updatedUser));

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully! ✅'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _linkedInController.dispose();
    _portfolioController.dispose();
    _githubController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) return const SizedBox();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Edit Profile'),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: AppColors.background, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                const _SectionLabel('Full Name'),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _nameController,
                  label: 'Your name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),

                // Bio
                const _SectionLabel('Bio'),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _bioController,
                  label: 'Tell us about yourself...',
                  maxLines: 4,
                  maxLength: 300,
                ),
                const SizedBox(height: 20),

                // Student-specific fields
                if (user.isStudent) ...[
                  const _SectionLabel('Campus'),
                  const SizedBox(height: 8),
                  _DropdownField(
                    hint: 'Select your campus',
                    value: _selectedCampus,
                    items: AppConstants.aluCampuses,
                    onChanged: (v) => setState(() => _selectedCampus = v),
                  ),
                  const SizedBox(height: 20),

                  const _SectionLabel('Major'),
                  const SizedBox(height: 8),
                  _DropdownField(
                    hint: 'Select your major',
                    value: _selectedMajor,
                    items: AppConstants.aluMajors,
                    onChanged: (v) => setState(() => _selectedMajor = v),
                  ),
                  const SizedBox(height: 20),

                  const _SectionLabel('Year of Study'),
                  const SizedBox(height: 8),
                  _DropdownField(
                    hint: 'Select your year',
                    value: _selectedYear,
                    items: AppConstants.programYears,
                    onChanged: (v) => setState(() => _selectedYear = v),
                  ),
                  const SizedBox(height: 20),
                ],

                // Skills
                const _SectionLabel('Skills'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _skillController,
                        label: 'Add a skill (e.g., Flutter)',
                        prefixIcon: Icons.add_circle_outline_rounded,
                        onEditingComplete: _addSkill,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _addSkill,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (_skills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _skills
                        .map(
                          (skill) => Chip(
                            label: Text(skill),
                            onDeleted: () =>
                                setState(() => _skills.remove(skill)),
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            deleteIconColor: AppColors.textMuted,
                            labelStyle: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // Links
                const _SectionLabel('Professional Links'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _linkedInController,
                  label: 'LinkedIn URL',
                  hint: 'https://linkedin.com/in/...',
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.work_rounded,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _portfolioController,
                  label: 'Portfolio URL',
                  hint: 'https://yourportfolio.com',
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.link_rounded,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _githubController,
                  label: 'GitHub URL',
                  hint: 'https://github.com/username',
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.code_rounded,
                ),

                const SizedBox(height: 32),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return GradientButton(
                      label: 'Save Profile',
                      icon: Icons.check_rounded,
                      isLoading: state.isLoading,
                      onTap: _save,
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.hint,
    this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          isExpanded: true,
          dropdownColor: AppColors.surfaceCard,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          items: items
              .map(
                (item) => DropdownMenuItem(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
