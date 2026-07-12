import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/opportunity_model.dart';
import '../../../data/repositories/opportunity_repository.dart';

// --- State ---
enum OpportunityStatus2 { initial, loading, loaded, error }

class OpportunityState extends Equatable {
  final OpportunityStatus2 status;
  final List<OpportunityModel> opportunities;
  final List<OpportunityModel> searchResults;
  final List<OpportunityModel> bookmarkedOpportunities;
  final String? errorMessage;
  final String? successMessage;
  final bool isSearching;
  final String searchQuery;
  final String? typeFilter;
  final String? locationFilter;
  final bool? isPaidFilter;

  const OpportunityState({
    this.status = OpportunityStatus2.initial,
    this.opportunities = const [],
    this.searchResults = const [],
    this.bookmarkedOpportunities = const [],
    this.errorMessage,
    this.successMessage,
    this.isSearching = false,
    this.searchQuery = '',
    this.typeFilter,
    this.locationFilter,
    this.isPaidFilter,
  });

  List<OpportunityModel> get displayedOpportunities =>
      isSearching ? searchResults : opportunities;

  bool get hasActiveFilters =>
      typeFilter != null || locationFilter != null || isPaidFilter != null;

  OpportunityState copyWith({
    OpportunityStatus2? status,
    List<OpportunityModel>? opportunities,
    List<OpportunityModel>? searchResults,
    List<OpportunityModel>? bookmarkedOpportunities,
    String? errorMessage,
    String? successMessage,
    bool? isSearching,
    String? searchQuery,
    String? typeFilter,
    String? locationFilter,
    bool? isPaidFilter,
    bool clearFilters = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return OpportunityState(
      status: status ?? this.status,
      opportunities: opportunities ?? this.opportunities,
      searchResults: searchResults ?? this.searchResults,
      bookmarkedOpportunities: bookmarkedOpportunities ?? this.bookmarkedOpportunities,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearFilters ? null : (typeFilter ?? this.typeFilter),
      locationFilter: clearFilters ? null : (locationFilter ?? this.locationFilter),
      isPaidFilter: clearFilters ? null : (isPaidFilter ?? this.isPaidFilter),
    );
  }

  @override
  List<Object?> get props => [
        status,
        opportunities,
        searchResults,
        bookmarkedOpportunities,
        errorMessage,
        successMessage,
        isSearching,
        searchQuery,
        typeFilter,
        locationFilter,
        isPaidFilter,
      ];
}

// --- Cubit ---
class OpportunityCubit extends Cubit<OpportunityState> {
  final OpportunityRepository _repository;
  StreamSubscription<List<OpportunityModel>>? _opportunitiesSubscription;
  StreamSubscription<List<OpportunityModel>>? _bookmarksSubscription;

  OpportunityCubit({required OpportunityRepository repository})
      : _repository = repository,
        super(const OpportunityState());

  void subscribeToOpportunities() {
    _opportunitiesSubscription?.cancel();
    _opportunitiesSubscription =
        _repository.openOpportunitiesStream().listen(
      (opportunities) {
        emit(state.copyWith(
          status: OpportunityStatus2.loaded,
          opportunities: opportunities,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: OpportunityStatus2.error,
          errorMessage: e.toString(),
        ));
      },
    );
  }

  void subscribeToBookmarks(String userId) {
    _bookmarksSubscription?.cancel();
    _bookmarksSubscription =
        _repository.bookmarkedOpportunitiesStream(userId).listen(
      (bookmarked) {
        emit(state.copyWith(bookmarkedOpportunities: bookmarked));
      },
      onError: (e) {
        emit(state.copyWith(
          errorMessage: 'Failed to sync bookmarks: ${e.toString()}',
        ));
      },
    );
  }

  Future<void> searchOpportunities({
    String? query,
    String? type,
    String? location,
    bool? isPaid,
  }) async {
    emit(state.copyWith(
      isSearching: true,
      searchQuery: query ?? state.searchQuery,
      typeFilter: type,
      locationFilter: location,
      isPaidFilter: isPaid,
    ));

    try {
      final results = await _repository.searchOpportunities(
        query: query,
        type: type,
        location: location,
        isPaid: isPaid,
      );
      emit(state.copyWith(
        status: OpportunityStatus2.loaded,
        searchResults: results,
        isSearching: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString(), clearError: false));
    }
  }

  void clearSearch() {
    emit(state.copyWith(
      isSearching: false,
      searchQuery: '',
      searchResults: [],
      clearFilters: true,
    ));
  }

  Future<void> toggleBookmark(String opportunityId, String userId) async {
    try {
      await _repository.toggleBookmark(opportunityId, userId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update bookmark'));
    }
  }

  Future<void> createOpportunity(OpportunityModel opportunity) async {
    try {
      await _repository.createOpportunity(opportunity);
      emit(state.copyWith(successMessage: 'Opportunity posted successfully!'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> updateOpportunity(OpportunityModel opportunity) async {
    try {
      await _repository.updateOpportunity(opportunity);
      emit(state.copyWith(successMessage: 'Opportunity updated successfully!'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> deleteOpportunity(String opportunityId) async {
    try {
      await _repository.deleteOpportunity(opportunityId);
      emit(state.copyWith(successMessage: 'Opportunity deleted.'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  bool isBookmarked(String opportunityId, String userId) {
    return state.bookmarkedOpportunities.any((o) => o.id == opportunityId);
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  @override
  Future<void> close() {
    _opportunitiesSubscription?.cancel();
    _bookmarksSubscription?.cancel();
    return super.close();
  }
}
