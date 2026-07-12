import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/startup/startup_cubit.dart';
import '../../blocs/opportunity/opportunity_cubit.dart';
import '../../../data/models/opportunity_model.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/custom_text_field.dart';

class PostOpportunityScreen extends StatefulWidget {
  const PostOpportunityScreen({super.key});

  @override
  State<PostOpportunityScreen> createState() => _PostOpportunityScreenState();
}

class _PostOpportunityScreenState extends State<PostOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stipendController = TextEditingController();
  final _responsibilitiesController = TextEditingController();
  final _requirementsController = TextEditingController();

  String _selectedType = AppConstants.opportunityTypes.first;
  String _selectedDuration = AppConstants.durationOptions.first;
  String _selectedLocation = 'remote';
  bool _isPaid = false;
  int _openings = 1;
  List<String> _requiredSkills = [];
  final _skillController = TextEditingController();
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stipendController.dispose();
    _responsibilitiesController.dispose();
    _requirementsController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _deadline = date);
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_requiredSkills.contains(skill)) {
      setState(() {
        _requiredSkills.add(skill);
        _skillController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    final user = authState.user;
    final startupState = context.read<StartupCubit>().state;
    final startup = startupState.currentUserStartup;

    print('DEBUG SUBMIT: user=$user');
    print('DEBUG SUBMIT: userRole=${user?.role}');
    print('DEBUG SUBMIT: startupState=$startupState');
    print('DEBUG SUBMIT: currentUserStartup=$startup');

    if (user == null || startup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set up your startup profile first.')),
      );
      return;
    }

    if (!startup.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Your startup must be verified before posting opportunities.'),
        ),
      );
      return;
    }

    final responsibilities = _responsibilitiesController.text
        .split('\n')
        .where((r) => r.trim().isNotEmpty)
        .toList();
    final requirements = _requirementsController.text
        .split('\n')
        .where((r) => r.trim().isNotEmpty)
        .toList();

    final opportunity = OpportunityModel(
      id: '',
      startupId: startup.id,
      startupName: startup.name,
      startupLogoUrl: startup.logoUrl,
      startupIsVerified: startup.isVerified,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      requiredSkills: _requiredSkills,
      duration: _selectedDuration,
      isPaid: _isPaid,
      stipend: _isPaid ? _stipendController.text.trim() : null,
      location: _selectedLocation,
      campus: startup.campus,
      openings: _openings,
      deadline: _deadline,
      responsibilities: responsibilities,
      requirements: requirements,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.read<OpportunityCubit>().createOpportunity(opportunity);

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opportunity posted successfully! 🚀'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Opportunity'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: BlocListener<OpportunityCubit, OpportunityState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Role type
              _SectionLabel('Opportunity Type'),
              const SizedBox(height: 8),
              _DropdownField(
                value: _selectedType,
                items: AppConstants.opportunityTypes,
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 20),

              // Title
              _SectionLabel('Job Title'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _titleController,
                label: 'e.g., Frontend Developer Intern',
                prefixIcon: Icons.title_rounded,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),

              // Description
              _SectionLabel('Role Description'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descriptionController,
                label: 'Describe the role...',
                maxLines: 4,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 20),

              // Responsibilities
              _SectionLabel('Responsibilities (one per line)'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _responsibilitiesController,
                label: 'Build responsive UIs\nCollaborate with design team...',
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // Requirements
              _SectionLabel('Requirements (one per line)'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _requirementsController,
                label: 'Flutter experience\nStrong communication skills...',
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Skills
              _SectionLabel('Required Skills'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _skillController,
                      label: 'Add a skill',
                      prefixIcon: Icons.code_rounded,
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
              if (_requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _requiredSkills
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          onDeleted: () => setState(
                              () => _requiredSkills.remove(skill)),
                          deleteIconColor: AppColors.textMuted,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),

              // Duration & Location row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Duration'),
                        const SizedBox(height: 8),
                        _DropdownField(
                          value: _selectedDuration,
                          items: AppConstants.durationOptions,
                          onChanged: (v) =>
                              setState(() => _selectedDuration = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Location'),
                        const SizedBox(height: 8),
                        _DropdownField(
                          value: _selectedLocation,
                          items: ['remote', 'on-campus', 'hybrid'],
                          onChanged: (v) =>
                              setState(() => _selectedLocation = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Openings
              _SectionLabel('Number of Openings'),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _openings = (_openings - 1).clamp(1, 20)),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.remove, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _openings.toString(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _openings = (_openings + 1).clamp(1, 20)),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Paid toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid Internship',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            'Will you provide a stipend?',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPaid,
                      onChanged: (v) => setState(() => _isPaid = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              if (_isPaid) ...[
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _stipendController,
                  label: 'Stipend amount (e.g., \$200/month)',
                  prefixIcon: Icons.attach_money_rounded,
                ),
              ],
              const SizedBox(height: 20),

              // Deadline
              GestureDetector(
                onTap: _selectDeadline,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Application Deadline',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              _deadline != null
                                  ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                  : 'Tap to set deadline (optional)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _deadline != null
                                        ? AppColors.primary
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textMuted, size: 18),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              BlocBuilder<OpportunityCubit, OpportunityState>(
                builder: (context, state) {
                  return GradientButton(
                    label: 'Post Opportunity 🚀',
                    onTap: _submit,
                    isLoading: state.status == OpportunityStatus2.loading,
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
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
