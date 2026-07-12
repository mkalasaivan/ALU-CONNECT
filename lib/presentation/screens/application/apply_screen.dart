import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/application/application_cubit.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/opportunity_model.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/custom_text_field.dart';

class ApplyScreen extends StatefulWidget {
  final String opportunityId;

  const ApplyScreen({super.key, required this.opportunityId});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _linkedInController = TextEditingController();
  OpportunityModel? _opportunity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOpportunity();
    // Pre-fill from profile
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      _portfolioController.text = user.portfolioUrl ?? '';
      _linkedInController.text = user.linkedInUrl ?? '';
    }
  }

  Future<void> _loadOpportunity() async {
    final opp = await context
        .read<OpportunityRepository>()
        .getOpportunityById(widget.opportunityId);
    if (mounted) setState(() {
      _opportunity = opp;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthBloc>().state.user;
    final opp = _opportunity;
    if (user == null || opp == null) return;

    final application = ApplicationModel(
      id: '',
      opportunityId: opp.id,
      opportunityTitle: opp.title,
      startupId: opp.startupId,
      startupName: opp.startupName,
      startupLogoUrl: opp.startupLogoUrl,
      applicantId: user.uid,
      applicantName: user.displayName,
      applicantEmail: user.email,
      applicantPhotoUrl: user.photoUrl,
      coverLetter: _coverLetterController.text.trim(),
      relevantSkills: user.skills,
      portfolioUrl: _portfolioController.text.trim().isEmpty
          ? null
          : _portfolioController.text.trim(),
      linkedInUrl: _linkedInController.text.trim().isEmpty
          ? null
          : _linkedInController.text.trim(),
      appliedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await context
        .read<ApplicationCubit>()
        .submitApplication(application);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _portfolioController.dispose();
    _linkedInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Apply for Role'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : BlocListener<ApplicationCubit, ApplicationState>(
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
                    // Opportunity summary card
                    if (_opportunity != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.cardGradient,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Applying for:',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              _opportunity!.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _opportunity!.startupName,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (_opportunity!.startupIsVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded,
                                      color: AppColors.secondary, size: 14),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Cover Letter
                    Text(
                      'Cover Letter *',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell the startup why you\'re the right fit. Be specific about your skills and motivation.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _coverLetterController,
                      label: 'Write your cover letter here...',
                      maxLines: 8,
                      maxLength: 1000,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Cover letter is required';
                        }
                        if (v.length < 100) {
                          return 'Please write at least 100 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Profile Links
                    Text(
                      'Your Links',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _portfolioController,
                      label: 'Portfolio URL (optional)',
                      hint: 'https://yourportfolio.com',
                      keyboardType: TextInputType.url,
                      prefixIcon: Icons.link_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _linkedInController,
                      label: 'LinkedIn URL (optional)',
                      hint: 'https://linkedin.com/in/yourname',
                      keyboardType: TextInputType.url,
                      prefixIcon: Icons.work_rounded,
                    ),

                    const SizedBox(height: 32),

                    // Note about profile
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppColors.info, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your profile information, skills, and contact details will be shared with the startup.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    BlocBuilder<ApplicationCubit, ApplicationState>(
                      builder: (context, state) {
                        return GradientButton(
                          label: 'Submit Application',
                          icon: Icons.send_rounded,
                          isLoading:
                              state.status == ApplicationStatusEnum.submitting,
                          onTap: _submit,
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
