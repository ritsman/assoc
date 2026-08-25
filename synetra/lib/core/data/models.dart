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
    required this.primaryLoginEmail,
    required this.secondaryLoginEmail,
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
  final String primaryLoginEmail;
  final String secondaryLoginEmail;

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
      primaryLoginEmail: json['primaryLoginEmail']?.toString() ?? '',
      secondaryLoginEmail: json['secondaryLoginEmail']?.toString() ?? '',
    );
  }
}

class VendorProfileAsset {
  const VendorProfileAsset({
    required this.url,
    required this.originalName,
    required this.mimeType,
  });

  const VendorProfileAsset.empty() : url = '', originalName = '', mimeType = '';

  final String url;
  final String originalName;
  final String mimeType;

  bool get hasValue => url.trim().isNotEmpty;
  bool get isImage => mimeType.toLowerCase().startsWith('image/');
  String get displayName =>
      originalName.trim().isNotEmpty ? originalName.trim() : 'Saved file';

  factory VendorProfileAsset.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const VendorProfileAsset.empty();
    }

    return VendorProfileAsset(
      url: value['url']?.toString() ?? '',
      originalName: value['originalName']?.toString() ?? '',
      mimeType: value['mimeType']?.toString() ?? '',
    );
  }
}

class VendorSelfProfile {
  const VendorSelfProfile({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.address,
    required this.country,
    required this.state,
    required this.city,
    required this.zipcode,
    required this.website,
    required this.workDescription,
    required this.category,
    required this.vendorType,
    required this.facebookUrl,
    required this.instagramUrl,
    required this.youtubeUrl,
    required this.linkedinUrl,
    required this.xUrl,
    required this.googleLocation,
    required this.companyLogoAsset,
    required this.idProofAsset,
    required this.locationProofAsset,
    required this.companyBrochureAsset,
    required this.profilePhotoAsset,
    required this.visitingCardAsset,
  });

  final String id;
  final String companyName;
  final String contactPerson;
  final String email;
  final String phone;
  final String whatsapp;
  final String address;
  final String country;
  final String state;
  final String city;
  final String zipcode;
  final String website;
  final String workDescription;
  final String category;
  final String vendorType;
  final String facebookUrl;
  final String instagramUrl;
  final String youtubeUrl;
  final String linkedinUrl;
  final String xUrl;
  final String googleLocation;
  final VendorProfileAsset companyLogoAsset;
  final VendorProfileAsset idProofAsset;
  final VendorProfileAsset locationProofAsset;
  final VendorProfileAsset companyBrochureAsset;
  final VendorProfileAsset profilePhotoAsset;
  final VendorProfileAsset visitingCardAsset;

  factory VendorSelfProfile.fromJson(Map<String, dynamic> json) {
    return VendorSelfProfile(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      zipcode: json['zipcode']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      workDescription: json['workDescription']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      vendorType: json['vendorType']?.toString() ?? '',
      facebookUrl: json['facebookUrl']?.toString() ?? '',
      instagramUrl: json['instagramUrl']?.toString() ?? '',
      youtubeUrl: json['youtubeUrl']?.toString() ?? '',
      linkedinUrl: json['linkedinUrl']?.toString() ?? '',
      xUrl: json['xUrl']?.toString() ?? '',
      googleLocation: json['googleLocation']?.toString() ?? '',
      companyLogoAsset: VendorProfileAsset.fromJson(json['companyLogoAsset']),
      idProofAsset: VendorProfileAsset.fromJson(json['idProofAsset']),
      locationProofAsset: VendorProfileAsset.fromJson(
        json['locationProofAsset'],
      ),
      companyBrochureAsset: VendorProfileAsset.fromJson(
        json['companyBrochureAsset'],
      ),
      profilePhotoAsset: VendorProfileAsset.fromJson(json['profilePhotoAsset']),
      visitingCardAsset: VendorProfileAsset.fromJson(json['visitingCardAsset']),
    );
  }
}

class VendorSelfProfileDraft {
  const VendorSelfProfileDraft({
    required this.companyName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.address,
    required this.country,
    required this.state,
    required this.city,
    required this.zipcode,
    required this.website,
    required this.workDescription,
    required this.category,
    required this.vendorType,
    required this.facebookUrl,
    required this.instagramUrl,
    required this.youtubeUrl,
    required this.linkedinUrl,
    required this.xUrl,
    required this.googleLocation,
    required this.companyLogoAsset,
    required this.idProofAsset,
    required this.locationProofAsset,
    required this.companyBrochureAsset,
    required this.profilePhotoAsset,
    required this.visitingCardAsset,
    required this.companyLogoFile,
    required this.idProofFile,
    required this.locationProofFile,
    required this.companyBrochureFile,
    required this.profilePhotoFile,
    required this.visitingCardFile,
  });

  const VendorSelfProfileDraft.empty()
    : companyName = '',
      contactPerson = '',
      email = '',
      phone = '',
      whatsapp = '',
      address = '',
      country = '',
      state = '',
      city = '',
      zipcode = '',
      website = '',
      workDescription = '',
      category = '',
      vendorType = '',
      facebookUrl = '',
      instagramUrl = '',
      youtubeUrl = '',
      linkedinUrl = '',
      xUrl = '',
      googleLocation = '',
      companyLogoAsset = const VendorProfileAsset.empty(),
      idProofAsset = const VendorProfileAsset.empty(),
      locationProofAsset = const VendorProfileAsset.empty(),
      companyBrochureAsset = const VendorProfileAsset.empty(),
      profilePhotoAsset = const VendorProfileAsset.empty(),
      visitingCardAsset = const VendorProfileAsset.empty(),
      companyLogoFile = null,
      idProofFile = null,
      locationProofFile = null,
      companyBrochureFile = null,
      profilePhotoFile = null,
      visitingCardFile = null;

  final String companyName;
  final String contactPerson;
  final String email;
  final String phone;
  final String whatsapp;
  final String address;
  final String country;
  final String state;
  final String city;
  final String zipcode;
  final String website;
  final String workDescription;
  final String category;
  final String vendorType;
  final String facebookUrl;
  final String instagramUrl;
  final String youtubeUrl;
  final String linkedinUrl;
  final String xUrl;
  final String googleLocation;
  final VendorProfileAsset companyLogoAsset;
  final VendorProfileAsset idProofAsset;
  final VendorProfileAsset locationProofAsset;
  final VendorProfileAsset companyBrochureAsset;
  final VendorProfileAsset profilePhotoAsset;
  final VendorProfileAsset visitingCardAsset;
  final AssociationUploadFile? companyLogoFile;
  final AssociationUploadFile? idProofFile;
  final AssociationUploadFile? locationProofFile;
  final AssociationUploadFile? companyBrochureFile;
  final AssociationUploadFile? profilePhotoFile;
  final AssociationUploadFile? visitingCardFile;

  factory VendorSelfProfileDraft.fromProfile(VendorSelfProfile profile) {
    return VendorSelfProfileDraft(
      companyName: profile.companyName,
      contactPerson: profile.contactPerson,
      email: profile.email,
      phone: profile.phone,
      whatsapp: profile.whatsapp,
      address: profile.address,
      country: profile.country,
      state: profile.state,
      city: profile.city,
      zipcode: profile.zipcode,
      website: profile.website,
      workDescription: profile.workDescription,
      category: profile.category,
      vendorType: profile.vendorType,
      facebookUrl: profile.facebookUrl,
      instagramUrl: profile.instagramUrl,
      youtubeUrl: profile.youtubeUrl,
      linkedinUrl: profile.linkedinUrl,
      xUrl: profile.xUrl,
      googleLocation: profile.googleLocation,
      companyLogoAsset: profile.companyLogoAsset,
      idProofAsset: profile.idProofAsset,
      locationProofAsset: profile.locationProofAsset,
      companyBrochureAsset: profile.companyBrochureAsset,
      profilePhotoAsset: profile.profilePhotoAsset,
      visitingCardAsset: profile.visitingCardAsset,
      companyLogoFile: null,
      idProofFile: null,
      locationProofFile: null,
      companyBrochureFile: null,
      profilePhotoFile: null,
      visitingCardFile: null,
    );
  }

  VendorSelfProfileDraft copyWith({
    String? companyName,
    String? contactPerson,
    String? email,
    String? phone,
    String? whatsapp,
    String? address,
    String? country,
    String? state,
    String? city,
    String? zipcode,
    String? website,
    String? workDescription,
    String? category,
    String? vendorType,
    String? facebookUrl,
    String? instagramUrl,
    String? youtubeUrl,
    String? linkedinUrl,
    String? xUrl,
    String? googleLocation,
    VendorProfileAsset? companyLogoAsset,
    VendorProfileAsset? idProofAsset,
    VendorProfileAsset? locationProofAsset,
    VendorProfileAsset? companyBrochureAsset,
    VendorProfileAsset? profilePhotoAsset,
    VendorProfileAsset? visitingCardAsset,
    AssociationUploadFile? companyLogoFile,
    AssociationUploadFile? idProofFile,
    AssociationUploadFile? locationProofFile,
    AssociationUploadFile? companyBrochureFile,
    AssociationUploadFile? profilePhotoFile,
    AssociationUploadFile? visitingCardFile,
  }) {
    return VendorSelfProfileDraft(
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      zipcode: zipcode ?? this.zipcode,
      website: website ?? this.website,
      workDescription: workDescription ?? this.workDescription,
      category: category ?? this.category,
      vendorType: vendorType ?? this.vendorType,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      xUrl: xUrl ?? this.xUrl,
      googleLocation: googleLocation ?? this.googleLocation,
      companyLogoAsset: companyLogoAsset ?? this.companyLogoAsset,
      idProofAsset: idProofAsset ?? this.idProofAsset,
      locationProofAsset: locationProofAsset ?? this.locationProofAsset,
      companyBrochureAsset: companyBrochureAsset ?? this.companyBrochureAsset,
      profilePhotoAsset: profilePhotoAsset ?? this.profilePhotoAsset,
      visitingCardAsset: visitingCardAsset ?? this.visitingCardAsset,
      companyLogoFile: companyLogoFile ?? this.companyLogoFile,
      idProofFile: idProofFile ?? this.idProofFile,
      locationProofFile: locationProofFile ?? this.locationProofFile,
      companyBrochureFile: companyBrochureFile ?? this.companyBrochureFile,
      profilePhotoFile: profilePhotoFile ?? this.profilePhotoFile,
      visitingCardFile: visitingCardFile ?? this.visitingCardFile,
    );
  }

  String? get validationMessage {
    if (companyName.trim().isEmpty) {
      return 'Company name is required.';
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      return 'Enter a valid contact email.';
    }
    return null;
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
    required this.primaryLoginEmail,
    required this.secondaryLoginEmail,
    required this.membershipPlan,
    required this.paymentAmount,
    required this.onboardingStartDate,
    required this.onboardingEndDate,
    required this.paymentDueDate,
    required this.notes,
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
  final String primaryLoginEmail;
  final String secondaryLoginEmail;
  final String membershipPlan;
  final String paymentAmount;
  final String onboardingStartDate;
  final String onboardingEndDate;
  final String paymentDueDate;
  final String notes;

  static MemberAccessStatus _accessStatusFromVendorJson(
    Map<String, dynamic> json,
  ) {
    final vendorStatus = json['status']?.toString().trim().toUpperCase() ?? '';
    switch (vendorStatus) {
      case 'ACTIVE':
        return MemberAccessStatus.approved;
      case 'SUSPENDED':
        return MemberAccessStatus.suspended;
      case 'LAPSED':
        return MemberAccessStatus.cancelled;
      case 'PENDING':
        return MemberAccessStatus.pending;
    }

    final users =
        (json['users'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
    final primaryUser =
        users.isNotEmpty ? users.first : json['user'] as Map<String, dynamic>?;
    if (primaryUser != null) {
      return MemberAccessStatusMeta.fromApi(
        approvalStatus: primaryUser['approvalStatus']?.toString() ?? 'PENDING',
        isActive: primaryUser['isActive'] == true,
      );
    }
    return MemberAccessStatus.pending;
  }

  factory AdminVendorAccessItem.fromJson(Map<String, dynamic> json) {
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
      accessStatus: _accessStatusFromVendorJson(json),
      primaryLoginEmail: json['primaryLoginEmail']?.toString() ?? '',
      secondaryLoginEmail: json['secondaryLoginEmail']?.toString() ?? '',
      membershipPlan: json['membershipPlan']?.toString() ?? '',
      paymentAmount: json['paymentAmount']?.toString() ?? '',
      onboardingStartDate: json['onboardingStartAt']?.toString() ?? '',
      onboardingEndDate: json['onboardingEndAt']?.toString() ?? '',
      paymentDueDate: json['paymentDueDate']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class AdminVendorApprovalDraft {
  const AdminVendorApprovalDraft({
    required this.planName,
    required this.openingTime,
    required this.closingTime,
    required this.membershipPlan,
    required this.paymentAmount,
    required this.onboardingStartAt,
    required this.onboardingEndAt,
    required this.paymentDueDate,
    required this.gstNumber,
    required this.isRestaurant,
    required this.paymentMode,
    required this.bankName,
    required this.transactionId,
    required this.paymentDescription,
    required this.googleLocation,
    required this.idProof,
    required this.locationProof,
    required this.companyBrochure,
    required this.profilePhoto,
    required this.visitingCard,
  });

  const AdminVendorApprovalDraft.empty()
    : planName = '',
      openingTime = '',
      closingTime = '',
      membershipPlan = '',
      paymentAmount = '',
      onboardingStartAt = '',
      onboardingEndAt = '',
      paymentDueDate = '',
      gstNumber = '',
      isRestaurant = false,
      paymentMode = 'Online/NEFT/IMPS',
      bankName = '',
      transactionId = '',
      paymentDescription = '',
      googleLocation = '',
      idProof = null,
      locationProof = null,
      companyBrochure = null,
      profilePhoto = null,
      visitingCard = null;

  final String planName;
  final String openingTime;
  final String closingTime;
  final String membershipPlan;
  final String paymentAmount;
  final String onboardingStartAt;
  final String onboardingEndAt;
  final String paymentDueDate;
  final String gstNumber;
  final bool isRestaurant;
  final String paymentMode;
  final String bankName;
  final String transactionId;
  final String paymentDescription;
  final String googleLocation;
  final PlatformFile? idProof;
  final PlatformFile? locationProof;
  final PlatformFile? companyBrochure;
  final PlatformFile? profilePhoto;
  final PlatformFile? visitingCard;

  AdminVendorApprovalDraft copyWith({
    String? planName,
    String? openingTime,
    String? closingTime,
    String? membershipPlan,
    String? paymentAmount,
    String? onboardingStartAt,
    String? onboardingEndAt,
    String? paymentDueDate,
    String? gstNumber,
    bool? isRestaurant,
    String? paymentMode,
    String? bankName,
    String? transactionId,
    String? paymentDescription,
    String? googleLocation,
    PlatformFile? idProof,
    PlatformFile? locationProof,
    PlatformFile? companyBrochure,
    PlatformFile? profilePhoto,
    PlatformFile? visitingCard,
    bool clearIdProof = false,
    bool clearLocationProof = false,
    bool clearCompanyBrochure = false,
    bool clearProfilePhoto = false,
    bool clearVisitingCard = false,
  }) {
    return AdminVendorApprovalDraft(
      planName: planName ?? this.planName,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      membershipPlan: membershipPlan ?? this.membershipPlan,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      onboardingStartAt: onboardingStartAt ?? this.onboardingStartAt,
      onboardingEndAt: onboardingEndAt ?? this.onboardingEndAt,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      gstNumber: gstNumber ?? this.gstNumber,
      isRestaurant: isRestaurant ?? this.isRestaurant,
      paymentMode: paymentMode ?? this.paymentMode,
      bankName: bankName ?? this.bankName,
      transactionId: transactionId ?? this.transactionId,
      paymentDescription: paymentDescription ?? this.paymentDescription,
      googleLocation: googleLocation ?? this.googleLocation,
      idProof: clearIdProof ? null : (idProof ?? this.idProof),
      locationProof:
          clearLocationProof ? null : (locationProof ?? this.locationProof),
      companyBrochure:
          clearCompanyBrochure
              ? null
              : (companyBrochure ?? this.companyBrochure),
      profilePhoto:
          clearProfilePhoto ? null : (profilePhoto ?? this.profilePhoto),
      visitingCard:
          clearVisitingCard ? null : (visitingCard ?? this.visitingCard),
    );
  }

  String? get validationMessage {
    if (planName.trim().isEmpty) {
      return 'Plan name is required before approving a vendor registration.';
    }
    if (membershipPlan.trim().isEmpty) {
      return 'Membership plan is required before approving a vendor registration.';
    }
    if (paymentAmount.trim().isEmpty) {
      return 'Payment amount is required before approving a vendor registration.';
    }
    if (onboardingStartAt.trim().isEmpty) {
      return 'Start date is required before approving a vendor registration.';
    }
    if (onboardingEndAt.trim().isEmpty) {
      return 'End date is required before approving a vendor registration.';
    }
    if (paymentMode.trim().isEmpty) {
      return 'Payment mode is required before approving a vendor registration.';
    }
    if (bankName.trim().isEmpty) {
      return 'Bank name is required before approving a vendor registration.';
    }
    if (transactionId.trim().isEmpty) {
      return 'Transaction ID is required before approving a vendor registration.';
    }
    return null;
  }
}

class VendorTaxonomySubCategoryItem {
  const VendorTaxonomySubCategoryItem({
    required this.id,
    required this.associationId,
    required this.categoryId,
    required this.name,
    required this.displayOrder,
  });

  final String id;
  final String associationId;
  final String categoryId;
  final String name;
  final int displayOrder;

  factory VendorTaxonomySubCategoryItem.fromJson(Map<String, dynamic> json) {
    return VendorTaxonomySubCategoryItem(
      id: json['id']?.toString() ?? '',
      associationId: json['associationId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class VendorTaxonomyCategoryItem {
  const VendorTaxonomyCategoryItem({
    required this.id,
    required this.associationId,
    required this.name,
    required this.displayOrder,
    required this.subCategories,
  });

  final String id;
  final String associationId;
  final String name;
  final int displayOrder;
  final List<VendorTaxonomySubCategoryItem> subCategories;

  factory VendorTaxonomyCategoryItem.fromJson(Map<String, dynamic> json) {
    final subCategories =
        (json['subCategories'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(VendorTaxonomySubCategoryItem.fromJson)
            .toList()
          ..sort((left, right) {
            final orderCompare = left.displayOrder.compareTo(
              right.displayOrder,
            );
            if (orderCompare != 0) {
              return orderCompare;
            }
            return left.name.toLowerCase().compareTo(right.name.toLowerCase());
          });

    return VendorTaxonomyCategoryItem(
      id: json['id']?.toString() ?? '',
      associationId: json['associationId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      subCategories: subCategories,
    );
  }
}

class AdminVendorRegistrationDraft {
  const AdminVendorRegistrationDraft({
    required this.companyName,
    required this.contactPerson,
    required this.phoneCode,
    required this.phone,
    required this.whatsAppCode,
    required this.whatsApp,
    required this.email,
    required this.primaryLoginEmail,
    required this.secondaryLoginEmail,
    required this.categoryId,
    required this.categoryName,
    required this.subCategoryId,
    required this.subCategoryName,
    required this.country,
    required this.state,
    required this.address,
    required this.city,
    required this.zipcode,
    required this.website,
    required this.facebookUrl,
    required this.instagramUrl,
    required this.youtubeUrl,
    required this.linkedinUrl,
    required this.xUrl,
  });

  const AdminVendorRegistrationDraft.empty()
    : companyName = '',
      contactPerson = '',
      phoneCode = '+91',
      phone = '',
      whatsAppCode = '+91',
      whatsApp = '',
      email = '',
      primaryLoginEmail = '',
      secondaryLoginEmail = '',
      categoryId = '',
      categoryName = '',
      subCategoryId = '',
      subCategoryName = '',
      country = 'India',
      state = '',
      address = '',
      city = '',
      zipcode = '',
      website = '',
      facebookUrl = '',
      instagramUrl = '',
      youtubeUrl = '',
      linkedinUrl = '',
      xUrl = '';

  final String companyName;
  final String contactPerson;
  final String phoneCode;
  final String phone;
  final String whatsAppCode;
  final String whatsApp;
  final String email;
  final String primaryLoginEmail;
  final String secondaryLoginEmail;
  final String categoryId;
  final String categoryName;
  final String subCategoryId;
  final String subCategoryName;
  final String country;
  final String state;
  final String address;
  final String city;
  final String zipcode;
  final String website;
  final String facebookUrl;
  final String instagramUrl;
  final String youtubeUrl;
  final String linkedinUrl;
  final String xUrl;

  AdminVendorRegistrationDraft copyWith({
    String? companyName,
    String? contactPerson,
    String? phoneCode,
    String? phone,
    String? whatsAppCode,
    String? whatsApp,
    String? email,
    String? primaryLoginEmail,
    String? secondaryLoginEmail,
    String? categoryId,
    String? categoryName,
    String? subCategoryId,
    String? subCategoryName,
    String? country,
    String? state,
    String? address,
    String? city,
    String? zipcode,
    String? website,
    String? facebookUrl,
    String? instagramUrl,
    String? youtubeUrl,
    String? linkedinUrl,
    String? xUrl,
  }) {
    return AdminVendorRegistrationDraft(
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phoneCode: phoneCode ?? this.phoneCode,
      phone: phone ?? this.phone,
      whatsAppCode: whatsAppCode ?? this.whatsAppCode,
      whatsApp: whatsApp ?? this.whatsApp,
      email: email ?? this.email,
      primaryLoginEmail: primaryLoginEmail ?? this.primaryLoginEmail,
      secondaryLoginEmail: secondaryLoginEmail ?? this.secondaryLoginEmail,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      country: country ?? this.country,
      state: state ?? this.state,
      address: address ?? this.address,
      city: city ?? this.city,
      zipcode: zipcode ?? this.zipcode,
      website: website ?? this.website,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      xUrl: xUrl ?? this.xUrl,
    );
  }

  String? get validationMessage {
    if (companyName.trim().isEmpty) {
      return 'Company name is required.';
    }
    if (contactPerson.trim().isEmpty) {
      return 'Contact person is required.';
    }
    if (phone.trim().isEmpty) {
      return 'Mobile number is required.';
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      return 'Enter a valid contact email.';
    }
    if (primaryLoginEmail.trim().isEmpty || !primaryLoginEmail.contains('@')) {
      return 'Enter a valid primary login email.';
    }
    if (secondaryLoginEmail.trim().isNotEmpty &&
        !secondaryLoginEmail.contains('@')) {
      return 'Enter a valid secondary login email or leave it blank.';
    }
    if (secondaryLoginEmail.trim().isNotEmpty &&
        secondaryLoginEmail.trim().toLowerCase() ==
            primaryLoginEmail.trim().toLowerCase()) {
      return 'Primary and secondary login emails must be different.';
    }
    if (categoryId.trim().isEmpty || categoryName.trim().isEmpty) {
      return 'Select a vendor category.';
    }
    if (subCategoryId.trim().isEmpty || subCategoryName.trim().isEmpty) {
      return 'Select a vendor sub-category.';
    }
    if (country.trim() == 'India' && state.trim().isEmpty) {
      return 'Select a state.';
    }
    if (country.trim() == 'India' && city.trim().isEmpty) {
      return 'Select a city.';
    }
    if (address.trim().isEmpty) {
      return 'Address is required.';
    }
    return null;
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
    required this.brochureUrl,
    required this.socialMediaUrl,
    required this.reviewStatus,
    required this.paymentReceived,
    required this.paymentMode,
    required this.paymentRemarks,
    required this.displayIndex,
    required this.displayStart,
    required this.displayEnd,
  });

  final String id;
  final String vendorName;
  final String shortText;
  final String contactNumber;
  final String mediaUrl;
  final String brochureUrl;
  final String socialMediaUrl;
  final BannerReviewStatus reviewStatus;
  final bool paymentReceived;
  final String paymentMode;
  final String paymentRemarks;
  final int displayIndex;
  final String displayStart;
  final String displayEnd;

  factory AdminAppBannerItem.fromJson(Map<String, dynamic> json) {
    return AdminAppBannerItem(
      id: json['id']?.toString() ?? '',
      vendorName: json['vendorName']?.toString() ?? '',
      shortText: json['shortText']?.toString() ?? '',
      contactNumber: json['contactNumber']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      brochureUrl: json['brochureUrl']?.toString() ?? '',
      socialMediaUrl: json['socialMediaUrl']?.toString() ?? '',
      reviewStatus: BannerReviewStatusMeta.fromApi(
        json['reviewStatus']?.toString() ?? 'PENDING',
      ),
      paymentReceived: json['paymentReceived'] == true,
      paymentMode: json['paymentMode']?.toString() ?? '',
      paymentRemarks: json['paymentRemarks']?.toString() ?? '',
      displayIndex: (json['displayIndex'] as num?)?.toInt() ?? 0,
      displayStart: json['displayStart']?.toString() ?? '',
      displayEnd: json['displayEnd']?.toString() ?? '',
    );
  }
}

class AdminBannerModerationDraft {
  const AdminBannerModerationDraft({
    required this.status,
    required this.paymentReceived,
    required this.paymentMode,
    required this.paymentRemarks,
    required this.displayIndex,
    required this.displayStart,
    required this.displayEnd,
  });

  final BannerReviewStatus status;
  final bool paymentReceived;
  final String paymentMode;
  final String paymentRemarks;
  final String displayIndex;
  final String displayStart;
  final String displayEnd;

  AdminBannerModerationDraft copyWith({
    BannerReviewStatus? status,
    bool? paymentReceived,
    String? paymentMode,
    String? paymentRemarks,
    String? displayIndex,
    String? displayStart,
    String? displayEnd,
  }) {
    return AdminBannerModerationDraft(
      status: status ?? this.status,
      paymentReceived: paymentReceived ?? this.paymentReceived,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentRemarks: paymentRemarks ?? this.paymentRemarks,
      displayIndex: displayIndex ?? this.displayIndex,
      displayStart: displayStart ?? this.displayStart,
      displayEnd: displayEnd ?? this.displayEnd,
    );
  }

  String? get validationMessage {
    if (status == BannerReviewStatus.approved) {
      if (displayIndex.trim().isEmpty) {
        return 'Banner slot is required before approving.';
      }
      if (int.tryParse(displayIndex.trim()) == null) {
        return 'Banner slot must be a valid number.';
      }
      if (!paymentReceived) {
        return 'Mark payment as received before approving a banner.';
      }
      if (paymentMode.trim().isEmpty) {
        return 'Payment mode is required before approving a banner.';
      }
    }
    return null;
  }
}

class AdminAppBannerDraft {
  const AdminAppBannerDraft({
    required this.vendorId,
    required this.vendorName,
    required this.contactNumber,
    required this.shortText,
    required this.socialMediaUrl,
    required this.mediaFile,
    required this.brochureFile,
  });

  const AdminAppBannerDraft.empty()
    : vendorId = '',
      vendorName = '',
      contactNumber = '',
      shortText = '',
      socialMediaUrl = '',
      mediaFile = null,
      brochureFile = null;

  final String vendorId;
  final String vendorName;
  final String contactNumber;
  final String shortText;
  final String socialMediaUrl;
  final AssociationUploadFile? mediaFile;
  final AssociationUploadFile? brochureFile;

  bool get canSubmit =>
      vendorId.trim().isNotEmpty &&
      shortText.trim().isNotEmpty &&
      mediaFile != null;

  String? get validationMessage {
    if (vendorId.trim().isEmpty) {
      return 'Select a vendor first.';
    }
    if (shortText.trim().isEmpty) {
      return 'Add the banner message before submitting.';
    }
    if (mediaFile == null) {
      return 'Attach a lightweight banner image for the Flutter app.';
    }
    return null;
  }

  AdminAppBannerDraft copyWith({
    String? vendorId,
    String? vendorName,
    String? contactNumber,
    String? shortText,
    String? socialMediaUrl,
    AssociationUploadFile? mediaFile,
    AssociationUploadFile? brochureFile,
  }) {
    return AdminAppBannerDraft(
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      contactNumber: contactNumber ?? this.contactNumber,
      shortText: shortText ?? this.shortText,
      socialMediaUrl: socialMediaUrl ?? this.socialMediaUrl,
      mediaFile: mediaFile ?? this.mediaFile,
      brochureFile: brochureFile ?? this.brochureFile,
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

class AdminTimelineDraft {
  const AdminTimelineDraft({
    required this.sourceType,
    required this.memberId,
    required this.vendorId,
    required this.postedBy,
    required this.caption,
    required this.contactNumber,
    required this.landingPageUrl,
    required this.youtubeUrl,
    required this.facebookUrl,
    required this.imageFile,
    required this.brochureFile,
  });

  const AdminTimelineDraft.empty()
    : sourceType = 'ASSOCIATION',
      memberId = '',
      vendorId = '',
      postedBy = '',
      caption = '',
      contactNumber = '',
      landingPageUrl = '',
      youtubeUrl = '',
      facebookUrl = '',
      imageFile = null,
      brochureFile = null;

  final String sourceType;
  final String memberId;
  final String vendorId;
  final String postedBy;
  final String caption;
  final String contactNumber;
  final String landingPageUrl;
  final String youtubeUrl;
  final String facebookUrl;
  final AssociationUploadFile? imageFile;
  final AssociationUploadFile? brochureFile;

  bool get canSubmit {
    final type = sourceType.trim().toUpperCase();
    if (caption.trim().isEmpty) {
      return false;
    }
    if (type == 'VENDOR') {
      return vendorId.trim().isNotEmpty;
    }
    if (type == 'MEMBER') {
      return memberId.trim().isNotEmpty;
    }
    return true;
  }

  String? get validationMessage {
    final type = sourceType.trim().toUpperCase();
    if (caption.trim().isEmpty) {
      return 'Add the timeline post copy before saving.';
    }
    if (type == 'VENDOR' && vendorId.trim().isEmpty) {
      return 'Select a vendor for this timeline post.';
    }
    if (type == 'MEMBER' && memberId.trim().isEmpty) {
      return 'Select a member for this timeline post.';
    }
    return null;
  }

  AdminTimelineDraft copyWith({
    String? sourceType,
    String? memberId,
    String? vendorId,
    String? postedBy,
    String? caption,
    String? contactNumber,
    String? landingPageUrl,
    String? youtubeUrl,
    String? facebookUrl,
    AssociationUploadFile? imageFile,
    AssociationUploadFile? brochureFile,
  }) {
    return AdminTimelineDraft(
      sourceType: sourceType ?? this.sourceType,
      memberId: memberId ?? this.memberId,
      vendorId: vendorId ?? this.vendorId,
      postedBy: postedBy ?? this.postedBy,
      caption: caption ?? this.caption,
      contactNumber: contactNumber ?? this.contactNumber,
      landingPageUrl: landingPageUrl ?? this.landingPageUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      imageFile: imageFile ?? this.imageFile,
      brochureFile: brochureFile ?? this.brochureFile,
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

class AssociationGalleryPhoto {
  const AssociationGalleryPhoto({
    required this.id,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.createdAt,
  });

  final String id;
  final String imageUrl;
  final String thumbnailUrl;
  final String createdAt;

  String get createdDateLabel =>
      createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

  factory AssociationGalleryPhoto.fromJson(Map<String, dynamic> json) {
    return AssociationGalleryPhoto(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      thumbnailUrl:
          json['thumbnailUrl']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class AssociationGalleryFolder {
  const AssociationGalleryFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.photoCount,
    required this.previewPhotos,
    required this.photos,
  });

  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int photoCount;
  final List<AssociationGalleryPhoto> previewPhotos;
  final List<AssociationGalleryPhoto> photos;

  String get createdDateLabel =>
      createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

  String get displayName {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    if (createdDateLabel.isNotEmpty) {
      return createdDateLabel;
    }
    return 'Gallery folder';
  }

  factory AssociationGalleryFolder.fromJson(Map<String, dynamic> json) {
    return AssociationGalleryFolder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      previewPhotos:
          (json['previewPhotos'] as List<dynamic>? ?? const [])
              .map(
                (item) => AssociationGalleryPhoto.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      photos:
          (json['photos'] as List<dynamic>? ?? const [])
              .map(
                (item) => AssociationGalleryPhoto.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
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
      'vendor' => AppViewerRole.vendor,
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

class SessionReportSummary {
  const SessionReportSummary({
    required this.activeWindowMinutes,
    required this.loggedInUsers,
    required this.activeUsers,
    required this.totalSessions,
    required this.activeSessions,
    required this.sessionsToday,
  });

  final int activeWindowMinutes;
  final int loggedInUsers;
  final int activeUsers;
  final int totalSessions;
  final int activeSessions;
  final int sessionsToday;

  factory SessionReportSummary.fromJson(Map<String, dynamic> json) {
    return SessionReportSummary(
      activeWindowMinutes: (json['activeWindowMinutes'] as num?)?.toInt() ?? 5,
      loggedInUsers: (json['loggedInUsers'] as num?)?.toInt() ?? 0,
      activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      activeSessions: (json['activeSessions'] as num?)?.toInt() ?? 0,
      sessionsToday: (json['sessionsToday'] as num?)?.toInt() ?? 0,
    );
  }
}

class SessionReportItem {
  const SessionReportItem({
    required this.sessionId,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.viewerRole,
    required this.isActiveNow,
    required this.createdAt,
    required this.lastSeenAt,
    required this.expiresAt,
    required this.refreshExpiresAt,
    required this.deviceInfo,
    required this.userAgent,
    required this.ipAddress,
  });

  final String sessionId;
  final String userId;
  final String displayName;
  final String email;
  final AppViewerRole viewerRole;
  final bool isActiveNow;
  final String createdAt;
  final String lastSeenAt;
  final String expiresAt;
  final String refreshExpiresAt;
  final String deviceInfo;
  final String userAgent;
  final String ipAddress;

  String get displayLabel => displayName.trim().isEmpty ? email : displayName;

  factory SessionReportItem.fromJson(Map<String, dynamic> json) {
    final viewerRole = switch (json['viewerRole']?.toString()) {
      'admin' => AppViewerRole.admin,
      'member' => AppViewerRole.member,
      'vendor' => AppViewerRole.vendor,
      _ => AppViewerRole.viewOnly,
    };

    return SessionReportItem(
      sessionId: json['sessionId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      viewerRole: viewerRole,
      isActiveNow: json['isActiveNow'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
      lastSeenAt: json['lastSeenAt']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
      refreshExpiresAt: json['refreshExpiresAt']?.toString() ?? '',
      deviceInfo: json['deviceInfo']?.toString() ?? '',
      userAgent: json['userAgent']?.toString() ?? '',
      ipAddress: json['ipAddress']?.toString() ?? '',
    );
  }
}

class SessionReportData {
  const SessionReportData({required this.summary, required this.sessions});

  final SessionReportSummary summary;
  final List<SessionReportItem> sessions;

  factory SessionReportData.fromJson(Map<String, dynamic> json) {
    return SessionReportData(
      summary: SessionReportSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      sessions:
          (json['sessions'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(SessionReportItem.fromJson)
              .toList(),
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
    if (approvalStatus == 'CANCELLED' || approvalStatus == 'REJECTED') {
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
      photoUrl:
          json['photoUrl']?.toString() ??
          json['thumbnailUrl']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
    );
  }
}

class AdminMemberAccessItem {
  const AdminMemberAccessItem({
    required this.id,
    required this.name,
    required this.companyName,
    required this.roleTitle,
    required this.committeePost,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.accessStatus,
  });

  final String id;
  final String name;
  final String companyName;
  final String roleTitle;
  final String committeePost;
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
      committeePost: json['committeePost']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      photoUrl:
          json['photoUrl']?.toString() ??
          json['thumbnailUrl']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
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
      photoUrl:
          json['thumbnailUrl']?.toString() ??
          json['photoUrl']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
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

class MemberDirectoryPage {
  const MemberDirectoryPage({
    required this.members,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  const MemberDirectoryPage.empty()
    : members = const [],
      page = 1,
      pageSize = 0,
      totalCount = 0,
      hasMore = false;

  final List<MemberDirectoryItem> members;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  factory MemberDirectoryPage.fromJson(Map<String, dynamic> json) {
    final items =
        (json['members'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MemberDirectoryItem.fromJson)
            .toList();
    final pagination = json['pagination'] as Map<String, dynamic>? ?? const {};
    return MemberDirectoryPage(
      members: items,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      pageSize: (pagination['pageSize'] as num?)?.toInt() ?? items.length,
      totalCount: (pagination['totalCount'] as num?)?.toInt() ?? items.length,
      hasMore: pagination['hasMore'] == true,
    );
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

  String? get validationMessage {
    if (name.trim().isEmpty) {
      return 'Event name is required.';
    }
    if (type.trim().isEmpty) {
      return 'Event type is required.';
    }
    if (date.trim().isEmpty) {
      return 'Event date is required.';
    }
    if (venue.trim().isEmpty) {
      return 'Event venue is required.';
    }
    if (audience.trim().isEmpty) {
      return 'Select the audience for this event.';
    }
    if (entryType.trim().isEmpty) {
      return 'Choose whether the event is free or paid.';
    }
    if (entryType.trim().toLowerCase() == 'paid' &&
        entryCharges.trim().isEmpty) {
      return 'Entry charges are required for paid events.';
    }
    if (summary.trim().isEmpty) {
      return 'Add a short event summary before saving.';
    }
    return null;
  }

  bool get canSubmit => validationMessage == null;
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
    required this.galleryFolders,
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
      galleryItems = const [],
      galleryFolders = const [];

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
  final List<AssociationGalleryFolder> galleryFolders;

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
      galleryFolders:
          (json['galleryFolders'] as List<dynamic>? ?? const [])
              .map(
                (item) => AssociationGalleryFolder.fromJson(
                  item as Map<String, dynamic>,
                ),
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

  String? get validationMessage {
    if (name.trim().isEmpty) {
      return 'Association name is required.';
    }
    if (headOfficeAddress.trim().isEmpty) {
      return 'Head office address is required.';
    }
    if (city.trim().isEmpty) {
      return 'Head office city is required.';
    }
    if (state.trim().isEmpty) {
      return 'Head office state is required.';
    }
    if (pincode.trim().isEmpty) {
      return 'Head office pincode is required.';
    }
    if (contactNumbers
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .isEmpty) {
      return 'At least one association contact number is required.';
    }
    for (var index = 0; index < regionalAddresses.length; index++) {
      final address = regionalAddresses[index];
      final hasAnyField =
          address.label.trim().isNotEmpty ||
          address.officeAddress.trim().isNotEmpty ||
          address.city.trim().isNotEmpty ||
          address.state.trim().isNotEmpty ||
          address.pincode.trim().isNotEmpty ||
          address.registrationNumber.trim().isNotEmpty ||
          address.gstNumber.trim().isNotEmpty ||
          address.website.trim().isNotEmpty ||
          address.helpdeskNumber.trim().isNotEmpty ||
          address.contactNumbers.trim().isNotEmpty ||
          address.googleMapsLink.trim().isNotEmpty;
      if (!hasAnyField) {
        continue;
      }
      if (address.label.trim().isEmpty) {
        return 'Regional office ${index + 1} needs a label.';
      }
      if (address.officeAddress.trim().isEmpty) {
        return 'Regional office ${index + 1} needs an office address.';
      }
      if (address.city.trim().isEmpty || address.state.trim().isEmpty) {
        return 'Regional office ${index + 1} needs both city and state.';
      }
    }
    return null;
  }

  bool get canSubmit => validationMessage == null;
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
    final hasCommitteePost = member.committeePost.trim().isNotEmpty;
    return switch (this) {
      MemberDirectoryFilter.all => true,
      MemberDirectoryFilter.primary => role == 'primary',
      MemberDirectoryFilter.committee => hasCommitteePost,
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
        title: 'Guest Members',
        subtitle:
            'Guest member records from the backend using the same searchable member card view.',
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
