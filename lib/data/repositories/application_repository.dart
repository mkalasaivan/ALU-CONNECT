import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';
import '../../core/constants/app_constants.dart';

class ApplicationRepository {
  final FirebaseFirestore _firestore;

  ApplicationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _applications =>
      _firestore.collection(AppConstants.applicationsCollection);

  // Submit application
  Future<ApplicationModel> submitApplication(ApplicationModel application) async {
    final docRef = await _applications.add(application.toFirestore());
    final doc = await docRef.get();
    return ApplicationModel.fromFirestore(doc);
  }

  // Check if user already has an active (not rejected and not withdrawn) application
  Future<bool> hasApplied(String opportunityId, String applicantId) async {
    final query = await _applications
        .where('opportunityId', isEqualTo: opportunityId)
        .where('applicantId', isEqualTo: applicantId)
        .get();

    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'pending';
      if (status != 'rejected' && status != 'withdrawn') {
        return true;
      }
    }
    return false;
  }

  // Get applications for a student (real-time)
  Stream<List<ApplicationModel>> studentApplicationsStream(String applicantId) {
    return _applications
        .where('applicantId', isEqualTo: applicantId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => ApplicationModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return list;
        });
  }

  // Get applications for an opportunity (startup view - real-time)
  Stream<List<ApplicationModel>> opportunityApplicationsStream(String opportunityId) {
    return _applications
        .where('opportunityId', isEqualTo: opportunityId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => ApplicationModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return list;
        });
  }

  // Get all applications for a startup (real-time)
  Stream<List<ApplicationModel>> startupApplicationsStream(String startupId) {
    return _applications
        .where('startupId', isEqualTo: startupId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => ApplicationModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          return list;
        });
  }

  // Update application status
  Future<ApplicationModel> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status, {
    String? note,
  }) async {
    final updates = {
      'status': status.toString().split('.').last,
      'updatedAt': Timestamp.now(),
      if (note != null) 'statusNote': note,
    };
    await _applications.doc(applicationId).update(updates);
    final doc = await _applications.doc(applicationId).get();
    return ApplicationModel.fromFirestore(doc);
  }

  // Withdraw application
  Future<void> withdrawApplication(String applicationId) async {
    await _applications.doc(applicationId).update({
      'status': ApplicationStatus.withdrawn.name,
      'updatedAt': Timestamp.now(),
    });
  }

  // Get application by ID
  Future<ApplicationModel?> getApplicationById(String id) async {
    final doc = await _applications.doc(id).get();
    if (!doc.exists) return null;
    return ApplicationModel.fromFirestore(doc);
  }

  // Get application stats for startup
  Future<Map<String, int>> getApplicationStats(String startupId) async {
    final snapshot = await _applications
        .where('startupId', isEqualTo: startupId)
        .get();

    final stats = <String, int>{
      'total': 0,
      'pending': 0,
      'reviewing': 0,
      'shortlisted': 0,
      'accepted': 0,
      'rejected': 0,
    };

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'pending';
      stats['total'] = (stats['total'] ?? 0) + 1;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }
}
