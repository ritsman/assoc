part of '../../main.dart';

class SynetraApiClient {
  SynetraApiClient({
    http.Client? httpClient,
    String? authToken,
    Future<String?> Function()? refreshAuthToken,
  }) : _httpClient = httpClient ?? http.Client(),
       _authToken = authToken?.trim() ?? '',
       _refreshAuthToken = refreshAuthToken;

  final http.Client _httpClient;
  final String _authToken;
  final Future<String?> Function()? _refreshAuthToken;
  final String _baseUrl = 'https://app.operisaverick.com/api';
  final Map<String, _ApiCacheEntry<dynamic>> _cache = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  static const _shortCacheTtl = Duration(seconds: 30);
  static const _mediumCacheTtl = Duration(minutes: 2);
  static const _dashboardCacheTtl = Duration(seconds: 45);
  static const _requestTimeout = Duration(seconds: 15);
  static const Set<String> _memberCacheKeys = {
    'members',
    'members-directory',
    'members-admin',
  };

  bool _isMemberVisibleToApp(Map<String, dynamic> item) {
    final user = item['user'] as Map<String, dynamic>?;
    final approvalStatus =
        user?['approvalStatus']?.toString().trim().toUpperCase() ?? '';
    final isActive = user?['isActive'] == true;
    return approvalStatus == 'APPROVED' && isActive;
  }

  bool _isVendorVisibleToApp(Map<String, dynamic> item) {
    final vendorStatus = item['status']?.toString().trim().toUpperCase() ?? '';
    if (vendorStatus != 'ACTIVE') {
      return false;
    }

    final users =
        (item['users'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
    final primaryUser =
        users.isNotEmpty ? users.first : item['user'] as Map<String, dynamic>?;

    if (primaryUser == null) {
      return false;
    }

    final approvalStatus =
        primaryUser['approvalStatus']?.toString().trim().toUpperCase() ?? '';
    final isActive = primaryUser['isActive'] == true;

    return approvalStatus == 'APPROVED' && isActive;
  }

  Future<AuthSession> authenticate({
    required String username,
    required String password,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _buildHeaders(includeJsonContentType: true),
      body: jsonEncode({'username': username.trim(), 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    return AuthSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AuthSession> fetchCurrentSession() async {
    final response = await _authorizedGet(Uri.parse('$_baseUrl/auth/me'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    return AuthSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AuthSession> refreshSession({required String refreshToken}) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: _buildHeaders(includeJsonContentType: true),
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    return AuthSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> logout() async {
    final response = await _authorizedPost(
      Uri.parse('$_baseUrl/auth/logout'),
      includeJsonContentType: false,
    );

    if (response.statusCode == 401) {
      return;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: _buildHeaders(includeJsonContentType: true),
      body: jsonEncode({
        'username': username.trim(),
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<MemberArenaData> loadMemberArenaData({
    required AppViewerRole viewerRole,
  }) async {
    final results = await Future.wait<dynamic>([
      fetchPosts(approvedOnly: !viewerRole.isAdmin),
      fetchMembers(approvedOnly: !viewerRole.isAdmin),
    ]);
    final posts = results[0] as List<MemberPostItem>;
    final members = results[1] as List<MemberDirectoryItem>;
    return MemberArenaData(posts: posts, members: members);
  }

  Future<AdminArenaData> loadAdminArenaData() async {
    final results = await Future.wait<dynamic>([
      fetchAppAccess(),
      fetchAdminMembers(),
      fetchPosts(approvedOnly: false),
      fetchAdminVendors(),
      fetchAdminAppBanners(),
      fetchAdminTimelinePosts(),
      fetchEvents(),
      fetchEventTypes(),
    ]);
    final appAccess = results[0] as AdminAppAccessSettings;
    final members = results[1] as List<AdminMemberAccessItem>;
    final posts = results[2] as List<MemberPostItem>;
    final vendors = results[3] as List<AdminVendorAccessItem>;
    final appBanners = results[4] as List<AdminAppBannerItem>;
    final timelinePosts = results[5] as List<AdminTimelineItem>;
    final events = results[6] as List<AdminEventItem>;
    final eventTypes = results[7] as List<AdminEventTypeItem>;
    return AdminArenaData(
      appAccess: appAccess,
      members: members,
      posts: posts,
      vendors: vendors,
      appBanners: appBanners,
      timelinePosts: timelinePosts,
      events: events,
      eventTypes: eventTypes,
    );
  }

  Future<List<MemberPostItem>> fetchPosts({required bool approvedOnly}) async {
    final uri = Uri.parse('$_baseUrl/member-posts').replace(
      queryParameters:
          approvedOnly
              ? {'reviewStatus': PostReviewStatus.approved.apiValue}
              : null,
    );
    final json = await _getCachedJson(
      uri,
      cacheKey: approvedOnly ? 'posts-approved' : 'posts-all',
      ttl: _shortCacheTtl,
    );
    final items = (json['posts'] as List<dynamic>? ?? const []);
    return items
        .map((item) => MemberPostItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MemberDirectoryItem>> fetchMembers({
    bool approvedOnly = false,
  }) async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/members?view=directory'),
      cacheKey: 'members-directory',
      ttl: _mediumCacheTtl,
    );
    final items = (json['members'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .where((item) => !approvedOnly || _isMemberVisibleToApp(item))
        .map((item) => MemberDirectoryItem.fromJson(item))
        .toList();
  }

  Future<List<AdminMemberAccessItem>> fetchAdminMembers() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/members?view=admin'),
      cacheKey: 'members-admin',
      ttl: _mediumCacheTtl,
    );
    final items = (json['members'] as List<dynamic>? ?? const []);
    return items
        .map(
          (item) =>
              AdminMemberAccessItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<AdminAppAccessSettings> fetchAppAccess() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/associations/current/app-access'),
      cacheKey: 'association-app-access',
      ttl: _shortCacheTtl,
    );
    return AdminAppAccessSettings.fromJson(
      json['appAccess'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<List<AdminVendorAccessItem>> fetchAdminVendors() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/vendors'),
      cacheKey: 'admin-vendors',
      ttl: _shortCacheTtl,
    );
    final items = (json['vendors'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(AdminVendorAccessItem.fromJson)
        .toList();
  }

  Future<List<AdminAppBannerItem>> fetchAdminAppBanners() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/app-banners'),
      cacheKey: 'admin-app-banners',
      ttl: _shortCacheTtl,
    );
    final items = (json['banners'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(AdminAppBannerItem.fromJson)
        .toList();
  }

  Future<List<AdminTimelineItem>> fetchAdminTimelinePosts() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/timeline-posts'),
      cacheKey: 'admin-timeline-posts',
      ttl: _shortCacheTtl,
    );
    final items = (json['posts'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(AdminTimelineItem.fromJson)
        .toList();
  }

  Future<List<AdminEventItem>> fetchEvents() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/events'),
      cacheKey: 'events',
      ttl: _shortCacheTtl,
    );
    final items = (json['events'] as List<dynamic>? ?? const []);
    return items
        .map((item) => AdminEventItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminEventTypeItem>> fetchEventTypes() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/events/types'),
      cacheKey: 'event-types',
      ttl: _mediumCacheTtl,
    );
    final items = (json['eventTypes'] as List<dynamic>? ?? const []);
    return items
        .map(
          (item) => AdminEventTypeItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<SessionReportData> fetchSessionReport() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/users/session-report'),
      cacheKey: 'session-report',
      ttl: _shortCacheTtl,
    );
    return SessionReportData.fromJson(json);
  }

  Future<EventsArenaData> loadEventsArenaData() async {
    final results = await Future.wait<dynamic>([
      fetchEvents(),
      fetchEventTypes(),
    ]);
    final events = results[0] as List<AdminEventItem>;
    final eventTypes = results[1] as List<AdminEventTypeItem>;
    return EventsArenaData(events: events, eventTypes: eventTypes);
  }

  Future<DashboardData> loadDashboardData() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/associations/current/dashboard-summary'),
      cacheKey: 'dashboard-summary',
      ttl: _dashboardCacheTtl,
    );
    final optionalResults = await Future.wait<Map<String, dynamic>>([
      _getCachedJsonOrEmpty(
        Uri.parse('$_baseUrl/app-banners'),
        cacheKey: 'dashboard-banners',
        ttl: _dashboardCacheTtl,
      ),
      _getCachedJsonOrEmpty(
        Uri.parse('$_baseUrl/timeline-posts'),
        cacheKey: 'dashboard-timeline',
        ttl: _dashboardCacheTtl,
      ),
      _getCachedJsonOrEmpty(
        Uri.parse('$_baseUrl/vendors'),
        cacheKey: 'dashboard-vendors',
        ttl: _dashboardCacheTtl,
      ),
    ]);
    final bannersJson = optionalResults[0];
    final timelineJson = optionalResults[1];
    final vendorsJson = optionalResults[2];
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    final galleryItems =
        (summary['galleryItems'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  DashboardGalleryItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
    final upcomingEvents =
        (summary['upcomingEvents'] as List<dynamic>? ?? const [])
            .map(
              (item) => AdminEventItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
    final committeeMembers =
        (summary['committeeMembers'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  MemberDirectoryItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
    final appBanners =
        (bannersJson['banners'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .where(
              (item) =>
                  item['reviewStatus']?.toString().toUpperCase() ==
                      'APPROVED' &&
                  ((item['displayIndex'] as num?)?.toInt() ?? 0) > 0,
            )
            .map(DashboardAppBannerItem.fromJson)
            .where((item) => item.displayIndex > 0)
            .toList()
          ..sort(
            (left, right) => left.displayIndex.compareTo(right.displayIndex),
          );
    final timelinePosts =
        (timelineJson['posts'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .where(
              (item) =>
                  item['reviewStatus']?.toString().toUpperCase() == 'APPROVED',
            )
            .map(DashboardTimelineItem.fromJson)
            .toList();
    final featuredVendors =
        (vendorsJson['vendors'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .where(_isVendorVisibleToApp)
            .map(DashboardVendorItem.fromJson)
            .toList()
          ..shuffle();

    return DashboardData(
      associationName: summary['associationName']?.toString() ?? '',
      galleryItems: galleryItems,
      committeeMembers: committeeMembers,
      totalMembers: (summary['totalMembers'] as num?)?.toInt() ?? 0,
      totalCities: (summary['totalCities'] as num?)?.toInt() ?? 0,
      totalGuests: (summary['totalGuests'] as num?)?.toInt() ?? 0,
      totalVendors: (summary['totalVendors'] as num?)?.toInt() ?? 0,
      upcomingEvents: upcomingEvents,
      appBanners: appBanners,
      featuredVendors: featuredVendors.take(10).toList(),
      timelinePosts: timelinePosts,
    );
  }

  Future<List<DashboardVendorItem>> fetchVendors() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/vendors'),
      cacheKey: 'dashboard-vendors',
      ttl: _dashboardCacheTtl,
    );
    final items = (json['vendors'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .where(_isVendorVisibleToApp)
        .map(DashboardVendorItem.fromJson)
        .toList();
  }

  Future<List<VendorTaxonomyCategoryItem>> fetchVendorTaxonomy() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/vendor-taxonomy/categories'),
      cacheKey: 'vendor-taxonomy',
      ttl: _shortCacheTtl,
    );
    final items = (json['categories'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(VendorTaxonomyCategoryItem.fromJson)
        .toList()
      ..sort((left, right) {
        final orderCompare = left.displayOrder.compareTo(right.displayOrder);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
  }

  Future<void> uploadAssociationGalleryImages({
    required String associationId,
    required List<AssociationUploadFile> files,
  }) async {
    if (files.isEmpty) {
      return;
    }

    final uri = Uri.parse(
      '$_baseUrl/associations/$associationId/gallery/uploads',
    );
    final response = await _authorizedMultipartRequest((overrideAuthToken) {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(
        _buildHeaders(overrideAuthToken: overrideAuthToken),
      );

      for (final file in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            file.bytes,
            filename: file.name,
          ),
        );
      }

      return request;
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'association-current', 'dashboard-summary'});
  }

  Future<void> createAssociationGalleryFolder({
    required String associationId,
    required String name,
    required List<AssociationUploadFile> files,
  }) async {
    if (name.trim().isEmpty || files.isEmpty) {
      return;
    }

    final uri = Uri.parse(
      '$_baseUrl/associations/$associationId/gallery/folders',
    );
    final response = await _authorizedMultipartRequest((overrideAuthToken) {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(
        _buildHeaders(overrideAuthToken: overrideAuthToken),
      );
      request.fields['name'] = name.trim();

      for (final file in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            file.bytes,
            filename: file.name,
          ),
        );
      }

      return request;
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'association-current', 'dashboard-summary'});
  }

  Future<void> renameAssociationGalleryFolder({
    required String associationId,
    required String folderId,
    required String name,
  }) async {
    final response = await _authorizedPatch(
      Uri.parse(
        '$_baseUrl/associations/$associationId/gallery/folders/$folderId',
      ),
      includeJsonContentType: true,
      body: jsonEncode({'name': name.trim()}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'association-current', 'dashboard-summary'});
  }

  Future<void> deleteAssociationGalleryFolder({
    required String associationId,
    required String folderId,
  }) async {
    final response = await _authorizedDelete(
      Uri.parse(
        '$_baseUrl/associations/$associationId/gallery/folders/$folderId',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'association-current', 'dashboard-summary'});
  }

  Future<void> deleteAssociationGalleryFolderPhoto({
    required String associationId,
    required String folderId,
    required String photoId,
  }) async {
    final response = await _authorizedDelete(
      Uri.parse(
        '$_baseUrl/associations/$associationId/gallery/folders/$folderId/photos/$photoId',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'association-current', 'dashboard-summary'});
  }

  Future<void> deleteAssociationGalleryItem({
    required String associationId,
    required String galleryItemId,
  }) async {
    final response = await _authorizedDelete(
      Uri.parse('$_baseUrl/associations/$associationId/gallery/$galleryItemId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'association-current', 'dashboard-summary'});
  }

  Future<void> updateMemberAccess({
    required String memberId,
    required MemberAccessStatus status,
  }) async {
    final uri = Uri.parse('$_baseUrl/members/$memberId/access');
    final response = await _authorizedPatch(
      uri,
      includeJsonContentType: true,
      body: jsonEncode({'accessStatus': status.apiValue}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({..._memberCacheKeys, 'dashboard-summary'});
  }

  Future<void> updateAppAccess({
    required AdminAppAccessSettings settings,
  }) async {
    final uri = Uri.parse('$_baseUrl/associations/current/app-access');
    final response = await _authorizedPatch(
      uri,
      includeJsonContentType: true,
      body: jsonEncode(settings.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'association-app-access'});
  }

  Future<void> updateVendorAccess({
    required String vendorId,
    required MemberAccessStatus status,
  }) async {
    final response = await _authorizedPatch(
      Uri.parse('$_baseUrl/vendors/$vendorId/access'),
      includeJsonContentType: true,
      body: jsonEncode({'accessStatus': status.apiValue}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    _invalidateCacheKeys({'admin-vendors', 'dashboard-vendors'});
  }

  Future<void> saveVendorApproval({
    required String vendorId,
    required AdminVendorApprovalDraft draft,
    required MemberAccessStatus status,
  }) async {
    final notes = [
      if (draft.planName.trim().isNotEmpty)
        'Plan Name: ${draft.planName.trim()}',
      if (draft.openingTime.trim().isNotEmpty)
        'Opening Time: ${draft.openingTime.trim()}',
      if (draft.closingTime.trim().isNotEmpty)
        'Closing Time: ${draft.closingTime.trim()}',
      if (draft.gstNumber.trim().isNotEmpty)
        'GST Number: ${draft.gstNumber.trim()}',
      'Is Restaurant: ${draft.isRestaurant ? 'Yes' : 'No'}',
      if (draft.paymentMode.trim().isNotEmpty)
        'Payment Mode: ${draft.paymentMode.trim()}',
      if (draft.bankName.trim().isNotEmpty)
        'Bank Name: ${draft.bankName.trim()}',
      if (draft.transactionId.trim().isNotEmpty)
        'Transaction ID: ${draft.transactionId.trim()}',
      if (draft.paymentDescription.trim().isNotEmpty)
        'Payment Description: ${draft.paymentDescription.trim()}',
      if (draft.googleLocation.trim().isNotEmpty)
        'Google Location: ${draft.googleLocation.trim()}',
      if (draft.idProof?.name.trim().isNotEmpty == true)
        'ID Proof: ${draft.idProof!.name.trim()}',
      if (draft.locationProof?.name.trim().isNotEmpty == true)
        'Location Proof: ${draft.locationProof!.name.trim()}',
      if (draft.companyBrochure?.name.trim().isNotEmpty == true)
        'Company Profile/Brochure: ${draft.companyBrochure!.name.trim()}',
      if (draft.profilePhoto?.name.trim().isNotEmpty == true)
        'Profile Photo: ${draft.profilePhoto!.name.trim()}',
      if (draft.visitingCard?.name.trim().isNotEmpty == true)
        'Visiting Card: ${draft.visitingCard!.name.trim()}',
    ].join('\n');

    final patchResponse = await _authorizedPatch(
      Uri.parse('$_baseUrl/vendors/$vendorId'),
      includeJsonContentType: true,
      body: jsonEncode({
        'membershipPlan': draft.membershipPlan.trim(),
        'paymentAmount': draft.paymentAmount.trim(),
        'onboardingStartAt':
            draft.onboardingStartAt.trim().isEmpty
                ? null
                : draft.onboardingStartAt.trim(),
        'onboardingEndAt':
            draft.onboardingEndAt.trim().isEmpty
                ? null
                : draft.onboardingEndAt.trim(),
        'paymentDueDate':
            draft.paymentDueDate.trim().isEmpty
                ? null
                : draft.paymentDueDate.trim(),
        'notes': notes,
      }),
    );
    if (patchResponse.statusCode < 200 || patchResponse.statusCode >= 300) {
      throw Exception(
        'Status ${patchResponse.statusCode}: ${patchResponse.body}',
      );
    }

    await updateVendorAccess(vendorId: vendorId, status: status);
    _invalidateCacheKeys({'admin-vendors', 'dashboard-vendors'});
  }

  Future<void> createVendorCategory({required String name}) async {
    final response = await _authorizedPost(
      Uri.parse('$_baseUrl/vendor-taxonomy/categories'),
      includeJsonContentType: true,
      body: jsonEncode({'name': name.trim()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'vendor-taxonomy',
      'admin-vendors',
      'dashboard-vendors',
    });
  }

  Future<void> updateVendorCategory({
    required String categoryId,
    required String name,
  }) async {
    final response = await _authorizedPatch(
      Uri.parse('$_baseUrl/vendor-taxonomy/categories/$categoryId'),
      includeJsonContentType: true,
      body: jsonEncode({'name': name.trim()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'vendor-taxonomy',
      'admin-vendors',
      'dashboard-vendors',
    });
  }

  Future<void> deleteVendorCategory({required String categoryId}) async {
    final response = await _authorizedDelete(
      Uri.parse('$_baseUrl/vendor-taxonomy/categories/$categoryId'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'vendor-taxonomy',
      'admin-vendors',
      'dashboard-vendors',
    });
  }

  Future<void> createVendorSubCategory({
    required String categoryId,
    required String name,
  }) async {
    final response = await _authorizedPost(
      Uri.parse('$_baseUrl/vendor-taxonomy/sub-categories'),
      includeJsonContentType: true,
      body: jsonEncode({'categoryId': categoryId, 'name': name.trim()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'vendor-taxonomy',
      'admin-vendors',
      'dashboard-vendors',
    });
  }

  Future<void> createVendorRecord({
    required AdminVendorRegistrationDraft draft,
  }) async {
    final response = await _authorizedPost(
      Uri.parse('$_baseUrl/vendors'),
      includeJsonContentType: true,
      body: jsonEncode({
        'name': draft.companyName.trim(),
        'companyName': draft.companyName.trim(),
        'contactPerson': draft.contactPerson.trim(),
        'phone': '${draft.phoneCode.trim()} ${draft.phone.trim()}'.trim(),
        'whatsapp':
            draft.whatsApp.trim().isEmpty
                ? ''
                : '${draft.whatsAppCode.trim()} ${draft.whatsApp.trim()}'
                    .trim(),
        'email': draft.email.trim(),
        'primaryLoginEmail': draft.primaryLoginEmail.trim().toLowerCase(),
        'secondaryLoginEmail':
            draft.secondaryLoginEmail.trim().isEmpty
                ? null
                : draft.secondaryLoginEmail.trim().toLowerCase(),
        'category': draft.categoryName.trim(),
        'vendorType': draft.subCategoryName.trim(),
        'address': draft.address.trim(),
        'city': draft.city.trim(),
        'facebookUrl': draft.facebookUrl.trim(),
        'instagramUrl': draft.instagramUrl.trim(),
        'youtubeUrl': draft.youtubeUrl.trim(),
        'linkedinUrl': draft.linkedinUrl.trim(),
        'xUrl': draft.xUrl.trim(),
        'paymentStatus': 'PENDING',
        'badge':
            draft.subCategoryName.trim().isNotEmpty
                ? draft.subCategoryName.trim()
                : draft.categoryName.trim(),
        'notes': [
          draft.country.trim().isNotEmpty
              ? 'Country: ${draft.country.trim()}'
              : '',
          draft.state.trim().isNotEmpty ? 'State: ${draft.state.trim()}' : '',
          draft.zipcode.trim().isNotEmpty
              ? 'Zipcode: ${draft.zipcode.trim()}'
              : '',
          draft.website.trim().isNotEmpty
              ? 'Website: ${draft.website.trim()}'
              : '',
        ].where((item) => item.isNotEmpty).join('\n'),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'admin-vendors',
      'dashboard-vendors',
      'vendor-taxonomy',
    });
  }

  Future<void> updateVendorSubCategory({
    required String subCategoryId,
    required String categoryId,
    required String name,
  }) async {
    final response = await _authorizedPatch(
      Uri.parse('$_baseUrl/vendor-taxonomy/sub-categories/$subCategoryId'),
      includeJsonContentType: true,
      body: jsonEncode({'categoryId': categoryId, 'name': name.trim()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'vendor-taxonomy',
      'admin-vendors',
      'dashboard-vendors',
    });
  }

  Future<void> deleteVendorSubCategory({required String subCategoryId}) async {
    final response = await _authorizedDelete(
      Uri.parse('$_baseUrl/vendor-taxonomy/sub-categories/$subCategoryId'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'vendor-taxonomy',
      'admin-vendors',
      'dashboard-vendors',
    });
  }

  Future<void> updateAppBannerModeration({
    required String bannerId,
    required BannerReviewStatus status,
    required bool paymentReceived,
    required String paymentMode,
    required String paymentRemarks,
    required int displayIndex,
    String? displayStart,
    String? displayEnd,
  }) async {
    final response = await _authorizedPatch(
      Uri.parse('$_baseUrl/app-banners/$bannerId/moderation'),
      includeJsonContentType: true,
      body: jsonEncode({
        'reviewStatus': status.apiValue,
        'paymentReceived': paymentReceived,
        'paymentMode': paymentMode,
        'paymentRemarks': paymentRemarks,
        'displayIndex':
            status == BannerReviewStatus.approved ? displayIndex : null,
        'displayStart':
            status == BannerReviewStatus.approved &&
                    (displayStart ?? '').trim().isNotEmpty
                ? displayStart!.trim()
                : null,
        'displayEnd':
            status == BannerReviewStatus.approved &&
                    (displayEnd ?? '').trim().isNotEmpty
                ? displayEnd!.trim()
                : null,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    _invalidateCacheKeys({'admin-app-banners', 'dashboard-banners'});
  }

  Future<void> createAppBanner({required AdminAppBannerDraft draft}) async {
    final uri = Uri.parse('$_baseUrl/app-banners');
    final response = await _authorizedMultipartRequest((overrideAuthToken) {
      final request =
          http.MultipartRequest('POST', uri)
            ..headers.addAll(
              _buildHeaders(overrideAuthToken: overrideAuthToken),
            )
            ..fields['vendorId'] = draft.vendorId.trim()
            ..fields['shortText'] = draft.shortText.trim()
            ..fields['contactNumber'] = draft.contactNumber.trim()
            ..fields['socialMediaUrl'] = draft.socialMediaUrl.trim();

      if (draft.mediaFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'mediaFile',
            draft.mediaFile!.bytes,
            filename: draft.mediaFile!.name,
          ),
        );
      }

      if (draft.brochureFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'brochureFile',
            draft.brochureFile!.bytes,
            filename: draft.brochureFile!.name,
          ),
        );
      }

      return request;
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    _invalidateCacheKeys({'admin-app-banners', 'dashboard-banners'});
  }

  Future<void> updateTimelineModeration({
    required String timelineId,
    required TimelineReviewStatus status,
  }) async {
    final response = await _authorizedPatch(
      Uri.parse('$_baseUrl/timeline-posts/$timelineId/moderation'),
      includeJsonContentType: true,
      body: jsonEncode({'reviewStatus': status.apiValue}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    _invalidateCacheKeys({'admin-timeline-posts', 'dashboard-timeline'});
  }

  Future<void> createTimelinePost({required AdminTimelineDraft draft}) async {
    final uri = Uri.parse('$_baseUrl/timeline-posts');
    final response = await _authorizedMultipartRequest((overrideAuthToken) {
      final request =
          http.MultipartRequest('POST', uri)
            ..headers.addAll(
              _buildHeaders(overrideAuthToken: overrideAuthToken),
            )
            ..fields['sourceType'] = draft.sourceType.trim().toUpperCase()
            ..fields['postedBy'] = draft.postedBy.trim()
            ..fields['caption'] = draft.caption.trim()
            ..fields['contactNumber'] = draft.contactNumber.trim()
            ..fields['landingPageUrl'] = draft.landingPageUrl.trim()
            ..fields['youtubeUrl'] = draft.youtubeUrl.trim()
            ..fields['facebookUrl'] = draft.facebookUrl.trim();

      if (draft.memberId.trim().isNotEmpty) {
        request.fields['memberId'] = draft.memberId.trim();
      }
      if (draft.vendorId.trim().isNotEmpty) {
        request.fields['vendorId'] = draft.vendorId.trim();
      }

      if (draft.imageFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'imageFile',
            draft.imageFile!.bytes,
            filename: draft.imageFile!.name,
            contentType: MediaType.parse(draft.imageFile!.mimeType),
          ),
        );
      }

      if (draft.brochureFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'brochureFile',
            draft.brochureFile!.bytes,
            filename: draft.brochureFile!.name,
            contentType: MediaType.parse(draft.brochureFile!.mimeType),
          ),
        );
      }

      return request;
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    _invalidateCacheKeys({'admin-timeline-posts', 'dashboard-timeline'});
  }

  Future<void> saveEvent({required AdminEventDraft draft}) async {
    final uri = Uri.parse(
      '$_baseUrl/events${draft.id.isEmpty ? '' : '/${draft.id}'}',
    );
    final response = await _authorizedMultipartRequest((overrideAuthToken) {
      final request =
          http.MultipartRequest(draft.id.isEmpty ? 'POST' : 'PATCH', uri)
            ..headers.addAll(
              _buildHeaders(overrideAuthToken: overrideAuthToken),
            )
            ..fields['name'] = draft.name
            ..fields['type'] = draft.type
            ..fields['audience'] = draft.audience
            ..fields['entryType'] = draft.entryType
            ..fields['entryCharges'] = draft.entryCharges
            ..fields['participationCharges'] = draft.participationCharges
            ..fields['date'] = draft.date
            ..fields['venue'] = draft.venue
            ..fields['startTime'] = draft.startTime
            ..fields['endTime'] = draft.endTime
            ..fields['summary'] = draft.summary;

      if (draft.bannerFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'bannerFile',
            draft.bannerFile!.bytes,
            filename: draft.bannerFile!.name,
          ),
        );
      }

      if (draft.videoFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'videoFile',
            draft.videoFile!.bytes,
            filename: draft.videoFile!.name,
          ),
        );
      }

      return request;
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'events'});
  }

  Future<void> deleteEvent({required String eventId}) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId');
    final response = await _authorizedDelete(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'events'});
  }

  Future<void> createEventType({required EventTypeDraft draft}) async {
    final response = await _authorizedPost(
      Uri.parse('$_baseUrl/events/types'),
      includeJsonContentType: true,
      body: jsonEncode({
        'name': draft.title.trim(),
        'description': draft.meta.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'event-types'});
  }

  Future<void> updateEventType({required EventTypeDraft draft}) async {
    final response = await _authorizedPatch(
      Uri.parse('$_baseUrl/events/types/${draft.id}'),
      includeJsonContentType: true,
      body: jsonEncode({
        'name': draft.title.trim(),
        'description': draft.meta.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'event-types'});
  }

  Future<AssociationProfileData> fetchAssociationProfile() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/associations/current'),
      cacheKey: 'association-current',
      ttl: _mediumCacheTtl,
    );
    return AssociationProfileData.fromJson(
      json['association'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> updateAssociationProfile({
    required AssociationProfileDraft draft,
  }) async {
    final uri = Uri.parse('$_baseUrl/associations/${draft.id}');
    final response = await _authorizedPatch(
      uri,
      includeJsonContentType: true,
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'association-current',
      'association-about',
      'association-circular-library',
      'dashboard-summary',
    });
  }

  Future<AssociationAboutData> fetchAssociationAbout() async {
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/associations/current/about'),
      cacheKey: 'association-about',
      ttl: _mediumCacheTtl,
    );
    return AssociationAboutData.fromJson(
      json['aboutContent'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> updateAssociationAbout({
    required AssociationAboutDraft draft,
  }) async {
    final profile = await fetchAssociationProfile();
    final uri = Uri.parse('$_baseUrl/associations/${profile.id}/about');
    final response = await _authorizedPatch(
      uri,
      includeJsonContentType: true,
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'association-about',
      'association-current',
      'dashboard-summary',
    });
  }

  Future<AssociationCircularLibraryData>
  fetchAssociationCircularLibrary() async {
    final profile = await fetchAssociationProfile();
    final json = await _getCachedJson(
      Uri.parse('$_baseUrl/associations/${profile.id}/circulars'),
      cacheKey: 'association-circular-library',
      ttl: _mediumCacheTtl,
    );
    final items = (json['circularDocuments'] as List<dynamic>? ?? const []);
    return AssociationCircularLibraryData(
      associationId: profile.id,
      associationName: profile.name,
      items:
          items
              .map(
                (item) => AssociationCircularDocument.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Future<void> saveAssociationCircular({
    required String associationId,
    required AssociationCircularDraft draft,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/associations/$associationId/circulars${draft.id.isEmpty ? '' : '/${draft.id}'}',
    );
    final response = await _authorizedMultipartRequest((overrideAuthToken) {
      final request =
          http.MultipartRequest(draft.id.isEmpty ? 'POST' : 'PATCH', uri)
            ..headers.addAll(
              _buildHeaders(overrideAuthToken: overrideAuthToken),
            )
            ..fields['headline'] = draft.headline
            ..fields['tagline'] = draft.tagline
            ..fields['summary'] = draft.summary;

      final selectedFile = draft.selectedFile;
      if (selectedFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            selectedFile.bytes,
            filename: selectedFile.name,
          ),
        );
      }

      return request;
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'association-circular-library',
      'association-current',
    });
  }

  Future<void> deleteAssociationCircular({
    required String associationId,
    required String circularId,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/associations/$associationId/circulars/$circularId',
    );
    final response = await _authorizedDelete(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({
      'association-circular-library',
      'association-current',
    });
  }

  Future<void> saveMemberRecord({required MemberMasterDraft draft}) async {
    if (draft.id.isEmpty) {
      final createResponse = await _authorizedPost(
        Uri.parse('$_baseUrl/members'),
        includeJsonContentType: true,
        body: jsonEncode(draft.toJson()),
      );
      if (createResponse.statusCode < 200 || createResponse.statusCode >= 300) {
        throw Exception(
          'Status ${createResponse.statusCode}: ${createResponse.body}',
        );
      }
      _invalidateCacheKeys({..._memberCacheKeys, 'dashboard-summary'});
      return;
    }

    final response = await _authorizedPatch(
      Uri.parse('$_baseUrl/members/${draft.id}'),
      includeJsonContentType: true,
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({..._memberCacheKeys, 'dashboard-summary'});
  }

  Future<void> submitPublicMemberRegistration({
    required MemberMasterDraft draft,
  }) async {
    final guestDraft = draft.copyWith(
      membershipType: 'Guest',
      paymentStatus: 'Pending',
    );
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/members'),
      headers: _buildHeaders(includeJsonContentType: true),
      body: jsonEncode(guestDraft.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({..._memberCacheKeys, 'dashboard-summary'});
  }

  Future<void> updateMemberCommittee({
    required String memberId,
    required String committeePost,
    String committeeTenureStart = '',
    String committeeTenureEnd = '',
  }) async {
    final response = await _authorizedPatch(
      Uri.parse('$_baseUrl/members/$memberId'),
      includeJsonContentType: true,
      body: jsonEncode({
        'committeePost': committeePost,
        'committeeTenureStart': committeeTenureStart,
        'committeeTenureEnd': committeeTenureEnd,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({..._memberCacheKeys, 'dashboard-summary'});
  }

  Future<void> deleteMemberRecord({required String memberId}) async {
    final uri = Uri.parse('$_baseUrl/members/$memberId');
    final response = await _authorizedDelete(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({..._memberCacheKeys, 'dashboard-summary'});
  }

  Future<void> updatePostStatus({
    required String postId,
    required PostReviewStatus status,
  }) async {
    final uri = Uri.parse('$_baseUrl/member-posts/$postId/moderation');
    final response = await _authorizedPatch(
      uri,
      includeJsonContentType: true,
      body: jsonEncode({'reviewStatus': status.apiValue}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
    _invalidateCacheKeys({'posts-all', 'posts-approved'});
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    Object? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _authorizedGet(uri).timeout(_requestTimeout);

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        return jsonDecode(response.body) as Map<String, dynamic>;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      } on HandshakeException catch (error) {
        lastError = error;
      } on TimeoutException catch (error) {
        lastError = error;
      }

      if (attempt == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }

    if (lastError != null) {
      throw SynetraApiException.network(uri: uri, cause: lastError);
    }

    throw SynetraApiException(
      'Unable to reach the server right now. Please try again.',
    );
  }

  Future<http.Response> _authorizedGet(Uri uri) {
    return _sendWithAuthRefresh(
      (overrideAuthToken) => _httpClient.get(
        uri,
        headers: _buildHeaders(overrideAuthToken: overrideAuthToken),
      ),
    );
  }

  Future<http.Response> _authorizedPost(
    Uri uri, {
    bool includeJsonContentType = false,
    Object? body,
  }) {
    return _sendWithAuthRefresh(
      (overrideAuthToken) => _httpClient.post(
        uri,
        headers: _buildHeaders(
          includeJsonContentType: includeJsonContentType,
          overrideAuthToken: overrideAuthToken,
        ),
        body: body,
      ),
    );
  }

  Future<http.Response> _authorizedPatch(
    Uri uri, {
    bool includeJsonContentType = false,
    Object? body,
  }) {
    return _sendWithAuthRefresh(
      (overrideAuthToken) => _httpClient.patch(
        uri,
        headers: _buildHeaders(
          includeJsonContentType: includeJsonContentType,
          overrideAuthToken: overrideAuthToken,
        ),
        body: body,
      ),
    );
  }

  Future<http.Response> _authorizedDelete(Uri uri) {
    return _sendWithAuthRefresh(
      (overrideAuthToken) => _httpClient.delete(
        uri,
        headers: _buildHeaders(overrideAuthToken: overrideAuthToken),
      ),
    );
  }

  Future<http.Response> _authorizedMultipartRequest(
    http.MultipartRequest Function(String? overrideAuthToken) buildRequest,
  ) async {
    final response = await _sendMultipartRequest(buildRequest, null);
    if (response.statusCode != 401 || _refreshAuthToken == null) {
      return response;
    }

    final refreshedToken = await _refreshAuthToken();
    if (refreshedToken == null || refreshedToken.trim().isEmpty) {
      return response;
    }

    return _sendMultipartRequest(buildRequest, refreshedToken);
  }

  Future<http.Response> _sendMultipartRequest(
    http.MultipartRequest Function(String? overrideAuthToken) buildRequest,
    String? overrideAuthToken,
  ) async {
    final request = buildRequest(overrideAuthToken);
    final streamedResponse = await _httpClient.send(request);
    return http.Response.fromStream(streamedResponse);
  }

  Future<http.Response> _sendWithAuthRefresh(
    Future<http.Response> Function(String? overrideAuthToken) requestBuilder,
  ) async {
    final response = await requestBuilder(null);
    if (response.statusCode != 401 || _refreshAuthToken == null) {
      return response;
    }

    final refreshedToken = await _refreshAuthToken();
    if (refreshedToken == null || refreshedToken.trim().isEmpty) {
      return response;
    }

    return requestBuilder(refreshedToken);
  }

  Map<String, String> _buildHeaders({
    bool includeJsonContentType = false,
    String? overrideAuthToken,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      if (includeJsonContentType) 'Content-Type': 'application/json',
      if ((overrideAuthToken ?? _authToken).isNotEmpty)
        'Authorization': 'Bearer ${overrideAuthToken ?? _authToken}',
    };
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<Map<String, dynamic>> _getCachedJson(
    Uri uri, {
    required String cacheKey,
    required Duration ttl,
  }) async {
    return _withCache<Map<String, dynamic>>(
      cacheKey,
      ttl: ttl,
      loader: () => _getJson(uri),
    );
  }

  Future<Map<String, dynamic>> _getCachedJsonOrEmpty(
    Uri uri, {
    required String cacheKey,
    required Duration ttl,
  }) async {
    try {
      return await _getCachedJson(uri, cacheKey: cacheKey, ttl: ttl);
    } catch (_) {
      return const {};
    }
  }

  Future<T> _withCache<T>(
    String key, {
    required Duration ttl,
    required Future<T> Function() loader,
  }) async {
    final now = DateTime.now();
    final cached = _cache[key];
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return cached.value as T;
    }

    final existingRequest = _inFlight[key];
    if (existingRequest != null) {
      return (await existingRequest) as T;
    }

    final request = loader();
    _inFlight[key] = request;

    try {
      final value = await request;
      _cache[key] = _ApiCacheEntry<dynamic>(
        value: value,
        expiresAt: now.add(ttl),
      );
      return value;
    } on SynetraApiException {
      if (cached != null) {
        return cached.value as T;
      }
      rethrow;
    } on SocketException catch (error) {
      if (cached != null) {
        return cached.value as T;
      }
      throw SynetraApiException.network(uri: Uri.parse(_baseUrl), cause: error);
    } on http.ClientException catch (error) {
      if (cached != null) {
        return cached.value as T;
      }
      throw SynetraApiException.network(uri: Uri.parse(_baseUrl), cause: error);
    } on HandshakeException catch (error) {
      if (cached != null) {
        return cached.value as T;
      }
      throw SynetraApiException.network(uri: Uri.parse(_baseUrl), cause: error);
    } on TimeoutException catch (error) {
      if (cached != null) {
        return cached.value as T;
      }
      throw SynetraApiException.network(uri: Uri.parse(_baseUrl), cause: error);
    } finally {
      _inFlight.remove(key);
    }
  }

  void _invalidateCacheKeys(Set<String> keys) {
    for (final key in keys) {
      _cache.remove(key);
      _inFlight.remove(key);
    }
  }
}

class SynetraApiException implements Exception {
  const SynetraApiException(this.message, {this.details});

  factory SynetraApiException.network({
    required Uri uri,
    required Object cause,
  }) {
    return SynetraApiException(
      'We could not connect to the NIMA server. Please check your internet connection and try again.',
      details: 'Request failed for $uri: $cause',
    );
  }

  final String message;
  final String? details;

  @override
  String toString() => message;
}

class _ApiCacheEntry<T> {
  const _ApiCacheEntry({required this.value, required this.expiresAt});

  final T value;
  final DateTime expiresAt;
}
