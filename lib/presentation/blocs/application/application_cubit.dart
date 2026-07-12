import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/application_model.dart';
import '../../../data/repositories/application_repository.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- State ---
enum ApplicationStatusEnum { initial, loading, loaded, submitting, error, success }

class ApplicationState extends Equatable {
  final ApplicationStatusEnum status;
  final List<ApplicationModel> myApplications;
  final List<ApplicationModel> receivedApplications;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, int> stats;

  const ApplicationState({
    this.status = ApplicationStatusEnum.initial,
    this.myApplications = const [],
    this.receivedApplications = const [],
    this.errorMessage,
    this.successMessage,
    this.stats = const {},
  });

  ApplicationState copyWith({
    ApplicationStatusEnum? status,
    List<ApplicationModel>? myApplications,
    List<ApplicationModel>? receivedApplications,
    String? errorMessage,
    String? successMessage,
    Map<String, int>? stats,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ApplicationState(
      status: status ?? this.status,
      myApplications: myApplications ?? this.myApplications,
      receivedApplications: receivedApplications ?? this.receivedApplications,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        status,
        myApplications,
        receivedApplications,
        errorMessage,
        successMessage,
        stats,
      ];
}

// --- Cubit ---
class ApplicationCubit extends Cubit<ApplicationState> {
  final ApplicationRepository _applicationRepository;
  final OpportunityRepository _opportunityRepository;
  final NotificationRepository _notificationRepository;
  StreamSubscription<List<ApplicationModel>>? _myApplicationsSubscription;
  StreamSubscription<List<ApplicationModel>>? _receivedApplicationsSubscription;

  ApplicationCubit({
    required ApplicationRepository applicationRepository,
    required OpportunityRepository opportunityRepository,
    required NotificationRepository notificationRepository,
  })  : _applicationRepository = applicationRepository,
        _opportunityRepository = opportunityRepository,
        _notificationRepository = notificationRepository,
        super(const ApplicationState());

  // Subscribe to student's own applications
  void subscribeToMyApplications(String applicantId) {
    _myApplicationsSubscription?.cancel();
    _myApplicationsSubscription =
        _applicationRepository.studentApplicationsStream(applicantId).listen(
      (applications) {
        emit(state.copyWith(
          status: ApplicationStatusEnum.loaded,
          myApplications: applications,
        ));
      },
      onError: (e) {
        emit(state.copyWith(errorMessage: e.toString()));
      },
    );
  }

  // Subscribe to startup's received applications
  void subscribeToReceivedApplications(String startupId) {
    _receivedApplicationsSubscription?.cancel();
    _receivedApplicationsSubscription =
        _applicationRepository.startupApplicationsStream(startupId).listen(
      (applications) {
        emit(state.copyWith(
          status: ApplicationStatusEnum.loaded,
          receivedApplications: applications,
        ));
      },
      onError: (e) {
        emit(state.copyWith(errorMessage: e.toString()));
      },
    );
  }

  // Submit an application
  Future<bool> submitApplication(ApplicationModel application) async {
    emit(state.copyWith(status: ApplicationStatusEnum.submitting));
    try {
      // Check for duplicate
      final alreadyApplied = await _applicationRepository.hasApplied(
        application.opportunityId,
        application.applicantId,
      );

      if (alreadyApplied) {
        emit(state.copyWith(
          status: ApplicationStatusEnum.error,
          errorMessage: 'You have already applied to this opportunity.',
        ));
        return false;
      }

      final submittedApp = await _applicationRepository.submitApplication(application);
      await _opportunityRepository.incrementApplicantCount(application.opportunityId);

      // Trigger notification to the startup owner
      try {
        final startupDoc = await FirebaseFirestore.instance.collection('startups').doc(application.startupId).get();
        final ownerId = startupDoc.data()?['ownerId'] ?? application.startupId;

        await _notificationRepository.sendNotification(NotificationModel(
          id: '',
          userId: ownerId,
          title: 'New Application Received 🚀',
          body: '${application.applicantName} applied for the "${application.opportunityTitle}" role.',
          type: 'application',
          timestamp: DateTime.now(),
          extraData: {'applicationId': submittedApp.id},
        ));
      } catch (e) {
        // Silently fail notification
      }

      emit(state.copyWith(
        status: ApplicationStatusEnum.success,
        successMessage: 'Application submitted successfully! 🎉',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: ApplicationStatusEnum.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  // Update application status (startup action)
  Future<void> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status, {
    String? note,
  }) async {
    try {
      await _applicationRepository.updateApplicationStatus(
        applicationId,
        status,
        note: note,
      );

      // Trigger notification to the applicant (student)
      try {
        final app = await _applicationRepository.getApplicationById(applicationId);
        if (app != null) {
          final statusName = status.toString().split('.').last;
          await _notificationRepository.sendNotification(NotificationModel(
            id: '',
            userId: app.applicantId,
            title: 'Application Update 📣',
            body: 'Your application for "${app.opportunityTitle}" has been $statusName.',
            type: 'application',
            timestamp: DateTime.now(),
            extraData: {'applicationId': applicationId},
          ));
        }
      } catch (e) {
        // Silently fail notification
      }

      emit(state.copyWith(
        successMessage: 'Application status updated to ${status.toString().split('.').last}.',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  // Withdraw application (student action)
  Future<void> withdrawApplication(String applicationId) async {
    try {
      await _applicationRepository.withdrawApplication(applicationId);
      emit(state.copyWith(successMessage: 'Application withdrawn.'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  // Load stats for startup dashboard
  Future<void> loadStats(String startupId) async {
    try {
      final stats = await _applicationRepository.getApplicationStats(startupId);
      emit(state.copyWith(stats: stats));
    } catch (e) {
      // Silently fail for stats
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  @override
  Future<void> close() {
    _myApplicationsSubscription?.cancel();
    _receivedApplicationsSubscription?.cancel();
    return super.close();
  }
}
