import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/startup_model.dart';
import '../../core/constants/app_constants.dart';

class StartupRepository {
  final FirebaseFirestore _firestore;

  StartupRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _startups =>
      _firestore.collection(AppConstants.startupsCollection);

  // Create startup profile
  Future<StartupModel> createStartup(StartupModel startup) async {
    final docRef = await _startups.add(startup.toFirestore());
    final doc = await docRef.get();
    return StartupModel.fromFirestore(doc);
  }

  // Get startup by ID
  Future<StartupModel?> getStartupById(String id) async {
    final doc = await _startups.doc(id).get();
    if (!doc.exists) return null;
    return StartupModel.fromFirestore(doc);
  }

  // Get startup by owner ID
  Future<StartupModel?> getStartupByOwnerId(String ownerId) async {
    final query = await _startups
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return StartupModel.fromFirestore(query.docs.first);
  }

  // Real-time stream of startup by owner
  Stream<StartupModel?> startupByOwnerStream(String ownerId) {
    return _startups
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return StartupModel.fromFirestore(snapshot.docs.first);
    });
  }

  // Get all verified startups
  Stream<List<StartupModel>> verifiedStartupsStream() {
    return _startups
        .where('verificationStatus', isEqualTo: 'verified')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => StartupModel.fromFirestore(doc)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Get all startups (for admin)
  Stream<List<StartupModel>> allStartupsStream() {
    return _startups
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StartupModel.fromFirestore(doc)).toList());
  }

  // Search startups by name or category
  Future<List<StartupModel>> searchStartups(String query) async {
    // Firestore doesn't support native full-text search
    // Using client-side filtering for simple search
    final snapshot = await _startups
        .where('verificationStatus', isEqualTo: 'verified')
        .get();

    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => StartupModel.fromFirestore(doc))
        .where((s) =>
            s.name.toLowerCase().contains(lowerQuery) ||
            s.category.toLowerCase().contains(lowerQuery) ||
            s.tagline.toLowerCase().contains(lowerQuery) ||
            s.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  // Update startup
  Future<StartupModel> updateStartup(StartupModel startup) async {
    await _startups.doc(startup.id).update(startup.toFirestore());
    return startup;
  }

  // Update verification status (admin only)
  Future<void> updateVerificationStatus(
    String startupId,
    VerificationStatus status, {
    String? note,
  }) async {
    await _startups.doc(startupId).update({
      'verificationStatus': status.toString().split('.').last,
      if (note != null) 'verificationNote': note,
      'updatedAt': Timestamp.now(),
    });
  }

  // Get startups by category
  Stream<List<StartupModel>> startupsByCategoryStream(String category) {
    return _startups
        .where('verificationStatus', isEqualTo: 'verified')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StartupModel.fromFirestore(doc)).toList());
  }

  // Increment opportunity count
  Future<void> incrementOpportunityCount(String startupId) async {
    await _startups.doc(startupId).update({
      'opportunityCount': FieldValue.increment(1),
    });
  }
}
