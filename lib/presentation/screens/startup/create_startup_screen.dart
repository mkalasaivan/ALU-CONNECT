import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/startup/startup_cubit.dart';
import '../../../data/models/startup_model.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/custom_text_field.dart';

class CreateStartupScreen extends StatefulWidget {
  const CreateStartupScreen({super.key});

  @override
  State<CreateStartupScreen> createState() => _CreateStartupScreenState();
}

class _CreateStartupScreenState extends State<CreateStartupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _programController = TextEditingController();

  String _selectedCategory = AppConstants.startupCategories.first;
  String _selectedCampus = AppConstants.aluCampuses.first;
  String _selectedStage = 'mvp';
  DateTime _foundedDate = DateTime.now();
  List<String> _tags = [];
  final _tagController = TextEditingController();

  final stages = [
    {'id': 'idea', 'label': 'Idea Stage', 'desc': 'Just starting out'},
    {'id': 'mvp', 'label': 'MVP', 'desc': 'Building first version'},
    {'id': 'growth', 'label': 'Growth', 'desc': 'Growing user base'},
    {'id': 'scale', 'label': 'Scaling', 'desc': 'Expanding operations'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _linkedInController.dispose();
    _programController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    final startup = StartupModel(
      id: '',
      ownerId: user.uid,
      name: _nameController.text.trim(),
      tagline: _taglineController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      websiteUrl: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      linkedInUrl: _linkedInController.text.trim().isEmpty
          ? null
          : _linkedInController.text.trim(),
      aluProgramName: _programController.text.trim().isEmpty
          ? null
          : _programController.text.trim(),
      campus: _selectedCampus,
      stage: _selectedStage,
      tags: _tags,
      foundedDate: _foundedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.read<StartupCubit>().createStartup(startup);

    if (mounted) {
      context.go('/dashboard');
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register Startup'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: BlocListener<StartupCubit, StartupState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.info, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your startup will be reviewed by the ALU admin team before being listed publicly. Only startups affiliated with ALU programs or recognized at ALU will be approved.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Startup Name
              _Label('Startup Name *'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nameController,
                label: 'e.g., EduBridge',
                prefixIcon: Icons.business_rounded,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),

              // Tagline
              _Label('Tagline *'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _taglineController,
                label: 'One line about your startup',
                prefixIcon: Icons.short_text_rounded,
                maxLength: 100,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Tagline is required' : null,
              ),
              const SizedBox(height: 20),

              // Description
              _Label('Description *'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descriptionController,
                label: 'Tell us what your startup does...',
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Description is required';
                  if (v.length < 50) return 'Please write at least 50 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              _Label('Industry Category *'),
              const SizedBox(height: 8),
              _DropdownField(
                value: _selectedCategory,
                items: AppConstants.startupCategories,
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 20),

              // Campus
              _Label('ALU Campus *'),
              const SizedBox(height: 8),
              _DropdownField(
                value: _selectedCampus,
                items: AppConstants.aluCampuses,
                onChanged: (v) => setState(() => _selectedCampus = v!),
              ),
              const SizedBox(height: 20),

              // Stage
              _Label('Startup Stage'),
              const SizedBox(height: 12),
              Row(
                children: stages
                    .map(
                      (stage) => Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedStage = stage['id']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                              right: stages.indexOf(stage) < stages.length - 1
                                  ? 8
                                  : 0,
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 6),
                            decoration: BoxDecoration(
                              gradient: _selectedStage == stage['id']
                                  ? AppColors.primaryGradient
                                  : null,
                              color: _selectedStage == stage['id']
                                  ? null
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedStage == stage['id']
                                    ? Colors.transparent
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  stage['label']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedStage == stage['id']
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),

              // ALU Program
              _Label('ALU Program / Initiative (optional)'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _programController,
                label: 'e.g., ALU Ventures, ALU Entrepreneurship Lab',
                prefixIcon: Icons.school_rounded,
              ),
              const SizedBox(height: 20),

              // Tags
              _Label('Tags'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _tagController,
                      label: 'e.g., mobile, education',
                      prefixIcon: Icons.tag_rounded,
                      onEditingComplete: _addTag,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addTag,
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
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                          backgroundColor: AppColors.secondary.withOpacity(0.1),
                          deleteIconColor: AppColors.textMuted,
                          labelStyle: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),

              // Website
              _Label('Website & Socials (optional)'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _websiteController,
                label: 'Website URL',
                hint: 'https://yourstartup.com',
                keyboardType: TextInputType.url,
                prefixIcon: Icons.language_rounded,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _linkedInController,
                label: 'LinkedIn URL',
                hint: 'https://linkedin.com/company/...',
                keyboardType: TextInputType.url,
                prefixIcon: Icons.work_rounded,
              ),
              const SizedBox(height: 32),

              BlocBuilder<StartupCubit, StartupState>(
                builder: (context, state) {
                  return GradientButton(
                    label: 'Submit for Review 🚀',
                    isLoading: state.status == StartupStatus.loading,
                    onTap: _submit,
                    colors: [
                      const Color(0xFF06B6D4),
                      const Color(0xFF6C3AE8),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
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
          isExpanded: true,
          dropdownColor: AppColors.surfaceCard,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
