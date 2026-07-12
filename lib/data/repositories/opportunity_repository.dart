import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/opportunity_model.dart';
import '../../core/constants/app_constants.dart';

class OpportunityRepository {
  final FirebaseFirestore _firestore;

  OpportunityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _opportunities =>
      _firestore.collection(AppConstants.opportunitiesCollection);

  // Create opportunity
  Future<OpportunityModel> createOpportunity(OpportunityModel opportunity) async {
    final docRef = await _opportunities.add(opportunity.toFirestore());
    final doc = await docRef.get();
    return OpportunityModel.fromFirestore(doc);
  }

  // Get all open opportunities - real-time
  Stream<List<OpportunityModel>> openOpportunitiesStream() {
    return _opportunities
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => OpportunityModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Get opportunities by startup
  Stream<List<OpportunityModel>> opportunitiesByStartupStream(String startupId) {
    return _opportunities
        .where('startupId', isEqualTo: startupId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => OpportunityModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Get single opportunity
  Future<OpportunityModel?> getOpportunityById(String id) async {
    final doc = await _opportunities.doc(id).get();
    if (!doc.exists) return null;
    return OpportunityModel.fromFirestore(doc);
  }

  // Real-time single opportunity stream
  Stream<OpportunityModel?> opportunityStream(String id) {
    return _opportunities.doc(id).snapshots().map(
        (doc) => doc.exists ? OpportunityModel.fromFirestore(doc) : null);
  }

  // Search opportunities
  Future<List<OpportunityModel>> searchOpportunities({
    String? query,
    String? type,
    String? location,
    bool? isPaid,
    String? campus,
  }) async {
    Query q = _opportunities.where('status', isEqualTo: 'open');

    if (type != null && type.isNotEmpty) {
      q = q.where('type', isEqualTo: type);
    }
    if (location != null && location.isNotEmpty) {
      q = q.where('location', isEqualTo: location);
    }
    if (isPaid != null) {
      q = q.where('isPaid', isEqualTo: isPaid);
    }
    if (campus != null && campus.isNotEmpty) {
      q = q.where('campus', isEqualTo: campus);
    }

    final snapshot = await q.get();
    List<OpportunityModel> results =
        snapshot.docs.map((d) => OpportunityModel.fromFirestore(d)).toList();

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results
          .where((o) =>
              o.title.toLowerCase().contains(lowerQuery) ||
              o.description.toLowerCase().contains(lowerQuery) ||
              o.startupName.toLowerCase().contains(lowerQuery) ||
              o.requiredSkills.any((s) => s.toLowerCase().contains(lowerQuery)))
          .toList();
    }

    return results;
  }

  // Update opportunity
  Future<OpportunityModel> updateOpportunity(OpportunityModel opportunity) async {
    await _opportunities.doc(opportunity.id).update(opportunity.toFirestore());
    return opportunity;
  }

  // Toggle bookmark
  Future<void> toggleBookmark(String opportunityId, String userId) async {
    final doc = await _opportunities.doc(opportunityId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);

    if (bookmarkedBy.contains(userId)) {
      bookmarkedBy.remove(userId);
    } else {
      bookmarkedBy.add(userId);
    }

    await _opportunities.doc(opportunityId).update({'bookmarkedBy': bookmarkedBy});
  }

  // Get bookmarked opportunities for a user
  Stream<List<OpportunityModel>> bookmarkedOpportunitiesStream(String userId) {
    return _opportunities
        .where('bookmarkedBy', arrayContains: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => OpportunityModel.fromFirestore(d)).toList());
  }

  // Increment applicant count
  Future<void> incrementApplicantCount(String opportunityId) async {
    await _opportunities.doc(opportunityId).update({
      'applicantCount': FieldValue.increment(1),
    });
  }

  // Update opportunity status
  Future<void> updateStatus(String opportunityId, OpportunityStatus status) async {
    await _opportunities.doc(opportunityId).update({
      'status': status.toString().split('.').last,
      'updatedAt': Timestamp.now(),
    });
  }

  // Delete opportunity
  Future<void> deleteOpportunity(String opportunityId) async {
    await _opportunities.doc(opportunityId).delete();
  }
}
