part of '../../main.dart';

class AssociationCircularLibraryData {
  const AssociationCircularLibraryData({
    required this.associationId,
    required this.associationName,
    required this.items,
  });

  const AssociationCircularLibraryData.empty()
    : associationId = '',
      associationName = '',
      items = const [];

  final String associationId;
  final String associationName;
  final List<AssociationCircularDocument> items;
}

class AssociationCircularDocument {
  const AssociationCircularDocument({
    required this.id,
    required this.headline,
    required this.tagline,
    required this.summary,
    required this.originalFileName,
    required this.mimeType,
    required this.fileSize,
    required this.fileExtension,
    required this.documentUrl,
    required this.previewUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String headline;
  final String tagline;
  final String summary;
  final String originalFileName;
  final String mimeType;
  final int fileSize;
  final String fileExtension;
  final String documentUrl;
  final String previewUrl;
  final String createdAt;
  final String updatedAt;

  String get createdDateLabel =>
      createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

  factory AssociationCircularDocument.fromJson(Map<String, dynamic> json) {
    return AssociationCircularDocument(
      id: json['id']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      originalFileName: json['originalFileName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      fileExtension: json['fileExtension']?.toString() ?? 'FILE',
      documentUrl: json['documentUrl']?.toString() ?? '',
      previewUrl: json['previewUrl']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class AssociationCircularDraft {
  const AssociationCircularDraft({
    required this.id,
    required this.headline,
    required this.tagline,
    required this.summary,
    required this.selectedFile,
    required this.existingFileName,
    required this.existingFileExtension,
    required this.existingPreviewUrl,
  });

  const AssociationCircularDraft.empty()
    : id = '',
      headline = '',
      tagline = '',
      summary = '',
      selectedFile = null,
      existingFileName = '',
      existingFileExtension = 'DOC',
      existingPreviewUrl = '';

  final String id;
  final String headline;
  final String tagline;
  final String summary;
  final AssociationUploadFile? selectedFile;
  final String existingFileName;
  final String existingFileExtension;
  final String existingPreviewUrl;

  bool get canSubmit =>
      headline.trim().isNotEmpty &&
      (selectedFile != null || id.isNotEmpty || existingFileName.isNotEmpty);

  String get displayFileName => selectedFile?.name ?? existingFileName;

  String get displayFileExtension =>
      selectedFile?.extensionLabel ?? existingFileExtension;

  factory AssociationCircularDraft.fromDocument(
    AssociationCircularDocument document,
  ) {
    return AssociationCircularDraft(
      id: document.id,
      headline: document.headline,
      tagline: document.tagline,
      summary: document.summary,
      selectedFile: null,
      existingFileName: document.originalFileName,
      existingFileExtension: document.fileExtension,
      existingPreviewUrl: document.previewUrl,
    );
  }

  AssociationCircularDraft copyWith({
    String? id,
    String? headline,
    String? tagline,
    String? summary,
    AssociationUploadFile? selectedFile,
    bool clearSelectedFile = false,
    String? existingFileName,
    String? existingFileExtension,
    String? existingPreviewUrl,
  }) {
    return AssociationCircularDraft(
      id: id ?? this.id,
      headline: headline ?? this.headline,
      tagline: tagline ?? this.tagline,
      summary: summary ?? this.summary,
      selectedFile:
          clearSelectedFile ? null : (selectedFile ?? this.selectedFile),
      existingFileName: existingFileName ?? this.existingFileName,
      existingFileExtension:
          existingFileExtension ?? this.existingFileExtension,
      existingPreviewUrl: existingPreviewUrl ?? this.existingPreviewUrl,
    );
  }
}

class AssociationUploadFile {
  const AssociationUploadFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;

  String get extensionLabel {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == name.length - 1) {
      return 'FILE';
    }
    return name.substring(lastDot + 1).toUpperCase();
  }

  factory AssociationUploadFile.fromPlatformFile(PlatformFile file) {
    final name = file.name;
    final extension = (file.extension ?? '').toLowerCase();
    return AssociationUploadFile(
      name: name,
      mimeType: _inferMimeType(extension),
      bytes: file.bytes!,
    );
  }

  static String _inferMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}

class MemberMasterDraft {
  const MemberMasterDraft({
    required this.id,
    required this.name,
    required this.companyName,
    required this.email,
    required this.phone,
    required this.address,
    required this.gst,
    required this.photoUrl,
    required this.membershipDetails,
    required this.membershipType,
    required this.membershipStartDate,
    required this.membershipEndDate,
    required this.paymentAmount,
    required this.paymentStatus,
  });

  const MemberMasterDraft.empty()
    : id = '',
      name = '',
      companyName = '',
      email = '',
      phone = '',
      address = '',
      gst = '',
      photoUrl = '',
      membershipDetails = '',
      membershipType = 'Primary',
      membershipStartDate = '',
      membershipEndDate = '',
      paymentAmount = '',
      paymentStatus = 'Pending';

  final String id;
  final String name;
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String gst;
  final String photoUrl;
  final String membershipDetails;
  final String membershipType;
  final String membershipStartDate;
  final String membershipEndDate;
  final String paymentAmount;
  final String paymentStatus;

  bool get canSubmit =>
      name.trim().isNotEmpty &&
      companyName.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      name.trim().split(RegExp(r'\s+')).length >= 2;

  factory MemberMasterDraft.fromMember(MemberDirectoryItem member) {
    return MemberMasterDraft(
      id: member.id,
      name: member.name,
      companyName: member.companyName,
      email: member.email,
      phone: member.phone,
      address: member.address,
      gst: member.gst,
      photoUrl: member.photoUrl,
      membershipDetails: member.membershipDetails,
      membershipType: member.roleTitle.isEmpty ? 'Primary' : member.roleTitle,
      membershipStartDate: member.membershipStartDate,
      membershipEndDate: member.membershipEndDate,
      paymentAmount: member.paymentAmount,
      paymentStatus:
          member.paymentStatus.isEmpty ? 'Pending' : member.paymentStatus,
    );
  }

  MemberMasterDraft copyWith({
    String? id,
    String? name,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? gst,
    String? photoUrl,
    String? membershipDetails,
    String? membershipType,
    String? membershipStartDate,
    String? membershipEndDate,
    String? paymentAmount,
    String? paymentStatus,
  }) {
    return MemberMasterDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gst: gst ?? this.gst,
      photoUrl: photoUrl ?? this.photoUrl,
      membershipDetails: membershipDetails ?? this.membershipDetails,
      membershipType: membershipType ?? this.membershipType,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  Map<String, dynamic> toJson() {
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : name.trim();
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '-';
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'gst': gst.trim(),
      'photoUrl': photoUrl.trim(),
      'companyName': companyName.trim(),
      'roleTitle': membershipType.trim(),
      'membershipDetails': membershipDetails.trim(),
      'membershipStartDate':
          membershipStartDate.trim().isEmpty
              ? null
              : membershipStartDate.trim(),
      'membershipEndDate':
          membershipEndDate.trim().isEmpty ? null : membershipEndDate.trim(),
      'paymentAmount': paymentAmount.trim(),
      'paymentStatus': _paymentStatusApiValue(paymentStatus),
    };
  }

  static String _paymentStatusApiValue(String value) {
    switch (value) {
      case 'Paid':
        return 'PAID';
      case 'Overdue':
        return 'OVERDUE';
      case 'Waived':
        return 'WAIVED';
      default:
        return 'PENDING';
    }
  }
}

class MemberArenaData {
  const MemberArenaData({required this.posts, required this.members});

  const MemberArenaData.empty() : posts = const [], members = const [];

  final List<MemberPostItem> posts;
  final List<MemberDirectoryItem> members;
}

class AdminArenaData {
  const AdminArenaData({
    required this.appAccess,
    required this.members,
    required this.posts,
    required this.vendors,
    required this.appBanners,
    required this.timelinePosts,
    required this.events,
    required this.eventTypes,
  });

  const AdminArenaData.empty()
    : appAccess = const AdminAppAccessSettings.defaults(),
      members = const [],
      posts = const [],
      vendors = const [],
      appBanners = const [],
      timelinePosts = const [],
      events = const [],
      eventTypes = const [];

  final AdminAppAccessSettings appAccess;
  final List<AdminMemberAccessItem> members;
  final List<MemberPostItem> posts;
  final List<AdminVendorAccessItem> vendors;
  final List<AdminAppBannerItem> appBanners;
  final List<AdminTimelineItem> timelinePosts;
  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;
}

class EventsArenaData {
  const EventsArenaData({required this.events, required this.eventTypes});

  const EventsArenaData.empty() : events = const [], eventTypes = const [];

  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;
}

class DashboardData {
  const DashboardData({
    required this.associationName,
    required this.galleryItems,
    required this.committeeMembers,
    required this.totalMembers,
    required this.totalCities,
    required this.totalGuests,
    required this.totalVendors,
    required this.upcomingEvents,
    required this.appBanners,
    required this.featuredVendors,
    required this.timelinePosts,
  });

  const DashboardData.empty()
    : associationName = '',
      galleryItems = const [],
      committeeMembers = const [],
      totalMembers = 0,
      totalCities = 0,
      totalGuests = 0,
      totalVendors = 0,
      upcomingEvents = const [],
      appBanners = const [],
      featuredVendors = const [],
      timelinePosts = const [];

  final String associationName;
  final List<DashboardGalleryItem> galleryItems;
  final List<MemberDirectoryItem> committeeMembers;
  final int totalMembers;
  final int totalCities;
  final int totalGuests;
  final int totalVendors;
  final List<AdminEventItem> upcomingEvents;
  final List<DashboardAppBannerItem> appBanners;
  final List<DashboardVendorItem> featuredVendors;
  final List<DashboardTimelineItem> timelinePosts;
}

class DashboardVendorItem {
  const DashboardVendorItem({
    required this.id,
    required this.name,
    required this.companyName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.city,
    required this.category,
    required this.vendorType,
    required this.badge,
    required this.avatarUrl,
    required this.facebookUrl,
    required this.instagramUrl,
    required this.youtubeUrl,
    required this.linkedinUrl,
    required this.xUrl,
  });

  final String id;
  final String name;
  final String companyName;
  final String contactPerson;
  final String email;
  final String phone;
  final String city;
  final String category;
  final String vendorType;
  final String badge;
  final String avatarUrl;
  final String facebookUrl;
  final String instagramUrl;
  final String youtubeUrl;
  final String linkedinUrl;
  final String xUrl;

  String get displayName =>
      companyName.trim().isNotEmpty ? companyName : name.trim();

  factory DashboardVendorItem.fromJson(Map<String, dynamic> json) {
    return DashboardVendorItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      vendorType: json['vendorType']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      avatarUrl:
          json['logoUrl']?.toString() ??
          json['photoUrl']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
      facebookUrl: json['facebookUrl']?.toString() ?? '',
      instagramUrl: json['instagramUrl']?.toString() ?? '',
      youtubeUrl: json['youtubeUrl']?.toString() ?? '',
      linkedinUrl: json['linkedinUrl']?.toString() ?? '',
      xUrl: json['xUrl']?.toString() ?? '',
    );
  }
}

class AdminVendorAccessItem {
  const AdminVendorAccessItem({
    required this.id,
    required this.displayName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.city,
    required this.category,
    required this.vendorType,
    required this.badge,
    required this.avatarUrl,
    required this.accessStatus,
  });

  final String id;
  final String displayName;
  final String contactPerson;
  final String email;
  final String phone;
  final String city;
  final String category;
  final String vendorType;
  final String badge;
  final String avatarUrl;
  final MemberAccessStatus accessStatus;

  factory AdminVendorAccessItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final displayName =
        json['companyName']?.toString().trim().isNotEmpty == true
            ? json['companyName']!.toString()
            : json['name']?.toString() ?? '';
    return AdminVendorAccessItem(
      id: json['id']?.toString() ?? '',
      displayName: displayName,
      contactPerson: json['contactPerson']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      vendorType: json['vendorType']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      avatarUrl:
          json['logoUrl']?.toString() ??
          json['photoUrl']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
      accessStatus: MemberAccessStatusMeta.fromApi(
        approvalStatus: user?['approvalStatus']?.toString() ?? 'PENDING',
        isActive: user?['isActive'] == true,
      ),
    );
  }
}

class DashboardAppBannerItem {
  const DashboardAppBannerItem({
    required this.id,
    required this.vendorName,
    required this.shortText,
    required this.contactNumber,
    required this.mediaUrl,
    required this.socialMediaUrl,
    required this.reviewStatus,
    required this.paymentReceived,
    required this.paymentMode,
    required this.paymentRemarks,
    required this.displayIndex,
  });

  final String id;
  final String vendorName;
  final String shortText;
  final String contactNumber;
  final String mediaUrl;
  final String socialMediaUrl;
  final String reviewStatus;
  final bool paymentReceived;
  final String paymentMode;
  final String paymentRemarks;
  final int displayIndex;

  factory DashboardAppBannerItem.fromJson(Map<String, dynamic> json) {
    return DashboardAppBannerItem(
      id: json['id']?.toString() ?? '',
      vendorName: json['vendorName']?.toString() ?? '',
      shortText: json['shortText']?.toString() ?? '',
      contactNumber: json['contactNumber']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      socialMediaUrl: json['socialMediaUrl']?.toString() ?? '',
      reviewStatus: json['reviewStatus']?.toString() ?? 'PENDING',
      paymentReceived: json['paymentReceived'] == true,
      paymentMode: json['paymentMode']?.toString() ?? '',
      paymentRemarks: json['paymentRemarks']?.toString() ?? '',
      displayIndex: (json['displayIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

enum BannerReviewStatus { approved, rejected, pending, onHold }

extension BannerReviewStatusMeta on BannerReviewStatus {
  String get apiValue => switch (this) {
    BannerReviewStatus.approved => 'APPROVED',
    BannerReviewStatus.rejected => 'REJECTED',
    BannerReviewStatus.pending => 'PENDING',
    BannerReviewStatus.onHold => 'ON_HOLD',
  };

  String get label => switch (this) {
    BannerReviewStatus.approved => 'Approved',
    BannerReviewStatus.rejected => 'Rejected',
    BannerReviewStatus.pending => 'Pending',
    BannerReviewStatus.onHold => 'On Hold',
  };

  Color get color => switch (this) {
    BannerReviewStatus.approved => const Color(0xFF10B981),
    BannerReviewStatus.rejected => const Color(0xFFEF4444),
    BannerReviewStatus.pending => const Color(0xFFF59E0B),
    BannerReviewStatus.onHold => const Color(0xFF6B7280),
  };

  static BannerReviewStatus fromApi(String value) => switch (value) {
    'APPROVED' => BannerReviewStatus.approved,
    'REJECTED' => BannerReviewStatus.rejected,
    'ON_HOLD' => BannerReviewStatus.onHold,
    _ => BannerReviewStatus.pending,
  };
}

class AdminAppBannerItem {
  const AdminAppBannerItem({
    required this.id,
    required this.vendorName,
    required this.shortText,
    required this.contactNumber,
    required this.mediaUrl,
    required this.socialMediaUrl,
    required this.reviewStatus,
    required this.paymentReceived,
    required this.paymentMode,
    required this.paymentRemarks,
    required this.displayIndex,
  });

  final String id;
  final String vendorName;
  final String shortText;
  final String contactNumber;
  final String mediaUrl;
  final String socialMediaUrl;
  final BannerReviewStatus reviewStatus;
  final bool paymentReceived;
  final String paymentMode;
  final String paymentRemarks;
  final int displayIndex;

  factory AdminAppBannerItem.fromJson(Map<String, dynamic> json) {
    return AdminAppBannerItem(
      id: json['id']?.toString() ?? '',
      vendorName: json['vendorName']?.toString() ?? '',
      shortText: json['shortText']?.toString() ?? '',
      contactNumber: json['contactNumber']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      socialMediaUrl: json['socialMediaUrl']?.toString() ?? '',
      reviewStatus: BannerReviewStatusMeta.fromApi(
        json['reviewStatus']?.toString() ?? 'PENDING',
      ),
      paymentReceived: json['paymentReceived'] == true,
      paymentMode: json['paymentMode']?.toString() ?? '',
      paymentRemarks: json['paymentRemarks']?.toString() ?? '',
      displayIndex: (json['displayIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

enum TimelineReviewStatus { approved, rejected, pending, onHold }

extension TimelineReviewStatusMeta on TimelineReviewStatus {
  String get apiValue => switch (this) {
    TimelineReviewStatus.approved => 'APPROVED',
    TimelineReviewStatus.rejected => 'REJECTED',
    TimelineReviewStatus.pending => 'PENDING',
    TimelineReviewStatus.onHold => 'ON_HOLD',
  };

  String get label => switch (this) {
    TimelineReviewStatus.approved => 'Approved',
    TimelineReviewStatus.rejected => 'Rejected',
    TimelineReviewStatus.pending => 'Pending',
    TimelineReviewStatus.onHold => 'On Hold',
  };

  Color get color => switch (this) {
    TimelineReviewStatus.approved => const Color(0xFF10B981),
    TimelineReviewStatus.rejected => const Color(0xFFEF4444),
    TimelineReviewStatus.pending => const Color(0xFFF59E0B),
    TimelineReviewStatus.onHold => const Color(0xFF6B7280),
  };

  static TimelineReviewStatus fromApi(String value) => switch (value) {
    'APPROVED' => TimelineReviewStatus.approved,
    'REJECTED' => TimelineReviewStatus.rejected,
    'ON_HOLD' => TimelineReviewStatus.onHold,
    _ => TimelineReviewStatus.pending,
  };
}

class AdminTimelineItem {
  const AdminTimelineItem({
    required this.id,
    required this.sourceType,
    required this.sourceName,
    required this.postedBy,
    required this.caption,
    required this.contactNumber,
    required this.imageUrl,
    required this.landingPageUrl,
    required this.youtubeUrl,
    required this.facebookUrl,
    required this.brochureUrl,
    required this.postedOn,
    required this.createdAt,
    required this.reviewStatus,
    required this.displayStart,
    required this.displayEnd,
  });

  final String id;
  final String sourceType;
  final String sourceName;
  final String postedBy;
  final String caption;
  final String contactNumber;
  final String imageUrl;
  final String landingPageUrl;
  final String youtubeUrl;
  final String facebookUrl;
  final String brochureUrl;
  final String postedOn;
  final String createdAt;
  final TimelineReviewStatus reviewStatus;
  final String displayStart;
  final String displayEnd;

  String get displayTitle =>
      sourceName.trim().isNotEmpty ? sourceName.trim() : 'Timeline Update';

  factory AdminTimelineItem.fromJson(Map<String, dynamic> json) {
    return AdminTimelineItem(
      id: json['id']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? 'ASSOCIATION',
      sourceName: json['sourceName']?.toString() ?? '',
      postedBy: json['postedBy']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      contactNumber: json['contactNumber']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      landingPageUrl: json['landingPageUrl']?.toString() ?? '',
      youtubeUrl: json['youtubeUrl']?.toString() ?? '',
      facebookUrl: json['facebookUrl']?.toString() ?? '',
      brochureUrl: json['brochureUrl']?.toString() ?? '',
      postedOn: json['postedOn']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      reviewStatus: TimelineReviewStatusMeta.fromApi(
        json['reviewStatus']?.toString() ?? 'PENDING',
      ),
      displayStart: json['displayStart']?.toString() ?? '',
      displayEnd: json['displayEnd']?.toString() ?? '',
    );
  }
}

class DashboardTimelineItem {
  const DashboardTimelineItem({
    required this.id,
    required this.sourceType,
    required this.sourceName,
    required this.postedBy,
    required this.caption,
    required this.contactNumber,
    required this.imageUrl,
    required this.landingPageUrl,
    required this.youtubeUrl,
    required this.facebookUrl,
    required this.brochureUrl,
    required this.postedOn,
    required this.createdAt,
  });

  final String id;
  final String sourceType;
  final String sourceName;
  final String postedBy;
  final String caption;
  final String contactNumber;
  final String imageUrl;
  final String landingPageUrl;
  final String youtubeUrl;
  final String facebookUrl;
  final String brochureUrl;
  final String postedOn;
  final String createdAt;

  String get displayTitle =>
      sourceName.trim().isNotEmpty ? sourceName.trim() : 'Timeline Update';

  factory DashboardTimelineItem.fromJson(Map<String, dynamic> json) {
    return DashboardTimelineItem(
      id: json['id']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? 'ASSOCIATION',
      sourceName: json['sourceName']?.toString() ?? '',
      postedBy: json['postedBy']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      contactNumber: json['contactNumber']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      landingPageUrl: json['landingPageUrl']?.toString() ?? '',
      youtubeUrl: json['youtubeUrl']?.toString() ?? '',
      facebookUrl: json['facebookUrl']?.toString() ?? '',
      brochureUrl: json['brochureUrl']?.toString() ?? '',
      postedOn: json['postedOn']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class DashboardGalleryItem {
  const DashboardGalleryItem({
    required this.id,
    required this.imageUrl,
    required this.headline,
    required this.tagline,
    required this.description,
  });

  final String id;
  final String imageUrl;
  final String headline;
  final String tagline;
  final String description;

  factory DashboardGalleryItem.fromJson(Map<String, dynamic> json) {
    return DashboardGalleryItem(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class AdminAppAccessSettings {
  const AdminAppAccessSettings({
    required this.approveMembersLogin,
    required this.disableScreenshots,
    required this.approveMembership,
    required this.approveRegistrationRequest,
    required this.disableAdminFunctionsFromApp,
  });

  const AdminAppAccessSettings.defaults()
    : approveMembersLogin = true,
      disableScreenshots = false,
      approveMembership = true,
      approveRegistrationRequest = true,
      disableAdminFunctionsFromApp = false;

  final bool approveMembersLogin;
  final bool disableScreenshots;
  final bool approveMembership;
  final bool approveRegistrationRequest;
  final bool disableAdminFunctionsFromApp;

  AdminAppAccessSettings copyWith({
    bool? approveMembersLogin,
    bool? disableScreenshots,
    bool? approveMembership,
    bool? approveRegistrationRequest,
    bool? disableAdminFunctionsFromApp,
  }) {
    return AdminAppAccessSettings(
      approveMembersLogin: approveMembersLogin ?? this.approveMembersLogin,
      disableScreenshots: disableScreenshots ?? this.disableScreenshots,
      approveMembership: approveMembership ?? this.approveMembership,
      approveRegistrationRequest:
          approveRegistrationRequest ?? this.approveRegistrationRequest,
      disableAdminFunctionsFromApp:
          disableAdminFunctionsFromApp ?? this.disableAdminFunctionsFromApp,
    );
  }

  factory AdminAppAccessSettings.fromJson(Map<String, dynamic> json) {
    return AdminAppAccessSettings(
      approveMembersLogin: json['approveMembersLogin'] == true,
      disableScreenshots: json['disableScreenshots'] == true,
      approveMembership: json['approveMembership'] != false,
      approveRegistrationRequest: json['approveRegistrationRequest'] != false,
      disableAdminFunctionsFromApp:
          json['disableAdminFunctionsFromApp'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'approveMembersLogin': approveMembersLogin,
      'disableScreenshots': disableScreenshots,
      'approveMembership': approveMembership,
      'approveRegistrationRequest': approveRegistrationRequest,
      'disableAdminFunctionsFromApp': disableAdminFunctionsFromApp,
    };
  }
}

enum MemberAccessStatus { approved, pending, suspended, cancelled }

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.viewerRole,
    required this.mustChangePassword,
    required this.authToken,
    required this.refreshToken,
    required this.sessionId,
  });

  final String userId;
  final String email;
  final String displayName;
  final AppViewerRole viewerRole;
  final bool mustChangePassword;
  final String authToken;
  final String refreshToken;
  final String sessionId;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final auth = json['auth'] as Map<String, dynamic>? ?? const {};
    final viewerRole = switch (user['viewerRole']?.toString()) {
      'admin' => AppViewerRole.admin,
      'member' => AppViewerRole.member,
      _ => AppViewerRole.viewOnly,
    };

    return AuthSession(
      userId: user['id']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      displayName: user['displayName']?.toString() ?? '',
      viewerRole: viewerRole,
      mustChangePassword: user['mustChangePassword'] == true,
      authToken: auth['token']?.toString() ?? '',
      refreshToken: auth['refreshToken']?.toString() ?? '',
      sessionId: auth['sessionId']?.toString() ?? '',
    );
  }
}

extension MemberAccessStatusMeta on MemberAccessStatus {
  String get apiValue => switch (this) {
    MemberAccessStatus.approved => 'APPROVED',
    MemberAccessStatus.pending => 'PENDING',
    MemberAccessStatus.suspended => 'SUSPENDED',
    MemberAccessStatus.cancelled => 'CANCELLED',
  };

  String get label => switch (this) {
    MemberAccessStatus.approved => 'Approved',
    MemberAccessStatus.pending => 'Pending',
    MemberAccessStatus.suspended => 'Suspended',
    MemberAccessStatus.cancelled => 'Cancelled',
  };

  Color get color => switch (this) {
    MemberAccessStatus.approved => const Color(0xFF10B981),
    MemberAccessStatus.pending => const Color(0xFFF59E0B),
    MemberAccessStatus.suspended => const Color(0xFFEF4444),
    MemberAccessStatus.cancelled => const Color(0xFF6B7280),
  };

  static MemberAccessStatus fromApi({
    required String approvalStatus,
    required bool isActive,
  }) {
    if (approvalStatus == 'CANCELLED') {
      return MemberAccessStatus.cancelled;
    }
    if (approvalStatus == 'PENDING') {
      return MemberAccessStatus.pending;
    }
    if (approvalStatus == 'APPROVED' && !isActive) {
      return MemberAccessStatus.suspended;
    }
    if (approvalStatus == 'APPROVED') {
      return MemberAccessStatus.approved;
    }
    return MemberAccessStatus.pending;
  }
}

enum PostReviewStatus { approved, rejected, pending }

extension PostReviewStatusMeta on PostReviewStatus {
  String get apiValue => switch (this) {
    PostReviewStatus.approved => 'APPROVED',
    PostReviewStatus.rejected => 'REJECTED',
    PostReviewStatus.pending => 'PENDING',
  };

  String get label => switch (this) {
    PostReviewStatus.approved => 'Approved',
    PostReviewStatus.rejected => 'Rejected',
    PostReviewStatus.pending => 'Pending',
  };

  Color get color => switch (this) {
    PostReviewStatus.approved => const Color(0xFF10B981),
    PostReviewStatus.rejected => const Color(0xFFEF4444),
    PostReviewStatus.pending => const Color(0xFFF59E0B),
  };

  static PostReviewStatus fromApi(String value) => switch (value) {
    'APPROVED' => PostReviewStatus.approved,
    'REJECTED' => PostReviewStatus.rejected,
    _ => PostReviewStatus.pending,
  };
}

class MemberPostItem {
  const MemberPostItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.mediaUrl,
    required this.mediaType,
    required this.postType,
    required this.reviewStatus,
    required this.displayStart,
    required this.displayEnd,
    required this.postedOn,
    required this.member,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final String mediaUrl;
  final String mediaType;
  final String postType;
  final PostReviewStatus reviewStatus;
  final String displayStart;
  final String displayEnd;
  final String postedOn;
  final PostAuthor member;

  factory MemberPostItem.fromJson(Map<String, dynamic> json) {
    return MemberPostItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? '',
      postType: json['postType']?.toString() ?? 'Post',
      reviewStatus: PostReviewStatusMeta.fromApi(
        json['reviewStatus']?.toString() ?? 'PENDING',
      ),
      displayStart: json['displayStart']?.toString() ?? '',
      displayEnd: json['displayEnd']?.toString() ?? '',
      postedOn: json['postedOn']?.toString() ?? '',
      member: PostAuthor.fromJson(
        json['member'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class PostAuthor {
  const PostAuthor({
    required this.id,
    required this.name,
    required this.company,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final String company;
  final String photoUrl;

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Member',
      company: json['company']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
    );
  }
}

class AdminMemberAccessItem {
  const AdminMemberAccessItem({
    required this.id,
    required this.name,
    required this.companyName,
    required this.roleTitle,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.accessStatus,
  });

  final String id;
  final String name;
  final String companyName;
  final String roleTitle;
  final String email;
  final String phone;
  final String photoUrl;
  final MemberAccessStatus accessStatus;

  factory AdminMemberAccessItem.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final user = json['user'] as Map<String, dynamic>?;
    return AdminMemberAccessItem(
      id: json['id']?.toString() ?? '',
      name: '$firstName $lastName'.trim(),
      companyName: json['companyName']?.toString() ?? '',
      roleTitle: json['roleTitle']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      accessStatus: MemberAccessStatusMeta.fromApi(
        approvalStatus: user?['approvalStatus']?.toString() ?? 'PENDING',
        isActive: user?['isActive'] == true,
      ),
    );
  }
}

class MemberDirectoryItem {
  const MemberDirectoryItem({
    required this.id,
    required this.name,
    required this.companyName,
    required this.roleTitle,
    required this.gst,
    required this.committeePost,
    required this.committeeTenureStart,
    required this.committeeTenureEnd,
    required this.memberBio,
    required this.membershipDetails,
    required this.membershipStartDate,
    required this.membershipEndDate,
    required this.paymentAmount,
    required this.paymentStatus,
    required this.address,
    required this.email,
    required this.phone,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final String companyName;
  final String roleTitle;
  final String gst;
  final String committeePost;
  final String committeeTenureStart;
  final String committeeTenureEnd;
  final String memberBio;
  final String membershipDetails;
  final String membershipStartDate;
  final String membershipEndDate;
  final String paymentAmount;
  final String paymentStatus;
  final String address;
  final String email;
  final String phone;
  final String photoUrl;

  factory MemberDirectoryItem.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    return MemberDirectoryItem(
      id: json['id']?.toString() ?? '',
      name: '$firstName $lastName'.trim(),
      companyName: json['companyName']?.toString() ?? '',
      roleTitle: json['roleTitle']?.toString() ?? '',
      gst: json['gst']?.toString() ?? '',
      committeePost: json['committeePost']?.toString() ?? '',
      committeeTenureStart: _asDateOnly(
        json['committeeTenureStart']?.toString(),
      ),
      committeeTenureEnd: _asDateOnly(json['committeeTenureEnd']?.toString()),
      memberBio: json['memberBio']?.toString() ?? '',
      membershipDetails: json['membershipDetails']?.toString() ?? '',
      membershipStartDate: _asDateOnly(json['membershipStartDate']?.toString()),
      membershipEndDate: _asDateOnly(json['membershipEndDate']?.toString()),
      paymentAmount: json['paymentAmount']?.toString() ?? '',
      paymentStatus: _paymentLabel(json['paymentStatus']?.toString() ?? ''),
      address: json['address']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
    );
  }

  static String _asDateOnly(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    return value.length >= 10 ? value.substring(0, 10) : value;
  }

  static String _paymentLabel(String value) {
    switch (value) {
      case 'PAID':
        return 'Paid';
      case 'OVERDUE':
        return 'Overdue';
      case 'WAIVED':
        return 'Waived';
      case 'PENDING':
        return 'Pending';
      default:
        return value;
    }
  }
}

class AdminEventItem {
  const AdminEventItem({
    required this.id,
    required this.name,
    required this.type,
    required this.audience,
    required this.entryType,
    required this.entryCharges,
    required this.participationCharges,
    required this.date,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.summary,
    required this.imageName,
    required this.videoName,
    required this.bannerUrl,
    required this.promoVideoUrl,
    required this.liveStatus,
  });

  final String id;
  final String name;
  final String type;
  final String audience;
  final String entryType;
  final String entryCharges;
  final String participationCharges;
  final String date;
  final String venue;
  final String startTime;
  final String endTime;
  final String summary;
  final String imageName;
  final String videoName;
  final String bannerUrl;
  final String promoVideoUrl;
  final String liveStatus;

  factory AdminEventItem.fromJson(Map<String, dynamic> json) {
    return AdminEventItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      audience: json['audience']?.toString() ?? '',
      entryType: json['entryType']?.toString() ?? '',
      entryCharges: json['entryCharges']?.toString() ?? '',
      participationCharges: json['participationCharges']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      imageName: json['imageName']?.toString() ?? '',
      videoName: json['videoName']?.toString() ?? '',
      bannerUrl: json['bannerUrl']?.toString() ?? '',
      promoVideoUrl: json['promoVideoUrl']?.toString() ?? '',
      liveStatus: json['liveStatus']?.toString() ?? 'Scheduled',
    );
  }
}

class AdminEventTypeItem {
  const AdminEventTypeItem({
    required this.id,
    required this.title,
    required this.meta,
  });

  final String id;
  final String title;
  final String meta;

  factory AdminEventTypeItem.fromJson(Map<String, dynamic> json) {
    return AdminEventTypeItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      meta: json['meta']?.toString() ?? '',
    );
  }
}

class AdminEventDraft {
  const AdminEventDraft({
    required this.id,
    required this.name,
    required this.type,
    required this.audience,
    required this.entryType,
    required this.entryCharges,
    required this.participationCharges,
    required this.date,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.summary,
    required this.imageName,
    required this.videoName,
    required this.bannerUrl,
    required this.promoVideoUrl,
    required this.bannerFile,
    required this.videoFile,
  });

  const AdminEventDraft.empty()
    : id = '',
      name = '',
      type = '',
      audience = '',
      entryType = '',
      entryCharges = '',
      participationCharges = '',
      date = '',
      venue = '',
      startTime = '',
      endTime = '',
      summary = '',
      imageName = '',
      videoName = '',
      bannerUrl = '',
      promoVideoUrl = '',
      bannerFile = null,
      videoFile = null;

  final String id;
  final String name;
  final String type;
  final String audience;
  final String entryType;
  final String entryCharges;
  final String participationCharges;
  final String date;
  final String venue;
  final String startTime;
  final String endTime;
  final String summary;
  final String imageName;
  final String videoName;
  final String bannerUrl;
  final String promoVideoUrl;
  final AssociationUploadFile? bannerFile;
  final AssociationUploadFile? videoFile;

  AdminEventDraft copyWith({
    String? id,
    String? name,
    String? type,
    String? audience,
    String? entryType,
    String? entryCharges,
    String? participationCharges,
    String? date,
    String? venue,
    String? startTime,
    String? endTime,
    String? summary,
    String? imageName,
    String? videoName,
    String? bannerUrl,
    String? promoVideoUrl,
    AssociationUploadFile? bannerFile,
    AssociationUploadFile? videoFile,
  }) {
    return AdminEventDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      audience: audience ?? this.audience,
      entryType: entryType ?? this.entryType,
      entryCharges: entryCharges ?? this.entryCharges,
      participationCharges: participationCharges ?? this.participationCharges,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      summary: summary ?? this.summary,
      imageName: imageName ?? this.imageName,
      videoName: videoName ?? this.videoName,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      promoVideoUrl: promoVideoUrl ?? this.promoVideoUrl,
      bannerFile: bannerFile ?? this.bannerFile,
      videoFile: videoFile ?? this.videoFile,
    );
  }

  factory AdminEventDraft.fromEvent(AdminEventItem event) {
    return AdminEventDraft(
      id: event.id,
      name: event.name,
      type: event.type,
      audience: event.audience,
      entryType: event.entryType,
      entryCharges: event.entryCharges,
      participationCharges: event.participationCharges,
      date: event.date,
      venue: event.venue,
      startTime: event.startTime,
      endTime: event.endTime,
      summary: event.summary,
      imageName: event.imageName,
      videoName: event.videoName,
      bannerUrl: event.bannerUrl,
      promoVideoUrl: event.promoVideoUrl,
      bannerFile: null,
      videoFile: null,
    );
  }
}

class EventTypeDraft {
  const EventTypeDraft({
    required this.id,
    required this.title,
    required this.meta,
  });

  const EventTypeDraft.empty() : id = '', title = '', meta = '';

  final String id;
  final String title;
  final String meta;

  bool get canSubmit => title.trim().isNotEmpty && meta.trim().isNotEmpty;

  factory EventTypeDraft.fromItem(AdminEventTypeItem item) {
    return EventTypeDraft(id: item.id, title: item.title, meta: item.meta);
  }

  EventTypeDraft copyWith({String? id, String? title, String? meta}) {
    return EventTypeDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      meta: meta ?? this.meta,
    );
  }
}

class AssociationProfileData {
  const AssociationProfileData({
    required this.id,
    required this.name,
    required this.slug,
    required this.headOfficeAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.registrationNumber,
    required this.gstNumber,
    required this.website,
    required this.helpdeskNumber,
    required this.contactNumbers,
    required this.googleMapsLink,
    required this.regionalAddresses,
    required this.galleryItems,
  });

  const AssociationProfileData.empty()
    : id = '',
      name = '',
      slug = '',
      headOfficeAddress = '',
      city = '',
      state = '',
      pincode = '',
      registrationNumber = '',
      gstNumber = '',
      website = '',
      helpdeskNumber = '',
      contactNumbers = const [],
      googleMapsLink = '',
      regionalAddresses = const [],
      galleryItems = const [];

  final String id;
  final String name;
  final String slug;
  final String headOfficeAddress;
  final String city;
  final String state;
  final String pincode;
  final String registrationNumber;
  final String gstNumber;
  final String website;
  final String helpdeskNumber;
  final List<String> contactNumbers;
  final String googleMapsLink;
  final List<AssociationRegionalAddressData> regionalAddresses;
  final List<DashboardGalleryItem> galleryItems;

  String get contactNumbersLabel => contactNumbers.join(', ');

  factory AssociationProfileData.fromJson(Map<String, dynamic> json) {
    return AssociationProfileData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      headOfficeAddress: json['headOfficeAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      gstNumber: json['gstNumber']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      helpdeskNumber: json['helpdeskNumber']?.toString() ?? '',
      contactNumbers:
          (json['contactNumbers'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      googleMapsLink: json['googleMapsLink']?.toString() ?? '',
      regionalAddresses:
          (json['regionalAddresses'] as List<dynamic>? ?? const [])
              .map(
                (item) => AssociationRegionalAddressData.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      galleryItems:
          (json['galleryItems'] as List<dynamic>? ?? const [])
              .map(
                (item) =>
                    DashboardGalleryItem.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class AssociationRegionalAddressData {
  const AssociationRegionalAddressData({
    required this.id,
    required this.label,
    required this.officeAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.registrationNumber,
    required this.gstNumber,
    required this.website,
    required this.helpdeskNumber,
    required this.contactNumbers,
    required this.googleMapsLink,
  });

  final String id;
  final String label;
  final String officeAddress;
  final String city;
  final String state;
  final String pincode;
  final String registrationNumber;
  final String gstNumber;
  final String website;
  final String helpdeskNumber;
  final List<String> contactNumbers;
  final String googleMapsLink;

  String get contactNumbersLabel => contactNumbers.join(', ');

  factory AssociationRegionalAddressData.fromJson(Map<String, dynamic> json) {
    return AssociationRegionalAddressData(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      officeAddress: json['officeAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      gstNumber: json['gstNumber']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      helpdeskNumber: json['helpdeskNumber']?.toString() ?? '',
      contactNumbers:
          (json['contactNumbers'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      googleMapsLink: json['googleMapsLink']?.toString() ?? '',
    );
  }
}

class AssociationProfileDraft {
  const AssociationProfileDraft({
    required this.id,
    required this.name,
    required this.slug,
    required this.headOfficeAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.registrationNumber,
    required this.gstNumber,
    required this.website,
    required this.helpdeskNumber,
    required this.contactNumbers,
    required this.googleMapsLink,
    required this.regionalAddresses,
  });

  final String id;
  final String name;
  final String slug;
  final String headOfficeAddress;
  final String city;
  final String state;
  final String pincode;
  final String registrationNumber;
  final String gstNumber;
  final String website;
  final String helpdeskNumber;
  final String contactNumbers;
  final String googleMapsLink;
  final List<AssociationRegionalAddressDraft> regionalAddresses;

  factory AssociationProfileDraft.fromProfile(AssociationProfileData profile) {
    return AssociationProfileDraft(
      id: profile.id,
      name: profile.name,
      slug: profile.slug,
      headOfficeAddress: profile.headOfficeAddress,
      city: profile.city,
      state: profile.state,
      pincode: profile.pincode,
      registrationNumber: profile.registrationNumber,
      gstNumber: profile.gstNumber,
      website: profile.website,
      helpdeskNumber: profile.helpdeskNumber,
      contactNumbers: profile.contactNumbers.join(', '),
      googleMapsLink: profile.googleMapsLink,
      regionalAddresses:
          profile.regionalAddresses
              .map(AssociationRegionalAddressDraft.fromData)
              .toList(),
    );
  }

  AssociationProfileDraft copyWith({
    String? id,
    String? name,
    String? slug,
    String? headOfficeAddress,
    String? city,
    String? state,
    String? pincode,
    String? registrationNumber,
    String? gstNumber,
    String? website,
    String? helpdeskNumber,
    String? contactNumbers,
    String? googleMapsLink,
    List<AssociationRegionalAddressDraft>? regionalAddresses,
  }) {
    return AssociationProfileDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      headOfficeAddress: headOfficeAddress ?? this.headOfficeAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      website: website ?? this.website,
      helpdeskNumber: helpdeskNumber ?? this.helpdeskNumber,
      contactNumbers: contactNumbers ?? this.contactNumbers,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      regionalAddresses: regionalAddresses ?? this.regionalAddresses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'slug':
          slug.trim().isNotEmpty
              ? slug.trim()
              : name.trim().toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]+'),
                '-',
              ),
      'headOfficeAddress': headOfficeAddress.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'registrationNumber': registrationNumber.trim(),
      'gstNumber': gstNumber.trim(),
      'website': website.trim(),
      'contactNumbers':
          contactNumbers
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(),
      'helpdeskNumber': helpdeskNumber.trim(),
      'googleMapsLink': googleMapsLink.trim(),
      'regionalAddresses':
          regionalAddresses.map((item) => item.toJson()).toList(),
    };
  }
}

class AssociationRegionalAddressDraft {
  const AssociationRegionalAddressDraft({
    required this.id,
    required this.label,
    required this.officeAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.registrationNumber,
    required this.gstNumber,
    required this.website,
    required this.helpdeskNumber,
    required this.contactNumbers,
    required this.googleMapsLink,
  });

  factory AssociationRegionalAddressDraft.empty({required String id}) {
    return AssociationRegionalAddressDraft(
      id: id,
      label: '',
      officeAddress: '',
      city: '',
      state: '',
      pincode: '',
      registrationNumber: '',
      gstNumber: '',
      website: '',
      helpdeskNumber: '',
      contactNumbers: '',
      googleMapsLink: '',
    );
  }

  factory AssociationRegionalAddressDraft.fromData(
    AssociationRegionalAddressData data,
  ) {
    return AssociationRegionalAddressDraft(
      id: data.id,
      label: data.label,
      officeAddress: data.officeAddress,
      city: data.city,
      state: data.state,
      pincode: data.pincode,
      registrationNumber: data.registrationNumber,
      gstNumber: data.gstNumber,
      website: data.website,
      helpdeskNumber: data.helpdeskNumber,
      contactNumbers: data.contactNumbers.join(', '),
      googleMapsLink: data.googleMapsLink,
    );
  }

  final String id;
  final String label;
  final String officeAddress;
  final String city;
  final String state;
  final String pincode;
  final String registrationNumber;
  final String gstNumber;
  final String website;
  final String helpdeskNumber;
  final String contactNumbers;
  final String googleMapsLink;

  AssociationRegionalAddressDraft copyWith({
    String? id,
    String? label,
    String? officeAddress,
    String? city,
    String? state,
    String? pincode,
    String? registrationNumber,
    String? gstNumber,
    String? website,
    String? helpdeskNumber,
    String? contactNumbers,
    String? googleMapsLink,
  }) {
    return AssociationRegionalAddressDraft(
      id: id ?? this.id,
      label: label ?? this.label,
      officeAddress: officeAddress ?? this.officeAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      website: website ?? this.website,
      helpdeskNumber: helpdeskNumber ?? this.helpdeskNumber,
      contactNumbers: contactNumbers ?? this.contactNumbers,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label.trim(),
      'officeAddress': officeAddress.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'registrationNumber': registrationNumber.trim(),
      'gstNumber': gstNumber.trim(),
      'website': website.trim(),
      'contactNumbers':
          contactNumbers
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(),
      'helpdeskNumber': helpdeskNumber.trim(),
      'googleMapsLink': googleMapsLink.trim(),
    };
  }
}

class AssociationAboutData {
  const AssociationAboutData({
    required this.heroTitle,
    required this.heroIntro,
    required this.missionTitle,
    required this.missionText,
    required this.goalsTitle,
    required this.goalsText,
    required this.journeyTitle,
    required this.journeyText,
  });

  const AssociationAboutData.empty()
    : heroTitle = '',
      heroIntro = '',
      missionTitle = '',
      missionText = '',
      goalsTitle = '',
      goalsText = '',
      journeyTitle = '',
      journeyText = '';

  final String heroTitle;
  final String heroIntro;
  final String missionTitle;
  final String missionText;
  final String goalsTitle;
  final String goalsText;
  final String journeyTitle;
  final String journeyText;

  factory AssociationAboutData.fromJson(Map<String, dynamic> json) {
    return AssociationAboutData(
      heroTitle: json['heroTitle']?.toString() ?? '',
      heroIntro: json['heroIntro']?.toString() ?? '',
      missionTitle: json['missionTitle']?.toString() ?? '',
      missionText: json['missionText']?.toString() ?? '',
      goalsTitle: json['goalsTitle']?.toString() ?? '',
      goalsText: json['goalsText']?.toString() ?? '',
      journeyTitle: json['journeyTitle']?.toString() ?? '',
      journeyText: json['journeyText']?.toString() ?? '',
    );
  }
}

class AssociationAboutDraft {
  const AssociationAboutDraft({
    required this.heroTitle,
    required this.heroIntro,
    required this.missionTitle,
    required this.missionText,
    required this.goalsTitle,
    required this.goalsText,
    required this.journeyTitle,
    required this.journeyText,
  });

  final String heroTitle;
  final String heroIntro;
  final String missionTitle;
  final String missionText;
  final String goalsTitle;
  final String goalsText;
  final String journeyTitle;
  final String journeyText;

  factory AssociationAboutDraft.fromAbout(AssociationAboutData about) {
    return AssociationAboutDraft(
      heroTitle: about.heroTitle,
      heroIntro: about.heroIntro,
      missionTitle: about.missionTitle,
      missionText: about.missionText,
      goalsTitle: about.goalsTitle,
      goalsText: about.goalsText,
      journeyTitle: about.journeyTitle,
      journeyText: about.journeyText,
    );
  }

  AssociationAboutDraft copyWith({
    String? heroTitle,
    String? heroIntro,
    String? missionTitle,
    String? missionText,
    String? goalsTitle,
    String? goalsText,
    String? journeyTitle,
    String? journeyText,
  }) {
    return AssociationAboutDraft(
      heroTitle: heroTitle ?? this.heroTitle,
      heroIntro: heroIntro ?? this.heroIntro,
      missionTitle: missionTitle ?? this.missionTitle,
      missionText: missionText ?? this.missionText,
      goalsTitle: goalsTitle ?? this.goalsTitle,
      goalsText: goalsText ?? this.goalsText,
      journeyTitle: journeyTitle ?? this.journeyTitle,
      journeyText: journeyText ?? this.journeyText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heroTitle': heroTitle.trim(),
      'heroIntro': heroIntro.trim(),
      'missionTitle': missionTitle.trim(),
      'missionText': missionText.trim(),
      'goalsTitle': goalsTitle.trim(),
      'goalsText': goalsText.trim(),
      'journeyTitle': journeyTitle.trim(),
      'journeyText': journeyText.trim(),
    };
  }
}

enum MemberDirectoryFilter { all, primary, committee, associate, guest }

extension MemberDirectoryFilterMeta on MemberDirectoryFilter {
  String get label => switch (this) {
    MemberDirectoryFilter.all => 'All',
    MemberDirectoryFilter.primary => 'Primary',
    MemberDirectoryFilter.committee => 'Committee',
    MemberDirectoryFilter.associate => 'Associate',
    MemberDirectoryFilter.guest => 'Guest',
  };

  IconData get icon => switch (this) {
    MemberDirectoryFilter.all => Icons.apps_rounded,
    MemberDirectoryFilter.primary => Icons.workspace_premium_rounded,
    MemberDirectoryFilter.committee => Icons.groups_2_rounded,
    MemberDirectoryFilter.associate => Icons.handshake_rounded,
    MemberDirectoryFilter.guest => Icons.person_outline_rounded,
  };

  bool matches(MemberDirectoryItem member) {
    final role = member.roleTitle.trim().toLowerCase();
    return switch (this) {
      MemberDirectoryFilter.all => true,
      MemberDirectoryFilter.primary => role == 'primary',
      MemberDirectoryFilter.committee => role == 'committee',
      MemberDirectoryFilter.associate => role == 'associate',
      MemberDirectoryFilter.guest =>
        role == 'temporary visit' || role == 'guest' || role == 'visitor',
    };
  }
}

class MemberArenaDirectoryConfig {
  const MemberArenaDirectoryConfig({
    required this.filter,
    required this.title,
    required this.subtitle,
  });

  final MemberDirectoryFilter filter;
  final String title;
  final String subtitle;
}

extension MemberArenaSectionDirectoryMeta on MemberArenaSection {
  static MemberArenaDirectoryConfig configFor(MemberArenaSection section) {
    return switch (section) {
      MemberArenaSection.allMembers => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.all,
        title: 'All Members',
        subtitle:
            'Browse every backend-loaded member in one place, sorted alphabetically with the same searchable card layout.',
      ),
      MemberArenaSection.primaryMembers => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.primary,
        title: 'Primary Members',
        subtitle:
            'Primary member records from the backend, presented in the same searchable directory format.',
      ),
      MemberArenaSection.associateMembers => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.associate,
        title: 'Associate Members',
        subtitle:
            'Associate member records from the backend, ready for quick search and reference.',
      ),
      MemberArenaSection.temporaryVisitors => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.guest,
        title: 'Temporary Visitors',
        subtitle:
            'Guest and temporary-visitor records from the backend using the same member card view.',
      ),
      MemberArenaSection.committeeMembers => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.committee,
        title: 'Committee Members',
        subtitle:
            'Committee member records from the backend, shown in the directory-style member cards.',
      ),
      _ => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.all,
        title: 'Member Directory',
        subtitle:
            'Browse members alphabetically, filter by membership type, and search by name, company, city, or profile details.',
      ),
    };
  }
}
