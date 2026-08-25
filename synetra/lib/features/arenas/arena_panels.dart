part of '../../main.dart';

class MemberArenaPanel extends ConsumerStatefulWidget {
  const MemberArenaPanel({
    super.key,
    required this.viewerRole,
    required this.section,
    required this.onSectionSelected,
  });

  final AppViewerRole viewerRole;
  final MemberArenaSection section;
  final ValueChanged<MemberArenaSection> onSectionSelected;

  @override
  ConsumerState<MemberArenaPanel> createState() => _MemberArenaPanelState();
}

class _MemberArenaPanelState extends ConsumerState<MemberArenaPanel> {
  String? _updatingPostId;
  String? _editingMemberMasterId;
  bool _isSavingMemberMaster = false;
  int _directoryRefreshToken = 0;

  Future<void> _refresh() async {
    ref.invalidate(memberPostsProvider(widget.viewerRole));
    ref.invalidate(tenantProvider);
    if (widget.section == MemberArenaSection.media) {
      await ref.read(memberPostsProvider(widget.viewerRole).future);
      return;
    }
    if (widget.section == MemberArenaSection.master) {
      if (mounted) {
        setState(() {
          _directoryRefreshToken++;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _directoryRefreshToken++;
      });
    }
  }

  Future<void> _updatePostStatus(
    MemberPostItem post,
    PostReviewStatus status,
  ) async {
    setState(() {
      _updatingPostId = post.id;
    });

    try {
      await ref
          .read(apiClientProvider)
          .updatePostStatus(postId: post.id, status: status);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${post.member.name} post marked ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update post status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingPostId = null;
        });
      }
    }
  }

  Future<void> _openMemberMasterEditor([MemberDirectoryItem? member]) async {
    setState(() {
      _editingMemberMasterId = member?.id ?? '';
    });

    final result = await showDialog<MemberMasterDraft>(
      context: context,
      builder:
          (dialogContext) => _MemberMasterDialog(
            initialDraft:
                member == null
                    ? const MemberMasterDraft.empty()
                    : MemberMasterDraft.fromMember(member),
          ),
    );

    if (!mounted) return;
    setState(() {
      _editingMemberMasterId = null;
    });

    if (result == null || _isSavingMemberMaster) {
      return;
    }

    setState(() {
      _isSavingMemberMaster = true;
    });
    try {
      await ref.read(apiClientProvider).saveMemberRecord(draft: result);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.id.isEmpty ? 'Member created.' : 'Member updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save member: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMemberMaster = false;
        });
      }
    }
  }

  Future<void> _deleteMemberMaster(String memberId) async {
    if (_isSavingMemberMaster) {
      return;
    }
    setState(() {
      _isSavingMemberMaster = true;
    });
    try {
      await ref.read(apiClientProvider).deleteMemberRecord(memberId: memberId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Member deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete member: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMemberMaster = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMediaSection = widget.section == MemberArenaSection.media;
    final isMasterSection = widget.section == MemberArenaSection.master;
    final postsAsync =
        isMediaSection
            ? ref.watch(memberPostsProvider(widget.viewerRole))
            : null;
    if (isMediaSection) {
      return postsAsync!.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load members',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data:
            (posts) => Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(height: 8),
                _MemberMediaView(
                  viewerRole: widget.viewerRole,
                  tenant: ref.watch(tenantProvider).valueOrNull,
                  onNavigateToMemberArena:
                      () => widget.onSectionSelected(
                        MemberArenaNavigation.defaultSection(widget.viewerRole),
                      ),
                  child: _MemberMediaSection(
                    posts: posts,
                    viewerRole: widget.viewerRole,
                    updatingPostId: _updatingPostId,
                    onUpdateStatus: _updatePostStatus,
                  ),
                ),
              ],
            ),
      );
    }

    if (isMasterSection) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 8),
          _PagedMemberMasterSection(
            viewerRole: widget.viewerRole,
            refreshToken: _directoryRefreshToken,
            canManage: widget.viewerRole.isAdmin,
            editingMemberId: _editingMemberMasterId,
            isSaving: _isSavingMemberMaster,
            onOpenEditor: _openMemberMasterEditor,
            onDelete: _deleteMemberMaster,
          ),
        ],
      );
    }

    final tenant = ref.watch(tenantProvider).valueOrNull;
    final directoryChild =
        widget.section == MemberArenaSection.directory
            ? _MemberDirectorySection(
              viewerRole: widget.viewerRole,
              refreshToken: _directoryRefreshToken,
            )
            : _FilteredMemberDirectorySection(
              viewerRole: widget.viewerRole,
              section: widget.section,
              refreshToken: _directoryRefreshToken,
            );

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.section == MemberArenaSection.directory)
          _MemberDirectoryView(
            tenant: tenant,
            onNavigateToMemberArena:
                () => widget.onSectionSelected(
                  MemberArenaNavigation.defaultSection(widget.viewerRole),
                ),
            child: directoryChild,
          )
        else
          _MemberFilteredDirectoryView(
            tenant: tenant,
            section: widget.section,
            onNavigateToMemberArena:
                () => widget.onSectionSelected(
                  MemberArenaNavigation.defaultSection(widget.viewerRole),
                ),
            child: directoryChild,
          ),
      ],
    );
  }
}

class AdminArenaPanel extends ConsumerStatefulWidget {
  const AdminArenaPanel({
    super.key,
    required this.section,
    required this.onSectionSelected,
  });

  final AdminArenaSection section;
  final ValueChanged<AdminArenaSection> onSectionSelected;

  @override
  ConsumerState<AdminArenaPanel> createState() => _AdminArenaPanelState();
}

class VendorArenaPanel extends ConsumerStatefulWidget {
  const VendorArenaPanel({
    super.key,
    required this.viewerRole,
    required this.section,
    required this.onSectionSelected,
    required this.onOpenProfile,
  });

  final AppViewerRole viewerRole;
  final VendorArenaSection section;
  final ValueChanged<VendorArenaSection> onSectionSelected;
  final VoidCallback onOpenProfile;

  @override
  ConsumerState<VendorArenaPanel> createState() => _VendorArenaPanelState();
}

class _VendorArenaPanelState extends ConsumerState<VendorArenaPanel> {
  static const List<String> _vendorPhoneCodeOptions = ['+91'];
  static const List<String> _vendorPlanOptions = [
    'Basic',
    'Standard',
    'Premium',
    'Featured',
  ];
  static const List<String> _vendorPaymentModeOptions = [
    'Online/NEFT/IMPS',
    'Cheque',
    'Cash',
    'Card',
  ];
  static const List<String> _vendorCountryOptions = [
    'India',
    'United Arab Emirates',
    'Singapore',
  ];
  static const Map<String, List<String>> _vendorStateOptionsByCountry = {
    'India': ['Gujarat', 'Maharashtra', 'Karnataka', 'Delhi'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah'],
    'Singapore': ['Central Region'],
  };
  static const Map<String, List<String>> _vendorCityOptionsByState = {
    'Gujarat': [
      'Ahmedabad',
      'Surat',
      'Vadodara',
      'Rajkot',
      'Bhavnagar',
      'Jamnagar',
      'Junagadh',
      'Gandhinagar',
      'Anand',
      'Nadiad',
      'Morbi',
      'Mehsana',
      'Bharuch',
      'Navsari',
      'Vapi',
      'Porbandar',
      'Palanpur',
      'Veraval',
      'Godhra',
      'Gandhidham',
    ],
    'Maharashtra': [
      'Mumbai',
      'Pune',
      'Nagpur',
      'Nashik',
      'Thane',
      'Navi Mumbai',
      'Aurangabad',
      'Solapur',
      'Kolhapur',
      'Amravati',
      'Nanded',
      'Sangli',
      'Jalgaon',
      'Akola',
      'Latur',
      'Ahmednagar',
      'Dhule',
      'Chandrapur',
      'Parbhani',
      'Jalna',
      'Bhiwandi',
      'Panvel',
      'Satara',
      'Ratnagiri',
      'Beed',
      'Yavatmal',
      'Gondia',
      'Wardha',
      'Osmanabad',
      'Palghar',
      'Malegaon',
      'Mira-Bhayandar',
      'Ulhasnagar',
      'Ichalkaranji',
      'Baramati',
    ],
    'Karnataka': [
      'Bengaluru',
      'Mysuru',
      'Mangaluru',
      'Hubballi',
      'Dharwad',
      'Belagavi',
      'Kalaburagi',
      'Ballari',
      'Shivamogga',
      'Tumakuru',
      'Davanagere',
      'Udupi',
      'Vijayapura',
      'Raichur',
      'Bidar',
      'Hassan',
      'Mandya',
      'Kolar',
      'Chikkamagaluru',
      'Karwar',
    ],
    'Delhi': [
      'New Delhi',
      'Central Delhi',
      'East Delhi',
      'North Delhi',
      'South Delhi',
      'West Delhi',
      'Dwarka',
      'Rohini',
      'Saket',
      'Karol Bagh',
      'Janakpuri',
      'Shahdara',
      'Pitampura',
    ],
    'Dubai': ['Dubai'],
    'Abu Dhabi': ['Abu Dhabi'],
    'Sharjah': ['Sharjah'],
    'Central Region': ['Singapore'],
  };

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedTaxonomyCategoryId;
  String? _updatingVendorId;
  String? _updatingBannerId;
  bool _isSavingNewBanner = false;
  String? _savingTaxonomyKey;
  String? _savingVendorRegistrationId;
  String? _savingVendorApprovalId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(vendorDirectoryProvider);
    ref.invalidate(vendorTaxonomyProvider);
    if (widget.viewerRole.isAdmin) {
      ref.invalidate(adminArenaDataProvider);
    }
    await ref.read(vendorDirectoryProvider.future);
  }

  Future<void> _refreshVendorTaxonomy() async {
    ref.invalidate(vendorTaxonomyProvider);
    ref.invalidate(vendorDirectoryProvider);
    if (widget.viewerRole.isAdmin) {
      ref.invalidate(adminArenaDataProvider);
    }
    await Future.wait([
      ref.read(vendorTaxonomyProvider.future),
      ref.read(vendorDirectoryProvider.future),
    ]);
  }

  Future<void> _updateVendorAccess(
    AdminVendorAccessItem vendor,
    MemberAccessStatus status,
  ) async {
    setState(() {
      _updatingVendorId = vendor.id;
    });

    try {
      await ref
          .read(apiClientProvider)
          .updateVendorAccess(vendorId: vendor.id, status: status);
      if (!mounted) return;
      ref.invalidate(adminArenaDataProvider);
      await ref.read(adminArenaDataProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${vendor.displayName} marked ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update vendor access: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingVendorId = null;
        });
      }
    }
  }

  Future<void> _updateBannerStatus(
    AdminAppBannerItem banner,
    BannerReviewStatus status,
  ) async {
    setState(() {
      _updatingBannerId = banner.id;
    });

    try {
      await ref
          .read(apiClientProvider)
          .updateAppBannerModeration(
            bannerId: banner.id,
            status: status,
            paymentReceived:
                status == BannerReviewStatus.approved
                    ? true
                    : banner.paymentReceived,
            paymentMode:
                status == BannerReviewStatus.approved
                    ? (banner.paymentMode.trim().isEmpty
                        ? 'Bank'
                        : banner.paymentMode)
                    : banner.paymentMode,
            paymentRemarks: banner.paymentRemarks,
            displayIndex: banner.displayIndex > 0 ? banner.displayIndex : 1,
          );
      if (!mounted) return;
      ref.invalidate(adminArenaDataProvider);
      await ref.read(adminArenaDataProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${banner.vendorName.isEmpty ? 'Banner' : banner.vendorName} moved to ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update banner status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingBannerId = null;
        });
      }
    }
  }

  AdminBannerModerationDraft _buildBannerModerationDraft(
    AdminAppBannerItem banner,
  ) {
    return AdminBannerModerationDraft(
      status: banner.reviewStatus,
      paymentReceived: banner.paymentReceived,
      paymentMode: banner.paymentMode,
      paymentRemarks: banner.paymentRemarks,
      displayIndex: banner.displayIndex > 0 ? '${banner.displayIndex}' : '',
      displayStart: banner.displayStart,
      displayEnd: banner.displayEnd,
    );
  }

  Future<void> _openBannerModerationDialog(AdminAppBannerItem banner) async {
    var draft = _buildBannerModerationDraft(banner);
    String? validationMessage;

    final result = await showDialog<AdminBannerModerationDraft>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              void updateDraft(AdminBannerModerationDraft nextDraft) {
                setDialogState(() {
                  draft = nextDraft;
                  validationMessage = null;
                });
              }

              Future<void> submit() async {
                final error = draft.validationMessage;
                if (error != null) {
                  setDialogState(() {
                    validationMessage = error;
                  });
                  return;
                }
                Navigator.of(context).pop(draft);
              }

              return AlertDialog(
                title: Text(
                  banner.vendorName.isEmpty
                      ? 'Review Banner'
                      : 'Review ${banner.vendorName}',
                ),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<BannerReviewStatus>(
                          value: draft.status,
                          decoration: const InputDecoration(
                            labelText: 'Banner status',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              BannerReviewStatus.values
                                  .map(
                                    (status) =>
                                        DropdownMenuItem<BannerReviewStatus>(
                                          value: status,
                                          child: Text(status.label),
                                        ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            updateDraft(draft.copyWith(status: value));
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: draft.paymentReceived,
                          title: const Text('Payment received'),
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(paymentReceived: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Payment Mode',
                          initialValue: draft.paymentMode,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(paymentMode: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Payment Remarks',
                          initialValue: draft.paymentRemarks,
                          maxLines: 2,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(paymentRemarks: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Banner Slot',
                          initialValue: draft.displayIndex,
                          keyboardType: TextInputType.number,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(displayIndex: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogTextField(
                                label: 'Display Start',
                                initialValue: draft.displayStart,
                                onChanged:
                                    (value) => updateDraft(
                                      draft.copyWith(displayStart: value),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dialogTextField(
                                label: 'Display End',
                                initialValue: draft.displayEnd,
                                onChanged:
                                    (value) => updateDraft(
                                      draft.copyWith(displayEnd: value),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (validationMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            validationMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  FilledButton(onPressed: submit, child: const Text('Save')),
                ],
              );
            },
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _updatingBannerId = banner.id;
    });
    try {
      await ref
          .read(apiClientProvider)
          .updateAppBannerModeration(
            bannerId: banner.id,
            status: result.status,
            paymentReceived: result.paymentReceived,
            paymentMode: result.paymentMode.trim(),
            paymentRemarks: result.paymentRemarks.trim(),
            displayIndex: int.tryParse(result.displayIndex.trim()) ?? 1,
            displayStart: result.displayStart.trim(),
            displayEnd: result.displayEnd.trim(),
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${banner.vendorName.isEmpty ? 'Banner' : banner.vendorName} updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update banner moderation: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingBannerId = null;
        });
      }
    }
  }

  Future<void> _openAppBannerDialog(List<AdminVendorAccessItem> vendors) async {
    if (vendors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one vendor before creating a banner.'),
        ),
      );
      return;
    }

    AdminAppBannerDraft draft = AdminAppBannerDraft.empty().copyWith(
      vendorId: vendors.first.id,
      vendorName: vendors.first.displayName,
      contactNumber: vendors.first.phone,
    );
    String? validationMessage;

    Future<AssociationUploadFile?> pickFile({
      required FileType type,
      List<String>? allowedExtensions,
    }) async {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: type,
        allowedExtensions: allowedExtensions,
        withData: true,
      );
      final file = result?.files.single;
      if (file == null || file.bytes == null) {
        return null;
      }
      return AssociationUploadFile.fromPlatformFile(file);
    }

    final result = await showDialog<AdminAppBannerDraft>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              void updateDraft(AdminAppBannerDraft nextDraft) {
                setDialogState(() {
                  draft = nextDraft;
                  validationMessage = null;
                });
              }

              return AlertDialog(
                title: const Text('Add New App Banner'),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value:
                              draft.vendorId.isNotEmpty ? draft.vendorId : null,
                          decoration: const InputDecoration(
                            labelText: 'Vendor *',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              vendors
                                  .map(
                                    (vendor) => DropdownMenuItem<String>(
                                      value: vendor.id,
                                      child: Text(vendor.displayName),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final selectedVendor = vendors.firstWhere(
                              (vendor) => vendor.id == value,
                              orElse: () => vendors.first,
                            );
                            updateDraft(
                              draft.copyWith(
                                vendorId: selectedVendor.id,
                                vendorName: selectedVendor.displayName,
                                contactNumber: selectedVendor.phone,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Short Text *',
                          initialValue: draft.shortText,
                          maxLines: 3,
                          onChanged:
                              (value) =>
                                  updateDraft(draft.copyWith(shortText: value)),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Contact Number',
                          initialValue: draft.contactNumber,
                          keyboardType: TextInputType.phone,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(contactNumber: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Social Media URL',
                          initialValue: draft.socialMediaUrl,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(socialMediaUrl: value),
                              ),
                        ),
                        const SizedBox(height: 14),
                        _AdminFileTile(
                          label: 'Banner Image *',
                          fileName: draft.mediaFile?.name ?? '',
                          helperText: 'JPG, PNG, or WebP up to 1 MB.',
                          buttonLabel:
                              draft.mediaFile == null
                                  ? 'Upload image'
                                  : 'Replace image',
                          onPressed: () async {
                            final file = await pickFile(type: FileType.image);
                            if (file == null) return;
                            if (file.bytes.length > 1024 * 1024) {
                              setDialogState(() {
                                validationMessage =
                                    'Banner image is too large. Keep it at or below 1 MB.';
                              });
                              return;
                            }
                            updateDraft(draft.copyWith(mediaFile: file));
                          },
                        ),
                        const SizedBox(height: 12),
                        _AdminFileTile(
                          label: 'Brochure PDF',
                          fileName: draft.brochureFile?.name ?? '',
                          helperText: 'Optional PDF brochure up to 2 MB.',
                          buttonLabel:
                              draft.brochureFile == null
                                  ? 'Upload brochure'
                                  : 'Replace brochure',
                          onPressed: () async {
                            final file = await pickFile(
                              type: FileType.custom,
                              allowedExtensions: const ['pdf'],
                            );
                            if (file == null) return;
                            if (file.bytes.length > 2 * 1024 * 1024) {
                              setDialogState(() {
                                validationMessage =
                                    'Brochure PDF is too large. Keep it at or below 2 MB.';
                              });
                              return;
                            }
                            updateDraft(draft.copyWith(brochureFile: file));
                          },
                        ),
                        if (validationMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            validationMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final error = draft.validationMessage;
                      if (error != null) {
                        setDialogState(() {
                          validationMessage = error;
                        });
                        return;
                      }
                      Navigator.of(context).pop(draft);
                    },
                    child: const Text('Add Banner'),
                  ),
                ],
              );
            },
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _isSavingNewBanner = true;
    });
    try {
      await ref.read(apiClientProvider).createAppBanner(draft: result);
      if (!mounted) return;
      ref.invalidate(adminArenaDataProvider);
      await ref.read(adminArenaDataProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.vendorName.isEmpty ? 'App banner' : result.vendorName} banner submitted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create app banner: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNewBanner = false;
        });
      }
    }
  }

  Future<bool> _confirmTaxonomyDelete({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Future<void> _openCategoryDialog({
    VendorTaxonomyCategoryItem? category,
  }) async {
    final controller = TextEditingController(text: category?.name ?? '');
    String? validationMessage;

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    category == null ? 'Add Category' : 'Edit Category',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Category name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          if (validationMessage != null) {
                            setDialogState(() {
                              validationMessage = null;
                            });
                          }
                        },
                        onSubmitted: (_) {
                          final value = controller.text.trim();
                          if (value.isEmpty) {
                            setDialogState(() {
                              validationMessage = 'Category name is required.';
                            });
                            return;
                          }
                          Navigator.of(context).pop(value);
                        },
                      ),
                      if (validationMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          validationMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          setDialogState(() {
                            validationMessage = 'Category name is required.';
                          });
                          return;
                        }
                        Navigator.of(context).pop(value);
                      },
                      child: Text(category == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    final savingKey = category == null ? '__new_category__' : category.id;
    setState(() {
      _savingTaxonomyKey = savingKey;
    });

    try {
      if (category == null) {
        await ref.read(apiClientProvider).createVendorCategory(name: result);
      } else {
        await ref
            .read(apiClientProvider)
            .updateVendorCategory(categoryId: category.id, name: result);
      }
      if (!mounted) return;
      await _refreshVendorTaxonomy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null
                ? 'Vendor category added.'
                : 'Vendor category updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save category: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingTaxonomyKey = null;
        });
      }
    }
  }

  Future<void> _deleteCategory(VendorTaxonomyCategoryItem category) async {
    final confirmed = await _confirmTaxonomyDelete(
      title: 'Delete category?',
      message:
          'This will remove "${category.name}" from the taxonomy and clear that category from any linked vendors.',
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _savingTaxonomyKey = category.id;
    });
    try {
      await ref
          .read(apiClientProvider)
          .deleteVendorCategory(categoryId: category.id);
      if (!mounted) return;
      await _refreshVendorTaxonomy();
      if (!mounted) return;
      if (_selectedTaxonomyCategoryId == category.id) {
        setState(() {
          _selectedTaxonomyCategoryId = null;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vendor category deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete category: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingTaxonomyKey = null;
        });
      }
    }
  }

  Future<void> _openSubCategoryDialog(
    List<VendorTaxonomyCategoryItem> categories, {
    VendorTaxonomyCategoryItem? initialCategory,
    VendorTaxonomySubCategoryItem? subCategory,
  }) async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a category first before adding a sub-category.'),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: subCategory?.name ?? '');
    String? selectedCategoryId =
        initialCategory?.id ??
        _selectedTaxonomyCategoryId ??
        categories.first.id;
    String? validationMessage;

    final result = await showDialog<({String categoryId, String name})>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    subCategory == null
                        ? 'Add Sub-category'
                        : 'Edit Sub-category',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        items:
                            categories
                                .map(
                                  (category) => DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Text(category.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategoryId = value;
                            validationMessage = null;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Parent category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Sub-category name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          if (validationMessage != null) {
                            setDialogState(() {
                              validationMessage = null;
                            });
                          }
                        },
                      ),
                      if (validationMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          validationMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if ((selectedCategoryId ?? '').isEmpty) {
                          setDialogState(() {
                            validationMessage =
                                'Please choose a parent category.';
                          });
                          return;
                        }
                        if (value.isEmpty) {
                          setDialogState(() {
                            validationMessage =
                                'Sub-category name is required.';
                          });
                          return;
                        }
                        Navigator.of(
                          context,
                        ).pop((categoryId: selectedCategoryId!, name: value));
                      },
                      child: Text(subCategory == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _savingTaxonomyKey =
          subCategory == null ? '__new_sub_category__' : subCategory.id;
    });

    try {
      if (subCategory == null) {
        await ref
            .read(apiClientProvider)
            .createVendorSubCategory(
              categoryId: result.categoryId,
              name: result.name,
            );
      } else {
        await ref
            .read(apiClientProvider)
            .updateVendorSubCategory(
              subCategoryId: subCategory.id,
              categoryId: result.categoryId,
              name: result.name,
            );
      }
      if (!mounted) return;
      setState(() {
        _selectedTaxonomyCategoryId = result.categoryId;
      });
      await _refreshVendorTaxonomy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            subCategory == null
                ? 'Vendor sub-category added.'
                : 'Vendor sub-category updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save sub-category: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingTaxonomyKey = null;
        });
      }
    }
  }

  Future<void> _deleteSubCategory(
    VendorTaxonomyCategoryItem category,
    VendorTaxonomySubCategoryItem subCategory,
  ) async {
    final confirmed = await _confirmTaxonomyDelete(
      title: 'Delete sub-category?',
      message:
          'This will remove "${subCategory.name}" from "${category.name}" and clear that sub-category from linked vendors.',
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _savingTaxonomyKey = subCategory.id;
    });
    try {
      await ref
          .read(apiClientProvider)
          .deleteVendorSubCategory(subCategoryId: subCategory.id);
      if (!mounted) return;
      await _refreshVendorTaxonomy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor sub-category deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete sub-category: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingTaxonomyKey = null;
        });
      }
    }
  }

  Future<void> _openVendorRegistrationDialog(
    List<VendorTaxonomyCategoryItem> categories,
  ) async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one vendor category before adding a vendor.',
          ),
        ),
      );
      return;
    }

    AdminVendorRegistrationDraft draft =
        const AdminVendorRegistrationDraft.empty();
    draft = draft.copyWith(
      categoryId: categories.first.id,
      categoryName: categories.first.name,
      subCategoryId:
          categories.first.subCategories.isNotEmpty
              ? categories.first.subCategories.first.id
              : '',
      subCategoryName:
          categories.first.subCategories.isNotEmpty
              ? categories.first.subCategories.first.name
              : '',
    );
    String? validationMessage;

    final result = await showDialog<AdminVendorRegistrationDraft>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              final selectedCategory = categories.firstWhere(
                (item) => item.id == draft.categoryId,
                orElse: () => categories.first,
              );
              final subCategories = selectedCategory.subCategories;
              final stateOptions =
                  _vendorStateOptionsByCountry[draft.country] ??
                  const <String>[];
              final cityOptions =
                  _vendorCityOptionsByState[draft.state] ?? const <String>[];

              void updateDraft(AdminVendorRegistrationDraft nextDraft) {
                setDialogState(() {
                  draft = nextDraft;
                  validationMessage = null;
                });
              }

              return AlertDialog(
                title: const Text('Add New Vendor'),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dialogTextField(
                          label: 'Company name',
                          initialValue: draft.companyName,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(companyName: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Contact person',
                          initialValue: draft.contactPerson,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(contactPerson: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: draft.phoneCode,
                                decoration: const InputDecoration(
                                  labelText: 'Code',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    _vendorPhoneCodeOptions
                                        .map(
                                          (code) => DropdownMenuItem<String>(
                                            value: code,
                                            child: Text(code),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  updateDraft(draft.copyWith(phoneCode: value));
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: _dialogTextField(
                                label: 'Mobile number',
                                initialValue: draft.phone,
                                keyboardType: TextInputType.phone,
                                onChanged:
                                    (value) => updateDraft(
                                      draft.copyWith(phone: value),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: draft.whatsAppCode,
                                decoration: const InputDecoration(
                                  labelText: 'WhatsApp code',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    _vendorPhoneCodeOptions
                                        .map(
                                          (code) => DropdownMenuItem<String>(
                                            value: code,
                                            child: Text(code),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  updateDraft(
                                    draft.copyWith(whatsAppCode: value),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: _dialogTextField(
                                label: 'WhatsApp number',
                                initialValue: draft.whatsApp,
                                keyboardType: TextInputType.phone,
                                onChanged:
                                    (value) => updateDraft(
                                      draft.copyWith(whatsApp: value),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Email',
                          initialValue: draft.email,
                          keyboardType: TextInputType.emailAddress,
                          onChanged:
                              (value) =>
                                  updateDraft(draft.copyWith(email: value)),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Primary Login ID',
                          initialValue: draft.primaryLoginEmail,
                          keyboardType: TextInputType.emailAddress,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(primaryLoginEmail: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Secondary Login ID',
                          initialValue: draft.secondaryLoginEmail,
                          keyboardType: TextInputType.emailAddress,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(secondaryLoginEmail: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value:
                              draft.categoryId.isNotEmpty
                                  ? draft.categoryId
                                  : null,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              categories
                                  .map(
                                    (category) => DropdownMenuItem<String>(
                                      value: category.id,
                                      child: Text(category.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final category = categories.firstWhere(
                              (item) => item.id == value,
                            );
                            updateDraft(
                              draft.copyWith(
                                categoryId: category.id,
                                categoryName: category.name,
                                subCategoryId:
                                    category.subCategories.isNotEmpty
                                        ? category.subCategories.first.id
                                        : '',
                                subCategoryName:
                                    category.subCategories.isNotEmpty
                                        ? category.subCategories.first.name
                                        : '',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value:
                              draft.subCategoryId.isNotEmpty
                                  ? draft.subCategoryId
                                  : null,
                          decoration: const InputDecoration(
                            labelText: 'Sub-category',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              subCategories
                                  .map(
                                    (subCategory) => DropdownMenuItem<String>(
                                      value: subCategory.id,
                                      child: Text(subCategory.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              subCategories.isEmpty
                                  ? null
                                  : (value) {
                                    if (value == null) return;
                                    final subCategory = subCategories
                                        .firstWhere((item) => item.id == value);
                                    updateDraft(
                                      draft.copyWith(
                                        subCategoryId: subCategory.id,
                                        subCategoryName: subCategory.name,
                                      ),
                                    );
                                  },
                          hint: const Text('Optional'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: draft.country,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _vendorCountryOptions
                                  .map(
                                    (country) => DropdownMenuItem<String>(
                                      value: country,
                                      child: Text(country),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final nextState =
                                value == 'India' &&
                                        stateOptions.contains(draft.state)
                                    ? draft.state
                                    : '';
                            updateDraft(
                              draft.copyWith(
                                country: value,
                                state: nextState,
                                city: '',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: draft.state.isNotEmpty ? draft.state : null,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              stateOptions
                                  .map(
                                    (state) => DropdownMenuItem<String>(
                                      value: state,
                                      child: Text(state),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            updateDraft(draft.copyWith(state: value, city: ''));
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: draft.city.isNotEmpty ? draft.city : null,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              cityOptions
                                  .map(
                                    (city) => DropdownMenuItem<String>(
                                      value: city,
                                      child: Text(city),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            updateDraft(draft.copyWith(city: value));
                          },
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Website',
                          initialValue: draft.website,
                          keyboardType: TextInputType.url,
                          onChanged:
                              (value) =>
                                  updateDraft(draft.copyWith(website: value)),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Facebook Page',
                          initialValue: draft.facebookUrl,
                          keyboardType: TextInputType.url,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(facebookUrl: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Instagram Page',
                          initialValue: draft.instagramUrl,
                          keyboardType: TextInputType.url,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(instagramUrl: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'YouTube Channel',
                          initialValue: draft.youtubeUrl,
                          keyboardType: TextInputType.url,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(youtubeUrl: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'LinkedIn Page',
                          initialValue: draft.linkedinUrl,
                          keyboardType: TextInputType.url,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(linkedinUrl: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'X / Twitter Page',
                          initialValue: draft.xUrl,
                          keyboardType: TextInputType.url,
                          onChanged:
                              (value) =>
                                  updateDraft(draft.copyWith(xUrl: value)),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Address',
                          initialValue: draft.address,
                          maxLines: 2,
                          onChanged:
                              (value) =>
                                  updateDraft(draft.copyWith(address: value)),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Zipcode / Pincode',
                          initialValue: draft.zipcode,
                          keyboardType: TextInputType.number,
                          onChanged:
                              (value) =>
                                  updateDraft(draft.copyWith(zipcode: value)),
                        ),
                        if (validationMessage != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              validationMessage!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final message = draft.validationMessage;
                      if (message != null) {
                        setDialogState(() {
                          validationMessage = message;
                        });
                        return;
                      }
                      Navigator.of(context).pop(draft);
                    },
                    child: const Text('Save Vendor'),
                  ),
                ],
              );
            },
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _savingVendorRegistrationId = '__new_vendor__';
    });
    try {
      await ref.read(apiClientProvider).createVendorRecord(draft: result);
      if (!mounted) return;
      ref.invalidate(adminArenaDataProvider);
      ref.invalidate(vendorDirectoryProvider);
      await ref.read(adminArenaDataProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vendor created successfully and added to registration queue.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save vendor: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _savingVendorRegistrationId = null;
        });
      }
    }
  }

  Widget _dialogTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return _StableTextFormField(
      value: initialValue,
      label: label,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  String _readVendorNoteValue(String notes, String label) {
    if (notes.trim().isEmpty) {
      return '';
    }
    final pattern = RegExp('${RegExp.escape(label)}:\\s*(.*)');
    final match = pattern.firstMatch(notes);
    return match?.group(1)?.trim() ?? '';
  }

  AdminVendorApprovalDraft _buildVendorApprovalDraft(
    AdminVendorAccessItem vendor,
  ) {
    return AdminVendorApprovalDraft(
      planName:
          vendor.planName.trim().isNotEmpty
              ? vendor.planName
              : _readVendorNoteValue(vendor.notes, 'Plan Name'),
      openingTime:
          vendor.openingTime.trim().isNotEmpty
              ? vendor.openingTime
              : _readVendorNoteValue(vendor.notes, 'Opening Time'),
      closingTime:
          vendor.closingTime.trim().isNotEmpty
              ? vendor.closingTime
              : _readVendorNoteValue(vendor.notes, 'Closing Time'),
      membershipPlan:
          vendor.membershipPlan.trim().isNotEmpty ? vendor.membershipPlan : '',
      paymentAmount:
          vendor.paymentAmount.trim().isNotEmpty ? vendor.paymentAmount : '',
      onboardingStartAt:
          vendor.onboardingStartDate.length >= 10
              ? vendor.onboardingStartDate.substring(0, 10)
              : vendor.onboardingStartDate,
      onboardingEndAt:
          vendor.onboardingEndDate.length >= 10
              ? vendor.onboardingEndDate.substring(0, 10)
              : vendor.onboardingEndDate,
      paymentDueDate:
          vendor.paymentDueDate.length >= 10
              ? vendor.paymentDueDate.substring(0, 10)
              : vendor.paymentDueDate,
      gstNumber:
          vendor.gstNumber.trim().isNotEmpty
              ? vendor.gstNumber
              : _readVendorNoteValue(vendor.notes, 'GST Number'),
      isRestaurant:
          vendor.isRestaurant ??
          (_readVendorNoteValue(vendor.notes, 'Is Restaurant') == 'Yes'),
      paymentMode:
          vendor.paymentMode.trim().isNotEmpty
              ? vendor.paymentMode
              : _readVendorNoteValue(
                vendor.notes,
                'Payment Mode',
              ).trim().isEmpty
              ? 'Online/NEFT/IMPS'
              : _readVendorNoteValue(vendor.notes, 'Payment Mode'),
      bankName:
          vendor.bankName.trim().isNotEmpty
              ? vendor.bankName
              : _readVendorNoteValue(vendor.notes, 'Bank Name'),
      transactionId:
          vendor.transactionId.trim().isNotEmpty
              ? vendor.transactionId
              : _readVendorNoteValue(vendor.notes, 'Transaction ID'),
      paymentDescription:
          vendor.paymentDescription.trim().isNotEmpty
              ? vendor.paymentDescription
              : _readVendorNoteValue(vendor.notes, 'Payment Description'),
      googleLocation:
          vendor.googleLocation.trim().isNotEmpty
              ? vendor.googleLocation
              : _readVendorNoteValue(vendor.notes, 'Google Location'),
      idProof: null,
      locationProof: null,
      companyBrochure: null,
      profilePhoto: null,
      visitingCard: null,
      idProofAsset: vendor.idProofAsset,
      locationProofAsset: vendor.locationProofAsset,
      companyBrochureAsset: vendor.companyBrochureAsset,
      profilePhotoAsset: vendor.profilePhotoAsset,
      visitingCardAsset: vendor.visitingCardAsset,
    );
  }

  Future<PlatformFile?> _pickSingleFile({
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    return result?.files.single;
  }

  Future<void> _openVendorApprovalDialog(AdminVendorAccessItem vendor) async {
    var draft = _buildVendorApprovalDraft(vendor);
    String? validationMessage;

    Future<void> submit(MemberAccessStatus status) async {
      if (status == MemberAccessStatus.approved) {
        final error = draft.validationMessage;
        if (error != null) {
          validationMessage = error;
          return;
        }
      }

      Navigator.of(context).pop((draft: draft, status: status));
    }

    final result = await showDialog<
      ({AdminVendorApprovalDraft draft, MemberAccessStatus status})
    >(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> assignFile(
                String key, {
                List<String>? extensions,
              }) async {
                final file = await _pickSingleFile(
                  allowedExtensions: extensions,
                );
                if (file == null) return;
                setDialogState(() {
                  switch (key) {
                    case 'idProof':
                      draft = draft.copyWith(idProof: file);
                      break;
                    case 'locationProof':
                      draft = draft.copyWith(locationProof: file);
                      break;
                    case 'companyBrochure':
                      draft = draft.copyWith(companyBrochure: file);
                      break;
                    case 'profilePhoto':
                      draft = draft.copyWith(profilePhoto: file);
                      break;
                    case 'visitingCard':
                      draft = draft.copyWith(visitingCard: file);
                      break;
                  }
                  validationMessage = null;
                });
              }

              Widget dateField(
                String label,
                String value,
                ValueChanged<String> onChanged,
              ) {
                return _StableTextFormField(
                  value: value,
                  label: label,
                  onChanged: onChanged,
                );
              }

              return AlertDialog(
                title: Text('Review ${vendor.displayName}'),
                content: SizedBox(
                  width: 620,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value:
                              draft.planName.isNotEmpty ? draft.planName : null,
                          decoration: const InputDecoration(
                            labelText: 'Plan Name *',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _vendorPlanOptions
                                  .map(
                                    (plan) => DropdownMenuItem<String>(
                                      value: plan,
                                      child: Text(plan),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              draft = draft.copyWith(planName: value ?? '');
                              validationMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Membership Plan',
                          initialValue: draft.membershipPlan,
                          onChanged: (value) {
                            setDialogState(() {
                              draft = draft.copyWith(membershipPlan: value);
                              validationMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogTextField(
                                label: 'Opening Time',
                                initialValue: draft.openingTime,
                                onChanged: (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(openingTime: value);
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dialogTextField(
                                label: 'Closing Time',
                                initialValue: draft.closingTime,
                                onChanged: (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(closingTime: value);
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogTextField(
                                label: 'Payment Amount',
                                initialValue: draft.paymentAmount,
                                onChanged: (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(
                                      paymentAmount: value,
                                    );
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dialogTextField(
                                label: 'GST Number',
                                initialValue: draft.gstNumber,
                                onChanged: (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(gstNumber: value);
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: dateField(
                                'Start Date *',
                                draft.onboardingStartAt,
                                (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(
                                      onboardingStartAt: value,
                                    );
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: dateField(
                                'End Date *',
                                draft.onboardingEndAt,
                                (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(
                                      onboardingEndAt: value,
                                    );
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: dateField(
                                'Payment Due',
                                draft.paymentDueDate,
                                (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(
                                      paymentDueDate: value,
                                    );
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: draft.paymentMode,
                                decoration: const InputDecoration(
                                  labelText: 'Payment Mode *',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    _vendorPaymentModeOptions
                                        .map(
                                          (mode) => DropdownMenuItem<String>(
                                            value: mode,
                                            child: Text(mode),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(
                                      paymentMode: value ?? '',
                                    );
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogTextField(
                                label: 'Bank Name *',
                                initialValue: draft.bankName,
                                onChanged: (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(bankName: value);
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dialogTextField(
                                label: 'Transaction ID *',
                                initialValue: draft.transactionId,
                                onChanged: (value) {
                                  setDialogState(() {
                                    draft = draft.copyWith(
                                      transactionId: value,
                                    );
                                    validationMessage = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: draft.isRestaurant,
                          title: const Text('Is Restaurant?'),
                          onChanged: (value) {
                            setDialogState(() {
                              draft = draft.copyWith(isRestaurant: value);
                              validationMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Payment Description',
                          initialValue: draft.paymentDescription,
                          maxLines: 2,
                          onChanged: (value) {
                            setDialogState(() {
                              draft = draft.copyWith(paymentDescription: value);
                              validationMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Google Location',
                          initialValue: draft.googleLocation,
                          onChanged: (value) {
                            setDialogState(() {
                              draft = draft.copyWith(googleLocation: value);
                              validationMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _filePickerRow(
                          label: 'ID Proof',
                          fileName: draft.idProof?.name ?? '',
                          existingFileName: draft.idProofAsset.displayName,
                          onPick: () => assignFile('idProof'),
                        ),
                        _filePickerRow(
                          label: 'Location Proof',
                          fileName: draft.locationProof?.name ?? '',
                          existingFileName:
                              draft.locationProofAsset.displayName,
                          onPick: () => assignFile('locationProof'),
                        ),
                        _filePickerRow(
                          label: 'Company Profile / Brochure',
                          fileName: draft.companyBrochure?.name ?? '',
                          existingFileName:
                              draft.companyBrochureAsset.displayName,
                          onPick:
                              () => assignFile(
                                'companyBrochure',
                                extensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              ),
                        ),
                        _filePickerRow(
                          label: 'Profile Photo',
                          fileName: draft.profilePhoto?.name ?? '',
                          existingFileName: draft.profilePhotoAsset.displayName,
                          onPick:
                              () => assignFile(
                                'profilePhoto',
                                extensions: ['jpg', 'jpeg', 'png', 'webp'],
                              ),
                        ),
                        _filePickerRow(
                          label: 'Visiting Card',
                          fileName: draft.visitingCard?.name ?? '',
                          existingFileName: draft.visitingCardAsset.displayName,
                          onPick:
                              () => assignFile(
                                'visitingCard',
                                extensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              ),
                        ),
                        if (validationMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            validationMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                actions: [
                  SizedBox(
                    width: double.maxFinite,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: OutlinedButton(
                            onPressed:
                                () => submit(MemberAccessStatus.suspended),
                            child: const Text('Suspend'),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: OutlinedButton(
                            onPressed:
                                () => submit(MemberAccessStatus.cancelled),
                            child: const Text('Cancel'),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: FilledButton(
                            onPressed:
                                () => submit(MemberAccessStatus.approved),
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _savingVendorApprovalId = vendor.id;
    });
    try {
      await ref
          .read(apiClientProvider)
          .saveVendorApproval(
            vendorId: vendor.id,
            draft: result.draft,
            status: result.status,
          );
      if (!mounted) return;
      ref.invalidate(adminArenaDataProvider);
      await ref.read(adminArenaDataProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.status == MemberAccessStatus.approved
                ? '${vendor.displayName} approved.'
                : result.status == MemberAccessStatus.suspended
                ? '${vendor.displayName} suspended.'
                : '${vendor.displayName} cancelled.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update vendor status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingVendorApprovalId = null;
        });
      }
    }
  }

  Widget _filePickerRow({
    required String label,
    required String fileName,
    String existingFileName = '',
    required VoidCallback onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fileName.isNotEmpty
                  ? '$label: $fileName'
                  : existingFileName.isNotEmpty
                  ? '$label: $existingFileName'
                  : label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(existingFileName.isNotEmpty ? 'Replace' : 'Choose'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewerRole.isVendor) {
      return _VendorSelfServicePanel(onOpenProfile: widget.onOpenProfile);
    }
    if (widget.viewerRole.isAdmin) {
      return _buildAdminVendorArena();
    }
    return _buildVendorDirectory();
  }

  Widget _buildVendorDirectory() {
    final vendorsAsync = ref.watch(vendorDirectoryProvider);
    return vendorsAsync.when(
      loading: () => const _LoadingState(),
      error:
          (error, _) => _ErrorState(
            title: 'Could not load vendors',
            message: error.toString(),
            onRetry: _refresh,
          ),
      data: (vendors) {
        final query = _query.trim().toLowerCase();
        final categoryMap = <String, Set<String>>{};
        final vendorCountByCategory = <String, int>{};
        for (final vendor in vendors) {
          final category = vendor.category.trim();
          final subCategory = vendor.vendorType.trim();
          if (category.isEmpty && subCategory.isEmpty) {
            continue;
          }
          final key = category.isEmpty ? 'Uncategorized' : category;
          categoryMap.putIfAbsent(key, () => <String>{});
          vendorCountByCategory.update(
            key,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
          if (subCategory.isNotEmpty) {
            categoryMap[key]!.add(subCategory);
          }
        }
        final sortedCategories =
            categoryMap.entries.toList()..sort(
              (left, right) =>
                  left.key.toLowerCase().compareTo(right.key.toLowerCase()),
            );
        final screenWidth = MediaQuery.of(context).size.width;
        final categoryColumns = screenWidth >= 900 ? 3 : 2;
        final categoryAspectRatio =
            screenWidth >= 900
                ? 1.45
                : screenWidth >= 420
                ? 1.02
                : 0.8;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Vendor',
              subtitle: 'Search vendors by name, city, or category.',
              showAccent: true,
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                onSubmitted: (value) {
                  final normalizedQuery = value.trim();
                  if (normalizedQuery.isEmpty) {
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder:
                          (_) => _VendorSearchResultsScreen(
                            query: normalizedQuery,
                            vendors: vendors,
                          ),
                    ),
                  );
                },
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded),
                  hintText: 'Search by name, city, or category',
                ),
              ),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Press search on the keyboard to open vendor results on a new page.',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (sortedCategories.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categories And Sub Categories',
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sortedCategories.length} categories available',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedCategories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: categoryColumns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: categoryAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final entry = sortedCategories[index];
                        final sortedSubCategories =
                            entry.value.toList()..sort(
                              (left, right) => left.toLowerCase().compareTo(
                                right.toLowerCase(),
                              ),
                            );
                        final count = vendorCountByCategory[entry.key] ?? 0;
                        return _VendorCategoryGridCard(
                          categoryName: entry.key,
                          vendorCount: count,
                          subCategories: sortedSubCategories,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => _VendorCategoryDirectoryScreen(
                                      categoryName: entry.key,
                                      vendors: vendors,
                                      subCategories: sortedSubCategories,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAdminVendorArena() {
    if (widget.section == VendorArenaSection.category ||
        widget.section == VendorArenaSection.subCategory) {
      final taxonomyAsync = ref.watch(vendorTaxonomyProvider);
      final vendorsAsync = ref.watch(vendorDirectoryProvider);
      return taxonomyAsync.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load vendor taxonomy',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data: (categories) {
          return vendorsAsync.when(
            loading: () => const _LoadingState(),
            error:
                (error, _) => _ErrorState(
                  title: 'Could not load vendors',
                  message: error.toString(),
                  onRetry: _refresh,
                ),
            data: (vendors) {
              VendorTaxonomyCategoryItem? selectedCategory;
              for (final item in categories) {
                if (item.id == _selectedTaxonomyCategoryId) {
                  selectedCategory = item;
                  break;
                }
              }
              selectedCategory ??=
                  categories.isNotEmpty ? categories.first : null;
              final effectiveSelectedCategory = selectedCategory;
              if (effectiveSelectedCategory != null &&
                  _selectedTaxonomyCategoryId != effectiveSelectedCategory.id) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedTaxonomyCategoryId =
                          effectiveSelectedCategory.id;
                    });
                  }
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _VendorAdminSectionView(
                    currentLabel: widget.section.label,
                    onNavigateToVendorArena:
                        () => widget.onSectionSelected(
                          VendorArenaNavigation.defaultSection(
                            widget.viewerRole,
                          ),
                        ),
                    child:
                        widget.section == VendorArenaSection.category
                            ? _VendorCategoryAdminWorkspace(
                              categories: categories,
                              vendors: vendors,
                              savingKey: _savingTaxonomyKey,
                              onAddCategory: () => _openCategoryDialog(),
                              onEditCategory:
                                  (category) =>
                                      _openCategoryDialog(category: category),
                              onDeleteCategory: _deleteCategory,
                            )
                            : _VendorSubCategoryAdminWorkspace(
                              categories: categories,
                              vendors: vendors,
                              selectedCategoryId: effectiveSelectedCategory?.id,
                              savingKey: _savingTaxonomyKey,
                              onSelectCategory:
                                  (categoryId) => setState(
                                    () =>
                                        _selectedTaxonomyCategoryId =
                                            categoryId,
                                  ),
                              onAddSubCategory:
                                  () => _openSubCategoryDialog(
                                    categories,
                                    initialCategory: effectiveSelectedCategory,
                                  ),
                              onEditSubCategory:
                                  (category, subCategory) =>
                                      _openSubCategoryDialog(
                                        categories,
                                        initialCategory: category,
                                        subCategory: subCategory,
                                      ),
                              onDeleteSubCategory: _deleteSubCategory,
                            ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    final adminArenaDataAsync = ref.watch(adminArenaDataProvider);
    final taxonomyAsync = ref.watch(vendorTaxonomyProvider);
    return adminArenaDataAsync.when(
      loading: () => const _LoadingState(),
      error:
          (error, _) => _ErrorState(
            title: 'Could not load vendor admin workspace',
            message: error.toString(),
            onRetry: _refresh,
          ),
      data: (data) {
        final pendingVendors =
            data.vendors
                .where(
                  (vendor) => vendor.accessStatus == MemberAccessStatus.pending,
                )
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(height: 8),
            _VendorAdminSectionView(
              currentLabel: widget.section.label,
              onNavigateToVendorArena:
                  () => widget.onSectionSelected(
                    VendorArenaNavigation.defaultSection(widget.viewerRole),
                  ),
              child: switch (widget.section) {
                VendorArenaSection.vendor => _buildVendorDirectory(),
                VendorArenaSection.vendorRegistration => taxonomyAsync.when(
                  loading: () => const _LoadingState(),
                  error:
                      (error, _) => _ErrorState(
                        title: 'Could not load vendor registration form',
                        message: error.toString(),
                        onRetry: _refresh,
                      ),
                  data:
                      (categories) => _AdminVendorRegistrationWorkspace(
                        pendingCount: pendingVendors.length,
                        categories: categories,
                        isSaving: _savingVendorRegistrationId != null,
                        onAddNew:
                            () => _openVendorRegistrationDialog(categories),
                      ),
                ),
                VendorArenaSection.vendorStatus => _AdminVendorAccessWorkspace(
                  title: 'Vendor Status',
                  subtitle:
                      'Review and update the current access state for all vendor records.',
                  emptyTitle: 'No vendors found',
                  emptySubtitle:
                      'Vendor status records will appear here once vendors are registered.',
                  vendors: data.vendors,
                  updatingVendorId: _updatingVendorId,
                  reviewingVendorId: _savingVendorApprovalId,
                  onUpdateVendorAccess: _updateVendorAccess,
                  onEditVendor: _openVendorApprovalDialog,
                ),
                VendorArenaSection.appBanner => _AdminBannerAccessWorkspace(
                  banners: data.appBanners,
                  vendors: data.vendors,
                  updatingBannerId: _updatingBannerId,
                  isSavingNewBanner: _isSavingNewBanner,
                  onAddBanner: () => _openAppBannerDialog(data.vendors),
                  onEditBanner: _openBannerModerationDialog,
                  onUpdateBannerStatus: _updateBannerStatus,
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        );
      },
    );
  }
}

class _VendorSelfServicePanel extends StatelessWidget {
  const _VendorSelfServicePanel({required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26171717),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Manage your vendor profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your vendor area is now private. Other vendors are hidden here, while you can still use the member directory to discover association members.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onOpenProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFB91C1C),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update vendor profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What changed',
                  style: TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                _VendorSelfServicePoint(
                  icon: Icons.visibility_off_rounded,
                  title: 'Other vendors are hidden',
                  subtitle:
                      'This tab no longer exposes the full vendor directory to vendor accounts.',
                ),
                SizedBox(height: 10),
                _VendorSelfServicePoint(
                  icon: Icons.people_alt_rounded,
                  title: 'Members remain visible',
                  subtitle:
                      'Use the member directory to browse association members and find contacts.',
                ),
                SizedBox(height: 10),
                _VendorSelfServicePoint(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Profile updates stay available',
                  subtitle:
                      'Open your profile to refresh display name, contact information, and other account details.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorSelfServicePoint extends StatelessWidget {
  const _VendorSelfServicePoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFFEA580C), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EventsArenaPanel extends ConsumerStatefulWidget {
  const EventsArenaPanel({
    super.key,
    required this.viewerRole,
    required this.section,
  });

  final AppViewerRole viewerRole;
  final EventsArenaSection section;

  @override
  ConsumerState<EventsArenaPanel> createState() => _EventsArenaPanelState();
}

class _EventsArenaPanelState extends ConsumerState<EventsArenaPanel> {
  String? _savingEventId;
  String? _savingEventTypeId;

  @override
  void didUpdateWidget(covariant EventsArenaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(eventsArenaDataProvider);
    await ref.read(eventsArenaDataProvider.future);
  }

  Future<void> _saveEvent(AdminEventDraft draft) async {
    final validationMessage = draft.validationMessage;
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }
    setState(() {
      _savingEventId = draft.id.isEmpty ? '__new__' : draft.id;
    });

    try {
      await ref.read(apiClientProvider).saveEvent(draft: draft);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.id.isEmpty
                ? 'Event created and added to the live schedule.'
                : 'Event changes saved successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save event: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _savingEventId = null;
        });
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    setState(() {
      _savingEventId = eventId;
    });

    try {
      await ref.read(apiClientProvider).deleteEvent(eventId: eventId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete event: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _savingEventId = null;
        });
      }
    }
  }

  Future<void> _saveNewEventType(EventTypeDraft draft) async {
    setState(() {
      _savingEventTypeId = '__new__';
    });
    try {
      await ref.read(apiClientProvider).createEventType(draft: draft);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event type added.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event type: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingEventTypeId = null;
        });
      }
    }
  }

  Future<void> _updateEventType(EventTypeDraft draft) async {
    setState(() {
      _savingEventTypeId = draft.id;
    });
    try {
      await ref.read(apiClientProvider).updateEventType(draft: draft);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event type updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update event type: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingEventTypeId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsArenaDataAsync = ref.watch(eventsArenaDataProvider);

    return eventsArenaDataAsync.when(
      loading: () => const _LoadingState(),
      error:
          (error, _) => _ErrorState(
            title: 'Could not load events',
            message: error.toString(),
            onRetry: _refresh,
          ),
      data: (data) {
        final effectiveSection =
            widget.viewerRole.isAdmin
                ? widget.section
                : EventsArenaSection.event;
        return switch (effectiveSection) {
          EventsArenaSection.master => _EventsArenaMasterSection(
            events: data.events,
            eventTypes: data.eventTypes,
          ),
          EventsArenaSection.createNewEvent => _EventsArenaCreateSection(
            eventTypes: data.eventTypes,
            savingEventId: _savingEventId,
            onSaveEvent: _saveEvent,
          ),
          EventsArenaSection.typeOfEvent => _EventsArenaTypeManager(
            items: data.eventTypes,
            savingEventTypeId: _savingEventTypeId,
            onSaveNewType: _saveNewEventType,
            onUpdateType: _updateEventType,
          ),
          EventsArenaSection.event => _EventsArenaTimelineSection(
            events: data.events,
            eventTypes: data.eventTypes,
            canManage: widget.viewerRole.isAdmin,
            savingEventId: _savingEventId,
            onSaveEvent: _saveEvent,
            onDeleteEvent: _deleteEvent,
          ),
        };
      },
    );
  }
}

class DashboardPanel extends ConsumerStatefulWidget {
  const DashboardPanel({
    super.key,
    required this.onOpenAssociationGallery,
    required this.onOpenAssociationProfile,
    required this.onOpenAssociationCirculars,
    required this.onOpenMemberArena,
    required this.onOpenVendorArena,
    required this.onOpenEventsArena,
    required this.onOpenTimeline,
    required this.onOpenProfile,
    required this.onOpenAdminArena,
    required this.viewerRole,
  });

  final VoidCallback onOpenAssociationGallery;
  final VoidCallback onOpenAssociationProfile;
  final VoidCallback onOpenAssociationCirculars;
  final VoidCallback onOpenMemberArena;
  final VoidCallback onOpenVendorArena;
  final VoidCallback onOpenEventsArena;
  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAdminArena;
  final AppViewerRole viewerRole;

  @override
  ConsumerState<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends ConsumerState<DashboardPanel> {
  final PageController _bannerPageController = PageController(
    viewportFraction: 0.94,
  );
  final PageController _committeePageController = PageController(
    viewportFraction: 0.9,
  );
  Timer? _bannerCarouselTimer;
  int _currentBannerPage = 0;
  int _currentCommitteePage = 0;

  @override
  void dispose() {
    _bannerCarouselTimer?.cancel();
    _bannerPageController.dispose();
    _committeePageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(dashboardDataProvider);
    await ref.read(dashboardDataProvider.future);
  }

  void _startBannerCarousel(int itemCount) {
    _bannerCarouselTimer?.cancel();
    if (itemCount <= 1) {
      return;
    }
    _bannerCarouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_bannerPageController.hasClients) {
        return;
      }
      final nextPage = (_currentBannerPage + 1) % itemCount;
      _bannerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return dashboardDataAsync.when(
      loading: () => const _LoadingState(),
      error:
          (error, _) => _ErrorState(
            title: 'Could not load dashboard',
            message: error.toString(),
            onRetry: _refresh,
          ),
      data: (data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startBannerCarousel(data.appBanners.length);
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardAppBannerCarousel(
              items: data.appBanners,
              pageController: _bannerPageController,
              currentPage: _currentBannerPage,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerPage = index;
                });
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(height: 16),
            if (!widget.viewerRole.isVendor) ...[
              Row(
                children: [
                  const Text(
                    'Vendors',
                    style: TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onOpenVendorArena,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'See all',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _DashboardVendorCarousel(vendors: data.featuredVendors),
              const SizedBox(height: 22),
            ],
            _DashboardCommitteeCarousel(
              members: data.committeeMembers,
              pageController: _committeePageController,
              currentPage: _currentCommitteePage,
              onPageChanged: (index) {
                setState(() {
                  _currentCommitteePage = index;
                });
              },
            ),
            const SizedBox(height: 24),
            _DashboardArenaGrid(
              viewerRole: widget.viewerRole,
              onOpenAssociationProfile: widget.onOpenAssociationProfile,
              onOpenAssociationCirculars: widget.onOpenAssociationCirculars,
              onOpenAssociationGallery: widget.onOpenAssociationGallery,
              onOpenMemberArena: widget.onOpenMemberArena,
              onOpenVendorArena: widget.onOpenVendorArena,
              onOpenEventsArena: widget.onOpenEventsArena,
              onOpenTimeline: widget.onOpenTimeline,
              onOpenProfile: widget.onOpenProfile,
              onOpenAdminArena: widget.onOpenAdminArena,
            ),
          ],
        );
      },
    );
  }
}

class _DashboardArenaGrid extends StatelessWidget {
  const _DashboardArenaGrid({
    required this.viewerRole,
    required this.onOpenAssociationProfile,
    required this.onOpenAssociationCirculars,
    required this.onOpenAssociationGallery,
    required this.onOpenMemberArena,
    required this.onOpenVendorArena,
    required this.onOpenEventsArena,
    required this.onOpenTimeline,
    required this.onOpenProfile,
    required this.onOpenAdminArena,
  });

  final AppViewerRole viewerRole;
  final VoidCallback onOpenAssociationProfile;
  final VoidCallback onOpenAssociationCirculars;
  final VoidCallback onOpenAssociationGallery;
  final VoidCallback onOpenMemberArena;
  final VoidCallback onOpenVendorArena;
  final VoidCallback onOpenEventsArena;
  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAdminArena;

  @override
  Widget build(BuildContext context) {
    final items = <
      ({String label, IconData icon, List<Color> colors, VoidCallback onTap})
    >[
      (
        label: viewerRole.isVendor ? 'Association' : 'Association',
        icon: Icons.apartment_rounded,
        colors: const [Color(0xFF0F2D7A), Color(0xFF1D4ED8)],
        onTap: onOpenAssociationProfile,
      ),
      (
        label: 'Circulars',
        icon: Icons.campaign_rounded,
        colors: const [Color(0xFF7C2D12), Color(0xFFEA580C)],
        onTap: onOpenAssociationCirculars,
      ),
      (
        label: 'Gallery',
        icon: Icons.photo_library_rounded,
        colors: const [Color(0xFF4338CA), Color(0xFF7C3AED)],
        onTap: onOpenAssociationGallery,
      ),
      if (!viewerRole.isMember)
        (
          label: viewerRole.isVendor ? 'Members' : 'Members',
          icon: Icons.people_alt_rounded,
          colors: const [Color(0xFF065F46), Color(0xFF10B981)],
          onTap: onOpenMemberArena,
        ),
      (
        label: viewerRole.isVendor ? 'My Vendor' : 'Vendors',
        icon: Icons.storefront_rounded,
        colors: const [Color(0xFF9A3412), Color(0xFFF59E0B)],
        onTap: onOpenVendorArena,
      ),
      (
        label: 'Events',
        icon: Icons.event_available_rounded,
        colors: const [Color(0xFF7F1D1D), Color(0xFFEF4444)],
        onTap: onOpenEventsArena,
      ),
      (
        label: 'Timeline',
        icon: Icons.auto_awesome_motion_rounded,
        colors: const [Color(0xFF312E81), Color(0xFF6366F1)],
        onTap: onOpenTimeline,
      ),
      (
        label: viewerRole.isVendor ? 'Account' : 'Profile',
        icon: Icons.person_rounded,
        colors: const [Color(0xFF374151), Color(0xFF111827)],
        onTap: onOpenProfile,
      ),
      if (viewerRole.isAdmin)
        (
          label: 'Admin',
          icon: Icons.admin_panel_settings_rounded,
          colors: const [Color(0xFF581C87), Color(0xFFA21CAF)],
          onTap: onOpenAdminArena,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Sections',
            style: TextStyle(
              color: Color(0xFF171717),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jump straight into the areas you use most.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final crossAxisCount = isNarrow ? 2 : 3;
              final childAspectRatio = isNarrow ? 1.18 : 0.98;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _DashboardArenaCard(
                    label: item.label,
                    icon: item.icon,
                    colors: item.colors,
                    onTap: item.onTap,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardArenaCard extends StatelessWidget {
  const _DashboardArenaCard({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: const Color(0xFF171717), size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorCategoryAdminWorkspace extends StatelessWidget {
  const _VendorCategoryAdminWorkspace({
    required this.categories,
    required this.vendors,
    required this.savingKey,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  final List<VendorTaxonomyCategoryItem> categories;
  final List<DashboardVendorItem> vendors;
  final String? savingKey;
  final VoidCallback onAddCategory;
  final ValueChanged<VendorTaxonomyCategoryItem> onEditCategory;
  final ValueChanged<VendorTaxonomyCategoryItem> onDeleteCategory;

  int _vendorCountForCategory(String categoryName) {
    return vendors.where((vendor) {
      return vendor.category.trim().toLowerCase() == categoryName.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Category',
                subtitle:
                    'Create, rename, and remove the vendor categories used across the admin and registration flows.',
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: savingKey == '__new_category__' ? null : onAddCategory,
              icon:
                  savingKey == '__new_category__'
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.add_rounded),
              label: const Text('Add category'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (categories.isEmpty)
          const _EmptyStateCard(
            title: 'No categories found',
            subtitle:
                'Add the first vendor category here and it will become available in the vendor registration flow.',
          )
        else
          ...categories.map((category) {
            final vendorCount = _vendorCountForCategory(category.name);
            final isSaving = savingKey == category.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  color: Color(0xFF171717),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${category.subCategories.length} sub-categories linked',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            '$vendorCount vendors',
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (category.subCategories.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            category.subCategories
                                .map(
                                  (item) => _DirectoryFilterChip(
                                    label: item.name,
                                    icon: Icons.subdirectory_arrow_right,
                                    selected: false,
                                    onTap: () {},
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              isSaving ? null : () => onEditCategory(category),
                          icon:
                              isSaving
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed:
                              isSaving
                                  ? null
                                  : () => onDeleteCategory(category),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _VendorSubCategoryAdminWorkspace extends StatelessWidget {
  const _VendorSubCategoryAdminWorkspace({
    required this.categories,
    required this.vendors,
    required this.selectedCategoryId,
    required this.savingKey,
    required this.onSelectCategory,
    required this.onAddSubCategory,
    required this.onEditSubCategory,
    required this.onDeleteSubCategory,
  });

  final List<VendorTaxonomyCategoryItem> categories;
  final List<DashboardVendorItem> vendors;
  final String? selectedCategoryId;
  final String? savingKey;
  final ValueChanged<String?> onSelectCategory;
  final VoidCallback onAddSubCategory;
  final void Function(
    VendorTaxonomyCategoryItem category,
    VendorTaxonomySubCategoryItem subCategory,
  )
  onEditSubCategory;
  final void Function(
    VendorTaxonomyCategoryItem category,
    VendorTaxonomySubCategoryItem subCategory,
  )
  onDeleteSubCategory;

  int _vendorCountForSubCategory(String categoryName, String subCategoryName) {
    return vendors.where((vendor) {
      return vendor.category.trim().toLowerCase() ==
              categoryName.toLowerCase() &&
          vendor.vendorType.trim().toLowerCase() ==
              subCategoryName.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    VendorTaxonomyCategoryItem? selectedCategory;
    for (final category in categories) {
      if (category.id == selectedCategoryId) {
        selectedCategory = category;
        break;
      }
    }
    selectedCategory ??= categories.isNotEmpty ? categories.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Sub-category',
                subtitle:
                    'Choose a parent category, then maintain the linked sub-categories used by vendor registration.',
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed:
                  categories.isEmpty || savingKey == '__new_sub_category__'
                      ? null
                      : onAddSubCategory,
              icon:
                  savingKey == '__new_sub_category__'
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.add_rounded),
              label: const Text('Add sub-category'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (categories.isEmpty)
          const _EmptyStateCard(
            title: 'No categories available yet',
            subtitle:
                'Create a category first, then you can attach sub-categories to it here.',
          )
        else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: selectedCategory?.id,
              decoration: const InputDecoration(
                labelText: 'Parent category',
                border: OutlineInputBorder(),
              ),
              items:
                  categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
              onChanged: onSelectCategory,
            ),
          ),
          const SizedBox(height: 14),
          if (selectedCategory == null ||
              selectedCategory.subCategories.isEmpty)
            _EmptyStateCard(
              title: 'No sub-categories found',
              subtitle:
                  selectedCategory == null
                      ? 'Select a category to manage its sub-categories.'
                      : 'Add the first sub-category under ${selectedCategory.name}.',
            )
          else
            ...selectedCategory.subCategories.map((subCategory) {
              final isSaving = savingKey == subCategory.id;
              final vendorCount = _vendorCountForSubCategory(
                selectedCategory!.name,
                subCategory.name,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A0F172A),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subCategory.name,
                                  style: const TextStyle(
                                    color: Color(0xFF171717),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  selectedCategory.name,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              '$vendorCount vendors',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed:
                                isSaving
                                    ? null
                                    : () => onEditSubCategory(
                                      selectedCategory!,
                                      subCategory,
                                    ),
                            icon:
                                isSaving
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed:
                                isSaving
                                    ? null
                                    : () => onDeleteSubCategory(
                                      selectedCategory!,
                                      subCategory,
                                    ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ],
    );
  }
}

class TimelinePanel extends ConsumerStatefulWidget {
  const TimelinePanel({super.key, required this.viewerRole});

  final AppViewerRole viewerRole;

  @override
  ConsumerState<TimelinePanel> createState() => _TimelinePanelState();
}

class _TimelinePanelState extends ConsumerState<TimelinePanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedSourceType;
  bool _isSavingTimeline = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(dashboardDataProvider);
    if (widget.viewerRole.isAdmin) {
      ref.invalidate(adminArenaDataProvider);
      await Future.wait([
        ref.read(dashboardDataProvider.future),
        ref.read(adminArenaDataProvider.future),
      ]);
      return;
    }
    await ref.read(dashboardDataProvider.future);
  }

  Widget _dialogTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return _StableTextFormField(
      value: initialValue,
      label: label,
      keyboardType: keyboardType,
      minLines: maxLines > 1 ? maxLines : 1,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  Future<void> _openTimelineComposer({
    required List<AdminMemberAccessItem> members,
    required List<AdminVendorAccessItem> vendors,
    required TenantContext? tenant,
    MemberDirectoryItem? lockedMember,
    DashboardVendorItem? lockedVendor,
  }) async {
    final isMemberLocked = lockedMember != null;
    final isVendorLocked = lockedVendor != null;
    var draft =
        isMemberLocked
            ? AdminTimelineDraft.empty().copyWith(
              sourceType: 'MEMBER',
              memberId: lockedMember.id,
              postedBy: lockedMember.name,
              contactNumber: lockedMember.phone,
            )
            : isVendorLocked
            ? AdminTimelineDraft.empty().copyWith(
              sourceType: 'VENDOR',
              vendorId: lockedVendor.id,
              postedBy: lockedVendor.displayName,
              contactNumber: lockedVendor.phone,
            )
            : AdminTimelineDraft.empty().copyWith(
              postedBy:
                  tenant?.associationName.trim().isNotEmpty == true
                      ? tenant!.associationName
                      : 'Association Admin',
            );
    String? validationMessage;

    Future<AssociationUploadFile?> pickFile({
      required FileType type,
      List<String>? allowedExtensions,
    }) async {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: type,
        allowedExtensions: allowedExtensions,
        withData: true,
      );
      final file = result?.files.single;
      if (file == null || file.bytes == null) {
        return null;
      }
      return AssociationUploadFile.fromPlatformFile(file);
    }

    final result = await showDialog<AdminTimelineDraft>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              void updateDraft(AdminTimelineDraft nextDraft) {
                setDialogState(() {
                  draft = nextDraft;
                  validationMessage = null;
                });
              }

              final sourceType =
                  isMemberLocked
                      ? 'MEMBER'
                      : isVendorLocked
                      ? 'VENDOR'
                      : draft.sourceType.trim().toUpperCase();

              return AlertDialog(
                title: Text(
                  isMemberLocked
                      ? 'Add Member Timeline Post'
                      : isVendorLocked
                      ? 'Add Vendor Timeline Post'
                      : 'Add New Timeline Post',
                ),
                content: SizedBox(
                  width: 620,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMemberLocked && !isVendorLocked)
                          DropdownButtonFormField<String>(
                            value: sourceType,
                            decoration: const InputDecoration(
                              labelText: 'Source Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'ASSOCIATION',
                                child: Text('Association'),
                              ),
                              DropdownMenuItem(
                                value: 'MEMBER',
                                child: Text('Member'),
                              ),
                              DropdownMenuItem(
                                value: 'VENDOR',
                                child: Text('Vendor'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              updateDraft(
                                draft.copyWith(
                                  sourceType: value,
                                  memberId:
                                      value == 'MEMBER' ? draft.memberId : '',
                                  vendorId:
                                      value == 'VENDOR' ? draft.vendorId : '',
                                ),
                              );
                            },
                          ),
                        if (isMemberLocked || isVendorLocked) ...[
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Posting Profile',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              isMemberLocked
                                  ? lockedMember.name
                                  : lockedVendor!.displayName,
                            ),
                          ),
                        ] else if (sourceType == 'MEMBER') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value:
                                draft.memberId.isNotEmpty
                                    ? draft.memberId
                                    : null,
                            decoration: const InputDecoration(
                              labelText: 'Member *',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                members
                                    .map(
                                      (member) => DropdownMenuItem<String>(
                                        value: member.id,
                                        child: Text(member.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              updateDraft(
                                draft.copyWith(memberId: value ?? ''),
                              );
                            },
                          ),
                        ],
                        if (sourceType == 'VENDOR') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value:
                                draft.vendorId.isNotEmpty
                                    ? draft.vendorId
                                    : null,
                            decoration: const InputDecoration(
                              labelText: 'Vendor *',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                vendors
                                    .map(
                                      (vendor) => DropdownMenuItem<String>(
                                        value: vendor.id,
                                        child: Text(vendor.displayName),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              updateDraft(
                                draft.copyWith(vendorId: value ?? ''),
                              );
                            },
                          ),
                        ],
                        if (!isMemberLocked && !isVendorLocked) ...[
                          const SizedBox(height: 12),
                          _dialogTextField(
                            label: 'Posted By',
                            initialValue: draft.postedBy,
                            onChanged:
                                (value) => updateDraft(
                                  draft.copyWith(postedBy: value),
                                ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Caption *',
                          initialValue: draft.caption,
                          maxLines: 4,
                          onChanged:
                              (value) =>
                                  updateDraft(draft.copyWith(caption: value)),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Contact Number',
                          initialValue: draft.contactNumber,
                          keyboardType: TextInputType.phone,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(contactNumber: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Landing Page URL',
                          initialValue: draft.landingPageUrl,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(landingPageUrl: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'YouTube URL',
                          initialValue: draft.youtubeUrl,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(youtubeUrl: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _dialogTextField(
                          label: 'Facebook URL',
                          initialValue: draft.facebookUrl,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(facebookUrl: value),
                              ),
                        ),
                        const SizedBox(height: 14),
                        _AdminFileTile(
                          label: 'Post Image',
                          fileName: draft.imageFile?.name ?? '',
                          helperText: 'Optional image for the timeline card.',
                          buttonLabel:
                              draft.imageFile == null
                                  ? 'Upload image'
                                  : 'Replace image',
                          onPressed: () async {
                            final file = await pickFile(type: FileType.image);
                            if (file == null) return;
                            updateDraft(draft.copyWith(imageFile: file));
                          },
                        ),
                        const SizedBox(height: 12),
                        _AdminFileTile(
                          label: 'PDF Brochure',
                          fileName: draft.brochureFile?.name ?? '',
                          helperText: 'Optional brochure for downloads.',
                          buttonLabel:
                              draft.brochureFile == null
                                  ? 'Upload brochure'
                                  : 'Replace brochure',
                          onPressed: () async {
                            final file = await pickFile(
                              type: FileType.custom,
                              allowedExtensions: const ['pdf'],
                            );
                            if (file == null) return;
                            updateDraft(draft.copyWith(brochureFile: file));
                          },
                        ),
                        if (validationMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            validationMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final error = draft.validationMessage;
                      if (error != null) {
                        setDialogState(() {
                          validationMessage = error;
                        });
                        return;
                      }
                      Navigator.of(context).pop(draft);
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _isSavingTimeline = true;
    });
    try {
      await ref.read(apiClientProvider).createTimelinePost(draft: result);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Timeline post created.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create timeline post: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTimeline = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);
    final memberDataAsync =
        widget.viewerRole.isMember
            ? ref.watch(memberArenaDataProvider(widget.viewerRole))
            : null;
    final vendorDataAsync =
        widget.viewerRole.isVendor ? ref.watch(vendorDirectoryProvider) : null;
    final adminDataAsync =
        widget.viewerRole.isAdmin ? ref.watch(adminArenaDataProvider) : null;
    final tenant = ref.watch(tenantProvider).valueOrNull;
    final session = ref.watch(sessionProvider);

    if (dashboardDataAsync.isLoading ||
        (widget.viewerRole.isMember && (memberDataAsync?.isLoading ?? false)) ||
        (widget.viewerRole.isVendor && (vendorDataAsync?.isLoading ?? false)) ||
        (widget.viewerRole.isAdmin && (adminDataAsync?.isLoading ?? false))) {
      return const _LoadingState();
    }

    if (dashboardDataAsync.hasError) {
      return _ErrorState(
        title: 'Could not load timeline',
        message: dashboardDataAsync.error.toString(),
        onRetry: _refresh,
      );
    }

    if (widget.viewerRole.isMember && (memberDataAsync?.hasError ?? false)) {
      return _ErrorState(
        title: 'Could not load timeline',
        message: memberDataAsync!.error.toString(),
        onRetry: _refresh,
      );
    }

    if (widget.viewerRole.isVendor && (vendorDataAsync?.hasError ?? false)) {
      return _ErrorState(
        title: 'Could not load timeline',
        message: vendorDataAsync!.error.toString(),
        onRetry: _refresh,
      );
    }

    if (widget.viewerRole.isAdmin && (adminDataAsync?.hasError ?? false)) {
      return _ErrorState(
        title: 'Could not load timeline',
        message: adminDataAsync!.error.toString(),
        onRetry: _refresh,
      );
    }

    final dashboardData = dashboardDataAsync.requireValue;
    if (!widget.viewerRole.isAdmin) {
      MemberDirectoryItem? currentMember;
      DashboardVendorItem? currentVendor;
      if (widget.viewerRole.isMember) {
        final normalizedUsername = session.username.trim().toLowerCase();
        for (final member in memberDataAsync!.requireValue.members) {
          if (member.email.trim().toLowerCase() == normalizedUsername) {
            currentMember = member;
            break;
          }
        }
      } else if (widget.viewerRole.isVendor) {
        final normalizedUsername = session.username.trim().toLowerCase();
        for (final vendor in vendorDataAsync!.requireValue) {
          final loginEmails = [
            vendor.email.trim().toLowerCase(),
            vendor.primaryLoginEmail.trim().toLowerCase(),
            vendor.secondaryLoginEmail.trim().toLowerCase(),
          ].where((value) => value.isNotEmpty);
          if (loginEmails.contains(normalizedUsername)) {
            currentVendor = vendor;
            break;
          }
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.viewerRole.isMember || widget.viewerRole.isVendor) ...[
                FilledButton.icon(
                  onPressed:
                      _isSavingTimeline ||
                              (widget.viewerRole.isMember &&
                                  currentMember == null) ||
                              (widget.viewerRole.isVendor &&
                                  currentVendor == null)
                          ? null
                          : () => _openTimelineComposer(
                            members: const [],
                            vendors: const [],
                            tenant: tenant,
                            lockedMember: currentMember,
                            lockedVendor: currentVendor,
                          ),
                  icon:
                      _isSavingTimeline
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Add New'),
                ),
                const SizedBox(width: 10),
              ],
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
          if (widget.viewerRole.isMember && currentMember == null) ...[
            const SizedBox(height: 12),
            const _EmptyStateCard(
              title: 'Member profile not linked',
              subtitle:
                  'We could not match this login to a member record for timeline posting yet.',
            ),
          ] else if (widget.viewerRole.isVendor && currentVendor == null) ...[
            const SizedBox(height: 12),
            const _EmptyStateCard(
              title: 'Vendor profile not linked',
              subtitle:
                  'We could not match this login to a vendor record for timeline posting yet.',
            ),
          ],
          const SizedBox(height: 8),
          _TimelineStackFeed(posts: dashboardData.timelinePosts),
        ],
      );
    }

    final adminData = adminDataAsync!.requireValue;
    final filteredPosts =
        adminData.timelinePosts.where((post) {
            final sourceType = post.sourceType.trim().toUpperCase();
            if (_selectedSourceType != null &&
                sourceType != _selectedSourceType) {
              return false;
            }
            final normalizedQuery = _query.trim().toLowerCase();
            if (normalizedQuery.isEmpty) {
              return true;
            }
            return [
              post.sourceType,
              post.sourceName,
              post.postedBy,
              post.caption,
              post.contactNumber,
            ].any(
              (value) => value.trim().toLowerCase().contains(normalizedQuery),
            );
          }).toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Timeline',
                subtitle:
                    'Browse all association, member, and vendor posts in one place, then add a new post when needed.',
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed:
                  _isSavingTimeline
                      ? null
                      : () => _openTimelineComposer(
                        members: adminData.members,
                        vendors: adminData.vendors,
                        tenant: tenant,
                      ),
              icon:
                  _isSavingTimeline
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AdminToolbarSearch(
          controller: _searchController,
          hintText: 'Search source, posted by, or caption...',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        _AdminToolbarDropdown<String?>(
          value: _selectedSourceType,
          icon: Icons.tune_rounded,
          labelText: 'Timeline source',
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('All')),
            DropdownMenuItem<String?>(
              value: 'ASSOCIATION',
              child: Text('Association'),
            ),
            DropdownMenuItem<String?>(value: 'MEMBER', child: Text('Member')),
            DropdownMenuItem<String?>(value: 'VENDOR', child: Text('Vendor')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSourceType = value;
            });
          },
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(height: 8),
        if (filteredPosts.isEmpty)
          _EmptyStateCard(
            title: 'No timeline posts found',
            subtitle:
                _query.trim().isNotEmpty || _selectedSourceType != null
                    ? 'No timeline posts match the current source or search filter.'
                    : 'Create a timeline post to start filling the feed.',
          )
        else
          ...filteredPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TimelineBrowseCard(post: post),
            ),
          ),
      ],
    );
  }
}

class _AdminArenaPanelState extends ConsumerState<AdminArenaPanel> {
  String? _updatingMemberId;
  String? _updatingPostId;
  String? _updatingBannerId;
  String? _updatingTimelineId;
  bool _isSavingNewBanner = false;
  String? _savingEventId;

  @override
  void didUpdateWidget(covariant AdminArenaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(adminArenaDataProvider);
    await ref.read(adminArenaDataProvider.future);
  }

  Future<void> _updateMemberAccess(
    AdminMemberAccessItem member,
    MemberAccessStatus status,
  ) async {
    setState(() {
      _updatingMemberId = member.id;
    });

    try {
      await ref
          .read(apiClientProvider)
          .updateMemberAccess(memberId: member.id, status: status);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} marked ${status.label.toLowerCase()}.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update member access: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingMemberId = null;
        });
      }
    }
  }

  Future<void> _applyBulkMemberAccess(
    List<AdminMemberAccessItem> members,
    MemberAccessStatus status,
  ) async {
    if (members.isEmpty) {
      return;
    }

    setState(() {
      _updatingMemberId = '__bulk__';
    });

    try {
      for (final member in members) {
        await ref
            .read(apiClientProvider)
            .updateMemberAccess(memberId: member.id, status: status);
      }
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${members.length} members marked ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update selected members: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingMemberId = null;
        });
      }
    }
  }

  Future<void> _updatePostStatus(
    MemberPostItem post,
    PostReviewStatus status,
  ) async {
    setState(() {
      _updatingPostId = post.id;
    });

    try {
      await ref
          .read(apiClientProvider)
          .updatePostStatus(postId: post.id, status: status);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${post.member.name} post moved to ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update post status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingPostId = null;
        });
      }
    }
  }

  Future<void> _updateBannerStatus(
    AdminAppBannerItem banner,
    BannerReviewStatus status,
  ) async {
    setState(() {
      _updatingBannerId = banner.id;
    });

    try {
      await ref
          .read(apiClientProvider)
          .updateAppBannerModeration(
            bannerId: banner.id,
            status: status,
            paymentReceived:
                status == BannerReviewStatus.approved
                    ? true
                    : banner.paymentReceived,
            paymentMode:
                status == BannerReviewStatus.approved
                    ? (banner.paymentMode.trim().isEmpty
                        ? 'Bank'
                        : banner.paymentMode)
                    : banner.paymentMode,
            paymentRemarks: banner.paymentRemarks,
            displayIndex: banner.displayIndex > 0 ? banner.displayIndex : 1,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${banner.vendorName.isEmpty ? 'Banner' : banner.vendorName} moved to ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update banner status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingBannerId = null;
        });
      }
    }
  }

  Future<void> _updateTimelineStatus(
    AdminTimelineItem post,
    TimelineReviewStatus status,
  ) async {
    setState(() {
      _updatingTimelineId = post.id;
    });

    try {
      await ref
          .read(apiClientProvider)
          .updateTimelineModeration(timelineId: post.id, status: status);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${post.displayTitle} moved to ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update timeline status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingTimelineId = null;
        });
      }
    }
  }

  AdminBannerModerationDraft _buildBannerModerationDraft(
    AdminAppBannerItem banner,
  ) {
    return AdminBannerModerationDraft(
      status: banner.reviewStatus,
      paymentReceived: banner.paymentReceived,
      paymentMode: banner.paymentMode,
      paymentRemarks: banner.paymentRemarks,
      displayIndex: banner.displayIndex > 0 ? '${banner.displayIndex}' : '',
      displayStart: banner.displayStart,
      displayEnd: banner.displayEnd,
    );
  }

  Future<void> _openBannerModerationDialog(AdminAppBannerItem banner) async {
    var draft = _buildBannerModerationDraft(banner);
    String? validationMessage;

    final result = await showDialog<AdminBannerModerationDraft>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              void updateDraft(AdminBannerModerationDraft nextDraft) {
                setDialogState(() {
                  draft = nextDraft;
                  validationMessage = null;
                });
              }

              Future<void> submit() async {
                final error = draft.validationMessage;
                if (error != null) {
                  setDialogState(() {
                    validationMessage = error;
                  });
                  return;
                }
                Navigator.of(context).pop(draft);
              }

              return AlertDialog(
                title: Text(
                  banner.vendorName.isEmpty
                      ? 'Review Banner'
                      : 'Review ${banner.vendorName}',
                ),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<BannerReviewStatus>(
                          value: draft.status,
                          decoration: const InputDecoration(
                            labelText: 'Banner status',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              BannerReviewStatus.values
                                  .map(
                                    (status) =>
                                        DropdownMenuItem<BannerReviewStatus>(
                                          value: status,
                                          child: Text(status.label),
                                        ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            updateDraft(draft.copyWith(status: value));
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: draft.paymentReceived,
                          title: const Text('Payment received'),
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(paymentReceived: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _adminDialogTextField(
                          label: 'Payment Mode',
                          initialValue: draft.paymentMode,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(paymentMode: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _adminDialogTextField(
                          label: 'Payment Remarks',
                          initialValue: draft.paymentRemarks,
                          maxLines: 2,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(paymentRemarks: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _adminDialogTextField(
                          label: 'Banner Slot',
                          initialValue: draft.displayIndex,
                          keyboardType: TextInputType.number,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(displayIndex: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _adminDialogTextField(
                                label: 'Display Start',
                                initialValue: draft.displayStart,
                                onChanged:
                                    (value) => updateDraft(
                                      draft.copyWith(displayStart: value),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _adminDialogTextField(
                                label: 'Display End',
                                initialValue: draft.displayEnd,
                                onChanged:
                                    (value) => updateDraft(
                                      draft.copyWith(displayEnd: value),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (validationMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            validationMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  FilledButton(onPressed: submit, child: const Text('Save')),
                ],
              );
            },
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _updatingBannerId = banner.id;
    });
    try {
      await ref
          .read(apiClientProvider)
          .updateAppBannerModeration(
            bannerId: banner.id,
            status: result.status,
            paymentReceived: result.paymentReceived,
            paymentMode: result.paymentMode.trim(),
            paymentRemarks: result.paymentRemarks.trim(),
            displayIndex: int.tryParse(result.displayIndex.trim()) ?? 1,
            displayStart: result.displayStart.trim(),
            displayEnd: result.displayEnd.trim(),
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${banner.vendorName.isEmpty ? 'Banner' : banner.vendorName} updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update banner moderation: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingBannerId = null;
        });
      }
    }
  }

  Future<void> _openAppBannerDialog(List<AdminVendorAccessItem> vendors) async {
    if (vendors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one vendor before creating a banner.'),
        ),
      );
      return;
    }

    AdminAppBannerDraft draft = AdminAppBannerDraft.empty().copyWith(
      vendorId: vendors.first.id,
      vendorName: vendors.first.displayName,
      contactNumber: vendors.first.phone,
    );
    String? validationMessage;

    Future<AssociationUploadFile?> pickFile({
      required FileType type,
      List<String>? allowedExtensions,
    }) async {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: type,
        allowedExtensions: allowedExtensions,
        withData: true,
      );
      final file = result?.files.single;
      if (file == null || file.bytes == null) {
        return null;
      }
      return AssociationUploadFile.fromPlatformFile(file);
    }

    final result = await showDialog<AdminAppBannerDraft>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              void updateDraft(AdminAppBannerDraft nextDraft) {
                setDialogState(() {
                  draft = nextDraft;
                  validationMessage = null;
                });
              }

              return AlertDialog(
                title: const Text('Add New App Banner'),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value:
                              draft.vendorId.isNotEmpty ? draft.vendorId : null,
                          decoration: const InputDecoration(
                            labelText: 'Vendor *',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              vendors
                                  .map(
                                    (vendor) => DropdownMenuItem<String>(
                                      value: vendor.id,
                                      child: Text(vendor.displayName),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final selectedVendor = vendors.firstWhere(
                              (vendor) => vendor.id == value,
                              orElse: () => vendors.first,
                            );
                            updateDraft(
                              draft.copyWith(
                                vendorId: selectedVendor.id,
                                vendorName: selectedVendor.displayName,
                                contactNumber: selectedVendor.phone,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _adminDialogTextField(
                          label: 'Short Text *',
                          initialValue: draft.shortText,
                          maxLines: 3,
                          onChanged:
                              (value) =>
                                  updateDraft(draft.copyWith(shortText: value)),
                        ),
                        const SizedBox(height: 12),
                        _adminDialogTextField(
                          label: 'Contact Number',
                          initialValue: draft.contactNumber,
                          keyboardType: TextInputType.phone,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(contactNumber: value),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _adminDialogTextField(
                          label: 'Social Media URL',
                          initialValue: draft.socialMediaUrl,
                          onChanged:
                              (value) => updateDraft(
                                draft.copyWith(socialMediaUrl: value),
                              ),
                        ),
                        const SizedBox(height: 14),
                        _AdminFileTile(
                          label: 'Banner Image *',
                          fileName: draft.mediaFile?.name ?? '',
                          helperText: 'JPG, PNG, or WebP up to 1 MB.',
                          buttonLabel:
                              draft.mediaFile == null
                                  ? 'Upload image'
                                  : 'Replace image',
                          onPressed: () async {
                            final file = await pickFile(type: FileType.image);
                            if (file == null) return;
                            if (file.bytes.length > 1024 * 1024) {
                              setDialogState(() {
                                validationMessage =
                                    'Banner image is too large. Keep it at or below 1 MB.';
                              });
                              return;
                            }
                            updateDraft(draft.copyWith(mediaFile: file));
                          },
                        ),
                        const SizedBox(height: 12),
                        _AdminFileTile(
                          label: 'Brochure PDF',
                          fileName: draft.brochureFile?.name ?? '',
                          helperText: 'Optional PDF brochure up to 2 MB.',
                          buttonLabel:
                              draft.brochureFile == null
                                  ? 'Upload brochure'
                                  : 'Replace brochure',
                          onPressed: () async {
                            final file = await pickFile(
                              type: FileType.custom,
                              allowedExtensions: const ['pdf'],
                            );
                            if (file == null) return;
                            if (file.bytes.length > 2 * 1024 * 1024) {
                              setDialogState(() {
                                validationMessage =
                                    'Brochure PDF is too large. Keep it at or below 2 MB.';
                              });
                              return;
                            }
                            updateDraft(draft.copyWith(brochureFile: file));
                          },
                        ),
                        if (validationMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            validationMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final error = draft.validationMessage;
                      if (error != null) {
                        setDialogState(() {
                          validationMessage = error;
                        });
                        return;
                      }
                      Navigator.of(context).pop(draft);
                    },
                    child: const Text('Add Banner'),
                  ),
                ],
              );
            },
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _isSavingNewBanner = true;
    });
    try {
      await ref.read(apiClientProvider).createAppBanner(draft: result);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.vendorName.isEmpty ? 'App banner' : result.vendorName} banner submitted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create app banner: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNewBanner = false;
        });
      }
    }
  }

  Widget _adminDialogTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return _StableTextFormField(
      value: initialValue,
      label: label,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminArenaDataAsync = ref.watch(adminArenaDataProvider);

    return adminArenaDataAsync.when(
      loading: () => const _LoadingState(),
      error:
          (error, _) => _ErrorState(
            title: 'Could not load admin data',
            message: error.toString(),
            onRetry: _refresh,
          ),
      data: (data) {
        final tenant = ref.watch(tenantProvider).valueOrNull;
        const normalizedQuery = '';
        final filteredMembers =
            data.members.where((member) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return [
                member.name,
                member.companyName,
                member.roleTitle,
                member.email,
                member.phone,
              ].join(' ').toLowerCase().contains(normalizedQuery);
            }).toList();
        final filteredPosts =
            data.posts.where((post) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return [
                post.title,
                post.summary,
                post.member.name,
                post.member.company,
              ].join(' ').toLowerCase().contains(normalizedQuery);
            }).toList();
        final filteredEvents =
            data.events.where((event) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return [
                event.name,
                event.type,
                event.venue,
                event.summary,
              ].join(' ').toLowerCase().contains(normalizedQuery);
            }).toList();
        final filteredBanners =
            data.appBanners.where((banner) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return [
                banner.vendorName,
                banner.shortText,
                banner.contactNumber,
                banner.paymentMode,
              ].join(' ').toLowerCase().contains(normalizedQuery);
            }).toList();
        final filteredTimelinePosts =
            data.timelinePosts.where((post) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return [
                post.displayTitle,
                post.postedBy,
                post.caption,
                post.contactNumber,
                post.sourceType,
              ].join(' ').toLowerCase().contains(normalizedQuery);
            }).toList();

        return _AdminSectionView(
          tenant: tenant,
          section: widget.section,
          onNavigateToAdminArena:
              () => widget.onSectionSelected(AdminArenaSection.appAccess),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh data'),
                ),
              ),
              const SizedBox(height: 12),
              _AdminSummaryBanner(
                memberCount: data.members.length,
                postCount: data.posts.length,
                eventCount: data.events.length,
              ),
              const SizedBox(height: 18),
              switch (widget.section) {
                AdminArenaSection.appAccess => _AdminAppAccessSection(
                  initialSettings: data.appAccess,
                  onSave: _saveAppAccess,
                ),
                AdminArenaSection.memberAccess => Column(
                  children: [
                    _AdminMemberAccessWorkspace(
                      members: filteredMembers,
                      posts: filteredPosts,
                      updatingMemberId: _updatingMemberId,
                      updatingPostId: _updatingPostId,
                      onUpdateAccess: _updateMemberAccess,
                      onBulkUpdateAccess: _applyBulkMemberAccess,
                      onUpdateStatus: _updatePostStatus,
                    ),
                  ],
                ),
                AdminArenaSection.bannerAccess => _AdminBannerAccessWorkspace(
                  banners: filteredBanners,
                  vendors: data.vendors,
                  updatingBannerId: _updatingBannerId,
                  isSavingNewBanner: _isSavingNewBanner,
                  onAddBanner: () => _openAppBannerDialog(data.vendors),
                  onEditBanner: _openBannerModerationDialog,
                  onUpdateBannerStatus: _updateBannerStatus,
                ),
                AdminArenaSection.timelineAccess =>
                  _AdminTimelineAccessWorkspace(
                    posts: filteredTimelinePosts,
                    members: data.members,
                    vendors: data.vendors,
                    tenant: tenant,
                    updatingTimelineId: _updatingTimelineId,
                    onUpdateTimelineStatus: _updateTimelineStatus,
                  ),
                AdminArenaSection.eventAccess => _AdminEventsSection(
                  events: filteredEvents,
                  eventTypes: data.eventTypes,
                  savingEventId: _savingEventId,
                  onSaveEvent: _saveEvent,
                  onDeleteEvent: _deleteEvent,
                ),
              },
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveAppAccess(AdminAppAccessSettings settings) async {
    try {
      await ref.read(apiClientProvider).updateAppAccess(settings: settings);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App access settings saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save app access settings: $error')),
      );
    }
  }

  Future<void> _saveEvent(AdminEventDraft draft) async {
    setState(() {
      _savingEventId = draft.id.isEmpty ? '__new__' : draft.id;
    });

    try {
      await ref.read(apiClientProvider).saveEvent(draft: draft);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(draft.id.isEmpty ? 'Event created.' : 'Event updated.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save event: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _savingEventId = null;
        });
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    setState(() {
      _savingEventId = eventId;
    });

    try {
      await ref.read(apiClientProvider).deleteEvent(eventId: eventId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete event: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _savingEventId = null;
        });
      }
    }
  }
}

class AssociationArenaPanel extends ConsumerStatefulWidget {
  const AssociationArenaPanel({
    super.key,
    required this.viewerRole,
    required this.section,
    required this.onSectionSelected,
  });

  final AppViewerRole viewerRole;
  final AssociationArenaSection section;
  final ValueChanged<AssociationArenaSection> onSectionSelected;

  @override
  ConsumerState<AssociationArenaPanel> createState() =>
      _AssociationArenaPanelState();
}

class _AssociationArenaPanelState extends ConsumerState<AssociationArenaPanel> {
  static const List<String> _committeePosts = [
    'President',
    'Vice President',
    'Vice President-Large Scale',
    'Vice President-Small Scale',
    'Secretary',
    'Joint Secretary',
    'Treasurer',
    'Application Chairman',
    'Member',
  ];

  AssociationProfileDraft? _draft;
  AssociationAboutDraft? _aboutDraft;
  AssociationDocumentDraft? _circularDraft;
  AssociationDocumentDraft? _newsBulletinDraft;
  AssociationDocumentDraft? _magazineDraft;
  String? _editingMemberMasterId;
  String? _editingCircularId;
  String? _editingNewsBulletinId;
  String? _editingMagazineId;
  String _activeGalleryFolderId = '';
  bool _isEditing = false;
  bool _isEditingAbout = false;
  bool _isSaving = false;
  bool _isSavingGallery = false;

  int _committeePostRank(String value) {
    final index = _committeePosts.indexWhere(
      (post) => post.toLowerCase() == value.trim().toLowerCase(),
    );
    return index == -1 ? _committeePosts.length : index;
  }

  String _todayDateOnly() => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _refresh() async {
    ref.invalidate(tenantProvider);
    ref.invalidate(memberArenaDataProvider);
    ref.invalidate(memberDirectoryProvider(widget.viewerRole));
    await Future.wait([
      ref.refresh(associationProfileProvider.future),
      ref.refresh(associationAboutProvider.future),
      ref.refresh(memberDirectoryProvider(widget.viewerRole).future),
      ref.refresh(associationCircularLibraryProvider.future),
      ref.refresh(associationNewsBulletinLibraryProvider.future),
      ref.refresh(associationMagazineLibraryProvider.future),
    ]);
  }

  Future<void> _saveProfile() async {
    if (_draft == null || _isSaving) {
      return;
    }
    final validationMessage = _draft!.validationMessage;
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await ref
          .read(apiClientProvider)
          .updateAssociationProfile(draft: _draft!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Association profile updated successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save association profile: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<String?> _promptForGalleryFolderName({
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Folder name',
              hintText: 'Enter a folder name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return value;
  }

  Future<void> _createGalleryFolder(String associationId) async {
    if (_isSavingGallery) {
      return;
    }

    final folderName = await _promptForGalleryFolderName(
      title: 'Create Gallery Folder',
    );
    if (!mounted || folderName == null || folderName.trim().isEmpty) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      withData: true,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );

    final files =
        (result?.files ?? const <PlatformFile>[])
            .where((file) => file.bytes != null)
            .map(AssociationUploadFile.fromPlatformFile)
            .toList();

    if (files.isEmpty) {
      return;
    }

    setState(() {
      _isSavingGallery = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .createAssociationGalleryFolder(
            associationId: associationId,
            name: folderName,
            files: files,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      setState(() {
        _activeGalleryFolderId = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            files.length == 1
                ? 'Gallery folder created with 1 photo.'
                : 'Gallery folder created with ${files.length} photos.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload gallery images: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingGallery = false;
        });
      }
    }
  }

  Future<void> _renameGalleryFolder(
    String associationId,
    AssociationGalleryFolder folder,
  ) async {
    final nextName = await _promptForGalleryFolderName(
      title: 'Rename Gallery Folder',
      initialValue: folder.name,
    );
    if (!mounted || nextName == null || nextName.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSavingGallery = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .renameAssociationGalleryFolder(
            associationId: associationId,
            folderId: folder.id,
            name: nextName,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gallery folder renamed.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rename gallery folder: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingGallery = false;
        });
      }
    }
  }

  Future<void> _deleteGalleryFolder(
    String associationId,
    AssociationGalleryFolder folder,
  ) async {
    setState(() {
      _isSavingGallery = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .deleteAssociationGalleryFolder(
            associationId: associationId,
            folderId: folder.id,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      setState(() {
        if (_activeGalleryFolderId == folder.id) {
          _activeGalleryFolderId = '';
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gallery folder deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete gallery folder: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingGallery = false;
        });
      }
    }
  }

  Future<void> _deleteGalleryPhoto(
    String associationId,
    String folderId,
    String photoId,
  ) async {
    setState(() {
      _isSavingGallery = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .deleteAssociationGalleryFolderPhoto(
            associationId: associationId,
            folderId: folderId,
            photoId: photoId,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gallery photo deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete gallery photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingGallery = false;
        });
      }
    }
  }

  Future<void> _saveAbout() async {
    if (_aboutDraft == null || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await ref
          .read(apiClientProvider)
          .updateAssociationAbout(draft: _aboutDraft!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      setState(() {
        _isEditingAbout = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('About us content saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save about us content: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickCircularFile() async {
    final file = await _pickAssociationDocumentFile();
    if (file == null || _circularDraft == null) {
      return;
    }

    setState(() {
      _circularDraft = _circularDraft!.copyWith(selectedFile: file);
    });
  }

  Future<AssociationUploadFile?> _pickAssociationDocumentFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'png',
        'jpg',
        'jpeg',
        'webp',
        'tif',
        'tiff',
      ],
      withData: true,
    );

    final file = result?.files.single;
    if (file == null || file.bytes == null) {
      return null;
    }
    return AssociationUploadFile.fromPlatformFile(file);
  }

  Future<void> _openCircularDocument(AssociationDocumentItem document) async {
    final candidateUrls =
        [
          document.documentUrl.trim(),
          document.previewUrl.trim(),
        ].where((url) => url.isNotEmpty).toList();

    if (candidateUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid circular document URL.')),
      );
      return;
    }

    for (final url in candidateUrls) {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        continue;
      }

      final didLaunch = await launchUrl(
        uri,
        mode:
            kIsWeb
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );
      if (didLaunch) {
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the full circular document.'),
        ),
      );
    }
  }

  void _openCircularEditor([AssociationDocumentItem? item]) {
    setState(() {
      _editingCircularId = item?.id ?? '';
      _circularDraft =
          item == null
              ? const AssociationDocumentDraft.empty()
              : AssociationDocumentDraft.fromDocument(item);
    });
  }

  Future<void> _pickNewsBulletinFile() async {
    final file = await _pickAssociationDocumentFile();
    if (file == null || _newsBulletinDraft == null) {
      return;
    }

    setState(() {
      _newsBulletinDraft = _newsBulletinDraft!.copyWith(selectedFile: file);
    });
  }

  void _openNewsBulletinEditor([AssociationDocumentItem? item]) {
    setState(() {
      _editingNewsBulletinId = item?.id ?? '';
      _newsBulletinDraft =
          item == null
              ? const AssociationDocumentDraft.empty()
              : AssociationDocumentDraft.fromDocument(item);
    });
  }

  void _closeNewsBulletinEditor() {
    setState(() {
      _editingNewsBulletinId = null;
      _newsBulletinDraft = null;
    });
  }

  Future<void> _saveNewsBulletin(String associationId) async {
    if (_newsBulletinDraft == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .saveAssociationNewsBulletin(
            associationId: associationId,
            draft: _newsBulletinDraft!,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _closeNewsBulletinEditor();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('News & bulletin saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save news & bulletin: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteNewsBulletin(
    String associationId,
    String documentId,
  ) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .deleteAssociationNewsBulletin(
            associationId: associationId,
            documentId: documentId,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      if (_editingNewsBulletinId == documentId) {
        _closeNewsBulletinEditor();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('News & bulletin deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete news & bulletin: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickMagazineFile() async {
    final file = await _pickAssociationDocumentFile();
    if (file == null || _magazineDraft == null) {
      return;
    }

    setState(() {
      _magazineDraft = _magazineDraft!.copyWith(selectedFile: file);
    });
  }

  void _openMagazineEditor([AssociationDocumentItem? item]) {
    setState(() {
      _editingMagazineId = item?.id ?? '';
      _magazineDraft =
          item == null
              ? const AssociationDocumentDraft.empty()
              : AssociationDocumentDraft.fromDocument(item);
    });
  }

  void _closeMagazineEditor() {
    setState(() {
      _editingMagazineId = null;
      _magazineDraft = null;
    });
  }

  Future<void> _saveMagazine(String associationId) async {
    if (_magazineDraft == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .saveAssociationMagazine(
            associationId: associationId,
            draft: _magazineDraft!,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _closeMagazineEditor();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Magazine saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save magazine: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteMagazine(String associationId, String documentId) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .deleteAssociationMagazine(
            associationId: associationId,
            documentId: documentId,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      if (_editingMagazineId == documentId) {
        _closeMagazineEditor();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Magazine deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete magazine: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _closeCircularEditor() {
    setState(() {
      _editingCircularId = null;
      _circularDraft = null;
    });
  }

  Future<void> _saveCircular(String associationId) async {
    if (_circularDraft == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .saveAssociationCircular(
            associationId: associationId,
            draft: _circularDraft!,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _closeCircularEditor();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Circular saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save circular: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteCircular(String associationId, String circularId) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .deleteAssociationCircular(
            associationId: associationId,
            circularId: circularId,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      if (_editingCircularId == circularId) {
        _closeCircularEditor();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Circular deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete circular: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _openMemberMasterEditor([MemberDirectoryItem? member]) async {
    setState(() {
      _editingMemberMasterId = member?.id ?? '';
    });

    final result = await showDialog<MemberMasterDraft>(
      context: context,
      builder:
          (dialogContext) => _MemberMasterDialog(
            initialDraft:
                member == null
                    ? const MemberMasterDraft.empty()
                    : MemberMasterDraft.fromMember(member),
          ),
    );

    if (!mounted) return;
    setState(() {
      _editingMemberMasterId = null;
    });

    if (result == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(apiClientProvider).saveMemberRecord(draft: result);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.id.isEmpty ? 'Member created.' : 'Member updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save member: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteMemberMaster(String memberId) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(apiClientProvider).deleteMemberRecord(memberId: memberId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Member deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete member: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _assignCommitteeMember({
    required MemberDirectoryItem member,
    required String committeePost,
    required List<MemberDirectoryItem> allMembers,
  }) async {
    if (_isSaving) {
      return;
    }

    final normalizedPost = committeePost.trim();
    if (normalizedPost.isEmpty) {
      return;
    }

    final existingOccupant = allMembers.cast<MemberDirectoryItem?>().firstWhere(
      (candidate) =>
          candidate != null &&
          candidate.id != member.id &&
          candidate.committeePost.trim().toLowerCase() ==
              normalizedPost.toLowerCase(),
      orElse: () => null,
    );

    if (existingOccupant != null) {
      final shouldReplace =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Committee post already assigned'),
                  content: Text(
                    '${existingOccupant.name} is already assigned as $normalizedPost. Remove the existing committee assignment and add ${member.name} instead?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Replace'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!shouldReplace || !mounted) {
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (existingOccupant != null) {
        await ref
            .read(apiClientProvider)
            .updateMemberCommittee(
              memberId: existingOccupant.id,
              committeePost: '',
              committeeTenureStart: '',
              committeeTenureEnd: '',
            );
      }

      await ref
          .read(apiClientProvider)
          .updateMemberCommittee(
            memberId: member.id,
            committeePost: normalizedPost,
            committeeTenureStart:
                member.committeeTenureStart.isNotEmpty
                    ? member.committeeTenureStart
                    : _todayDateOnly(),
            committeeTenureEnd: '',
          );

      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} is now assigned as $normalizedPost.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update committee assignment: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _removeCommitteeMember(MemberDirectoryItem member) async {
    if (_isSaving) {
      return;
    }

    final shouldRemove =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Remove committee member'),
                content: Text(
                  'Remove ${member.name} from the committee? This will only clear the committee assignment and will not remove the association member.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!shouldRemove) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .updateMemberCommittee(
            memberId: member.id,
            committeePost: '',
            committeeTenureStart: '',
            committeeTenureEnd: '',
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} was removed from the committee.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove committee member: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = widget.viewerRole.isAdmin;
    if (widget.section == AssociationArenaSection.profile) {
      final profileAsync = ref.watch(associationProfileProvider);
      return profileAsync.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load association profile',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data: (profile) {
          _draft ??= AssociationProfileDraft.fromProfile(profile);

          if (canManage && _isEditing && _draft != null) {
            return _AssociationProfileEditor(
              draft: _draft!,
              isSaving: _isSaving,
              onChanged: (draft) => setState(() => _draft = draft),
              onAddRegionalAddress: () {
                setState(() {
                  _draft = _draft!.copyWith(
                    regionalAddresses: [
                      ..._draft!.regionalAddresses,
                      AssociationRegionalAddressDraft.empty(
                        id: 'regional-${DateTime.now().microsecondsSinceEpoch}',
                      ),
                    ],
                  );
                });
              },
              onRemoveRegionalAddress: (index) {
                setState(() {
                  final nextAddresses = [..._draft!.regionalAddresses]
                    ..removeAt(index);
                  _draft = _draft!.copyWith(regionalAddresses: nextAddresses);
                });
              },
              onSave: _saveProfile,
              onCancel: () {
                setState(() {
                  _draft = AssociationProfileDraft.fromProfile(profile);
                  _isEditing = false;
                });
              },
            );
          }

          return _AssociationProfileView(
            profile: profile,
            onNavigateToAssociation:
                () => widget.onSectionSelected(AssociationArenaSection.profile),
            onEdit:
                canManage
                    ? () {
                      setState(() {
                        _draft = AssociationProfileDraft.fromProfile(profile);
                        _isEditing = true;
                      });
                    }
                    : null,
          );
        },
      );
    }

    if (widget.section == AssociationArenaSection.aboutUs) {
      final aboutAsync = ref.watch(associationAboutProvider);
      return aboutAsync.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load association details',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data: (about) {
          _aboutDraft ??= AssociationAboutDraft.fromAbout(about);

          if (canManage && _isEditingAbout && _aboutDraft != null) {
            return _AssociationAboutEditor(
              draft: _aboutDraft!,
              isSaving: _isSaving,
              onChanged: (draft) => setState(() => _aboutDraft = draft),
              onSave: _saveAbout,
              onCancel: () {
                setState(() {
                  _aboutDraft = AssociationAboutDraft.fromAbout(about);
                  _isEditingAbout = false;
                });
              },
            );
          }

          return _AssociationAboutView(
            about: about,
            onNavigateToAssociation:
                () => widget.onSectionSelected(AssociationArenaSection.profile),
            onEdit:
                canManage
                    ? () {
                      setState(() {
                        _aboutDraft = AssociationAboutDraft.fromAbout(about);
                        _isEditingAbout = true;
                      });
                    }
                    : null,
          );
        },
      );
    }

    if (widget.section == AssociationArenaSection.managementCommittee) {
      final membersAsync = ref.watch(
        memberDirectoryProvider(widget.viewerRole),
      );
      return membersAsync.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load committee members',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data: (members) {
          final committeeMembers =
              members
                  .where((member) => member.committeePost.trim().isNotEmpty)
                  .toList()
                ..sort((a, b) {
                  final rankCompare = _committeePostRank(
                    a.committeePost,
                  ).compareTo(_committeePostRank(b.committeePost));
                  if (rankCompare != 0) {
                    return rankCompare;
                  }
                  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                });
          final sortedMembers = [...members]..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          return _AssociationCommitteeView(
            canManage: canManage,
            allMembers: sortedMembers,
            members: committeeMembers,
            isSaving: _isSaving,
            committeePosts: _committeePosts,
            onNavigateToAssociation:
                () => widget.onSectionSelected(AssociationArenaSection.profile),
            onAssignCommitteeMember:
                (member, post) => _assignCommitteeMember(
                  member: member,
                  committeePost: post,
                  allMembers: sortedMembers,
                ),
            onRemoveCommitteeMember: _removeCommitteeMember,
          );
        },
      );
    }

    if (widget.section == AssociationArenaSection.circulars) {
      final circularsAsync = ref.watch(associationCircularLibraryProvider);
      return circularsAsync.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load circulars',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data: (library) {
          return _AssociationDocumentLibrarySection(
            moduleLabel: 'Circular',
            emptyTitle: 'No circular documents yet',
            emptySubtitle:
                'Upload your first circular to start building the association document library.',
            headerSubtitle:
                'Upload PDFs, DOC files, or scanned circulars and make them available across admin surfaces.',
            saveButtonLabel: 'Save Circular',
            editorTitle: 'Circular CMS',
            canManage: canManage,
            items: library.items,
            draft: _circularDraft,
            editingItemId: _editingCircularId,
            isSaving: _isSaving,
            onOpenEditor: _openCircularEditor,
            onCancelEdit: _closeCircularEditor,
            onDraftChanged: (draft) => setState(() => _circularDraft = draft),
            onPickFile: _pickCircularFile,
            onOpenDocument: _openCircularDocument,
            onSave: () => _saveCircular(library.associationId),
            onDelete:
                (circularId) =>
                    _deleteCircular(library.associationId, circularId),
          );
        },
      );
    }

    if (widget.section == AssociationArenaSection.newsBulletin) {
      final libraryAsync = ref.watch(associationNewsBulletinLibraryProvider);
      return libraryAsync.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load news & bulletin',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data: (library) {
          return _AssociationDocumentLibrarySection(
            moduleLabel: 'News & Bulletin',
            emptyTitle: 'No news or bulletins yet',
            emptySubtitle:
                'Upload your first news or bulletin document to make it available across the app.',
            headerSubtitle:
                'Upload PDFs, DOC files, or image documents and make them available across admin, member, and vendor views.',
            saveButtonLabel: 'Save News & Bulletin',
            editorTitle: 'News & Bulletin CMS',
            canManage: canManage,
            items: library.items,
            draft: _newsBulletinDraft,
            editingItemId: _editingNewsBulletinId,
            isSaving: _isSaving,
            onOpenEditor: _openNewsBulletinEditor,
            onCancelEdit: _closeNewsBulletinEditor,
            onDraftChanged:
                (draft) => setState(() => _newsBulletinDraft = draft),
            onPickFile: _pickNewsBulletinFile,
            onOpenDocument: _openCircularDocument,
            onSave: () => _saveNewsBulletin(library.associationId),
            onDelete:
                (documentId) =>
                    _deleteNewsBulletin(library.associationId, documentId),
          );
        },
      );
    }

    if (widget.section == AssociationArenaSection.magazine) {
      final libraryAsync = ref.watch(associationMagazineLibraryProvider);
      return libraryAsync.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load magazines',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data: (library) {
          return _AssociationDocumentLibrarySection(
            moduleLabel: 'Magazine',
            emptyTitle: 'No magazines yet',
            emptySubtitle:
                'Upload your first magazine issue to make it available across the app.',
            headerSubtitle:
                'Upload PDFs, DOC files, or image documents and make them available across admin, member, and vendor views.',
            saveButtonLabel: 'Save Magazine',
            editorTitle: 'Magazine CMS',
            canManage: canManage,
            items: library.items,
            draft: _magazineDraft,
            editingItemId: _editingMagazineId,
            isSaving: _isSaving,
            onOpenEditor: _openMagazineEditor,
            onCancelEdit: _closeMagazineEditor,
            onDraftChanged: (draft) => setState(() => _magazineDraft = draft),
            onPickFile: _pickMagazineFile,
            onOpenDocument: _openCircularDocument,
            onSave: () => _saveMagazine(library.associationId),
            onDelete:
                (documentId) =>
                    _deleteMagazine(library.associationId, documentId),
          );
        },
      );
    }

    if (widget.section == AssociationArenaSection.master) {
      final membersAsync = ref.watch(
        memberDirectoryProvider(widget.viewerRole),
      );
      return membersAsync.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load member master',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data: (members) {
          final sortedMembers = [...members]..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          return _AssociationMasterSection(
            canManage: canManage,
            members: sortedMembers,
            editingMemberId: _editingMemberMasterId,
            isSaving: _isSaving,
            onNavigateToAssociation:
                () => widget.onSectionSelected(AssociationArenaSection.profile),
            onOpenEditor: _openMemberMasterEditor,
            onDelete: _deleteMemberMaster,
          );
        },
      );
    }

    if (widget.section == AssociationArenaSection.gallery) {
      final profileAsync = ref.watch(associationProfileProvider);
      return profileAsync.when(
        loading: () => const _LoadingState(),
        error:
            (error, _) => _ErrorState(
              title: 'Could not load association gallery',
              message: error.toString(),
              onRetry: _refresh,
            ),
        data: (profile) {
          final activeFolder = profile.galleryFolders.firstWhere(
            (folder) => folder.id == _activeGalleryFolderId,
            orElse:
                () =>
                    profile.galleryFolders.isNotEmpty
                        ? profile.galleryFolders.first
                        : const AssociationGalleryFolder(
                          id: '',
                          name: '',
                          createdAt: '',
                          updatedAt: '',
                          photoCount: 0,
                          previewPhotos: [],
                          photos: [],
                        ),
          );
          return _AssociationGallerySection(
            canManage: canManage,
            associationId: profile.id,
            folders: profile.galleryFolders,
            activeFolderId: activeFolder.id,
            isSaving: _isSavingGallery,
            onAddFolder: () => _createGalleryFolder(profile.id),
            onOpenFolder:
                (folderId) => setState(() {
                  _activeGalleryFolderId = folderId;
                }),
            onRenameFolder:
                (folder) => _renameGalleryFolder(profile.id, folder),
            onDeleteFolder:
                (folder) => _deleteGalleryFolder(profile.id, folder),
            onDeletePhoto:
                (folderId, photoId) =>
                    _deleteGalleryPhoto(profile.id, folderId, photoId),
          );
        },
      );
    }

    return _EmptyStateCard(
      title: '${widget.section.label} is next',
      subtitle:
          'The association menu now matches the web app. Profile, About Us, and Management Committee are live first, and ${widget.section.label} can be layered in next.',
    );
  }
}

class _MemberMediaSection extends StatelessWidget {
  const _MemberMediaSection({
    required this.posts,
    required this.viewerRole,
    required this.updatingPostId,
    required this.onUpdateStatus,
  });

  final List<MemberPostItem> posts;
  final AppViewerRole viewerRole;
  final String? updatingPostId;
  final Future<void> Function(MemberPostItem, PostReviewStatus) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Media Feed',
            subtitle:
                'Facebook-style informational posts from members will appear here once the backend has content.',
          ),
          SizedBox(height: 14),
          _EmptyStateCard(
            title: 'No posts yet',
            subtitle:
                'Try creating or approving a member post in the backend to populate this feed.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Media Feed',
          subtitle:
              'Informational member posts with role-aware visibility for the association feed.',
        ),
        const SizedBox(height: 14),
        _FeedInfoBanner(viewerRole: viewerRole, postCount: posts.length),
        const SizedBox(height: 14),
        ...posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MemberPostCard(
              post: post,
              viewerRole: viewerRole,
              isUpdating: updatingPostId == post.id,
              onUpdateStatus: onUpdateStatus,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MemberMediaView extends StatelessWidget {
  const _MemberMediaView({
    required this.viewerRole,
    required this.tenant,
    required this.onNavigateToMemberArena,
    required this.child,
  });

  final AppViewerRole viewerRole;
  final TenantContext? tenant;
  final VoidCallback onNavigateToMemberArena;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final associationName =
        tenant?.associationName.trim().isNotEmpty == true
            ? tenant!.associationName
            : 'NIMA';
    final locationLabel = tenant?.locationLabel ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MemberSectionHero(
          associationName: associationName,
          locationLabel: locationLabel,
          viewerRole: viewerRole,
        ),
        const SizedBox(height: 14),
        _MemberBreadcrumb(
          currentLabel: 'Media',
          onRootTap: onNavigateToMemberArena,
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _MemberDirectoryView extends StatelessWidget {
  const _MemberDirectoryView({
    required this.tenant,
    required this.onNavigateToMemberArena,
    required this.child,
  });

  final TenantContext? tenant;
  final VoidCallback onNavigateToMemberArena;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _MemberFilteredDirectoryView extends StatelessWidget {
  const _MemberFilteredDirectoryView({
    required this.tenant,
    required this.section,
    required this.onNavigateToMemberArena,
    required this.child,
  });

  final TenantContext? tenant;
  final MemberArenaSection section;
  final VoidCallback onNavigateToMemberArena;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _MemberSectionHero extends StatelessWidget {
  const _MemberSectionHero({
    required this.associationName,
    required this.locationLabel,
    required this.viewerRole,
  });

  final String associationName;
  final String locationLabel;
  final AppViewerRole viewerRole;

  @override
  Widget build(BuildContext context) {
    return _AssociationSectionHero(
      arenaLabel: 'Members',
      titleSpans: [
        const TextSpan(text: 'Welcome to '),
        TextSpan(
          text: associationName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const TextSpan(text: ' media'),
        if (locationLabel.isNotEmpty) ...[
          const TextSpan(text: ' in '),
          TextSpan(
            text: locationLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
        const TextSpan(text: '.'),
      ],
      footer: Text(
        '${viewerRole.label} view • ${_formatCurrentDateTime()}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.84),
          height: 1.45,
        ),
      ),
    );
  }
}

class _AdminSectionView extends StatelessWidget {
  const _AdminSectionView({
    required this.tenant,
    required this.section,
    required this.onNavigateToAdminArena,
    required this.child,
  });

  final TenantContext? tenant;
  final AdminArenaSection section;
  final VoidCallback onNavigateToAdminArena;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final associationName =
        tenant?.associationName.trim().isNotEmpty == true
            ? tenant!.associationName
            : 'NIMA';
    final locationLabel = tenant?.locationLabel ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminSectionHero(
          associationName: associationName,
          locationLabel: locationLabel,
          sectionLabel: section.label,
        ),
        const SizedBox(height: 14),
        _AdminBreadcrumb(
          currentLabel: section.label,
          onRootTap: onNavigateToAdminArena,
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _AdminSectionHero extends StatelessWidget {
  const _AdminSectionHero({
    required this.associationName,
    required this.locationLabel,
    required this.sectionLabel,
  });

  final String associationName;
  final String locationLabel;
  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    return _AssociationSectionHero(
      arenaLabel: 'Admin',
      titleSpans: [
        const TextSpan(text: 'Manage '),
        TextSpan(
          text: sectionLabel,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const TextSpan(text: ' for '),
        TextSpan(
          text: associationName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        if (locationLabel.isNotEmpty) ...[
          const TextSpan(text: ', '),
          TextSpan(
            text: locationLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
        const TextSpan(text: '.'),
      ],
    );
  }
}

class _AdminBreadcrumb extends StatelessWidget {
  const _AdminBreadcrumb({required this.currentLabel, required this.onRootTap});

  final String currentLabel;
  final VoidCallback onRootTap;

  @override
  Widget build(BuildContext context) {
    return _ArenaBreadcrumb(
      rootLabel: 'Admin',
      currentLabel: currentLabel,
      onRootTap: onRootTap,
    );
  }
}

class _MemberBreadcrumb extends StatelessWidget {
  const _MemberBreadcrumb({
    required this.currentLabel,
    required this.onRootTap,
  });

  final String currentLabel;
  final VoidCallback onRootTap;

  @override
  Widget build(BuildContext context) {
    return _ArenaBreadcrumb(
      rootLabel: 'Members',
      currentLabel: currentLabel,
      onRootTap: onRootTap,
    );
  }
}

class _FilteredMemberDirectorySection extends StatelessWidget {
  const _FilteredMemberDirectorySection({
    required this.viewerRole,
    required this.section,
    required this.refreshToken,
  });

  final AppViewerRole viewerRole;
  final MemberArenaSection section;
  final int refreshToken;

  @override
  Widget build(BuildContext context) {
    final config = MemberArenaSectionDirectoryMeta.configFor(section);
    return _MemberDirectorySection(
      viewerRole: viewerRole,
      refreshToken: refreshToken,
      initialFilter: config.filter,
      lockFilter: true,
      title: config.title,
      subtitle: config.subtitle,
    );
  }
}

class _DashboardAppBannerCarousel extends StatelessWidget {
  const _DashboardAppBannerCarousel({
    required this.items,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<DashboardAppBannerItem> items;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  Future<void> _openExternalLink(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareBanner(DashboardAppBannerItem item) async {
    final shareText = [
      item.vendorName.trim(),
      item.shortText.trim(),
      if (item.socialMediaUrl.trim().isNotEmpty) item.socialMediaUrl.trim(),
      if (item.contactNumber.trim().isNotEmpty)
        'Contact: ${item.contactNumber.trim()}',
    ].where((part) => part.isNotEmpty).join('\n\n');

    await Share.share(shareText, subject: item.vendorName.trim());
  }

  Future<void> _openPhoneActions(
    BuildContext context,
    DashboardAppBannerItem item,
  ) async {
    final phoneDigits = item.contactNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phoneDigits.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.vendorName,
                  style: const TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.contactNumber,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFECFDF5),
                    foregroundColor: Color(0xFF047857),
                    child: Icon(Icons.call_rounded),
                  ),
                  title: const Text('Call now'),
                  subtitle: const Text('Open the dialer with this number'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _openExternalLink('tel:$phoneDigits');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    foregroundColor: Color(0xFF15803D),
                    child: Icon(Icons.message_rounded),
                  ),
                  title: const Text('WhatsApp'),
                  subtitle: const Text('Start a chat on WhatsApp'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final whatsappDigits = phoneDigits.replaceAll('+', '');
                    await _openExternalLink('https://wa.me/$whatsappDigits');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isYouTubeLink(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    final host = uri?.host.toLowerCase() ?? '';
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  void _openBannerPreview(BuildContext context, DashboardAppBannerItem item) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.84),
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  color: const Color(0xFF09090B),
                  child: OrientationBuilder(
                    builder: (context, orientation) {
                      final actionPanel = _BannerPreviewActions(
                        item: item,
                        onPhoneTap: () => _openPhoneActions(context, item),
                        onYoutubeTap:
                            _isYouTubeLink(item.socialMediaUrl)
                                ? () => _openExternalLink(item.socialMediaUrl)
                                : null,
                        onMediaTap:
                            item.socialMediaUrl.trim().isNotEmpty
                                ? () => _openExternalLink(item.socialMediaUrl)
                                : null,
                        onShareTap: () => _shareBanner(item),
                      );

                      final previewImage = InteractiveViewer(
                        minScale: 0.9,
                        maxScale: 4,
                        child: Center(
                          child:
                              item.mediaUrl.isNotEmpty
                                  ? _BackendImage(
                                    imageUrl: item.mediaUrl,
                                    fit: BoxFit.contain,
                                    fallback: _BannerFallbackCard(item: item),
                                  )
                                  : _BannerFallbackCard(item: item),
                        ),
                      );

                      if (orientation == Orientation.landscape) {
                        return Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: previewImage),
                                  _BannerPreviewCloseButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 280,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                28,
                                20,
                                20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              child: actionPanel,
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(child: previewImage),
                                _BannerPreviewCloseButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            child: actionPanel,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyStateCard(
        title: 'No active app banners yet',
        subtitle:
            'Approved paid banners from the backend will appear here in sequence order starting from slot 1.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 235,
          child: PageView.builder(
            controller: pageController,
            itemCount: items.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12, top: 10),
                child: InkWell(
                  onTap: () => _openBannerPreview(context, item),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A0F172A),
                          blurRadius: 24,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item.mediaUrl.isNotEmpty)
                            _BackendImage(
                              imageUrl: item.mediaUrl,
                              fit: BoxFit.cover,
                              fallback: _BannerFallbackCard(item: item),
                            )
                          else
                            _BannerFallbackCard(item: item),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              items.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      currentPage == index
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BannerPreviewActions extends StatelessWidget {
  const _BannerPreviewActions({
    required this.item,
    required this.onPhoneTap,
    required this.onYoutubeTap,
    required this.onMediaTap,
    required this.onShareTap,
  });

  final DashboardAppBannerItem item;
  final VoidCallback? onPhoneTap;
  final VoidCallback? onYoutubeTap;
  final VoidCallback? onMediaTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.vendorName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.shortText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        if (item.contactNumber.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            item.contactNumber,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            _BannerActionIcon(
              icon: Icons.call_rounded,
              tooltip: 'Phone / WhatsApp',
              onTap: onPhoneTap,
            ),
            const SizedBox(width: 14),
            _BannerActionIcon(
              icon: Icons.play_circle_fill_rounded,
              tooltip: 'YouTube',
              onTap: onYoutubeTap,
            ),
            const SizedBox(width: 14),
            _BannerActionIcon(
              icon: Icons.perm_media_rounded,
              tooltip: 'Media link',
              onTap: onMediaTap,
            ),
            const SizedBox(width: 14),
            _BannerActionIcon(
              icon: Icons.share_rounded,
              tooltip: 'Share banner',
              onTap: onShareTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _BannerActionIcon extends StatelessWidget {
  const _BannerActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: isEnabled ? 0.18 : 0.08),
            ),
          ),
          child: Icon(
            icon,
            color:
                isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.32),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _BannerPreviewCloseButton extends StatelessWidget {
  const _BannerPreviewCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 14,
      right: 14,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class _DashboardVendorCarousel extends StatelessWidget {
  const _DashboardVendorCarousel({required this.vendors});

  final List<DashboardVendorItem> vendors;

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: vendors.length,
        separatorBuilder: (context, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final vendor = vendors[index];
          return SizedBox(
            width: 74,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _VendorProfileScreen(vendor: vendor),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _VendorAvatar(vendor: vendor, size: 56),
                    const SizedBox(height: 6),
                    Text(
                      vendor.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VendorDirectoryCard extends StatelessWidget {
  const _VendorDirectoryCard({required this.vendor});

  final DashboardVendorItem vendor;

  @override
  Widget build(BuildContext context) {
    final factPills = <Widget>[
      if (vendor.category.trim().isNotEmpty)
        _DirectoryFactPill(
          icon: Icons.category_rounded,
          label: vendor.category,
        ),
      if (vendor.city.trim().isNotEmpty)
        _DirectoryFactPill(
          icon: Icons.location_city_rounded,
          label: vendor.city,
        ),
      if (vendor.vendorType.trim().isNotEmpty)
        _DirectoryFactPill(
          icon: Icons.store_mall_directory_rounded,
          label: vendor.vendorType,
        ),
    ];

    final detailLines = <Widget>[
      if (vendor.companyName.trim().isNotEmpty)
        _DirectoryDetailLine(
          icon: Icons.business_outlined,
          label: vendor.companyName,
          emphasize: true,
        ),
      if (vendor.contactPerson.trim().isNotEmpty)
        _DirectoryDetailLine(
          icon: Icons.badge_outlined,
          label: vendor.contactPerson,
        ),
      if (vendor.email.trim().isNotEmpty)
        _DirectoryDetailLine(
          icon: Icons.mail_outline_rounded,
          label: vendor.email,
          onTap: () => _openEmailComposer(vendor.email),
        ),
      if (vendor.phone.trim().isNotEmpty)
        _DirectoryDetailLine(
          icon: Icons.call_outlined,
          label: vendor.phone,
          onTap:
              () => _showPhoneActionsSheet(
                context,
                title: vendor.displayName,
                phoneNumber: vendor.phone,
              ),
        ),
    ];

    return _EntityCardFrame(
      child: _ReusableMemberCard(
        name: vendor.displayName,
        photoUrl: vendor.avatarUrl,
        primaryLabel: vendor.category,
        onHeaderTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _VendorProfileScreen(vendor: vendor),
            ),
          );
        },
        factPills: factPills,
        detailLines: detailLines,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9CA3AF),
          size: 28,
        ),
        footer: Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _VendorProfileScreen(vendor: vendor),
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('View profile'),
          ),
        ),
      ),
    );
  }
}

class _VendorCategoryGridCard extends StatelessWidget {
  const _VendorCategoryGridCard({
    required this.categoryName,
    required this.vendorCount,
    required this.subCategories,
    required this.onTap,
  });

  final String categoryName;
  final int vendorCount;
  final List<String> subCategories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primarySubCategory =
        subCategories.isNotEmpty ? subCategories.first : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      categoryName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '$vendorCount',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subCategories.isEmpty
                    ? 'No sub categories'
                    : '${subCategories.length} sub categories',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    primarySubCategory ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (subCategories.length > 1) ...[
                  const SizedBox(height: 6),
                  Text(
                    '+${subCategories.length - 1} more',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorCategoryDirectoryScreen extends StatefulWidget {
  const _VendorCategoryDirectoryScreen({
    required this.categoryName,
    required this.vendors,
    required this.subCategories,
  });

  final String categoryName;
  final List<DashboardVendorItem> vendors;
  final List<String> subCategories;

  @override
  State<_VendorCategoryDirectoryScreen> createState() =>
      _VendorCategoryDirectoryScreenState();
}

class _VendorCategoryDirectoryScreenState
    extends State<_VendorCategoryDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedSubCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedCategory = widget.categoryName.trim().toLowerCase();
    final filteredVendors =
        widget.vendors.where((vendor) {
            final category =
                (vendor.category.trim().isEmpty
                        ? 'Uncategorized'
                        : vendor.category.trim())
                    .toLowerCase();
            if (category != normalizedCategory) {
              return false;
            }

            final subCategory = vendor.vendorType.trim();
            if (_selectedSubCategory != null &&
                subCategory.toLowerCase() !=
                    _selectedSubCategory!.trim().toLowerCase()) {
              return false;
            }

            final query = _query.trim().toLowerCase();
            if (query.isEmpty) {
              return true;
            }

            return [
              vendor.displayName,
              vendor.contactPerson,
              vendor.city,
              vendor.vendorType,
            ].any((value) => value.trim().toLowerCase().contains(query));
          }).toList()
          ..sort(
            (left, right) => left.displayName.toLowerCase().compareTo(
              right.displayName.toLowerCase(),
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF171717),
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _EntityCardFrame(
              padding: const EdgeInsets.all(18),
              radius: 28,
              shadowColor: const Color(0x0A0F172A),
              shadowBlur: 18,
              shadowOffset: const Offset(0, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${filteredVendors.length} vendor${filteredVendors.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Browse vendors in this category, or narrow the list with sub categories and search.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded),
                        hintText: 'Search vendors in this category',
                      ),
                    ),
                  ),
                  if (widget.subCategories.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DirectoryFilterChip(
                          label: 'All',
                          icon: Icons.category_rounded,
                          selected: _selectedSubCategory == null,
                          onTap: () {
                            setState(() {
                              _selectedSubCategory = null;
                            });
                          },
                        ),
                        ...widget.subCategories.map(
                          (subCategory) => _DirectoryFilterChip(
                            label: subCategory,
                            icon: Icons.subdirectory_arrow_right,
                            selected: _selectedSubCategory == subCategory,
                            onTap: () {
                              setState(() {
                                _selectedSubCategory =
                                    _selectedSubCategory == subCategory
                                        ? null
                                        : subCategory;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (filteredVendors.isEmpty)
              const _EmptyStateCard(
                title: 'No vendors found',
                subtitle:
                    'Try another search or sub category to find matching vendors.',
              )
            else
              ...filteredVendors.map(
                (vendor) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _VendorDirectoryCard(vendor: vendor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VendorSearchResultsScreen extends StatefulWidget {
  const _VendorSearchResultsScreen({
    required this.query,
    required this.vendors,
  });

  final String query;
  final List<DashboardVendorItem> vendors;

  @override
  State<_VendorSearchResultsScreen> createState() =>
      _VendorSearchResultsScreenState();
}

class _VendorSearchResultsScreenState
    extends State<_VendorSearchResultsScreen> {
  late final TextEditingController _searchController;
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredVendors =
        widget.vendors.where((vendor) {
            if (query.isEmpty) {
              return true;
            }
            return [
              vendor.displayName,
              vendor.contactPerson,
              vendor.city,
              vendor.category,
              vendor.vendorType,
            ].any((value) => value.trim().toLowerCase().contains(query));
          }).toList()
          ..sort(
            (left, right) => left.displayName.toLowerCase().compareTo(
              right.displayName.toLowerCase(),
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF171717),
        title: const Text(
          'Vendor Search',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _EntityCardFrame(
              padding: const EdgeInsets.all(18),
              radius: 28,
              shadowColor: const Color(0x0A0F172A),
              shadowBlur: 18,
              shadowOffset: const Offset(0, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Vendors',
                    style: TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded),
                        hintText: 'Search by vendor, city, or category',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${filteredVendors.length} vendor${filteredVendors.length == 1 ? '' : 's'} found',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (filteredVendors.isEmpty)
              const _EmptyStateCard(
                title: 'No vendors found',
                subtitle: 'Try another vendor name, city, or category keyword.',
              )
            else
              ...filteredVendors.map(
                (vendor) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _VendorDirectoryCard(vendor: vendor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VendorProfileScreen extends StatelessWidget {
  const _VendorProfileScreen({required this.vendor});

  final DashboardVendorItem vendor;

  Future<void> _openExternalLink(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _detailRow(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF171717),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetCard(
    BuildContext context,
    String label,
    VendorProfileAsset asset,
  ) {
    if (!asset.hasValue) {
      return const SizedBox.shrink();
    }
    return _EntityCardFrame(
      padding: const EdgeInsets.all(16),
      radius: 22,
      shadowColor: const Color(0x0A0F172A),
      shadowBlur: 12,
      shadowOffset: const Offset(0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF171717),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (asset.isImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: _BackendImage(
                  imageUrl: asset.url,
                  fit: BoxFit.cover,
                  fallback: Container(
                    color: const Color(0xFFF3F4F6),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            asset.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openExternalLink(asset.url),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open file'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileLinks =
        [
          ('Website', vendor.website),
          ('Facebook', vendor.facebookUrl),
          ('Instagram', vendor.instagramUrl),
          ('YouTube', vendor.youtubeUrl),
          ('LinkedIn', vendor.linkedinUrl),
          ('X / Twitter', vendor.xUrl),
        ].where((entry) => entry.$2.trim().isNotEmpty).toList();
    final assetCards = <Widget>[
      if (vendor.companyLogoAsset.hasValue)
        _assetCard(context, 'Company Logo', vendor.companyLogoAsset),
      if (vendor.profilePhotoAsset.hasValue)
        _assetCard(context, 'Profile Photo', vendor.profilePhotoAsset),
      if (vendor.idProofAsset.hasValue)
        _assetCard(context, 'ID Proof', vendor.idProofAsset),
      if (vendor.locationProofAsset.hasValue)
        _assetCard(context, 'Location Proof', vendor.locationProofAsset),
      if (vendor.companyBrochureAsset.hasValue)
        _assetCard(context, 'Company Brochure', vendor.companyBrochureAsset),
      if (vendor.visitingCardAsset.hasValue)
        _assetCard(context, 'Visiting Card', vendor.visitingCardAsset),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF171717),
        title: Text(
          vendor.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _EntityCardFrame(
              padding: const EdgeInsets.all(20),
              radius: 28,
              shadowColor: const Color(0x120F172A),
              shadowBlur: 18,
              shadowOffset: const Offset(0, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _VendorAvatar(vendor: vendor, size: 74),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.displayName,
                              style: const TextStyle(
                                color: Color(0xFF171717),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (vendor.contactPerson.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                vendor.contactPerson,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (vendor.badge.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  vendor.badge,
                                  style: const TextStyle(
                                    color: Color(0xFF4338CA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (vendor.phone.trim().isNotEmpty)
                        _TimelineLinkChip(
                          label: vendor.phone,
                          icon: Icons.call_rounded,
                          onTap:
                              () => _openExternalLink(
                                'tel:${vendor.phone.replaceAll(' ', '')}',
                              ),
                        ),
                      if (vendor.email.trim().isNotEmpty)
                        _TimelineLinkChip(
                          label: 'Email',
                          icon: Icons.mail_rounded,
                          onTap:
                              () => _openExternalLink('mailto:${vendor.email}'),
                        ),
                      if (vendor.website.trim().isNotEmpty)
                        _TimelineLinkChip(
                          label: 'Website',
                          icon: Icons.language_rounded,
                          onTap: () => _openExternalLink(vendor.website),
                        ),
                      if (vendor.youtubeUrl.trim().isNotEmpty)
                        _TimelineLinkChip(
                          label: 'YouTube',
                          icon: Icons.play_circle_fill_rounded,
                          onTap: () => _openExternalLink(vendor.youtubeUrl),
                        ),
                      if (vendor.facebookUrl.trim().isNotEmpty)
                        _TimelineLinkChip(
                          label: 'Facebook',
                          icon: Icons.thumb_up_alt_rounded,
                          onTap: () => _openExternalLink(vendor.facebookUrl),
                        ),
                      if (vendor.instagramUrl.trim().isNotEmpty)
                        _TimelineLinkChip(
                          label: 'Instagram',
                          icon: Icons.camera_alt_rounded,
                          onTap: () => _openExternalLink(vendor.instagramUrl),
                        ),
                      if (vendor.linkedinUrl.trim().isNotEmpty)
                        _TimelineLinkChip(
                          label: 'LinkedIn',
                          icon: Icons.business_center_rounded,
                          onTap: () => _openExternalLink(vendor.linkedinUrl),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (vendor.category.trim().isNotEmpty ||
                vendor.vendorType.trim().isNotEmpty ||
                vendor.city.trim().isNotEmpty ||
                vendor.country.trim().isNotEmpty ||
                vendor.state.trim().isNotEmpty)
              _EntityCardFrame(
                padding: const EdgeInsets.all(18),
                radius: 24,
                shadowColor: const Color(0x0D0F172A),
                shadowBlur: 14,
                shadowOffset: const Offset(0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vendor Details',
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _detailRow('Category', vendor.category),
                    _detailRow('Sub-category', vendor.vendorType),
                    _detailRow('City', vendor.city),
                    _detailRow('State', vendor.state),
                    _detailRow('Country', vendor.country),
                    _detailRow('Zipcode', vendor.zipcode),
                    _detailRow('Address', vendor.address),
                    _detailRow('Google Map', vendor.googleLocation),
                  ],
                ),
              ),
            if (vendor.workDescription.trim().isNotEmpty ||
                vendor.paymentDescription.trim().isNotEmpty ||
                vendor.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              _EntityCardFrame(
                padding: const EdgeInsets.all(18),
                radius: 24,
                shadowColor: const Color(0x0D0F172A),
                shadowBlur: 14,
                shadowOffset: const Offset(0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'More Details',
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _detailRow('Work', vendor.workDescription),
                    _detailRow('Plan', vendor.planName),
                    _detailRow('Membership', vendor.membershipPlan),
                    _detailRow('Payment Amt', vendor.paymentAmount),
                    _detailRow('Payment Due', vendor.paymentDueDate),
                    _detailRow('Payment Mode', vendor.paymentMode),
                    _detailRow('Bank Name', vendor.bankName),
                    _detailRow('Transaction', vendor.transactionId),
                    _detailRow('Payment Note', vendor.paymentDescription),
                    _detailRow('GST', vendor.gstNumber),
                    _detailRow('Opening Time', vendor.openingTime),
                    _detailRow('Closing Time', vendor.closingTime),
                    _detailRow(
                      'Restaurant',
                      vendor.isRestaurant == null
                          ? ''
                          : (vendor.isRestaurant! ? 'Yes' : 'No'),
                    ),
                    _detailRow('Start Date', vendor.onboardingStartDate),
                    _detailRow('End Date', vendor.onboardingEndDate),
                    _detailRow('Status', vendor.registrationStatus),
                  ],
                ),
              ),
            ],
            if (profileLinks.isNotEmpty) ...[
              const SizedBox(height: 18),
              _EntityCardFrame(
                padding: const EdgeInsets.all(18),
                radius: 24,
                shadowColor: const Color(0x0D0F172A),
                shadowBlur: 14,
                shadowOffset: const Offset(0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saved Links',
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...profileLinks.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _openExternalLink(entry.$2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.link_rounded,
                                color: Color(0xFF7C3AED),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.$1,
                                  style: const TextStyle(
                                    color: Color(0xFF171717),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (assetCards.isNotEmpty) ...[
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 820) {
                    return GridView.builder(
                      itemCount: assetCards.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 330,
                          ),
                      itemBuilder: (context, index) => assetCards[index],
                    );
                  }
                  return Column(
                    children: [
                      for (
                        var index = 0;
                        index < assetCards.length;
                        index++
                      ) ...[
                        assetCards[index],
                        if (index != assetCards.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VendorAvatar extends StatelessWidget {
  const _VendorAvatar({required this.vendor, required this.size});

  final DashboardVendorItem vendor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = vendor.avatarUrl.trim();
    final label = vendor.displayName.trim().isEmpty ? 'V' : vendor.displayName;
    final initials = label.trim().isEmpty ? 'V' : label.trim()[0].toUpperCase();

    if (avatarUrl.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: _BackendImage(
            imageUrl: avatarUrl,
            fit: BoxFit.cover,
            fallback: _VendorAvatarFallback(initials: initials, size: size),
          ),
        ),
      );
    }

    return _VendorAvatarFallback(initials: initials, size: size);
  }
}

class _VendorAvatarFallback extends StatelessWidget {
  const _VendorAvatarFallback({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BannerFallbackCard extends StatelessWidget {
  const _BannerFallbackCard({required this.item});

  final DashboardAppBannerItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDC2626), Color(0xFFF59E0B)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            item.vendorName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineStackFeed extends ConsumerWidget {
  const _TimelineStackFeed({required this.posts});

  final List<DashboardTimelineItem> posts;

  Future<void> _openExternalLink(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  DashboardVendorItem? _resolveLinkedVendor(
    List<DashboardVendorItem> vendors,
    DashboardTimelineItem post,
  ) {
    final sourceId = post.sourceId.trim();
    if (sourceId.isNotEmpty) {
      final idMatch =
          vendors.where((vendor) => vendor.id.trim() == sourceId).firstOrNull;
      if (idMatch != null) {
        return idMatch;
      }
    }

    final normalizedSourceName = post.sourceName.trim().toLowerCase();
    if (normalizedSourceName.isEmpty) {
      return null;
    }

    return vendors.where((vendor) {
      final displayName = vendor.displayName.trim().toLowerCase();
      final companyName = vendor.companyName.trim().toLowerCase();
      final contactPerson = vendor.contactPerson.trim().toLowerCase();
      return displayName == normalizedSourceName ||
          companyName == normalizedSourceName ||
          contactPerson == normalizedSourceName;
    }).firstOrNull;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(vendorDirectoryProvider).valueOrNull ?? const [];
    if (posts.isEmpty) {
      return const _EmptyStateCard(
        title: 'No timeline posts yet',
        subtitle:
            'Approved vendor timeline posts from the backend will appear here as the community feed.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _TimelineStackCard(
              post: post,
              linkedVendor:
                  post.sourceType.trim().toUpperCase() == 'VENDOR'
                      ? _resolveLinkedVendor(vendors, post)
                      : null,
              onOpenExternalLink: _openExternalLink,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineStackCard extends StatelessWidget {
  const _TimelineStackCard({
    required this.post,
    required this.linkedVendor,
    required this.onOpenExternalLink,
  });

  final DashboardTimelineItem post;
  final DashboardVendorItem? linkedVendor;
  final Future<void> Function(String) onOpenExternalLink;

  Color get _headerStartColor => switch (post.sourceType.toUpperCase()) {
    'MEMBER' => const Color(0xFF15803D),
    'VENDOR' => const Color(0xFFEA580C),
    _ => const Color(0xFF2563EB),
  };

  Color get _headerEndColor => switch (post.sourceType.toUpperCase()) {
    'MEMBER' => const Color(0xFF16A34A),
    'VENDOR' => const Color(0xFFF59E0B),
    _ => const Color(0xFF1D4ED8),
  };

  @override
  Widget build(BuildContext context) {
    void openVendorProfileIfAvailable() {
      final vendor = linkedVendor;
      if (vendor == null) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _VendorProfileScreen(vendor: vendor),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap:
                post.sourceType.trim().toUpperCase() == 'VENDOR' &&
                        linkedVendor != null
                    ? openVendorProfileIfAvailable
                    : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_headerStartColor, _headerEndColor],
                ),
              ),
              child: Row(
                children: [
                  _TimelinePosterAvatar(
                    name: post.sourceName,
                    color: _headerStartColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          post.postedBy.trim().isEmpty
                              ? post.postedOn
                              : '${post.postedBy} • ${post.postedOn}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.caption,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
                if (post.imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _BackendImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        fallback: const ColoredBox(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    if (post.landingPageUrl.isNotEmpty)
                      _TimelineIconButton(
                        icon: Icons.language_rounded,
                        onTap: () => onOpenExternalLink(post.landingPageUrl),
                      ),
                    if (post.youtubeUrl.isNotEmpty)
                      _TimelineIconButton(
                        icon: Icons.play_arrow_rounded,
                        onTap: () => onOpenExternalLink(post.youtubeUrl),
                      ),
                    if (post.facebookUrl.isNotEmpty)
                      _TimelineIconButton(
                        icon: Icons.thumb_up_alt_rounded,
                        onTap: () => onOpenExternalLink(post.facebookUrl),
                      ),
                    if (post.contactNumber.isNotEmpty)
                      _TimelineIconButton(
                        icon: Icons.call_rounded,
                        onTap:
                            () => _showPhoneActionsSheet(
                              context,
                              title: post.sourceName,
                              phoneNumber: post.contactNumber,
                            ),
                      ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePosterAvatar extends StatelessWidget {
  const _TimelinePosterAvatar({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = name.trim().isEmpty ? 'T' : name.trim()[0].toUpperCase();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TimelineIconButton extends StatelessWidget {
  const _TimelineIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _TimelineLinkChip extends StatelessWidget {
  const _TimelineLinkChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF171717),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      backgroundColor: Colors.white,
    );
  }
}

class _AssociationGallerySection extends StatefulWidget {
  const _AssociationGallerySection({
    required this.canManage,
    required this.associationId,
    required this.folders,
    required this.activeFolderId,
    required this.isSaving,
    required this.onAddFolder,
    required this.onOpenFolder,
    required this.onRenameFolder,
    required this.onDeleteFolder,
    required this.onDeletePhoto,
  });

  final bool canManage;
  final String associationId;
  final List<AssociationGalleryFolder> folders;
  final String activeFolderId;
  final bool isSaving;
  final VoidCallback onAddFolder;
  final ValueChanged<String> onOpenFolder;
  final ValueChanged<AssociationGalleryFolder> onRenameFolder;
  final ValueChanged<AssociationGalleryFolder> onDeleteFolder;
  final void Function(String folderId, String photoId) onDeletePhoto;

  @override
  State<_AssociationGallerySection> createState() =>
      _AssociationGallerySectionState();
}

class _AssociationGallerySectionState
    extends State<_AssociationGallerySection> {
  static const int _folderPageSize = 12;
  static const int _photoPageSize = 24;

  int _visibleFolderCount = _folderPageSize;
  int _visiblePhotoCount = _photoPageSize;

  void _openGalleryImage(BuildContext context, AssociationGalleryPhoto item) {
    final resolvedUrl = _resolveBackendAssetUrl(item.imageUrl);
    final imageBytes = _decodeImageBytes(item.imageUrl);
    if (resolvedUrl.isEmpty && imageBytes == null) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: _BackendImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.contain,
                    fallback: Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Could not load this gallery image.',
                          style: TextStyle(
                            color: Color(0xFF171717),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: SafeArea(
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant _AssociationGallerySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folders != widget.folders) {
      _visibleFolderCount = _folderPageSize;
      _visiblePhotoCount = _photoPageSize;
    } else if (oldWidget.activeFolderId != widget.activeFolderId) {
      _visiblePhotoCount = _photoPageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final folders = widget.folders;
    final activeFolder = folders.firstWhere(
      (folder) => folder.id == widget.activeFolderId,
      orElse:
          () => const AssociationGalleryFolder(
            id: '',
            name: '',
            createdAt: '',
            updatedAt: '',
            photoCount: 0,
            previewPhotos: [],
            photos: [],
          ),
    );
    final visibleFolders = folders.take(_visibleFolderCount).toList();
    final hasMoreFolders = visibleFolders.length < folders.length;
    final visiblePhotos = activeFolder.photos.take(_visiblePhotoCount).toList();
    final hasMorePhotos = visiblePhotos.length < activeFolder.photos.length;

    if (folders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.canManage) ...[
            Row(
              children: [
                FilledButton.icon(
                  onPressed:
                      widget.isSaving || widget.associationId.isEmpty
                          ? null
                          : widget.onAddFolder,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(widget.isSaving ? 'Uploading...' : 'Add Folder'),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          const _EmptyStateCard(
            title: 'No gallery folders yet',
            subtitle:
                'Create a folder and upload photos to start organizing the association gallery.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${folders.length} folders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF171717),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (widget.canManage) ...[
              OutlinedButton.icon(
                onPressed: widget.isSaving ? null : widget.onAddFolder,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(widget.isSaving ? 'Uploading...' : 'Add Folder'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleFolders.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.74,
          ),
          itemBuilder: (context, index) {
            final item = visibleFolders[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Material(
                color: Colors.white.withValues(alpha: 0.72),
                child: InkWell(
                  onTap: () => widget.onOpenFolder(item.id),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: GridView.count(
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                children:
                                    item.previewPhotos.isEmpty
                                        ? [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        ]
                                        : item.previewPhotos
                                            .take(4)
                                            .map<Widget>(
                                              (photo) => ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: _BackendImage(
                                                  imageUrl: photo.thumbnailUrl,
                                                  fit: BoxFit.cover,
                                                  fallback: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFFF3F4F6,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF171717),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (item.createdDateLabel.isNotEmpty) ...[
                                  Text(
                                    item.createdDateLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                Text(
                                  '${item.photoCount} photo${item.photoCount == 1 ? '' : 's'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.canManage)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                widget.onRenameFolder(item);
                              } else if (value == 'delete') {
                                widget.onDeleteFolder(item);
                              }
                            },
                            itemBuilder:
                                (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Rename folder'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete folder'),
                                  ),
                                ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (hasMoreFolders) ...[
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _visibleFolderCount = (_visibleFolderCount + _folderPageSize)
                      .clamp(_folderPageSize, folders.length);
                });
              },
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(
                'Load more folders (${folders.length - visibleFolders.length} remaining)',
              ),
            ),
          ),
        ],
        if (activeFolder.id.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            activeFolder.displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF171717),
            ),
          ),
          if (activeFolder.createdDateLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              activeFolder.createdDateLabel,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visiblePhotos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.74,
            ),
            itemBuilder: (context, index) {
              final photo = visiblePhotos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () => _openGalleryImage(context, photo),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _BackendImage(
                                imageUrl: photo.imageUrl,
                                fit: BoxFit.cover,
                                fallback: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF3F4F6),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                photo.createdDateLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.canManage)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              onPressed:
                                  widget.isSaving
                                      ? null
                                      : () => widget.onDeletePhoto(
                                        activeFolder.id,
                                        photo.id,
                                      ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (hasMorePhotos) ...[
            const SizedBox(height: 10),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _visiblePhotoCount = (_visiblePhotoCount + _photoPageSize)
                        .clamp(_photoPageSize, activeFolder.photos.length);
                  });
                },
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  'Load more photos (${activeFolder.photos.length - visiblePhotos.length} remaining)',
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _DashboardCommitteeCarousel extends StatelessWidget {
  const _DashboardCommitteeCarousel({
    required this.members,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<MemberDirectoryItem> members;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const _EmptyStateCard(
        title: 'No committee members found',
        subtitle:
            'Committee members will appear here once the association has published them.',
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.vertical;
    final textScaleFactor = mediaQuery.textScaler.scale(1);
    final viewportWidth =
        mediaQuery.size.width * pageController.viewportFraction;
    final isCompactViewport = viewportWidth < 348 || textScaleFactor > 1.0;
    final maxPanelHeight =
        (availableHeight * 0.54).clamp(428.0, 470.0).toDouble();
    final panelHeight =
        (isCompactViewport
                ? 382.0 + ((textScaleFactor - 1).clamp(0.0, 0.25) * 28)
                : viewportWidth * 1.14)
            .clamp(378.0, maxPanelHeight)
            .toDouble();
    final heroHeight =
        (isCompactViewport ? 98.0 : viewportWidth * 0.34)
            .clamp(96.0, 144.0)
            .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Management Committee',
          subtitle:
              'Swipe through the current committee lineup from the backend-linked member records.',
          titleColor: Color(0xFF0F766E),
          showAccent: true,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: panelHeight,
          child: PageView.builder(
            controller: pageController,
            itemCount: members.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == members.length - 1 ? 0 : 12,
                ),
                child: _DashboardCommitteeCard(
                  member: members[index],
                  heroHeight: heroHeight,
                  summaryMaxLines: isCompactViewport ? 1 : 2,
                  compactLayout: isCompactViewport,
                ),
              );
            },
          ),
        ),
        if (members.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              members.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      currentPage == index
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DashboardCommitteeCard extends StatelessWidget {
  const _DashboardCommitteeCard({
    required this.member,
    required this.heroHeight,
    required this.summaryMaxLines,
    required this.compactLayout,
  });

  final MemberDirectoryItem member;
  final double heroHeight;
  final int summaryMaxLines;
  final bool compactLayout;

  @override
  Widget build(BuildContext context) {
    final memberNotes =
        member.memberBio.isNotEmpty
            ? member.memberBio
            : member.membershipDetails;
    final tenureLabel =
        member.committeeTenureStart.isNotEmpty ||
                member.committeeTenureEnd.isNotEmpty
            ? '${member.committeeTenureStart.isEmpty ? 'Now' : member.committeeTenureStart} to ${member.committeeTenureEnd.isEmpty ? 'Ongoing' : member.committeeTenureEnd}'
            : '';

    return _ReusableMemberCard(
      name: member.name,
      photoUrl: member.photoUrl,
      primaryLabel: member.companyName,
      summary: memberNotes,
      showHeroImage: true,
      useCircularHeroAvatar: true,
      heroHeight: heroHeight,
      summaryMaxLines: summaryMaxLines,
      padding:
          compactLayout
              ? const EdgeInsets.fromLTRB(12, 12, 12, 10)
              : const EdgeInsets.fromLTRB(14, 14, 14, 12),
      heroBottomSpacing: compactLayout ? 8 : 10,
      sectionSpacing: compactLayout ? 8 : 10,
      detailsTopSpacing: compactLayout ? 10 : 12,
      detailsDividerSpacing: compactLayout ? 8 : 10,
      detailLineSpacing: compactLayout ? 6 : 8,
      factPills: [
        _DirectoryRolePill(
          label:
              member.committeePost.isNotEmpty
                  ? member.committeePost
                  : 'Committee Member',
        ),
        if (tenureLabel.isNotEmpty && !compactLayout)
          _DirectoryFactPill(
            icon: Icons.calendar_today_rounded,
            label: tenureLabel,
          ),
      ],
      detailLines: [
        if (tenureLabel.isNotEmpty && compactLayout)
          _DirectoryDetailLine(
            icon: Icons.calendar_today_rounded,
            label: tenureLabel,
            maxLines: 2,
          ),
        if (member.email.isNotEmpty)
          _DirectoryDetailLine(
            icon: Icons.mail_outline_rounded,
            label: member.email,
            onTap: () => _openEmailComposer(member.email),
          ),
        if (member.phone.isNotEmpty)
          _DirectoryDetailLine(
            icon: Icons.call_outlined,
            label: member.phone,
            onTap:
                () => _showPhoneActionsSheet(
                  context,
                  title: member.name,
                  phoneNumber: member.phone,
                ),
          ),
      ],
    );
  }
}

class _AdminSummaryBanner extends StatelessWidget {
  const _AdminSummaryBanner({
    required this.memberCount,
    required this.postCount,
    required this.eventCount,
  });

  final int memberCount;
  final int postCount;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$memberCount members, $postCount content items, and $eventCount events are loaded from the backend for admin review.',
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssociationProfileView extends StatelessWidget {
  const _AssociationProfileView({
    required this.profile,
    this.onEdit,
    required this.onNavigateToAssociation,
  });

  final AssociationProfileData profile;
  final VoidCallback? onEdit;
  final VoidCallback onNavigateToAssociation;

  @override
  Widget build(BuildContext context) {
    final cityLine = [
      profile.city,
      profile.state,
      profile.pincode,
    ].where((part) => part.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssociationProfileHero(
          associationName:
              profile.name.isEmpty ? 'Association Profile' : profile.name,
          cityLine: cityLine,
        ),
        const SizedBox(height: 14),
        _AssociationBreadcrumb(
          currentLabel: 'Profile',
          onRootTap: onNavigateToAssociation,
        ),
        const SizedBox(height: 18),
        const _SectionHeader(
          title: 'Association Profile',
          subtitle: 'Head Office',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.name.isEmpty
                          ? 'Association Profile'
                          : profile.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    FilledButton(
                      onPressed: onEdit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF171717),
                      ),
                      child: const Text('Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _AssociationInfoTile(
                    label: 'Head Office Address',
                    value: profile.headOfficeAddress,
                    wide: true,
                  ),
                  _AssociationInfoTile(
                    label: 'City, State with Pincode',
                    value: [
                      profile.city,
                      profile.state,
                      profile.pincode,
                    ].where((part) => part.isNotEmpty).join(', '),
                  ),
                  _AssociationInfoTile(
                    label: 'Registration Number',
                    value: profile.registrationNumber,
                  ),
                  _AssociationInfoTile(
                    label: 'GST Number',
                    value: profile.gstNumber,
                  ),
                  _AssociationInfoTile(
                    label: 'Website',
                    value: profile.website,
                  ),
                  _AssociationInfoTile(
                    label: 'Helpdesk Number',
                    value: profile.helpdeskNumber,
                  ),
                  _AssociationInfoTile(
                    label: 'Contact Numbers',
                    value: profile.contactNumbersLabel,
                    wide: true,
                  ),
                  _AssociationMapTile(
                    label: 'Google Map Access Location',
                    value: profile.googleMapsLink,
                    locationQuery: [
                      profile.name,
                      profile.headOfficeAddress,
                      profile.city,
                      profile.state,
                      profile.pincode,
                    ].where((part) => part.trim().isNotEmpty).join(', '),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (profile.regionalAddresses.isNotEmpty) ...[
          const SizedBox(height: 18),
          ...profile.regionalAddresses.asMap().entries.map((entry) {
            final index = entry.key;
            final address = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label.isEmpty
                          ? 'Regional Office ${index + 1}'
                          : address.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _AssociationInfoTile(
                          label: 'Office Address',
                          value: address.officeAddress,
                          wide: true,
                        ),
                        _AssociationInfoTile(
                          label: 'City, State with Pincode',
                          value: [
                            address.city,
                            address.state,
                            address.pincode,
                          ].where((part) => part.isNotEmpty).join(', '),
                        ),
                        _AssociationInfoTile(
                          label: 'Registration Number',
                          value: address.registrationNumber,
                        ),
                        _AssociationInfoTile(
                          label: 'GST Number',
                          value: address.gstNumber,
                        ),
                        _AssociationInfoTile(
                          label: 'Website',
                          value: address.website,
                        ),
                        _AssociationInfoTile(
                          label: 'Helpdesk Number',
                          value: address.helpdeskNumber,
                        ),
                        _AssociationInfoTile(
                          label: 'Contact Numbers',
                          value: address.contactNumbersLabel,
                          wide: true,
                        ),
                        _AssociationMapTile(
                          label: 'Google Map Access Location',
                          value: address.googleMapsLink,
                          locationQuery: [
                            address.label,
                            address.officeAddress,
                            address.city,
                            address.state,
                            address.pincode,
                          ].where((part) => part.trim().isNotEmpty).join(', '),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _AssociationProfileHero extends StatelessWidget {
  const _AssociationProfileHero({
    required this.associationName,
    required this.cityLine,
  });

  final String associationName;
  final String cityLine;

  @override
  Widget build(BuildContext context) {
    return _AssociationSectionHero(
      titleSpans: [
        const TextSpan(text: 'Welcome to '),
        TextSpan(
          text: associationName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        if (cityLine.isNotEmpty) ...[
          const TextSpan(text: ' in '),
          TextSpan(
            text: cityLine,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
        const TextSpan(text: '.'),
      ],
    );
  }
}

String _formatCurrentDateTime() {
  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final now = DateTime.now();
  final month = monthNames[now.month - 1];
  final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
  final minute = now.minute.toString().padLeft(2, '0');
  final suffix = now.hour >= 12 ? 'PM' : 'AM';
  return '${now.day} $month ${now.year} • $hour:$minute $suffix';
}

String _resolveBackendAssetUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final parsed = Uri.tryParse(trimmed);
  final apiBase = Uri.parse('https://app.operisaverick.com/api');
  final backendOrigin = Uri(
    scheme: apiBase.scheme,
    host: apiBase.host,
    port: apiBase.hasPort ? apiBase.port : null,
  );

  if (parsed == null) {
    return backendOrigin.resolve(trimmed).toString();
  }

  if (!parsed.hasScheme) {
    return backendOrigin.resolveUri(parsed).toString();
  }

  if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
    return backendOrigin
        .resolveUri(Uri(path: parsed.path, query: parsed.query))
        .toString();
  }

  if ((parsed.scheme == 'http' || parsed.scheme == 'https') &&
      parsed.host == backendOrigin.host) {
    return backendOrigin
        .replace(path: parsed.path, query: parsed.query)
        .toString();
  }

  return parsed.toString();
}

Uint8List? _decodeImageBytes(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed == null || parsed.scheme != 'data') {
    return null;
  }

  try {
    return UriData.parse(trimmed).contentAsBytes();
  } catch (_) {
    return null;
  }
}

class _BackendImage extends StatelessWidget {
  const _BackendImage({
    required this.imageUrl,
    required this.fit,
    required this.fallback,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeImageBytes(imageUrl);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final resolvedUrl = _resolveBackendAssetUrl(imageUrl);
    if (resolvedUrl.isEmpty) {
      return fallback;
    }

    return Image.network(
      resolvedUrl,
      fit: fit,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _AssociationProfileEditor extends StatelessWidget {
  const _AssociationProfileEditor({
    required this.draft,
    required this.isSaving,
    required this.onChanged,
    required this.onAddRegionalAddress,
    required this.onRemoveRegionalAddress,
    required this.onSave,
    required this.onCancel,
  });

  final AssociationProfileDraft draft;
  final bool isSaving;
  final ValueChanged<AssociationProfileDraft> onChanged;
  final VoidCallback onAddRegionalAddress;
  final ValueChanged<int> onRemoveRegionalAddress;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Edit Association Profile',
          subtitle:
              'Update the same fields used in the web profile screen, including regional offices.',
        ),
        const SizedBox(height: 14),
        if (draft.validationMessage != null) ...[
          _EmptyStateCard(
            title: 'Complete the required association details',
            subtitle: draft.validationMessage!,
          ),
          const SizedBox(height: 14),
        ],
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              _AssociationTextField(
                label: 'Association Name',
                value: draft.name,
                onChanged: (value) => onChanged(draft.copyWith(name: value)),
              ),
              _AssociationTextField(
                label: 'Registration Number',
                value: draft.registrationNumber,
                onChanged:
                    (value) =>
                        onChanged(draft.copyWith(registrationNumber: value)),
              ),
              _AssociationTextField(
                label: 'Head Office Address',
                value: draft.headOfficeAddress,
                maxLines: 3,
                onChanged:
                    (value) =>
                        onChanged(draft.copyWith(headOfficeAddress: value)),
              ),
              _AssociationTextField(
                label: 'City',
                value: draft.city,
                onChanged: (value) => onChanged(draft.copyWith(city: value)),
              ),
              _AssociationTextField(
                label: 'State',
                value: draft.state,
                onChanged: (value) => onChanged(draft.copyWith(state: value)),
              ),
              _AssociationTextField(
                label: 'Pincode',
                value: draft.pincode,
                onChanged: (value) => onChanged(draft.copyWith(pincode: value)),
              ),
              _AssociationTextField(
                label: 'GST Number',
                value: draft.gstNumber,
                onChanged:
                    (value) => onChanged(draft.copyWith(gstNumber: value)),
              ),
              _AssociationTextField(
                label: 'Website',
                value: draft.website,
                onChanged: (value) => onChanged(draft.copyWith(website: value)),
              ),
              _AssociationTextField(
                label: 'Helpdesk Number',
                value: draft.helpdeskNumber,
                onChanged:
                    (value) => onChanged(draft.copyWith(helpdeskNumber: value)),
              ),
              _AssociationTextField(
                label: 'Contact Numbers',
                value: draft.contactNumbers,
                onChanged:
                    (value) => onChanged(draft.copyWith(contactNumbers: value)),
              ),
              _AssociationTextField(
                label: 'Google Map Access Location',
                value: draft.googleMapsLink,
                onChanged:
                    (value) => onChanged(draft.copyWith(googleMapsLink: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text(
              'Regional Address List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: onAddRegionalAddress,
              child: const Text('Add Regional Address'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...draft.regionalAddresses.asMap().entries.map((entry) {
          final index = entry.key;
          final address = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label.isEmpty
                            ? 'Regional Office ${index + 1}'
                            : address.label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => onRemoveRegionalAddress(index),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AssociationTextField(
                    label: 'Label',
                    value: address.label,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(label: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Registration Number',
                    value: address.registrationNumber,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(registrationNumber: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Office Address',
                    value: address.officeAddress,
                    maxLines: 3,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(officeAddress: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'City',
                    value: address.city,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(city: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'State',
                    value: address.state,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(state: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Pincode',
                    value: address.pincode,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(pincode: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'GST Number',
                    value: address.gstNumber,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(gstNumber: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Website',
                    value: address.website,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(website: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Helpdesk Number',
                    value: address.helpdeskNumber,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(helpdeskNumber: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Contact Numbers',
                    value: address.contactNumbers,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(contactNumbers: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Google Map Access Location',
                    value: address.googleMapsLink,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(googleMapsLink: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: isSaving || !draft.canSubmit ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
              ),
              child: Text(isSaving ? 'Saving...' : 'Save Profile'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AssociationAboutView extends StatelessWidget {
  const _AssociationAboutView({
    required this.about,
    this.onEdit,
    required this.onNavigateToAssociation,
  });

  final AssociationAboutData about;
  final VoidCallback? onEdit;
  final VoidCallback onNavigateToAssociation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssociationAboutHero(
          heroTitle: about.heroTitle.isEmpty ? 'About Us' : about.heroTitle,
        ),
        const SizedBox(height: 14),
        _AssociationBreadcrumb(
          currentLabel: 'About Us',
          onRootTap: onNavigateToAssociation,
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'About Us', subtitle: 'About Us'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      about.heroTitle.isEmpty ? 'About Us' : about.heroTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    FilledButton(
                      onPressed: onEdit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF171717),
                      ),
                      child: const Text('Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _AssociationInfoTile(
                label: 'Hero Intro',
                value: about.heroIntro,
                wide: true,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _AssociationInfoTile(
                    label: 'Mission Title',
                    value: about.missionTitle,
                  ),
                  _AssociationInfoTile(
                    label: 'Goals Title',
                    value: about.goalsTitle,
                  ),
                  _AssociationInfoTile(
                    label: 'Journey Title',
                    value: about.journeyTitle,
                  ),
                  _AssociationInfoTile(
                    label: 'Mission Text',
                    value: about.missionText,
                    wide: true,
                  ),
                  _AssociationInfoTile(
                    label: 'Goals Text',
                    value: about.goalsText,
                    wide: true,
                  ),
                  _AssociationInfoTile(
                    label: 'Journey Text',
                    value: about.journeyText,
                    wide: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssociationAboutHero extends StatelessWidget {
  const _AssociationAboutHero({required this.heroTitle});

  final String heroTitle;

  @override
  Widget build(BuildContext context) {
    return _AssociationSectionHero(
      titleSpans: [
        const TextSpan(text: 'About '),
        TextSpan(
          text: heroTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _AssociationSectionHero extends StatelessWidget {
  const _AssociationSectionHero({
    this.title,
    this.titleSpans,
    this.arenaLabel = 'Association',
    this.footer,
  }) : assert(title != null || titleSpans != null);

  final String? title;
  final List<InlineSpan>? titleSpans;
  final String arenaLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332D106B),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arenaLabel,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w500,
                height: 1.08,
              ),
              children:
                  titleSpans ??
                  [
                    TextSpan(
                      text: title!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
            ),
          ),
          const SizedBox(height: 12),
          footer ??
              Text(
                _formatCurrentDateTime(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                  height: 1.45,
                ),
              ),
        ],
      ),
    );
  }
}

class _ArenaBreadcrumb extends StatelessWidget {
  const _ArenaBreadcrumb({
    required this.rootLabel,
    required this.currentLabel,
    required this.onRootTap,
  });

  final String rootLabel;
  final String currentLabel;
  final VoidCallback onRootTap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF6B7280),
      fontWeight: FontWeight.w600,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: onRootTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6B7280),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(rootLabel, style: baseStyle),
        ),
        Text(' / ', style: baseStyle?.copyWith(color: const Color(0xFFD1D5DB))),
        Text(
          currentLabel,
          style: const TextStyle(
            color: Color(0xFF171717),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AssociationBreadcrumb extends StatelessWidget {
  const _AssociationBreadcrumb({
    required this.currentLabel,
    required this.onRootTap,
  });

  final String currentLabel;
  final VoidCallback onRootTap;

  @override
  Widget build(BuildContext context) {
    return _ArenaBreadcrumb(
      rootLabel: 'Association',
      currentLabel: currentLabel,
      onRootTap: onRootTap,
    );
  }
}

class _VendorAdminSectionView extends StatelessWidget {
  const _VendorAdminSectionView({
    required this.currentLabel,
    required this.onNavigateToVendorArena,
    required this.child,
  });

  final String currentLabel;
  final VoidCallback onNavigateToVendorArena;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssociationSectionHero(title: currentLabel, arenaLabel: 'Vendor'),
        const SizedBox(height: 14),
        _ArenaBreadcrumb(
          rootLabel: 'Vendor',
          currentLabel: currentLabel,
          onRootTap: onNavigateToVendorArena,
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _AssociationAboutEditor extends StatelessWidget {
  const _AssociationAboutEditor({
    required this.draft,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  final AssociationAboutDraft draft;
  final bool isSaving;
  final ValueChanged<AssociationAboutDraft> onChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Edit About Us',
          subtitle:
              'Update the same backend-driven landing page content used in the web app.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              _AssociationTextField(
                label: 'Hero Title',
                value: draft.heroTitle,
                onChanged:
                    (value) => onChanged(draft.copyWith(heroTitle: value)),
              ),
              _AssociationTextField(
                label: 'Hero Intro',
                value: draft.heroIntro,
                maxLines: 3,
                onChanged:
                    (value) => onChanged(draft.copyWith(heroIntro: value)),
              ),
              _AssociationTextField(
                label: 'Mission Title',
                value: draft.missionTitle,
                onChanged:
                    (value) => onChanged(draft.copyWith(missionTitle: value)),
              ),
              _AssociationTextField(
                label: 'Mission Text',
                value: draft.missionText,
                maxLines: 4,
                onChanged:
                    (value) => onChanged(draft.copyWith(missionText: value)),
              ),
              _AssociationTextField(
                label: 'Goals Title',
                value: draft.goalsTitle,
                onChanged:
                    (value) => onChanged(draft.copyWith(goalsTitle: value)),
              ),
              _AssociationTextField(
                label: 'Goals Text',
                value: draft.goalsText,
                maxLines: 4,
                onChanged:
                    (value) => onChanged(draft.copyWith(goalsText: value)),
              ),
              _AssociationTextField(
                label: 'Journey Title',
                value: draft.journeyTitle,
                onChanged:
                    (value) => onChanged(draft.copyWith(journeyTitle: value)),
              ),
              _AssociationTextField(
                label: 'Journey Text',
                value: draft.journeyText,
                maxLines: 4,
                onChanged:
                    (value) => onChanged(draft.copyWith(journeyText: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: isSaving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
              ),
              child: Text(isSaving ? 'Saving...' : 'Save About Us'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AssociationCommitteeView extends StatefulWidget {
  const _AssociationCommitteeView({
    required this.canManage,
    required this.allMembers,
    required this.members,
    required this.isSaving,
    required this.committeePosts,
    required this.onNavigateToAssociation,
    required this.onAssignCommitteeMember,
    required this.onRemoveCommitteeMember,
  });

  final bool canManage;
  final List<MemberDirectoryItem> allMembers;
  final List<MemberDirectoryItem> members;
  final bool isSaving;
  final List<String> committeePosts;
  final VoidCallback onNavigateToAssociation;
  final Future<void> Function(MemberDirectoryItem member, String committeePost)
  onAssignCommitteeMember;
  final Future<void> Function(MemberDirectoryItem member)
  onRemoveCommitteeMember;

  @override
  State<_AssociationCommitteeView> createState() =>
      _AssociationCommitteeViewState();
}

class _AssociationCommitteeViewState extends State<_AssociationCommitteeView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isManaging = false;
  String _query = '';
  String? _selectedPost;
  MemberDirectoryItem? _selectedMember;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleManageMode() {
    setState(() {
      _isManaging = !_isManaging;
      if (!_isManaging) {
        _selectedMember = null;
        _selectedPost = null;
        _query = '';
        _searchController.clear();
      }
    });
  }

  void _selectMember(MemberDirectoryItem member) {
    setState(() {
      _selectedMember = member;
      _selectedPost =
          member.committeePost.trim().isNotEmpty ? member.committeePost : null;
    });
  }

  Future<void> _submitAssignment() async {
    if (_selectedMember == null || _selectedPost == null) {
      return;
    }
    await widget.onAssignCommitteeMember(_selectedMember!, _selectedPost!);
    if (!mounted) return;
    setState(() {
      _selectedMember = null;
      _selectedPost = null;
      _query = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.members.isEmpty && !widget.canManage) {
      return const _EmptyStateCard(
        title: 'No committee members found',
        subtitle:
            'Committee members will appear here once the association has published them.',
      );
    }

    final filteredMembers =
        widget.allMembers.where((member) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) {
            return member.committeePost.trim().isEmpty;
          }
          return [
            member.name,
            member.companyName,
            member.email,
            member.phone,
          ].any((value) => value.trim().toLowerCase().contains(query));
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AssociationSectionHero(title: 'Management Committee'),
        const SizedBox(height: 14),
        _AssociationBreadcrumb(
          currentLabel: 'Management Committee',
          onRootTap: widget.onNavigateToAssociation,
        ),
        const SizedBox(height: 18),
        const _SectionHeader(
          title: 'Management Committee',
          subtitle: 'Management Committee',
        ),
        if (widget.canManage) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.isSaving ? null : _toggleManageMode,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
              ),
              icon: Icon(
                _isManaging ? Icons.close_rounded : Icons.edit_rounded,
              ),
              label: Text(
                _isManaging
                    ? 'Close Committee Manager'
                    : 'Modify Committee Members',
              ),
            ),
          ),
          if (_isManaging) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Or Update Committee Member',
                    style: TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Search an existing association member, pick one committee post, and add them to the management committee.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded),
                        hintText:
                            'Search member by name, company, phone, or email',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_selectedMember != null) ...[
                    _AssociationCommitteeSelectionCard(
                      member: _selectedMember!,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value:
                          _selectedPost != null &&
                                  widget.committeePosts.contains(_selectedPost)
                              ? _selectedPost
                              : null,
                      decoration: InputDecoration(
                        labelText: 'Committee Post',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      items:
                          widget.committeePosts
                              .map(
                                (post) => DropdownMenuItem<String>(
                                  value: post,
                                  child: Text(post),
                                ),
                              )
                              .toList(),
                      onChanged:
                          widget.isSaving
                              ? null
                              : (value) =>
                                  setState(() => _selectedPost = value),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed:
                            widget.isSaving ||
                                    _selectedMember == null ||
                                    _selectedPost == null
                                ? null
                                : _submitAssignment,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF171717),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(
                          _selectedMember!.committeePost.trim().isNotEmpty
                              ? 'Update Committee Post'
                              : 'Add To Committee',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  const Text(
                    'Matching Members',
                    style: TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (filteredMembers.isEmpty)
                    const Text(
                      'No matching association members found.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    ...filteredMembers
                        .take(8)
                        .map(
                          (member) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AssociationCommitteeSelectionCard(
                              member: member,
                              selected: _selectedMember?.id == member.id,
                              onTap:
                                  widget.isSaving
                                      ? null
                                      : () => _selectMember(member),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 14),
        ...widget.members.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _AssociationCommitteeCard(
              member: member,
              showRemoveAction: widget.canManage && _isManaging,
              isSaving: widget.isSaving,
              onRemove:
                  widget.canManage
                      ? () => widget.onRemoveCommitteeMember(member)
                      : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssociationCommitteeCard extends StatelessWidget {
  const _AssociationCommitteeCard({
    required this.member,
    this.showRemoveAction = false,
    this.isSaving = false,
    this.onRemove,
  });

  final MemberDirectoryItem member;
  final bool showRemoveAction;
  final bool isSaving;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final memberNotes =
        member.memberBio.isNotEmpty
            ? member.memberBio
            : member.membershipDetails;

    return _ReusableMemberCard(
      name: member.name,
      photoUrl: member.photoUrl,
      primaryLabel: member.companyName,
      summary: memberNotes,
      showHeroImage: true,
      heroHeight: 180,
      factPills: [
        _DirectoryRolePill(
          label:
              member.committeePost.isNotEmpty
                  ? member.committeePost
                  : 'Committee Member',
        ),
        if (member.committeeTenureStart.isNotEmpty ||
            member.committeeTenureEnd.isNotEmpty)
          _DirectoryFactPill(
            icon: Icons.calendar_today_rounded,
            label:
                '${member.committeeTenureStart.isEmpty ? 'Now' : member.committeeTenureStart} to ${member.committeeTenureEnd.isEmpty ? 'Ongoing' : member.committeeTenureEnd}',
          ),
      ],
      detailLines: [
        if (member.email.isNotEmpty)
          _DirectoryDetailLine(
            icon: Icons.mail_outline_rounded,
            label: member.email,
            onTap: () => _openEmailComposer(member.email),
          ),
        if (member.phone.isNotEmpty)
          _DirectoryDetailLine(
            icon: Icons.call_outlined,
            label: member.phone,
            onTap:
                () => _showPhoneActionsSheet(
                  context,
                  title: member.name,
                  phoneNumber: member.phone,
                ),
          ),
      ],
      footer:
          showRemoveAction && onRemove != null
              ? Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: isSaving ? null : onRemove,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  label: const Text('Remove Member'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                  ),
                ),
              )
              : null,
    );
  }
}

class _AssociationCommitteeSelectionCard extends StatelessWidget {
  const _AssociationCommitteeSelectionCard({
    required this.member,
    this.selected = false,
    this.onTap,
  });

  final MemberDirectoryItem member;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  selected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              _MemberAvatar(
                name: member.name,
                photoUrl: member.photoUrl,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.companyName.isEmpty
                          ? 'No company added'
                          : member.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6D28D9),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (member.committeePost.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Current committee post: ${member.committeePost}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF7C3AED),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommitteeThumbnail extends StatelessWidget {
  const _CommitteeThumbnail({required this.name, required this.photoUrl});

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final initials =
        name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child:
            photoUrl.isNotEmpty
                ? _BackendImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.contain,
                  fallback: _CommitteeThumbnailFallback(initials: initials),
                )
                : _CommitteeThumbnailFallback(initials: initials),
      ),
    );
  }
}

class _CommitteeThumbnailFallback extends StatelessWidget {
  const _CommitteeThumbnailFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _AssociationDocumentLibrarySection extends StatefulWidget {
  const _AssociationDocumentLibrarySection({
    required this.moduleLabel,
    required this.headerSubtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.editorTitle,
    required this.saveButtonLabel,
    required this.canManage,
    required this.items,
    required this.draft,
    required this.editingItemId,
    required this.isSaving,
    required this.onOpenEditor,
    required this.onCancelEdit,
    required this.onDraftChanged,
    required this.onPickFile,
    required this.onOpenDocument,
    required this.onSave,
    required this.onDelete,
  });

  final String moduleLabel;
  final String headerSubtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final String editorTitle;
  final String saveButtonLabel;
  final bool canManage;
  final List<AssociationDocumentItem> items;
  final AssociationDocumentDraft? draft;
  final String? editingItemId;
  final bool isSaving;
  final ValueChanged<AssociationDocumentItem?> onOpenEditor;
  final VoidCallback onCancelEdit;
  final ValueChanged<AssociationDocumentDraft> onDraftChanged;
  final Future<void> Function() onPickFile;
  final Future<void> Function(AssociationDocumentItem document) onOpenDocument;
  final Future<void> Function() onSave;
  final Future<void> Function(String documentId) onDelete;

  @override
  State<_AssociationDocumentLibrarySection> createState() =>
      _AssociationDocumentLibrarySectionState();
}

class _AssociationDocumentLibrarySectionState
    extends State<_AssociationDocumentLibrarySection> {
  static const int _pageSize = 20;

  int _visibleCircularCount = _pageSize;

  @override
  void didUpdateWidget(covariant _AssociationDocumentLibrarySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _visibleCircularCount = _pageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visibleItems = items.take(_visibleCircularCount).toList();
    final hasMoreItems = visibleItems.length < items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionHeader(
                title: 'Document Library',
                subtitle: widget.headerSubtitle,
              ),
            ),
            if (widget.canManage) ...[
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => widget.onOpenEditor(null),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF171717),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Add New'),
              ),
            ],
          ],
        ),
        if (widget.canManage && widget.draft != null) ...[
          const SizedBox(height: 16),
          _AssociationCircularEditor(
            editorTitle: widget.editorTitle,
            saveButtonLabel: widget.saveButtonLabel,
            draft: widget.draft!,
            isSaving: widget.isSaving,
            onChanged: widget.onDraftChanged,
            onPickFile: widget.onPickFile,
            onSave: widget.onSave,
            onCancel: widget.onCancelEdit,
          ),
        ],
        const SizedBox(height: 16),
        if (items.isEmpty)
          _EmptyStateCard(
            title: widget.emptyTitle,
            subtitle: widget.emptySubtitle,
          )
        else
          ...visibleItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AssociationCircularCard(
                moduleLabel: widget.moduleLabel,
                item: item,
                isEditing: widget.editingItemId == item.id,
                onOpenDocument: () => widget.onOpenDocument(item),
                onDelete:
                    widget.canManage ? () => widget.onDelete(item.id) : null,
              ),
            ),
          ),
        if (hasMoreItems) ...[
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _visibleCircularCount = (_visibleCircularCount + _pageSize)
                      .clamp(_pageSize, items.length);
                });
              },
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(
                'Load more ${widget.moduleLabel.toLowerCase()} items (${items.length - visibleItems.length} remaining)',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AssociationCircularEditor extends StatelessWidget {
  const _AssociationCircularEditor({
    required this.editorTitle,
    required this.saveButtonLabel,
    required this.draft,
    required this.isSaving,
    required this.onChanged,
    required this.onPickFile,
    required this.onSave,
    required this.onCancel,
  });

  final String editorTitle;
  final String saveButtonLabel;
  final AssociationDocumentDraft draft;
  final bool isSaving;
  final ValueChanged<AssociationDocumentDraft> onChanged;
  final Future<void> Function() onPickFile;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  editorTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
              _MutedChip(
                icon: Icons.description_outlined,
                label: 'PDF, DOC, or image scan',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AssociationCircularPreview(draft: draft),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : () => onPickFile(),
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(
                draft.selectedFile == null
                    ? 'Upload Document'
                    : 'Replace Document',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AssociationTextField(
            label: 'Headline',
            value: draft.headline,
            onChanged: (value) => onChanged(draft.copyWith(headline: value)),
          ),
          _AssociationTextField(
            label: 'Tagline',
            value: draft.tagline,
            onChanged: (value) => onChanged(draft.copyWith(tagline: value)),
          ),
          _AssociationTextField(
            label: 'Brief Text',
            value: draft.summary,
            maxLines: 5,
            onChanged: (value) => onChanged(draft.copyWith(summary: value)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed:
                      isSaving || !draft.canSubmit ? null : () => onSave(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                  ),
                  child: Text(isSaving ? 'Saving...' : saveButtonLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssociationCircularPreview extends StatelessWidget {
  const _AssociationCircularPreview({required this.draft});

  final AssociationDocumentDraft draft;

  @override
  Widget build(BuildContext context) {
    final upload = draft.selectedFile;
    final isImageUpload =
        upload != null && upload.mimeType.startsWith('image/');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child:
          isImageUpload
              ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  upload.bytes,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
              : draft.existingPreviewUrl.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  draft.existingPreviewUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => _AssociationCircularPlaceholder(
                        label: draft.displayFileExtension,
                      ),
                ),
              )
              : Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFD946EF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      draft.displayFileExtension,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.displayFileName.isEmpty
                              ? 'Upload a PDF, DOC, or scanned image'
                              : draft.displayFileName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          draft.selectedFile != null
                              ? 'Selected from this device and ready to upload.'
                              : 'Keep a clear headline and short summary so members can scan the circular quickly.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

class _AssociationCircularCard extends StatelessWidget {
  const _AssociationCircularCard({
    required this.moduleLabel,
    required this.item,
    required this.isEditing,
    required this.onOpenDocument,
    this.onDelete,
  });

  final String moduleLabel;
  final AssociationDocumentItem item;
  final bool isEditing;
  final VoidCallback onOpenDocument;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final fileLabel =
        item.originalFileName.isNotEmpty
            ? item.originalFileName
            : item.fileExtension;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isEditing ? const Color(0xFFDDD6FE) : const Color(0xFFF1F5F9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssociationCircularThumbnail(item: item, onTap: onOpenDocument),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.headline,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CircularActionIcon(
                tooltip: 'Open ${moduleLabel.toLowerCase()}',
                icon: Icons.picture_as_pdf_outlined,
                color: const Color(0xFF475569),
                onTap: onOpenDocument,
              ),
              const SizedBox(width: 4),
              _CircularActionIcon(
                tooltip: 'Open file',
                icon: Icons.open_in_new_rounded,
                color: const Color(0xFF475569),
                onTap: onOpenDocument,
              ),
              const SizedBox(width: 4),
              if (onDelete != null)
                _CircularActionIcon(
                  tooltip: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFDC2626),
                  onTap: onDelete!,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.tagline.isEmpty ? 'No tagline added yet' : item.tagline,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C3AED),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.summary.isEmpty ? 'No brief text added yet.' : item.summary,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MutedChip(
                icon: Icons.insert_drive_file_outlined,
                label: fileLabel,
              ),
              _MutedChip(
                icon: Icons.schedule_rounded,
                label: item.createdDateLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssociationCircularThumbnail extends StatelessWidget {
  const _AssociationCircularThumbnail({
    required this.item,
    required this.onTap,
  });

  final AssociationDocumentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        item.previewUrl.isNotEmpty ? item.previewUrl : item.documentUrl;

    return Tooltip(
      message: 'Open document',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            width: double.infinity,
            height: 170,
            child: _BackendImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              fallback: _AssociationCircularPlaceholder(
                label: item.fileExtension,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularActionIcon extends StatelessWidget {
  const _CircularActionIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _AssociationCircularPlaceholder extends StatelessWidget {
  const _AssociationCircularPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _AssociationMasterSection extends StatefulWidget {
  const _AssociationMasterSection({
    required this.canManage,
    required this.members,
    required this.editingMemberId,
    required this.isSaving,
    this.onNavigateToAssociation,
    required this.onOpenEditor,
    required this.onDelete,
  });

  final bool canManage;
  final List<MemberDirectoryItem> members;
  final String? editingMemberId;
  final bool isSaving;
  final VoidCallback? onNavigateToAssociation;
  final Future<void> Function([MemberDirectoryItem? member]) onOpenEditor;
  final Future<void> Function(String memberId) onDelete;

  @override
  State<_AssociationMasterSection> createState() =>
      _AssociationMasterSectionState();
}

class _AssociationMasterSectionState extends State<_AssociationMasterSection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers =
        widget.members.where((member) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          return [
            member.name,
            member.companyName,
            member.roleTitle,
            member.email,
            member.phone,
            member.gst,
          ].join(' ').toLowerCase().contains(query);
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onNavigateToAssociation != null) ...[
          const _AssociationSectionHero(title: 'Master'),
          const SizedBox(height: 14),
          _AssociationBreadcrumb(
            currentLabel: 'Master',
            onRootTap: widget.onNavigateToAssociation!,
          ),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Membership Master',
                subtitle: 'Membership Master',
              ),
            ),
            if (widget.canManage) ...[
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => widget.onOpenEditor(null),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF171717),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Add Member'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _AdminToolbarSearch(
          controller: _searchController,
          hintText: 'Search name, company, membership, GST, contact...',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 16),
        if (filteredMembers.isEmpty)
          const _EmptyStateCard(
            title: 'No members found',
            subtitle:
                'Try a different search or create the first member record.',
          )
        else
          ...filteredMembers.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MemberMasterCard(
                member: member,
                isEditing: widget.editingMemberId == member.id,
                onEdit:
                    widget.canManage ? () => widget.onOpenEditor(member) : null,
                onDelete:
                    widget.canManage ? () => widget.onDelete(member.id) : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _PagedMemberMasterSection extends ConsumerStatefulWidget {
  const _PagedMemberMasterSection({
    required this.viewerRole,
    required this.refreshToken,
    required this.canManage,
    required this.editingMemberId,
    required this.isSaving,
    required this.onOpenEditor,
    required this.onDelete,
  });

  final AppViewerRole viewerRole;
  final int refreshToken;
  final bool canManage;
  final String? editingMemberId;
  final bool isSaving;
  final Future<void> Function([MemberDirectoryItem? member]) onOpenEditor;
  final Future<void> Function(String memberId) onDelete;

  @override
  ConsumerState<_PagedMemberMasterSection> createState() =>
      _PagedMemberMasterSectionState();
}

class _PagedMemberMasterSectionState
    extends ConsumerState<_PagedMemberMasterSection> {
  static const int _pageSize = 20;
  static const double _scrollPrefetchThreshold = 200;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listController = ScrollController();
  Timer? _searchDebounce;

  String _query = '';
  List<MemberDirectoryItem> _members = const [];
  int _currentPage = 0;
  int _totalCount = 0;
  int _requestGeneration = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _listController.addListener(_handleScroll);
    unawaited(_loadFirstPage());
  }

  @override
  void didUpdateWidget(covariant _PagedMemberMasterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.viewerRole != widget.viewerRole) {
      unawaited(_loadFirstPage());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _listController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_listController.hasClients) {
      return;
    }
    if (_listController.position.extentAfter <= _scrollPrefetchThreshold) {
      unawaited(_loadNextPage());
    }
  }

  Future<void> _loadFirstPage() async {
    final generation = ++_requestGeneration;
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _currentPage = 0;
      _totalCount = 0;
      _errorMessage = null;
    });

    try {
      final page = await ref
          .read(apiClientProvider)
          .fetchMemberDirectoryPage(
            viewerRole: widget.viewerRole,
            page: 1,
            pageSize: _pageSize,
            search: _query,
          );
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _members = page.members;
        _currentPage = page.page;
        _totalCount = page.totalCount;
        _hasMore = page.hasMore;
        _isInitialLoading = false;
      });
      if (_listController.hasClients) {
        _listController.jumpTo(0);
      }
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _members = const [];
        _errorMessage = error.toString();
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final generation = _requestGeneration;
    setState(() {
      _isLoadingMore = true;
      _errorMessage = null;
    });

    try {
      final page = await ref
          .read(apiClientProvider)
          .fetchMemberDirectoryPage(
            viewerRole: widget.viewerRole,
            page: _currentPage + 1,
            pageSize: _pageSize,
            search: _query,
          );
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      final seenIds = _members.map((member) => member.id).toSet();
      final appendedMembers = [
        ..._members,
        ...page.members.where((member) => !seenIds.contains(member.id)),
      ];
      setState(() {
        _members = appendedMembers;
        _currentPage = page.page;
        _totalCount = page.totalCount;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _isLoadingMore = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    _query = value.trim();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      unawaited(_loadFirstPage());
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasLoadedMembers = _members.isNotEmpty;
    final listItemCount =
        hasLoadedMembers ? _members.length + 1 + (_isLoadingMore ? 1 : 0) : 0;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  title: 'Membership Master',
                  subtitle: 'Search, edit, and manage member records in pages.',
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _totalCount <= 0 ? 'Live directory' : '$_totalCount total',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (widget.canManage) ...[
                const SizedBox(width: 12),
                FilledButton(
                  onPressed:
                      widget.isSaving ? null : () => widget.onOpenEditor(null),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Add Member'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _AdminToolbarSearch(
            controller: _searchController,
            hintText: 'Search name, company, membership, GST, contact...',
            onChanged: _scheduleSearch,
          ),
          const SizedBox(height: 16),
          if (_isInitialLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else if (!hasLoadedMembers) ...[
            if (_errorMessage != null)
              _ErrorState(
                title: 'Could not load members',
                message: _errorMessage!,
                onRetry: _loadFirstPage,
              )
            else
              const _EmptyStateCard(
                title: 'No members found',
                subtitle:
                    'Try a different search term or create the first member record.',
              ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                controller: _listController,
                physics: const BouncingScrollPhysics(),
                itemCount: listItemCount,
                itemBuilder: (context, index) {
                  if (index < _members.length) {
                    final member = _members[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _MemberMasterCard(
                        member: member,
                        isEditing: widget.editingMemberId == member.id,
                        onEdit:
                            widget.canManage
                                ? () => widget.onOpenEditor(member)
                                : null,
                        onDelete:
                            widget.canManage
                                ? () => widget.onDelete(member.id)
                                : null,
                      ),
                    );
                  }

                  if (index == _members.length) {
                    if (_errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        child: _ErrorState(
                          title: 'Could not load more members',
                          message: _errorMessage!,
                          onRetry: _loadNextPage,
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: Center(
                        child: Text(
                          _hasMore
                              ? 'Scroll to load more members'
                              : 'Showing all $_totalCount members',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberMasterDialog extends StatefulWidget {
  const _MemberMasterDialog({required this.initialDraft});

  final MemberMasterDraft initialDraft;

  @override
  State<_MemberMasterDialog> createState() => _MemberMasterDialogState();
}

class _MemberMasterDialogState extends State<_MemberMasterDialog> {
  late MemberMasterDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _MemberMasterEditor(
            draft: _draft,
            isSaving: false,
            onChanged: (nextDraft) => setState(() => _draft = nextDraft),
            onSave: () async => Navigator.of(context).pop(_draft),
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _MemberMasterEditor extends StatelessWidget {
  const _MemberMasterEditor({
    required this.draft,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  final MemberMasterDraft draft;
  final bool isSaving;
  final ValueChanged<MemberMasterDraft> onChanged;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                draft.id.isEmpty ? 'Add Member' : 'Edit Member',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171717),
                ),
              ),
            ),
            const _MutedChip(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin CRUD',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AssociationTextField(
          label: 'Full Name',
          value: draft.name,
          onChanged: (value) => onChanged(draft.copyWith(name: value)),
        ),
        _AssociationTextField(
          label: 'Company Name',
          value: draft.companyName,
          onChanged: (value) => onChanged(draft.copyWith(companyName: value)),
        ),
        _AssociationTextField(
          label: 'Email',
          value: draft.email,
          onChanged: (value) => onChanged(draft.copyWith(email: value)),
        ),
        _AssociationTextField(
          label: 'Phone',
          value: draft.phone,
          onChanged: (value) => onChanged(draft.copyWith(phone: value)),
        ),
        _AssociationTextField(
          label: 'Company Address',
          value: draft.address,
          maxLines: 3,
          onChanged: (value) => onChanged(draft.copyWith(address: value)),
        ),
        _AssociationTextField(
          label: 'GST',
          value: draft.gst,
          onChanged: (value) => onChanged(draft.copyWith(gst: value)),
        ),
        _AssociationTextField(
          label: 'Membership Details',
          value: draft.membershipDetails,
          maxLines: 3,
          onChanged:
              (value) => onChanged(draft.copyWith(membershipDetails: value)),
        ),
        _AssociationTextField(
          label: 'Membership Start Date',
          value: draft.membershipStartDate,
          onChanged:
              (value) => onChanged(draft.copyWith(membershipStartDate: value)),
        ),
        _AssociationTextField(
          label: 'Membership End Date',
          value: draft.membershipEndDate,
          onChanged:
              (value) => onChanged(draft.copyWith(membershipEndDate: value)),
        ),
        _AssociationTextField(
          label: 'Payment Amount',
          value: draft.paymentAmount,
          onChanged: (value) => onChanged(draft.copyWith(paymentAmount: value)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            value: draft.membershipType,
            decoration: const InputDecoration(
              labelText: 'Membership Type',
              border: OutlineInputBorder(),
            ),
            items:
                const ['Primary', 'Associate', 'Guest']
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
            onChanged:
                (value) => onChanged(
                  draft.copyWith(membershipType: value ?? 'Primary'),
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            value: draft.paymentStatus,
            decoration: const InputDecoration(
              labelText: 'Payment Status',
              border: OutlineInputBorder(),
            ),
            items:
                const ['Pending', 'Paid', 'Overdue', 'Waived']
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
            onChanged:
                (value) => onChanged(
                  draft.copyWith(paymentStatus: value ?? 'Pending'),
                ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: isSaving || !draft.canSubmit ? null : () => onSave(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF171717),
                ),
                child: Text(isSaving ? 'Saving...' : 'Save Member'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MemberMasterCard extends StatelessWidget {
  const _MemberMasterCard({
    required this.member,
    required this.isEditing,
    this.onEdit,
    this.onDelete,
  });

  final MemberDirectoryItem member;
  final bool isEditing;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final membershipLabel =
        member.roleTitle.isEmpty ? 'Primary' : member.roleTitle;
    final memberNotes =
        member.membershipDetails.isNotEmpty
            ? member.membershipDetails
            : member.memberBio;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEditing ? const Color(0xFFDDD6FE) : Colors.transparent,
          width: isEditing ? 1.4 : 0,
        ),
      ),
      child: _ReusableMemberCard(
        name: member.name,
        photoUrl: member.photoUrl,
        primaryLabel:
            member.companyName.isEmpty
                ? 'No company added'
                : member.companyName,
        summary: memberNotes,
        factPills: [
          _DirectoryRolePill(label: membershipLabel),
          if (member.gst.isNotEmpty)
            _DirectoryFactPill(
              icon: Icons.receipt_long_outlined,
              label: member.gst,
            ),
          if (member.paymentStatus.isNotEmpty)
            _DirectoryFactPill(
              icon: Icons.payments_outlined,
              label: member.paymentStatus,
            ),
        ],
        detailLines: [
          if (member.email.isNotEmpty)
            _DirectoryDetailLine(
              icon: Icons.mail_outline_rounded,
              label: member.email,
              onTap: () => _openEmailComposer(member.email),
            ),
          if (member.phone.isNotEmpty)
            _DirectoryDetailLine(
              icon: Icons.call_outlined,
              label: member.phone,
              onTap:
                  () => _showPhoneActionsSheet(
                    context,
                    title: member.name,
                    phoneNumber: member.phone,
                  ),
            ),
          if (member.membershipStartDate.isNotEmpty ||
              member.membershipEndDate.isNotEmpty)
            _DirectoryDetailLine(
              icon: Icons.calendar_today_rounded,
              label:
                  '${member.membershipStartDate.isEmpty ? 'Start open' : member.membershipStartDate} to ${member.membershipEndDate.isEmpty ? 'Ongoing' : member.membershipEndDate}',
              maxLines: 2,
            ),
        ],
        footer:
            onEdit == null && onDelete == null
                ? null
                : Row(
                  children: [
                    if (onEdit != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onEdit,
                          child: const Text('Edit'),
                        ),
                      ),
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 10),
                    if (onDelete != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}

class _AssociationInfoTile extends StatelessWidget {
  const _AssociationInfoTile({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 560 : 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? 'Not added yet' : value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssociationMapTile extends StatelessWidget {
  const _AssociationMapTile({
    required this.label,
    required this.value,
    this.locationQuery = '',
  });

  final String label;
  final String value;
  final String locationQuery;

  static bool get _supportsEmbeddedMap {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  static String _normalizeLocationQuery(String rawValue, String fallbackQuery) {
    final normalizedFallback = fallbackQuery.trim();
    if (normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    final trimmedValue = rawValue.trim();
    if (trimmedValue.isEmpty) {
      return '';
    }

    try {
      final parsedUri = Uri.parse(trimmedValue);
      final extractedQuery =
          parsedUri.queryParameters['q'] ??
          parsedUri.queryParameters['query'] ??
          parsedUri.queryParameters['destination'] ??
          parsedUri.queryParameters['daddr'] ??
          parsedUri.queryParameters['ll'];
      if (extractedQuery != null && extractedQuery.trim().isNotEmpty) {
        return extractedQuery.trim();
      }
    } catch (_) {
      return trimmedValue;
    }

    return trimmedValue;
  }

  static Uri? _buildLaunchUri(String rawValue, String fallbackQuery) {
    final normalizedQuery = _normalizeLocationQuery(rawValue, fallbackQuery);
    if (normalizedQuery.isEmpty) {
      return null;
    }

    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': normalizedQuery,
    });
  }

  static Uri? _buildEmbedUri(String rawValue, String fallbackQuery) {
    final normalizedQuery = _normalizeLocationQuery(rawValue, fallbackQuery);
    if (normalizedQuery.isEmpty) {
      return null;
    }

    try {
      final trimmedValue = rawValue.trim();
      final parsedUri = Uri.parse(trimmedValue);

      if (parsedUri.hasScheme &&
          parsedUri.host.contains('google.') &&
          parsedUri.path.contains('/maps/embed')) {
        return parsedUri;
      }

      final mapQuery =
          parsedUri.queryParameters['q'] ??
          parsedUri.queryParameters['query'] ??
          parsedUri.queryParameters['destination'] ??
          parsedUri.queryParameters['daddr'] ??
          parsedUri.queryParameters['ll'];

      if (mapQuery != null && mapQuery.trim().isNotEmpty) {
        return Uri.https('www.google.com', '/maps', {
          'q': mapQuery.trim(),
          'output': 'embed',
        });
      }
    } catch (_) {
      // Fall through to normalized query.
    }

    return Uri.https('www.google.com', '/maps', {
      'q': normalizedQuery,
      'output': 'embed',
    });
  }

  static String _buildEmbedHtml(Uri embedUri) {
    final escapedSrc = const HtmlEscape(
      HtmlEscapeMode.attribute,
    ).convert(embedUri.toString());

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <style>
      html, body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
        background: #f5f3ff;
      }

      iframe {
        width: 100%;
        height: 100%;
        border: 0;
      }
    </style>
  </head>
  <body>
    <iframe
      src="$escapedSrc"
      allowfullscreen
      loading="lazy"
      referrerpolicy="no-referrer-when-downgrade">
    </iframe>
  </body>
</html>
''';
  }

  Future<void> _openMap(Uri launchUri) async {
    await launchUrl(launchUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final launchUri = _buildLaunchUri(value, locationQuery);
    final embedUri = _buildEmbedUri(value, locationQuery);

    return SizedBox(
      width: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 10),
          if (launchUri == null || embedUri == null)
            const Text(
              'Not added yet',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child:
                          _supportsEmbeddedMap
                              ? IgnorePointer(
                                ignoring: true,
                                child: _AssociationEmbeddedMap(
                                  html: _buildEmbedHtml(embedUri),
                                ),
                              )
                              : const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Map preview is not available on this platform. Use the button below to open Google Maps.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4B5563),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: FilledButton.icon(
                        onPressed: () => _openMap(launchUri),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF171717),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open map'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _openMap(launchUri),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open in Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF171717),
                  side: const BorderSide(color: Color(0xFFD8B4FE)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssociationEmbeddedMap extends StatefulWidget {
  const _AssociationEmbeddedMap({required this.html});

  final String html;

  @override
  State<_AssociationEmbeddedMap> createState() =>
      _AssociationEmbeddedMapState();
}

class _AssociationEmbeddedMapState extends State<_AssociationEmbeddedMap> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..loadHtmlString(widget.html);
  }

  @override
  void didUpdateWidget(covariant _AssociationEmbeddedMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _controller.loadHtmlString(widget.html);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

class _AssociationTextField extends StatelessWidget {
  const _AssociationTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _StableTextFormField(
        value: value,
        label: label,
        minLines: maxLines,
        maxLines: maxLines,
        onChanged: onChanged,
      ),
    );
  }
}

class _StableTextFormField extends StatefulWidget {
  const _StableTextFormField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
  });

  final String value;
  final String label;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;

  @override
  State<_StableTextFormField> createState() => _StableTextFormFieldState();
}

class _StableTextFormFieldState extends State<_StableTextFormField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _StableTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      final selection = _controller.selection;
      _controller.value = TextEditingValue(
        text: widget.value,
        selection:
            selection.isValid
                ? selection.copyWith(
                  baseOffset: selection.baseOffset.clamp(
                    0,
                    widget.value.length,
                  ),
                  extentOffset: selection.extentOffset.clamp(
                    0,
                    widget.value.length,
                  ),
                )
                : TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _AdminAppAccessSection extends StatefulWidget {
  const _AdminAppAccessSection({
    required this.initialSettings,
    required this.onSave,
  });

  final AdminAppAccessSettings initialSettings;
  final Future<void> Function(AdminAppAccessSettings) onSave;

  @override
  State<_AdminAppAccessSection> createState() => _AdminAppAccessSectionState();
}

class _AdminAppAccessSectionState extends State<_AdminAppAccessSection> {
  late AdminAppAccessSettings _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  void didUpdateWidget(covariant _AdminAppAccessSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSettings != widget.initialSettings && !_isSaving) {
      _settings = widget.initialSettings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Approve members to login',
        'Require approval before members can sign into the app.',
        _settings.approveMembersLogin,
        (bool value) =>
            _settings = _settings.copyWith(approveMembersLogin: value),
      ),
      (
        'Disable screenshots',
        'Restrict screenshot capture inside the Flutter app.',
        _settings.disableScreenshots,
        (bool value) =>
            _settings = _settings.copyWith(disableScreenshots: value),
      ),
      (
        'Require membership activation',
        'Keep new member records in pending membership status until they are activated.',
        _settings.approveMembership,
        (bool value) =>
            _settings = _settings.copyWith(approveMembership: value),
      ),
      (
        'Approve registration request',
        'Review and approve incoming registration requests.',
        _settings.approveRegistrationRequest,
        (bool value) =>
            _settings = _settings.copyWith(approveRegistrationRequest: value),
      ),
      (
        'Disable admin functions from app',
        'Turn off admin-only features inside the member-facing app.',
        _settings.disableAdminFunctionsFromApp,
        (bool value) =>
            _settings = _settings.copyWith(disableAdminFunctionsFromApp: value),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Flutter App Permissions',
          subtitle:
              'These app access switches are now loaded from and saved back to the backend.',
        ),
        const SizedBox(height: 14),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    value: item.$3,
                    onChanged: (value) {
                      setState(() {
                        item.$4(value);
                      });
                    },
                    activeColor: const Color(0xFF7C3AED),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _isSaving
                    ? null
                    : () async {
                      setState(() {
                        _isSaving = true;
                      });
                      try {
                        await widget.onSave(_settings);
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                        }
                      }
                    },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF171717),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(_isSaving ? 'Saving...' : 'Save App Access'),
          ),
        ),
        const SizedBox(height: 20),
        const _AdminSessionReportPanel(),
      ],
    );
  }
}

class _AdminSessionReportPanel extends ConsumerWidget {
  const _AdminSessionReportPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(sessionReportProvider);

    return reportAsync.when(
      loading:
          () => const _EntityCardFrame(
            padding: EdgeInsets.all(20),
            radius: 28,
            child: _LoadingState(),
          ),
      error:
          (error, _) => _EntityCardFrame(
            padding: const EdgeInsets.all(20),
            radius: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(sessionReportProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
      data: (report) {
        final summary = report.summary;
        return _EntityCardFrame(
          padding: const EdgeInsets.all(20),
          radius: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Sessions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF171717),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Live visibility into logged-in and recently active app users.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(sessionReportProvider),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SessionMetricChip(
                    label: 'Logged in users',
                    value: '${summary.loggedInUsers}',
                  ),
                  _SessionMetricChip(
                    label: 'Active users',
                    value: '${summary.activeUsers}',
                  ),
                  _SessionMetricChip(
                    label: 'Total sessions',
                    value: '${summary.totalSessions}',
                  ),
                  _SessionMetricChip(
                    label: 'Sessions today',
                    value: '${summary.sessionsToday}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Active means seen within the last ${summary.activeWindowMinutes} minutes.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              ...report.sessions
                  .take(8)
                  .map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    session.displayLabel,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF171717),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        session.isActiveNow
                                            ? const Color(0xFFE7F8EE)
                                            : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    session.isActiveNow ? 'Active now' : 'Idle',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          session.isActiveNow
                                              ? const Color(0xFF0F9F58)
                                              : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${session.email} • ${session.viewerRole.label}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Last seen: ${session.lastSeenAt.length >= 16 ? session.lastSeenAt.substring(0, 16).replaceFirst('T', ' ') : session.lastSeenAt}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            if (session.deviceInfo.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Device: ${session.deviceInfo}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionMetricChip extends StatelessWidget {
  const _SessionMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

enum AdminMemberAccessView { app, content }

extension AdminMemberAccessViewMeta on AdminMemberAccessView {
  String get label => switch (this) {
    AdminMemberAccessView.app => 'App Access',
    AdminMemberAccessView.content => 'Content Access',
  };
}

enum AdminMemberTypeFilter { all, primary, associate, guest, committee }

extension AdminMemberTypeFilterMeta on AdminMemberTypeFilter {
  String get label => switch (this) {
    AdminMemberTypeFilter.all => 'All',
    AdminMemberTypeFilter.primary => 'Primary',
    AdminMemberTypeFilter.associate => 'Associate',
    AdminMemberTypeFilter.guest => 'Guest',
    AdminMemberTypeFilter.committee => 'Committee Members',
  };

  bool matches(AdminMemberAccessItem member) {
    final role = member.roleTitle.trim().toLowerCase();
    final hasCommitteePost = member.committeePost.trim().isNotEmpty;
    return switch (this) {
      AdminMemberTypeFilter.all => true,
      AdminMemberTypeFilter.primary => role.isEmpty || role == 'primary',
      AdminMemberTypeFilter.associate => role == 'associate',
      AdminMemberTypeFilter.guest =>
        role == 'temporary visit' || role == 'guest' || role == 'visitor',
      AdminMemberTypeFilter.committee => hasCommitteePost,
    };
  }
}

class _AdminMemberAccessWorkspace extends StatefulWidget {
  const _AdminMemberAccessWorkspace({
    required this.members,
    required this.posts,
    required this.updatingMemberId,
    required this.updatingPostId,
    required this.onUpdateAccess,
    required this.onBulkUpdateAccess,
    required this.onUpdateStatus,
  });

  final List<AdminMemberAccessItem> members;
  final List<MemberPostItem> posts;
  final String? updatingMemberId;
  final String? updatingPostId;
  final Future<void> Function(AdminMemberAccessItem, MemberAccessStatus)
  onUpdateAccess;
  final Future<void> Function(List<AdminMemberAccessItem>, MemberAccessStatus)
  onBulkUpdateAccess;
  final Future<void> Function(MemberPostItem, PostReviewStatus) onUpdateStatus;

  @override
  State<_AdminMemberAccessWorkspace> createState() =>
      _AdminMemberAccessWorkspaceState();
}

class _AdminMemberAccessWorkspaceState
    extends State<_AdminMemberAccessWorkspace> {
  AdminMemberAccessView _activeView = AdminMemberAccessView.app;
  AdminMemberTypeFilter _activeFilter = AdminMemberTypeFilter.all;
  MemberAccessStatus? _bulkAccessAction;
  final TextEditingController _appSearchController = TextEditingController();
  final TextEditingController _contentSearchController =
      TextEditingController();
  String _appQuery = '';
  String _contentQuery = '';
  final Set<String> _selectedMemberIds = <String>{};
  final Set<String> _selectedContentMemberIds = <String>{};

  @override
  void dispose() {
    _appSearchController.dispose();
    _contentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers =
        widget.members.where((member) {
          if (!_activeFilter.matches(member)) {
            return false;
          }
          if (_appQuery.trim().isEmpty) {
            return true;
          }
          return [
            member.name,
            member.companyName,
            member.roleTitle,
          ].join(' ').toLowerCase().contains(_appQuery.trim().toLowerCase());
        }).toList();
    final contentMemberMatches =
        widget.members.where((member) {
          if (_contentQuery.trim().isEmpty) {
            return true;
          }
          return [member.name, member.companyName]
              .join(' ')
              .toLowerCase()
              .contains(_contentQuery.trim().toLowerCase());
        }).toList();
    final filteredPosts =
        widget.posts.where((post) {
          final query = _contentQuery.trim().toLowerCase();
          if (query.isNotEmpty &&
              ![
                post.title,
                post.summary,
                post.member.name,
                post.reviewStatus.label,
              ].join(' ').toLowerCase().contains(query)) {
            return false;
          }
          if (_selectedContentMemberIds.isEmpty) {
            return true;
          }
          return _selectedContentMemberIds.contains(post.member.id);
        }).toList();
    final allFilteredSelected =
        filteredMembers.isNotEmpty &&
        filteredMembers.every(
          (member) => _selectedMemberIds.contains(member.id),
        );

    if (_activeView == AdminMemberAccessView.app && filteredMembers.isEmpty) {
      return const _EmptyStateCard(
        title: 'No members found',
        subtitle: 'No member access records match the current search.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Member Access',
          subtitle:
              'Match the same member app access and member content access workflow shown in the web admin.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children:
                AdminMemberAccessView.values.map((view) {
                  final selected = _activeView == view;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:
                            selected
                                ? const [
                                  BoxShadow(
                                    color: Color(0x120F172A),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                                : null,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _activeView = view;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            view.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  selected
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF4B5563),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (_activeView == AdminMemberAccessView.app) ...[
          _AdminToolbarSearch(
            controller: _appSearchController,
            hintText: 'Search name, company, membership type...',
            onChanged: (value) => setState(() => _appQuery = value),
          ),
          const SizedBox(height: 12),
          _AdminToolbarDropdown<AdminMemberTypeFilter>(
            value: _activeFilter,
            icon: Icons.badge_outlined,
            labelText: 'Member type',
            items:
                AdminMemberTypeFilter.values.map((filter) {
                  return DropdownMenuItem(
                    value: filter,
                    child: Text(filter.label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _activeFilter = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _AdminToolbarDropdown<MemberAccessStatus>(
            value: _bulkAccessAction,
            icon: Icons.rule_folder_outlined,
            labelText: 'Bulk action',
            items:
                const [
                  MemberAccessStatus.approved,
                  MemberAccessStatus.suspended,
                  MemberAccessStatus.cancelled,
                ].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status == MemberAccessStatus.approved
                          ? 'Approve'
                          : status == MemberAccessStatus.suspended
                          ? 'Suspend'
                          : 'Cancel',
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _bulkAccessAction = value;
              });
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                if (allFilteredSelected) {
                  _selectedMemberIds.removeAll(
                    filteredMembers.map((member) => member.id),
                  );
                } else {
                  _selectedMemberIds.addAll(
                    filteredMembers.map((member) => member.id),
                  );
                }
              });
            },
            icon: Icon(
              allFilteredSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
            ),
            label: Text(
              allFilteredSelected ? 'Selected filtered' : 'Select filtered',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed:
                  _selectedMemberIds.isEmpty ||
                          widget.updatingMemberId != null ||
                          _bulkAccessAction == null
                      ? null
                      : () => widget.onBulkUpdateAccess(
                        filteredMembers
                            .where(
                              (member) =>
                                  _selectedMemberIds.contains(member.id),
                            )
                            .toList(),
                        _bulkAccessAction!,
                      ),
              icon: const Icon(Icons.playlist_add_check_circle_rounded),
              label: const Text('Apply bulk action'),
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          _AdminToolbarSearch(
            controller: _contentSearchController,
            hintText: 'Search member to filter content...',
            onChanged: (value) => setState(() => _contentQuery = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedContentMemberIds
                      ..clear()
                      ..addAll(contentMemberMatches.map((member) => member.id));
                  });
                },
                child: const Text('Select All Matched Members'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedContentMemberIds.clear();
                  });
                },
                child: const Text('Clear Selection'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                contentMemberMatches.map((member) {
                  return FilterChip(
                    label: Text(member.name),
                    selected: _selectedContentMemberIds.contains(member.id),
                    onSelected: (_) {
                      setState(() {
                        if (_selectedContentMemberIds.contains(member.id)) {
                          _selectedContentMemberIds.remove(member.id);
                        } else {
                          _selectedContentMemberIds.add(member.id);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
          _AdminContentReviewSection(
            posts: filteredPosts,
            updatingPostId: widget.updatingPostId,
            onUpdateStatus: widget.onUpdateStatus,
          ),
        ],
        if (_activeView == AdminMemberAccessView.app)
          ...filteredMembers.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ReusableMemberCard(
                name: member.name,
                photoUrl: member.photoUrl,
                primaryLabel: member.companyName,
                summary: '',
                leadingControl: Checkbox(
                  value: _selectedMemberIds.contains(member.id),
                  onChanged:
                      (_) => setState(() {
                        if (_selectedMemberIds.contains(member.id)) {
                          _selectedMemberIds.remove(member.id);
                        } else {
                          _selectedMemberIds.add(member.id);
                        }
                      }),
                ),
                factPills: [
                  if (member.roleTitle.isNotEmpty)
                    _DirectoryRolePill(label: member.roleTitle),
                ],
                detailLines: [
                  if (member.email.isNotEmpty)
                    _DirectoryDetailLine(
                      icon: Icons.mail_outline_rounded,
                      label: member.email,
                      onTap: () => _openEmailComposer(member.email),
                    ),
                  if (member.phone.isNotEmpty)
                    _DirectoryDetailLine(
                      icon: Icons.call_outlined,
                      label: member.phone,
                      onTap:
                          () => _showPhoneActionsSheet(
                            context,
                            title: member.name,
                            phoneNumber: member.phone,
                          ),
                    ),
                ],
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MemberAccessStatusActionRow(
                      currentStatus: member.accessStatus,
                      isUpdating: widget.updatingMemberId == member.id,
                      onSelected:
                          (status) => widget.onUpdateAccess(member, status),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'App access controls',
                      style: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.updatingMemberId == member.id) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminToolbarSearch extends StatelessWidget {
  const _AdminToolbarSearch({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded),
          hintText: hintText,
        ),
      ),
    );
  }
}

class _AdminToolbarDropdown<T> extends StatelessWidget {
  const _AdminToolbarDropdown({
    required this.value,
    required this.icon,
    required this.labelText,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final IconData icon;
  final String labelText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(icon),
          labelText: labelText,
        ),
        isExpanded: true,
      ),
    );
  }
}

class _MemberAccessStatusActionRow extends StatelessWidget {
  const _MemberAccessStatusActionRow({
    required this.currentStatus,
    required this.isUpdating,
    required this.onSelected,
    this.primaryLabel = 'Approve / Pending',
    this.secondaryLabel = 'Cancel / Suspend',
  });

  final MemberAccessStatus currentStatus;
  final bool isUpdating;
  final ValueChanged<MemberAccessStatus> onSelected;
  final String primaryLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MemberAccessToggleButton(
            label: primaryLabel,
            icon:
                currentStatus == MemberAccessStatus.approved
                    ? Icons.check_circle_rounded
                    : Icons.hourglass_top_rounded,
            selected:
                currentStatus == MemberAccessStatus.approved ||
                currentStatus == MemberAccessStatus.pending,
            activeColor:
                currentStatus == MemberAccessStatus.approved
                    ? MemberAccessStatus.approved.color
                    : MemberAccessStatus.pending.color,
            enabled: !isUpdating,
            onPressed:
                () => onSelected(
                  currentStatus == MemberAccessStatus.approved
                      ? MemberAccessStatus.pending
                      : MemberAccessStatus.approved,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MemberAccessToggleButton(
            label: secondaryLabel,
            icon:
                currentStatus == MemberAccessStatus.cancelled
                    ? Icons.cancel_rounded
                    : Icons.pause_circle_rounded,
            selected:
                currentStatus == MemberAccessStatus.cancelled ||
                currentStatus == MemberAccessStatus.suspended,
            activeColor:
                currentStatus == MemberAccessStatus.cancelled
                    ? MemberAccessStatus.cancelled.color
                    : MemberAccessStatus.suspended.color,
            enabled: !isUpdating,
            onPressed:
                () => onSelected(
                  currentStatus == MemberAccessStatus.suspended
                      ? MemberAccessStatus.cancelled
                      : MemberAccessStatus.suspended,
                ),
          ),
        ),
      ],
    );
  }
}

class _MemberAccessToggleButton extends StatelessWidget {
  const _MemberAccessToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? activeColor : const Color(0xFF4B5563);
    final backgroundColor =
        selected
            ? activeColor.withValues(alpha: 0.14)
            : const Color(0xFFF8FAFC);
    final borderColor = selected ? activeColor : const Color(0xFFE5E7EB);

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 15),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: BorderSide(color: borderColor),
        minimumSize: const Size.fromHeight(38),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _AdminContentReviewSection extends StatelessWidget {
  const _AdminContentReviewSection({
    required this.posts,
    required this.updatingPostId,
    required this.onUpdateStatus,
  });

  final List<MemberPostItem> posts;
  final String? updatingPostId;
  final Future<void> Function(MemberPostItem, PostReviewStatus) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyStateCard(
        title: 'No posts found',
        subtitle: 'No member content items match the current search.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Content Review',
          subtitle:
              'Moderate member posts from the same queue used by web and members.',
        ),
        const SizedBox(height: 14),
        ...posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MemberPostCard(
              post: post,
              viewerRole: AppViewerRole.admin,
              isUpdating: updatingPostId == post.id,
              onUpdateStatus: onUpdateStatus,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminEventsSection extends StatefulWidget {
  const _AdminEventsSection({
    required this.events,
    required this.eventTypes,
    required this.savingEventId,
    required this.onSaveEvent,
    required this.onDeleteEvent,
  });

  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;
  final String? savingEventId;
  final Future<void> Function(AdminEventDraft) onSaveEvent;
  final Future<void> Function(String) onDeleteEvent;

  @override
  State<_AdminEventsSection> createState() => _AdminEventsSectionState();
}

class _AdminVendorAccessWorkspace extends StatefulWidget {
  const _AdminVendorAccessWorkspace({
    this.title = 'Vendor Requests',
    this.subtitle =
        'Approve vendor registrations and review paid app banner submissions from the live backend.',
    this.emptyTitle = 'No vendor requests found',
    this.emptySubtitle =
        'New vendor registrations will appear here for review.',
    required this.vendors,
    required this.updatingVendorId,
    this.reviewingVendorId,
    required this.onUpdateVendorAccess,
    this.onEditVendor,
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final List<AdminVendorAccessItem> vendors;
  final String? updatingVendorId;
  final String? reviewingVendorId;
  final Future<void> Function(AdminVendorAccessItem, MemberAccessStatus)
  onUpdateVendorAccess;
  final ValueChanged<AdminVendorAccessItem>? onEditVendor;

  @override
  State<_AdminVendorAccessWorkspace> createState() =>
      _AdminVendorAccessWorkspaceState();
}

class _AdminVendorAccessWorkspaceState
    extends State<_AdminVendorAccessWorkspace> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  MemberAccessStatus? _selectedStatus;

  String _vendorStatusLabel(MemberAccessStatus status) => switch (status) {
    MemberAccessStatus.approved => 'Active',
    MemberAccessStatus.pending => 'Pending',
    MemberAccessStatus.suspended => 'Suspended',
    MemberAccessStatus.cancelled => 'Cancelled',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredVendors =
        widget.vendors.where((vendor) {
          if (_selectedStatus != null &&
              vendor.accessStatus != _selectedStatus) {
            return false;
          }
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          return [
            vendor.displayName,
            vendor.contactPerson,
            vendor.email,
            vendor.phone,
            vendor.primaryLoginEmail,
            vendor.secondaryLoginEmail,
            vendor.city,
            vendor.category,
            vendor.vendorType,
          ].join(' ').toLowerCase().contains(query);
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: widget.title, subtitle: widget.subtitle),
        const SizedBox(height: 14),
        _AdminToolbarSearch(
          controller: _searchController,
          hintText: 'Search vendor, city, category, contact...',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        _AdminToolbarDropdown<MemberAccessStatus?>(
          value: _selectedStatus,
          icon: Icons.filter_alt_rounded,
          labelText: 'Status',
          items: [
            const DropdownMenuItem<MemberAccessStatus?>(
              value: null,
              child: Text('All'),
            ),
            ...const [
              MemberAccessStatus.pending,
              MemberAccessStatus.suspended,
              MemberAccessStatus.approved,
              MemberAccessStatus.cancelled,
            ].map(
              (status) => DropdownMenuItem<MemberAccessStatus?>(
                value: status,
                child: Text(_vendorStatusLabel(status)),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value;
            });
          },
        ),
        const SizedBox(height: 14),
        if (filteredVendors.isEmpty)
          _EmptyStateCard(
            title: widget.emptyTitle,
            subtitle:
                _query.trim().isNotEmpty || _selectedStatus != null
                    ? 'No vendors match the current search or status filter.'
                    : widget.emptySubtitle,
          )
        else
          ...filteredVendors.map(
            (vendor) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AdminVendorAccessCard(
                vendor: vendor,
                isUpdating:
                    widget.updatingVendorId == vendor.id ||
                    widget.reviewingVendorId == vendor.id,
                onUpdateAccess:
                    (status) => widget.onUpdateVendorAccess(vendor, status),
                onEdit:
                    widget.onEditVendor == null
                        ? null
                        : () => widget.onEditVendor!(vendor),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminVendorRegistrationWorkspace extends StatelessWidget {
  const _AdminVendorRegistrationWorkspace({
    required this.pendingCount,
    required this.categories,
    required this.isSaving,
    required this.onAddNew,
  });

  final int pendingCount;
  final List<VendorTaxonomyCategoryItem> categories;
  final bool isSaving;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final subCategoryCount = categories.fold<int>(
      0,
      (sum, category) => sum + category.subCategories.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Vendor Registration',
                subtitle:
                    'Add a new vendor from admin view using the same backend registration flow used on the web app.',
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: isSaving ? null : onAddNew,
              icon:
                  isSaving
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.add_business_rounded),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _AdminMetricCard(
              label: 'Categories',
              value: '${categories.length}',
              icon: Icons.category_rounded,
            ),
            _AdminMetricCard(
              label: 'Sub-categories',
              value: '$subCategoryCount',
              icon: Icons.subdirectory_arrow_right_rounded,
            ),
            _AdminMetricCard(
              label: 'Pending review',
              value: '$pendingCount',
              icon: Icons.hourglass_top_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF7C3AED), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBannerAccessWorkspace extends StatefulWidget {
  const _AdminBannerAccessWorkspace({
    required this.banners,
    required this.vendors,
    required this.updatingBannerId,
    required this.isSavingNewBanner,
    required this.onAddBanner,
    required this.onUpdateBannerStatus,
    this.onEditBanner,
  });

  final List<AdminAppBannerItem> banners;
  final List<AdminVendorAccessItem> vendors;
  final String? updatingBannerId;
  final bool isSavingNewBanner;
  final VoidCallback onAddBanner;
  final Future<void> Function(AdminAppBannerItem, BannerReviewStatus)
  onUpdateBannerStatus;
  final ValueChanged<AdminAppBannerItem>? onEditBanner;

  @override
  State<_AdminBannerAccessWorkspace> createState() =>
      _AdminBannerAccessWorkspaceState();
}

class _AdminBannerAccessWorkspaceState
    extends State<_AdminBannerAccessWorkspace> {
  final TextEditingController _vendorSearchController = TextEditingController();
  String _vendorQuery = '';
  BannerReviewStatus? _selectedStatus;

  @override
  void dispose() {
    _vendorSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBanners =
        widget.banners.where((banner) {
          if (_selectedStatus != null &&
              banner.reviewStatus != _selectedStatus) {
            return false;
          }
          final query = _vendorQuery.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          return [
            banner.vendorName,
            banner.shortText,
            banner.contactNumber,
            banner.socialMediaUrl,
          ].join(' ').toLowerCase().contains(query);
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Banner Access',
          subtitle:
              'Approve, reject, or hold paid banner requests from the live backend before they go live in the carousel.',
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed:
                widget.isSavingNewBanner || widget.vendors.isEmpty
                    ? null
                    : widget.onAddBanner,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(widget.isSavingNewBanner ? 'Adding...' : 'Add New'),
          ),
        ),
        const SizedBox(height: 12),
        _AdminToolbarSearch(
          controller: _vendorSearchController,
          hintText: 'Search vendor name...',
          onChanged: (value) => setState(() => _vendorQuery = value),
        ),
        const SizedBox(height: 12),
        _AdminToolbarDropdown<BannerReviewStatus?>(
          value: _selectedStatus,
          icon: Icons.filter_alt_rounded,
          labelText: 'Banner status',
          items: [
            const DropdownMenuItem<BannerReviewStatus?>(
              value: null,
              child: Text('All'),
            ),
            ...const [
              BannerReviewStatus.approved,
              BannerReviewStatus.pending,
              BannerReviewStatus.rejected,
              BannerReviewStatus.onHold,
            ].map(
              (status) => DropdownMenuItem<BannerReviewStatus?>(
                value: status,
                child: Text(status.label),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value;
            });
          },
        ),
        const SizedBox(height: 14),
        if (filteredBanners.isEmpty)
          _EmptyStateCard(
            title: 'No banner requests found',
            subtitle:
                _vendorQuery.trim().isNotEmpty || _selectedStatus != null
                    ? 'No banners match the current vendor search or status filter.'
                    : 'Submitted app banners will appear here for moderation.',
          )
        else
          ...filteredBanners.map(
            (banner) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AdminAppBannerCard(
                banner: banner,
                isUpdating: widget.updatingBannerId == banner.id,
                onEdit:
                    widget.onEditBanner == null
                        ? null
                        : () => widget.onEditBanner!(banner),
                onUpdateStatus:
                    (status) => widget.onUpdateBannerStatus(banner, status),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminTimelineAccessWorkspace extends StatefulWidget {
  const _AdminTimelineAccessWorkspace({
    required this.posts,
    required this.members,
    required this.vendors,
    required this.tenant,
    required this.updatingTimelineId,
    required this.onUpdateTimelineStatus,
  });

  final List<AdminTimelineItem> posts;
  final List<AdminMemberAccessItem> members;
  final List<AdminVendorAccessItem> vendors;
  final TenantContext? tenant;
  final String? updatingTimelineId;
  final Future<void> Function(AdminTimelineItem, TimelineReviewStatus)
  onUpdateTimelineStatus;

  @override
  State<_AdminTimelineAccessWorkspace> createState() =>
      _AdminTimelineAccessWorkspaceState();
}

class _AdminTimelineAccessWorkspaceState
    extends State<_AdminTimelineAccessWorkspace> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedSourceType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts =
        widget.posts.where((post) {
            final sourceType = post.sourceType.trim().toUpperCase();
            if (_selectedSourceType != null &&
                sourceType != _selectedSourceType) {
              return false;
            }
            final normalizedQuery = _query.trim().toLowerCase();
            if (normalizedQuery.isEmpty) {
              return true;
            }
            return [
              post.sourceType,
              post.sourceName,
              post.postedBy,
              post.caption,
              post.contactNumber,
            ].any(
              (value) => value.trim().toLowerCase().contains(normalizedQuery),
            );
          }).toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Timeline Access',
          subtitle:
              'Approve, reject, or hold association, member, and vendor timeline posts from the live backend.',
        ),
        const SizedBox(height: 14),
        _AdminToolbarSearch(
          controller: _searchController,
          hintText: 'Search source, posted by, or caption...',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        _AdminToolbarDropdown<String?>(
          value: _selectedSourceType,
          icon: Icons.tune_rounded,
          labelText: 'Timeline source',
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('All')),
            DropdownMenuItem<String?>(
              value: 'ASSOCIATION',
              child: Text('Association'),
            ),
            DropdownMenuItem<String?>(value: 'MEMBER', child: Text('Member')),
            DropdownMenuItem<String?>(value: 'VENDOR', child: Text('Vendor')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSourceType = value;
            });
          },
        ),
        const SizedBox(height: 14),
        if (filteredPosts.isEmpty)
          _EmptyStateCard(
            title: 'No timeline posts found',
            subtitle:
                _query.trim().isNotEmpty || _selectedSourceType != null
                    ? 'No timeline posts match the current source or search filter.'
                    : 'Submitted timeline posts will appear here for moderation.',
          )
        else
          ...filteredPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AdminTimelineAccessCard(
                post: post,
                isUpdating: widget.updatingTimelineId == post.id,
                onUpdateStatus:
                    (status) => widget.onUpdateTimelineStatus(post, status),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminVendorAccessCard extends StatelessWidget {
  const _AdminVendorAccessCard({
    required this.vendor,
    required this.isUpdating,
    required this.onUpdateAccess,
    this.onEdit,
  });

  final AdminVendorAccessItem vendor;
  final bool isUpdating;
  final ValueChanged<MemberAccessStatus> onUpdateAccess;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return _ReusableMemberCard(
      name: vendor.displayName,
      photoUrl: vendor.avatarUrl,
      primaryLabel: vendor.category,
      factPills: [
        if (vendor.vendorType.isNotEmpty)
          _DirectoryFactPill(
            icon: Icons.store_mall_directory_rounded,
            label: vendor.vendorType,
          ),
        if (vendor.city.isNotEmpty)
          _DirectoryFactPill(
            icon: Icons.location_city_rounded,
            label: vendor.city,
          ),
        if (vendor.badge.isNotEmpty)
          _DirectoryFactPill(
            icon: Icons.verified_outlined,
            label: vendor.badge,
          ),
      ],
      detailLines: [
        if (vendor.contactPerson.isNotEmpty)
          _DirectoryDetailLine(
            icon: Icons.badge_outlined,
            label: vendor.contactPerson,
          ),
        if (vendor.email.isNotEmpty)
          _DirectoryDetailLine(
            icon: Icons.mail_outline_rounded,
            label: vendor.email,
            onTap: () => _openEmailComposer(vendor.email),
          ),
        if (vendor.phone.isNotEmpty)
          _DirectoryDetailLine(
            icon: Icons.call_outlined,
            label: vendor.phone,
            onTap:
                () => _showPhoneActionsSheet(
                  context,
                  title: vendor.displayName,
                  phoneNumber: vendor.phone,
                ),
          ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onEdit != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: isUpdating ? null : onEdit,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _MemberAccessStatusActionRow(
            currentStatus: vendor.accessStatus,
            isUpdating: isUpdating,
            onSelected: onUpdateAccess,
            primaryLabel: 'Active / Pending',
            secondaryLabel: 'Cancel / Suspend',
          ),
          const SizedBox(height: 8),
          const Text(
            'Vendor access controls',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isUpdating) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminAppBannerCard extends StatelessWidget {
  const _AdminAppBannerCard({
    required this.banner,
    required this.isUpdating,
    required this.onUpdateStatus,
    this.onEdit,
  });

  final AdminAppBannerItem banner;
  final bool isUpdating;
  final ValueChanged<BannerReviewStatus> onUpdateStatus;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return _EntityCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (banner.mediaUrl.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: _BackendImage(
                      imageUrl: banner.mediaUrl,
                      fit: BoxFit.contain,
                      fallback: Container(
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                ),
              if (banner.mediaUrl.trim().isNotEmpty) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.vendorName.isEmpty
                          ? 'Vendor banner'
                          : banner.vendorName,
                      style: const TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner.shortText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (banner.displayIndex > 0)
                _DirectoryFactPill(
                  icon: Icons.view_carousel_rounded,
                  label: 'Slot ${banner.displayIndex}',
                ),
              _DirectoryFactPill(
                icon: Icons.payments_outlined,
                label:
                    banner.paymentReceived
                        ? (banner.paymentMode.isEmpty
                            ? 'Paid'
                            : 'Paid • ${banner.paymentMode}')
                        : 'Payment pending',
              ),
            ],
          ),
          if (banner.contactNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DirectoryDetailLine(
              icon: Icons.call_outlined,
              label: banner.contactNumber,
              onTap:
                  () => _showPhoneActionsSheet(
                    context,
                    title:
                        banner.vendorName.isEmpty
                            ? 'Vendor banner'
                            : banner.vendorName,
                    phoneNumber: banner.contactNumber,
                  ),
            ),
          ],
          if (banner.socialMediaUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DirectoryDetailLine(
              icon: Icons.link_rounded,
              label: banner.socialMediaUrl,
            ),
          ],
          if (banner.displayStart.isNotEmpty ||
              banner.displayEnd.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DirectoryDetailLine(
              icon: Icons.date_range_rounded,
              label:
                  banner.displayStart.isNotEmpty && banner.displayEnd.isNotEmpty
                      ? '${banner.displayStart} to ${banner.displayEnd}'
                      : banner.displayStart.isNotEmpty
                      ? 'From ${banner.displayStart}'
                      : 'Until ${banner.displayEnd}',
            ),
          ],
          if (banner.paymentRemarks.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DirectoryDetailLine(
              icon: Icons.receipt_long_outlined,
              label: banner.paymentRemarks,
            ),
          ],
          const SizedBox(height: 14),
          if (onEdit != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: isUpdating ? null : onEdit,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _BannerReviewStatusActionRow(
            currentStatus: banner.reviewStatus,
            isUpdating: isUpdating,
            onSelected: onUpdateStatus,
          ),
          if (isUpdating) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminFileTile extends StatelessWidget {
  const _AdminFileTile({
    required this.label,
    required this.fileName,
    required this.helperText,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String label;
  final String fileName;
  final String helperText;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fileName.isEmpty ? 'No file selected' : fileName,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helperText,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _BannerReviewStatusActionRow extends StatelessWidget {
  const _BannerReviewStatusActionRow({
    required this.currentStatus,
    required this.isUpdating,
    required this.onSelected,
  });

  final BannerReviewStatus currentStatus;
  final bool isUpdating;
  final ValueChanged<BannerReviewStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BannerReviewToggleButton(
            label: 'Approve / Pending',
            icon:
                currentStatus == BannerReviewStatus.approved
                    ? Icons.check_circle_rounded
                    : Icons.hourglass_top_rounded,
            selected:
                currentStatus == BannerReviewStatus.approved ||
                currentStatus == BannerReviewStatus.pending,
            activeColor:
                currentStatus == BannerReviewStatus.approved
                    ? BannerReviewStatus.approved.color
                    : BannerReviewStatus.pending.color,
            enabled: !isUpdating,
            onPressed:
                () => onSelected(
                  currentStatus == BannerReviewStatus.approved
                      ? BannerReviewStatus.pending
                      : BannerReviewStatus.approved,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BannerReviewToggleButton(
            label: 'Reject / Hold',
            icon:
                currentStatus == BannerReviewStatus.rejected
                    ? Icons.cancel_rounded
                    : Icons.pause_circle_rounded,
            selected:
                currentStatus == BannerReviewStatus.rejected ||
                currentStatus == BannerReviewStatus.onHold,
            activeColor:
                currentStatus == BannerReviewStatus.rejected
                    ? BannerReviewStatus.rejected.color
                    : BannerReviewStatus.onHold.color,
            enabled: !isUpdating,
            onPressed:
                () => onSelected(
                  currentStatus == BannerReviewStatus.rejected
                      ? BannerReviewStatus.onHold
                      : BannerReviewStatus.rejected,
                ),
          ),
        ),
      ],
    );
  }
}

class _BannerReviewToggleButton extends StatelessWidget {
  const _BannerReviewToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? activeColor : const Color(0xFF4B5563);
    final backgroundColor =
        selected
            ? activeColor.withValues(alpha: 0.14)
            : const Color(0xFFF8FAFC);
    final borderColor = selected ? activeColor : const Color(0xFFE5E7EB);

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 15),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: BorderSide(color: borderColor),
        minimumSize: const Size.fromHeight(38),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _AdminTimelineAccessCard extends StatelessWidget {
  const _AdminTimelineAccessCard({
    required this.post,
    required this.isUpdating,
    required this.onUpdateStatus,
  });

  final AdminTimelineItem post;
  final bool isUpdating;
  final ValueChanged<TimelineReviewStatus> onUpdateStatus;

  Color get _headerStartColor => switch (post.sourceType.toUpperCase()) {
    'MEMBER' => const Color(0xFF15803D),
    'VENDOR' => const Color(0xFFEA580C),
    _ => const Color(0xFF2563EB),
  };

  Color get _headerEndColor => switch (post.sourceType.toUpperCase()) {
    'MEMBER' => const Color(0xFF16A34A),
    'VENDOR' => const Color(0xFFF59E0B),
    _ => const Color(0xFF1D4ED8),
  };

  @override
  Widget build(BuildContext context) {
    return _EntityCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_headerStartColor, _headerEndColor],
              ),
            ),
            child: Row(
              children: [
                _TimelinePosterAvatar(
                  name: post.sourceName,
                  color: _headerStartColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        post.postedBy.trim().isEmpty
                            ? post.postedOn
                            : '${post.postedBy} • ${post.postedOn}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DirectoryFactPill(
                icon: Icons.account_tree_outlined,
                label: post.sourceType,
              ),
              if (post.displayEnd.isNotEmpty)
                _DirectoryFactPill(
                  icon: Icons.event_available_rounded,
                  label: 'Visible till ${post.displayEnd}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.caption,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 15,
              height: 1.55,
            ),
          ),
          if (post.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _BackendImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.contain,
                  fallback: const ColoredBox(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ],
          if (post.contactNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DirectoryDetailLine(
              icon: Icons.call_outlined,
              label: post.contactNumber,
              onTap:
                  () => _showPhoneActionsSheet(
                    context,
                    title: post.displayTitle,
                    phoneNumber: post.contactNumber,
                  ),
            ),
          ],
          const SizedBox(height: 14),
          _TimelineReviewStatusActionRow(
            currentStatus: post.reviewStatus,
            isUpdating: isUpdating,
            onSelected: onUpdateStatus,
          ),
          if (isUpdating) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineBrowseCard extends StatelessWidget {
  const _TimelineBrowseCard({required this.post});

  final AdminTimelineItem post;

  Color get _headerStartColor => switch (post.sourceType.toUpperCase()) {
    'MEMBER' => const Color(0xFF15803D),
    'VENDOR' => const Color(0xFFEA580C),
    _ => const Color(0xFF2563EB),
  };

  Color get _headerEndColor => switch (post.sourceType.toUpperCase()) {
    'MEMBER' => const Color(0xFF16A34A),
    'VENDOR' => const Color(0xFFF59E0B),
    _ => const Color(0xFF1D4ED8),
  };

  @override
  Widget build(BuildContext context) {
    return _EntityCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_headerStartColor, _headerEndColor],
              ),
            ),
            child: Row(
              children: [
                _TimelinePosterAvatar(
                  name: post.sourceName,
                  color: _headerStartColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        post.postedBy.trim().isEmpty
                            ? post.postedOn
                            : '${post.postedBy} • ${post.postedOn}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DirectoryFactPill(
                icon: Icons.account_tree_outlined,
                label: post.sourceType,
              ),
              _DirectoryFactPill(
                icon: Icons.info_outline_rounded,
                label: post.reviewStatus.label,
              ),
              if (post.displayEnd.isNotEmpty)
                _DirectoryFactPill(
                  icon: Icons.event_available_rounded,
                  label: 'Visible till ${post.displayEnd}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.caption,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 15,
              height: 1.55,
            ),
          ),
          if (post.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _BackendImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.contain,
                  fallback: const ColoredBox(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ],
          if (post.contactNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DirectoryDetailLine(
              icon: Icons.call_outlined,
              label: post.contactNumber,
              onTap:
                  () => _showPhoneActionsSheet(
                    context,
                    title: post.displayTitle,
                    phoneNumber: post.contactNumber,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineReviewStatusActionRow extends StatelessWidget {
  const _TimelineReviewStatusActionRow({
    required this.currentStatus,
    required this.isUpdating,
    required this.onSelected,
  });

  final TimelineReviewStatus currentStatus;
  final bool isUpdating;
  final ValueChanged<TimelineReviewStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimelineReviewToggleButton(
            label: 'Approve / Pending',
            icon:
                currentStatus == TimelineReviewStatus.approved
                    ? Icons.check_circle_rounded
                    : Icons.hourglass_top_rounded,
            selected:
                currentStatus == TimelineReviewStatus.approved ||
                currentStatus == TimelineReviewStatus.pending,
            activeColor:
                currentStatus == TimelineReviewStatus.approved
                    ? TimelineReviewStatus.approved.color
                    : TimelineReviewStatus.pending.color,
            enabled: !isUpdating,
            onPressed:
                () => onSelected(
                  currentStatus == TimelineReviewStatus.approved
                      ? TimelineReviewStatus.pending
                      : TimelineReviewStatus.approved,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TimelineReviewToggleButton(
            label: 'Reject / Hold',
            icon:
                currentStatus == TimelineReviewStatus.rejected
                    ? Icons.cancel_rounded
                    : Icons.pause_circle_rounded,
            selected:
                currentStatus == TimelineReviewStatus.rejected ||
                currentStatus == TimelineReviewStatus.onHold,
            activeColor:
                currentStatus == TimelineReviewStatus.rejected
                    ? TimelineReviewStatus.rejected.color
                    : TimelineReviewStatus.onHold.color,
            enabled: !isUpdating,
            onPressed:
                () => onSelected(
                  currentStatus == TimelineReviewStatus.rejected
                      ? TimelineReviewStatus.onHold
                      : TimelineReviewStatus.rejected,
                ),
          ),
        ),
      ],
    );
  }
}

class _TimelineReviewToggleButton extends StatelessWidget {
  const _TimelineReviewToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? activeColor : const Color(0xFF4B5563);
    final backgroundColor =
        selected
            ? activeColor.withValues(alpha: 0.14)
            : const Color(0xFFF8FAFC);
    final borderColor = selected ? activeColor : const Color(0xFFE5E7EB);

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 15),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: BorderSide(color: borderColor),
        minimumSize: const Size.fromHeight(38),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _AdminEventsSectionState extends State<_AdminEventsSection> {
  AdminEventDraft? _draft;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startEdit(AdminEventItem event) {
    setState(() {
      _draft = AdminEventDraft.fromEvent(event);
    });
  }

  void _resetDraft() {
    setState(() {
      _draft = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents =
        widget.events.where((event) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          return [
            event.name,
            event.type,
            event.venue,
            event.audience,
            event.summary,
            event.date,
          ].join(' ').toLowerCase().contains(query);
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Event Access Controls',
          subtitle:
              'Search, review, edit, and delete live events while keeping event creation in the main Events area.',
        ),
        const SizedBox(height: 14),
        _AdminToolbarSearch(
          controller: _searchController,
          hintText: 'Search event name, type, venue, audience...',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        if (filteredEvents.isEmpty)
          const _EmptyStateCard(
            title: 'No events found',
            subtitle: 'No events match the current search.',
          )
        else
          ...filteredEvents.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _EventTimelineCard(
                event: event,
                accentLabel: event.liveStatus,
                showEntryCharges: true,
                footer: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            widget.savingEventId != null
                                ? null
                                : () => _startEdit(event),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            widget.savingEventId != null
                                ? null
                                : () => widget.onDeleteEvent(event.id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                isSaving: widget.savingEventId == event.id,
              ),
            ),
          ),
        if (_draft != null) ...[
          const SizedBox(height: 18),
          _AdminEventForm(
            draft: _draft!,
            eventTypes: widget.eventTypes,
            isSaving: widget.savingEventId == _draft!.id,
            onChanged: (draft) {
              setState(() {
                _draft = draft;
              });
            },
            onSave: () => widget.onSaveEvent(_draft!),
            onCancel: _resetDraft,
          ),
        ],
      ],
    );
  }
}

class _EventsArenaMasterSection extends StatelessWidget {
  const _EventsArenaMasterSection({
    required this.events,
    required this.eventTypes,
  });

  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final upcoming =
        events.where((event) => event.date.compareTo(today) >= 0).length;
    final completed =
        events.where((event) => event.date.compareTo(today) < 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Events Master',
          subtitle:
              'A quick overview of live events, event types, and what is scheduled next from the backend.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Total Events',
                value: '${events.length}',
                accent: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: 'Upcoming',
                value: '$upcoming',
                accent: const Color(0xFFF57C00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: 'Event Types',
                value: '${eventTypes.length}',
                accent: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (events.isEmpty)
          const _EmptyStateCard(
            title: 'No events created yet',
            subtitle:
                'Use Create New Event to publish your first event and start building the timeline.',
          )
        else ...[
          ...events
              .take(3)
              .map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _EventTimelineCard(
                    event: event,
                    accentLabel: event.liveStatus,
                  ),
                ),
              ),
          if (completed > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$completed completed event${completed == 1 ? '' : 's'} remain available in the timeline archive.',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
        ],
      ],
    );
  }
}

class _EventsArenaCreateSection extends StatefulWidget {
  const _EventsArenaCreateSection({
    required this.eventTypes,
    required this.savingEventId,
    required this.onSaveEvent,
  });

  final List<AdminEventTypeItem> eventTypes;
  final String? savingEventId;
  final Future<void> Function(AdminEventDraft draft) onSaveEvent;

  @override
  State<_EventsArenaCreateSection> createState() =>
      _EventsArenaCreateSectionState();
}

class _EventsArenaCreateSectionState extends State<_EventsArenaCreateSection> {
  AdminEventDraft _draft = AdminEventDraft.empty();

  Future<void> _pickBanner() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(
        bannerFile: AssociationUploadFile.fromPlatformFile(file),
        imageName: file.name,
      );
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'mov', 'avi', 'mkv', 'webm'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(
        videoFile: AssociationUploadFile.fromPlatformFile(file),
        videoName: file.name,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventTypes.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Create New Event',
            subtitle:
                'Set up at least one event type first so new events can be categorised correctly.',
          ),
          SizedBox(height: 14),
          _EmptyStateCard(
            title: 'No event types available yet',
            subtitle:
                'Open Type of Event first, create an event type, and then come back here to publish the event.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Create New Event',
          subtitle:
              'Use the same backend event flow as web, including banner picture and promo video uploads.',
        ),
        const SizedBox(height: 14),
        if (!_draft.canSubmit) ...[
          _EmptyStateCard(
            title: 'Event details are still incomplete',
            subtitle:
                _draft.validationMessage ??
                'Fill in the required event details before saving.',
          ),
          const SizedBox(height: 14),
        ],
        _AdminEventForm(
          draft: _draft,
          eventTypes: widget.eventTypes,
          isSaving: widget.savingEventId == '__new__',
          onChanged: (draft) => setState(() => _draft = draft),
          onSave: () => widget.onSaveEvent(_draft),
          onCancel: null,
          onPickBanner: _pickBanner,
          onPickVideo: _pickVideo,
        ),
      ],
    );
  }
}

class _EventsArenaTypeManager extends StatefulWidget {
  const _EventsArenaTypeManager({
    required this.items,
    required this.savingEventTypeId,
    required this.onSaveNewType,
    required this.onUpdateType,
  });

  final List<AdminEventTypeItem> items;
  final String? savingEventTypeId;
  final Future<void> Function(EventTypeDraft draft) onSaveNewType;
  final Future<void> Function(EventTypeDraft draft) onUpdateType;

  @override
  State<_EventsArenaTypeManager> createState() =>
      _EventsArenaTypeManagerState();
}

class _EventsArenaTypeManagerState extends State<_EventsArenaTypeManager> {
  EventTypeDraft _draft = const EventTypeDraft.empty();
  late List<EventTypeDraft> _editableTypes;

  @override
  void initState() {
    super.initState();
    _editableTypes = widget.items.map(EventTypeDraft.fromItem).toList();
  }

  @override
  void didUpdateWidget(covariant _EventsArenaTypeManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _editableTypes = widget.items.map(EventTypeDraft.fromItem).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Type of Event',
          subtitle:
              'Add new event types or update existing ones from the same backend catalog used across event creation.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              _AssociationTextField(
                label: 'New Event Type',
                value: _draft.title,
                onChanged:
                    (value) =>
                        setState(() => _draft = _draft.copyWith(title: value)),
              ),
              _AssociationTextField(
                label: 'Description',
                value: _draft.meta,
                onChanged:
                    (value) =>
                        setState(() => _draft = _draft.copyWith(meta: value)),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed:
                      widget.savingEventTypeId != null || !_draft.canSubmit
                          ? null
                          : () async {
                            await widget.onSaveNewType(_draft);
                            if (!mounted) return;
                            setState(() {
                              _draft = const EventTypeDraft.empty();
                            });
                          },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                  ),
                  child: Text(
                    widget.savingEventTypeId == '__new__'
                        ? 'Adding...'
                        : 'Add Type',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._editableTypes.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _AssociationTextField(
                    label: 'Type Name',
                    value: item.title,
                    onChanged: (value) {
                      setState(() {
                        final index = _editableTypes.indexWhere(
                          (entry) => entry.id == item.id,
                        );
                        _editableTypes[index] = item.copyWith(title: value);
                      });
                    },
                  ),
                  _AssociationTextField(
                    label: 'Description',
                    value: item.meta,
                    onChanged: (value) {
                      setState(() {
                        final index = _editableTypes.indexWhere(
                          (entry) => entry.id == item.id,
                        );
                        _editableTypes[index] = item.copyWith(meta: value);
                      });
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed:
                          widget.savingEventTypeId != null
                              ? null
                              : () => widget.onUpdateType(
                                _editableTypes.firstWhere(
                                  (entry) => entry.id == item.id,
                                ),
                              ),
                      child: Text(
                        widget.savingEventTypeId == item.id
                            ? 'Saving...'
                            : 'Save Type',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventsArenaTimelineSection extends StatefulWidget {
  const _EventsArenaTimelineSection({
    required this.events,
    required this.eventTypes,
    required this.canManage,
    required this.savingEventId,
    required this.onSaveEvent,
    required this.onDeleteEvent,
  });

  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;
  final bool canManage;
  final String? savingEventId;
  final Future<void> Function(AdminEventDraft draft) onSaveEvent;
  final Future<void> Function(String eventId) onDeleteEvent;

  @override
  State<_EventsArenaTimelineSection> createState() =>
      _EventsArenaTimelineSectionState();
}

class _EventsArenaTimelineSectionState
    extends State<_EventsArenaTimelineSection> {
  AdminEventDraft? _editingDraft;

  Future<void> _pickBanner() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null || _editingDraft == null) {
      return;
    }
    setState(() {
      _editingDraft = _editingDraft!.copyWith(
        bannerFile: AssociationUploadFile.fromPlatformFile(file),
        imageName: file.name,
      );
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'mov', 'avi', 'mkv', 'webm'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null || _editingDraft == null) {
      return;
    }
    setState(() {
      _editingDraft = _editingDraft!.copyWith(
        videoFile: AssociationUploadFile.fromPlatformFile(file),
        videoName: file.name,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = <AdminEventItem>[];
    final completed = <AdminEventItem>[];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (final event in widget.events) {
      if (event.date.compareTo(today) < 0) {
        completed.add(event);
      } else {
        upcoming.add(event);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Event Timeline',
          subtitle:
              'Browse upcoming and completed events from the live timeline.',
        ),
        const SizedBox(height: 14),
        if (widget.canManage && _editingDraft != null) ...[
          _AdminEventForm(
            draft: _editingDraft!,
            eventTypes: widget.eventTypes,
            isSaving: widget.savingEventId == _editingDraft!.id,
            onChanged: (draft) => setState(() => _editingDraft = draft),
            onSave: () => widget.onSaveEvent(_editingDraft!),
            onCancel: () => setState(() => _editingDraft = null),
            onPickBanner: _pickBanner,
            onPickVideo: _pickVideo,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.events.isEmpty)
          const _EmptyStateCard(
            title: 'No events yet',
            subtitle:
                'Create an event first to populate the live timeline and archive.',
          )
        else ...[
          if (upcoming.isNotEmpty) ...[
            const _SectionHeader(
              title: 'Upcoming',
              subtitle: 'Scheduled events that are still ahead of today.',
            ),
            const SizedBox(height: 12),
            ...upcoming.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child:
                    widget.canManage
                        ? _EditableEventTimelineCard(
                          event: event,
                          isSaving: widget.savingEventId == event.id,
                          onEdit:
                              () => setState(() {
                                _editingDraft = AdminEventDraft.fromEvent(
                                  event,
                                );
                              }),
                          onDelete: () => widget.onDeleteEvent(event.id),
                        )
                        : _EventTimelineCard(
                          event: event,
                          accentLabel: event.liveStatus,
                          showEntryCharges: true,
                        ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (completed.isNotEmpty) ...[
            const _SectionHeader(
              title: 'Completed',
              subtitle: 'Past events remain visible here as a simple archive.',
            ),
            const SizedBox(height: 12),
            ...completed.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child:
                    widget.canManage
                        ? _EditableEventTimelineCard(
                          event: event,
                          isSaving: widget.savingEventId == event.id,
                          onEdit:
                              () => setState(() {
                                _editingDraft = AdminEventDraft.fromEvent(
                                  event,
                                );
                              }),
                          onDelete: () => widget.onDeleteEvent(event.id),
                        )
                        : _EventTimelineCard(
                          event: event,
                          accentLabel: event.liveStatus,
                          showEntryCharges: true,
                        ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _EventTimelineCard extends StatelessWidget {
  const _EventTimelineCard({
    required this.event,
    required this.accentLabel,
    this.footer,
    this.showEntryCharges = false,
    this.isSaving = false,
  });

  final AdminEventItem event;
  final String accentLabel;
  final Widget? footer;
  final bool showEntryCharges;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                event.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171717),
                ),
              ),
            ),
            _LiveStatusBadge(status: accentLabel),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          [
            event.type,
            event.date,
            event.venue,
          ].where((value) => value.isNotEmpty).join(' • '),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF7C3AED),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (event.summary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            event.summary,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (event.audience.isNotEmpty)
              _MutedChip(icon: Icons.groups_rounded, label: event.audience),
            if (event.entryType.isNotEmpty)
              _MutedChip(
                icon: Icons.confirmation_number_outlined,
                label: event.entryType,
              ),
            if (showEntryCharges && event.entryCharges.isNotEmpty)
              _MutedChip(
                icon: Icons.currency_rupee_rounded,
                label: event.entryCharges,
              ),
            if (event.imageName.isNotEmpty)
              _MutedChip(icon: Icons.image_outlined, label: event.imageName),
            if (event.videoName.isNotEmpty)
              _MutedChip(
                icon: Icons.video_library_outlined,
                label: event.videoName,
              ),
          ],
        ),
        if (footer != null) ...[const SizedBox(height: 14), footer!],
        if (isSaving) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
        ],
      ],
    );
    return _EntityCardFrame(
      padding: const EdgeInsets.all(18),
      radius: 28,
      shadowColor: const Color(0x0D0F172A),
      shadowBlur: 24,
      shadowOffset: const Offset(0, 14),
      child: content,
    );
  }
}

class _EditableEventTimelineCard extends StatelessWidget {
  const _EditableEventTimelineCard({
    required this.event,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminEventItem event;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _EventTimelineCard(
      event: event,
      accentLabel: event.liveStatus,
      showEntryCharges: true,
      footer: Row(
        children: [
          OutlinedButton(
            onPressed: isSaving ? null : onEdit,
            child: const Text('Edit'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: isSaving ? null : onDelete,
            child: const Text('Delete'),
          ),
        ],
      ),
      isSaving: isSaving,
    );
  }
}

class _AdminEventForm extends StatelessWidget {
  const _AdminEventForm({
    required this.draft,
    required this.eventTypes,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
    this.onPickBanner,
    this.onPickVideo,
  });

  final AdminEventDraft draft;
  final List<AdminEventTypeItem> eventTypes;
  final bool isSaving;
  final ValueChanged<AdminEventDraft> onChanged;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final Future<void> Function()? onPickBanner;
  final Future<void> Function()? onPickVideo;

  @override
  Widget build(BuildContext context) {
    return _EntityCardFrame(
      padding: const EdgeInsets.all(18),
      radius: 28,
      shadowColor: const Color(0x0D0F172A),
      shadowBlur: 24,
      shadowOffset: const Offset(0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.id.isEmpty ? 'Create Event' : 'Edit Event',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _EventField(
                width: 280,
                child: _StableTextFormField(
                  key: ValueKey('event-name-${draft.id}'),
                  value: draft.name,
                  label: 'Event Name',
                  onChanged: (value) => onChanged(draft.copyWith(name: value)),
                ),
              ),
              _EventField(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('event-type-${draft.id}'),
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  value: draft.type.isEmpty ? null : draft.type,
                  items: [
                    ...eventTypes.map(
                      (type) => DropdownMenuItem(
                        value: type.title,
                        child: Text(type.title),
                      ),
                    ),
                  ],
                  onChanged:
                      (value) => onChanged(draft.copyWith(type: value ?? '')),
                ),
              ),
              _EventField(
                width: 180,
                child: _StableTextFormField(
                  key: ValueKey('event-date-${draft.id}'),
                  value: draft.date,
                  label: 'Date',
                  onChanged: (value) => onChanged(draft.copyWith(date: value)),
                ),
              ),
              _EventField(
                width: 240,
                child: _StableTextFormField(
                  key: ValueKey('event-venue-${draft.id}'),
                  value: draft.venue,
                  label: 'Venue',
                  onChanged: (value) => onChanged(draft.copyWith(venue: value)),
                ),
              ),
              _EventField(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('event-audience-${draft.id}'),
                  decoration: const InputDecoration(
                    labelText: 'Audience',
                    border: OutlineInputBorder(),
                  ),
                  value: draft.audience.isEmpty ? null : draft.audience,
                  items: const [
                    DropdownMenuItem(
                      value: 'Primary Members',
                      child: Text('Primary Members'),
                    ),
                    DropdownMenuItem(
                      value: 'Associate Members',
                      child: Text('Associate Members'),
                    ),
                    DropdownMenuItem(value: 'Guest', child: Text('Guest')),
                    DropdownMenuItem(
                      value: 'Open for All',
                      child: Text('Open for All'),
                    ),
                  ],
                  onChanged:
                      (value) =>
                          onChanged(draft.copyWith(audience: value ?? '')),
                ),
              ),
              _EventField(
                width: 180,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('event-entry-type-${draft.id}'),
                  decoration: const InputDecoration(
                    labelText: 'Entry Type',
                    border: OutlineInputBorder(),
                  ),
                  value: draft.entryType.isEmpty ? null : draft.entryType,
                  items: const [
                    DropdownMenuItem(value: 'Free', child: Text('Free')),
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  ],
                  onChanged:
                      (value) =>
                          onChanged(draft.copyWith(entryType: value ?? '')),
                ),
              ),
              _EventField(
                width: 180,
                child: _StableTextFormField(
                  key: ValueKey('event-entry-charges-${draft.id}'),
                  value: draft.entryCharges,
                  label: 'Entry Charges',
                  onChanged:
                      (value) => onChanged(draft.copyWith(entryCharges: value)),
                ),
              ),
              _EventField(
                width: 200,
                child: _StableTextFormField(
                  key: ValueKey('event-participation-${draft.id}'),
                  value: draft.participationCharges,
                  label: 'Participation Charges',
                  onChanged:
                      (value) => onChanged(
                        draft.copyWith(participationCharges: value),
                      ),
                ),
              ),
              _EventField(
                width: 150,
                child: _StableTextFormField(
                  key: ValueKey('event-start-${draft.id}'),
                  value: draft.startTime,
                  label: 'Start Time',
                  onChanged:
                      (value) => onChanged(draft.copyWith(startTime: value)),
                ),
              ),
              _EventField(
                width: 150,
                child: _StableTextFormField(
                  key: ValueKey('event-end-${draft.id}'),
                  value: draft.endTime,
                  label: 'End Time',
                  onChanged:
                      (value) => onChanged(draft.copyWith(endTime: value)),
                ),
              ),
              if (onPickBanner != null)
                _EventField(
                  width: 280,
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : () => onPickBanner!(),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      draft.imageName.isEmpty
                          ? 'Pick Event Banner'
                          : 'Banner: ${draft.imageName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              if (onPickVideo != null)
                _EventField(
                  width: 280,
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : () => onPickVideo!(),
                    icon: const Icon(Icons.video_library_outlined),
                    label: Text(
                      draft.videoName.isEmpty
                          ? 'Pick Promo Video'
                          : 'Video: ${draft.videoName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          if (draft.bannerUrl.isNotEmpty ||
              draft.promoVideoUrl.isNotEmpty ||
              draft.imageName.isNotEmpty ||
              draft.videoName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (draft.imageName.isNotEmpty)
                  _MutedChip(
                    icon: Icons.image_outlined,
                    label: draft.imageName,
                  ),
                if (draft.videoName.isNotEmpty)
                  _MutedChip(
                    icon: Icons.video_library_outlined,
                    label: draft.videoName,
                  ),
                if (draft.bannerUrl.isNotEmpty && draft.bannerFile == null)
                  const _MutedChip(
                    icon: Icons.image_search_outlined,
                    label: 'Current banner attached',
                  ),
                if (draft.promoVideoUrl.isNotEmpty && draft.videoFile == null)
                  const _MutedChip(
                    icon: Icons.movie_creation_outlined,
                    label: 'Current promo video attached',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _StableTextFormField(
            value: draft.summary,
            label: 'Event Summary',
            minLines: 3,
            maxLines: 5,
            onChanged: (value) => onChanged(draft.copyWith(summary: value)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onCancel != null)
                OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              if (onCancel != null) const SizedBox(width: 10),
              FilledButton(
                onPressed: isSaving || !draft.canSubmit ? null : onSave,
                child: Text(isSaving ? 'Saving...' : 'Save Event'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventField extends StatelessWidget {
  const _EventField({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _FeedInfoBanner extends StatelessWidget {
  const _FeedInfoBanner({required this.viewerRole, required this.postCount});

  final AppViewerRole viewerRole;
  final int postCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.newspaper_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              viewerRole.isAdmin
                  ? '$postCount posts loaded. Admin can switch each post between approved, rejected, and pending.'
                  : '$postCount approved posts are visible in ${viewerRole.label.toLowerCase()} mode.',
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberPostCard extends StatelessWidget {
  const _MemberPostCard({
    required this.post,
    required this.viewerRole,
    required this.isUpdating,
    required this.onUpdateStatus,
  });

  final MemberPostItem post;
  final AppViewerRole viewerRole;
  final bool isUpdating;
  final Future<void> Function(MemberPostItem, PostReviewStatus) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MemberAvatar(
                  name: post.member.name,
                  photoUrl: post.member.photoUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.member.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (post.member.company.isNotEmpty)
                            post.member.company,
                          post.postedOn,
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: post.reviewStatus),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Text(
              post.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Text(
              post.summary,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF374151),
                height: 1.55,
              ),
            ),
          ),
          if (post.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Text(
                post.body,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.55,
                ),
              ),
            ),
          const SizedBox(height: 14),
          _PostMediaPreview(post: post),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MutedChip(
                      icon: Icons.category_rounded,
                      label: post.postType,
                    ),
                    if (post.displayStart.isNotEmpty ||
                        post.displayEnd.isNotEmpty)
                      _MutedChip(
                        icon: Icons.schedule_rounded,
                        label: _displayWindowLabel(post),
                      ),
                  ],
                ),
                if (viewerRole.isAdmin) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  const Text(
                    'Post status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF171717),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        PostReviewStatus.values.map((status) {
                          final selected = post.reviewStatus == status;
                          return ChoiceChip(
                            label: Text(status.label),
                            selected: selected,
                            onSelected:
                                isUpdating
                                    ? null
                                    : (_) => onUpdateStatus(post, status),
                            showCheckmark: false,
                            selectedColor: status.color.withValues(alpha: 0.16),
                            labelStyle: TextStyle(
                              color:
                                  selected
                                      ? status.color
                                      : const Color(0xFF4B5563),
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide(
                              color:
                                  selected
                                      ? status.color
                                      : const Color(0xFFE5E7EB),
                            ),
                          );
                        }).toList(),
                  ),
                  if (isUpdating) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayWindowLabel(MemberPostItem post) {
    if (post.displayStart.isEmpty && post.displayEnd.isEmpty) {
      return 'No schedule';
    }
    if (post.displayEnd.isEmpty) {
      return 'From ${post.displayStart}';
    }
    if (post.displayStart.isEmpty) {
      return 'Until ${post.displayEnd}';
    }
    return '${post.displayStart} to ${post.displayEnd}';
  }
}

class _PostMediaPreview extends StatelessWidget {
  const _PostMediaPreview({required this.post});

  final MemberPostItem post;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = post.mediaUrl.trim();
    if (mediaUrl.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDE68A), Color(0xFFF9A8D4), Color(0xFFC4B5FD)],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_rounded,
              size: 38,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              post.postType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openPostMedia(context, mediaUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          constraints: const BoxConstraints(minHeight: 180, maxHeight: 280),
          color: const Color(0xFFF3F4F6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _BackendImage(
                imageUrl: mediaUrl,
                fit: BoxFit.contain,
                fallback: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    'Media could not be loaded.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.54),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_full_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Open',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPostMedia(BuildContext context, String mediaUrl) {
    showDialog<void>(
      context: context,
      builder:
          (context) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: _BackendImage(
                      imageUrl: mediaUrl,
                      fit: BoxFit.contain,
                      fallback: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Media could not be loaded.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                    ),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _MemberDirectorySection extends ConsumerStatefulWidget {
  const _MemberDirectorySection({
    required this.viewerRole,
    this.refreshToken = 0,
    this.initialFilter = MemberDirectoryFilter.all,
    this.lockFilter = false,
    this.title = 'Member Directory',
    this.subtitle =
        'Browse members alphabetically, filter by membership type, and search by name, company, city, or profile details.',
  });

  final AppViewerRole viewerRole;
  final int refreshToken;
  final MemberDirectoryFilter initialFilter;
  final bool lockFilter;
  final String title;
  final String subtitle;

  @override
  ConsumerState<_MemberDirectorySection> createState() =>
      _MemberDirectorySectionState();
}

class _MemberDirectorySectionState
    extends ConsumerState<_MemberDirectorySection> {
  static const int _pageSize = 20;
  static const double _scrollPrefetchThreshold = 200;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listController = ScrollController();
  Timer? _searchDebounce;
  String _query = '';
  late MemberDirectoryFilter _activeFilter;
  List<MemberDirectoryItem> _members = const [];
  int _currentPage = 0;
  int _totalCount = 0;
  int _requestGeneration = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    _listController.addListener(_handleScroll);
    unawaited(_loadFirstPage());
  }

  @override
  void didUpdateWidget(covariant _MemberDirectorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter ||
        oldWidget.viewerRole != widget.viewerRole) {
      _activeFilter = widget.initialFilter;
      unawaited(_loadFirstPage());
    } else if (oldWidget.refreshToken != widget.refreshToken) {
      unawaited(_loadFirstPage());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _listController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_listController.hasClients) {
      return;
    }
    if (_listController.position.extentAfter <= _scrollPrefetchThreshold) {
      unawaited(_loadNextPage());
    }
  }

  Future<void> _loadFirstPage() async {
    final generation = ++_requestGeneration;
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _currentPage = 0;
      _totalCount = 0;
      _errorMessage = null;
    });

    try {
      final page = await ref
          .read(apiClientProvider)
          .fetchMemberDirectoryPage(
            viewerRole: widget.viewerRole,
            page: 1,
            pageSize: _pageSize,
            search: _query,
            filter: _activeFilter,
          );
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _members = page.members;
        _currentPage = page.page;
        _totalCount = page.totalCount;
        _hasMore = page.hasMore;
        _isInitialLoading = false;
      });
      if (_listController.hasClients) {
        _listController.jumpTo(0);
      }
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _members = const [];
        _errorMessage = error.toString();
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final generation = _requestGeneration;
    setState(() {
      _isLoadingMore = true;
      _errorMessage = null;
    });

    try {
      final page = await ref
          .read(apiClientProvider)
          .fetchMemberDirectoryPage(
            viewerRole: widget.viewerRole,
            page: _currentPage + 1,
            pageSize: _pageSize,
            search: _query,
            filter: _activeFilter,
          );
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      final seenIds = _members.map((member) => member.id).toSet();
      final appendedMembers = [
        ..._members,
        ...page.members.where((member) => !seenIds.contains(member.id)),
      ];
      setState(() {
        _members = appendedMembers;
        _currentPage = page.page;
        _totalCount = page.totalCount;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _isLoadingMore = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    _query = value.trim();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      unawaited(_loadFirstPage());
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasLoadedMembers = _members.isNotEmpty;
    final listItemCount =
        hasLoadedMembers ? _members.length + 1 + (_isLoadingMore ? 1 : 0) : 0;
    final countLabel =
        _totalCount <= 0 ? 'Live directory' : '$_totalCount total';

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Members / ${widget.title}',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171717),
                    height: 1.05,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  countLabel,
                  style: const TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _scheduleSearch,
              decoration: const InputDecoration(
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded),
                hintText: 'Search by name, company, city, role, or intro',
              ),
            ),
          ),
          if (!widget.lockFilter) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: MemberDirectoryFilter.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final filter = MemberDirectoryFilter.values[index];
                  final selected = filter == _activeFilter;
                  return _DirectoryFilterChip(
                    label: filter.label,
                    icon: filter.icon,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _activeFilter = filter;
                      });
                      unawaited(_loadFirstPage());
                    },
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_isInitialLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else if (!hasLoadedMembers) ...[
            if (_errorMessage != null)
              _ErrorState(
                title: 'Could not load members',
                message: _errorMessage!,
                onRetry: _loadFirstPage,
              )
            else
              const _EmptyStateCard(
                title: 'No matching members',
                subtitle:
                    'Try another search term or add more member records in the backend.',
              ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                controller: _listController,
                physics: const BouncingScrollPhysics(),
                itemCount: listItemCount,
                itemBuilder: (context, index) {
                  if (index < _members.length) {
                    final member = _members[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _MemberDirectoryCard(member: member),
                    );
                  }

                  if (index == _members.length) {
                    if (_errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        child: _ErrorState(
                          title: 'Could not load more members',
                          message: _errorMessage!,
                          onRetry: _loadNextPage,
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: Center(
                        child: Text(
                          _hasMore
                              ? 'Scroll to load more members'
                              : 'Showing all $_totalCount members',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberDirectoryCard extends StatelessWidget {
  const _MemberDirectoryCard({required this.member});

  final MemberDirectoryItem member;

  @override
  Widget build(BuildContext context) {
    final secondaryFacts = <Widget>[
      if (member.roleTitle.isNotEmpty)
        _DirectoryRolePill(label: member.roleTitle),
      if (member.committeePost.isNotEmpty)
        _DirectoryFactPill(
          icon: Icons.badge_outlined,
          label: member.committeePost,
        ),
      if (member.membershipDetails.isNotEmpty)
        _DirectoryFactPill(
          icon: Icons.confirmation_number_outlined,
          label: member.membershipDetails,
        ),
    ];

    final detailLines = <Widget>[
      if (member.companyName.isNotEmpty)
        _DirectoryDetailLine(
          icon: Icons.business_outlined,
          label: member.companyName,
          emphasize: true,
        ),
      if (member.address.isNotEmpty)
        _DirectoryDetailLine(
          icon: Icons.location_on_outlined,
          label: member.address,
          maxLines: 2,
        ),
      if (member.email.isNotEmpty)
        _DirectoryDetailLine(
          icon: Icons.mail_outline_rounded,
          label: member.email,
          onTap: () => _openEmailComposer(member.email),
        ),
      if (member.phone.isNotEmpty)
        _DirectoryDetailLine(
          icon: Icons.call_outlined,
          label: member.phone,
          onTap:
              () => _showPhoneActionsSheet(
                context,
                title: member.name,
                phoneNumber: member.phone,
              ),
        ),
    ];

    return _ReusableMemberCard(
      name: member.name,
      photoUrl: member.photoUrl,
      primaryLabel: member.companyName,
      summary: member.memberBio,
      factPills: secondaryFacts,
      detailLines: detailLines,
    );
  }
}

class _EntityCardFrame extends StatelessWidget {
  const _EntityCardFrame({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.shadowColor = const Color(0x0A0F172A),
    this.shadowBlur = 18,
    this.shadowOffset = const Offset(0, 10),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlur,
            offset: shadowOffset,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReusableMemberCard extends StatelessWidget {
  const _ReusableMemberCard({
    required this.name,
    required this.photoUrl,
    this.primaryLabel = '',
    this.summary = '',
    this.factPills = const [],
    this.detailLines = const [],
    this.leadingControl,
    this.trailing,
    this.footer,
    this.showHeroImage = false,
    this.useCircularHeroAvatar = true,
    this.heroHeight = 148,
    this.summaryMaxLines,
    this.padding = const EdgeInsets.all(16),
    this.heroBottomSpacing = 12,
    this.sectionSpacing = 12,
    this.detailsTopSpacing = 14,
    this.detailsDividerSpacing = 12,
    this.detailLineSpacing = 9,
    this.onHeaderTap,
  });

  final String name;
  final String photoUrl;
  final String primaryLabel;
  final String summary;
  final List<Widget> factPills;
  final List<Widget> detailLines;
  final Widget? leadingControl;
  final Widget? trailing;
  final Widget? footer;
  final bool showHeroImage;
  final bool useCircularHeroAvatar;
  final double heroHeight;
  final int? summaryMaxLines;
  final EdgeInsetsGeometry padding;
  final double heroBottomSpacing;
  final double sectionSpacing;
  final double detailsTopSpacing;
  final double detailsDividerSpacing;
  final double detailLineSpacing;
  final VoidCallback? onHeaderTap;

  @override
  Widget build(BuildContext context) {
    return _EntityCardFrame(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeroImage) ...[
            SizedBox(
              width: double.infinity,
              height: heroHeight,
              child:
                  useCircularHeroAvatar
                      ? Center(
                        child: _MemberAvatar(
                          name: name,
                          photoUrl: photoUrl,
                          size: heroHeight.clamp(88.0, 116.0),
                        ),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _CommitteeThumbnail(
                          name: name,
                          photoUrl: photoUrl,
                        ),
                      ),
            ),
            SizedBox(height: heroBottomSpacing),
          ],
          InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leadingControl != null) ...[
                  leadingControl!,
                  const SizedBox(width: 8),
                ],
                if (!showHeroImage) ...[
                  _MemberAvatar(name: name, photoUrl: photoUrl, size: 50),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                          height: 1.15,
                        ),
                      ),
                      if (primaryLabel.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          primaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  Flexible(child: trailing!),
                ],
              ],
            ),
          ),
          if (factPills.isNotEmpty) ...[
            SizedBox(height: sectionSpacing),
            Wrap(spacing: 8, runSpacing: 8, children: factPills),
          ],
          if (summary.trim().isNotEmpty) ...[
            SizedBox(height: sectionSpacing),
            Text(
              summary,
              maxLines: summaryMaxLines ?? (showHeroImage ? 4 : 2),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.45,
              ),
            ),
          ],
          if (detailLines.isNotEmpty) ...[
            SizedBox(height: detailsTopSpacing),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            SizedBox(height: detailsDividerSpacing),
            ...detailLines.indexed.expand(
              (entry) => [
                entry.$2,
                if (entry.$1 != detailLines.length - 1)
                  SizedBox(height: detailLineSpacing),
              ],
            ),
          ],
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }
}

class _DirectoryRolePill extends StatelessWidget {
  const _DirectoryRolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF6D28D9),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DirectoryFilterChip extends StatelessWidget {
  const _DirectoryFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF3E8FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? const Color(0xFF9333EA) : const Color(0xFFE5E7EB),
            ),
            boxShadow:
                selected
                    ? const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    selected
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color:
                      selected
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF4B5563),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectoryFactPill extends StatelessWidget {
  const _DirectoryFactPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryDetailLine extends StatelessWidget {
  const _DirectoryDetailLine({
    required this.icon,
    required this.label,
    this.maxLines = 1,
    this.emphasize = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int maxLines;
  final bool emphasize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final line = Row(
      crossAxisAlignment:
          maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
          child: Icon(
            icon,
            size: 16,
            color:
                onTap != null
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color:
                  onTap != null
                      ? const Color(0xFF5B21B6)
                      : emphasize
                      ? const Color(0xFF1F2937)
                      : const Color(0xFF6B7280),
              fontWeight:
                  onTap != null
                      ? FontWeight.w700
                      : emphasize
                      ? FontWeight.w700
                      : FontWeight.w500,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) {
      return line;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: line,
      ),
    );
  }
}

Future<void> _showPhoneActionsSheet(
  BuildContext context, {
  required String title,
  required String phoneNumber,
}) async {
  final phoneDigits = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  if (phoneDigits.isEmpty) {
    return;
  }

  Future<void> openExternalLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                phoneNumber,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFECFDF5),
                  foregroundColor: Color(0xFF047857),
                  child: Icon(Icons.call_rounded),
                ),
                title: const Text('Call now'),
                subtitle: const Text('Open the dialer with this number'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await openExternalLink('tel:$phoneDigits');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  foregroundColor: Color(0xFF15803D),
                  child: Icon(Icons.message_rounded),
                ),
                title: const Text('WhatsApp'),
                subtitle: const Text('Start a chat on WhatsApp'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final whatsappDigits = phoneDigits.replaceAll('+', '');
                  await openExternalLink('https://wa.me/$whatsappDigits');
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _openEmailComposer(String emailAddress) async {
  final trimmed = emailAddress.trim();
  if (trimmed.isEmpty) {
    return;
  }
  final uri = Uri(scheme: 'mailto', path: trimmed);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.name,
    required this.photoUrl,
    this.size = 48,
  });

  final String name;
  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials =
        name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: _BackendImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            fallback: _MemberAvatarFallback(initials: initials, size: size),
          ),
        ),
      );
    }

    return _MemberAvatarFallback(initials: initials, size: size);
  }
}

class _MemberAvatarFallback extends StatelessWidget {
  const _MemberAvatarFallback({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'M' : initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PostReviewStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LiveStatusBadge extends StatelessWidget {
  const _LiveStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color =
        normalized == 'completed'
            ? const Color(0xFF6B7280)
            : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MutedChip extends StatelessWidget {
  const _MutedChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderArenaContent extends StatelessWidget {
  const _PlaceholderArenaContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SectionHeader(
          title: 'Priority Actions',
          subtitle: 'The first admin modules we can wire up next.',
        ),
        SizedBox(height: 14),
        _ActionCard(
          icon: Icons.groups_rounded,
          title: 'Workspace',
          subtitle:
              'Key admin tools live here already, and the remaining workflows can be polished into the same app shell.',
        ),
        SizedBox(height: 12),
        _ActionCard(
          icon: Icons.receipt_long_rounded,
          title: 'Billing & dues',
          subtitle: 'Track collections, unpaid balances, and receipts.',
        ),
      ],
    );
  }
}

class _LoadingState extends StatefulWidget {
  const _LoadingState();

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1D6D8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 6.283185307179586,
                    child: child,
                  );
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: _nimaBrandRedDark,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Refreshing your data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while the latest updates load into this section.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              const _NimaLoadingDots(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _EmptyStateCard(
      title: title,
      subtitle: message,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171717),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => onAction!.call(),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.showAccent = false,
  });

  final String title;
  final String subtitle;
  final Color? titleColor;
  final bool showAccent;

  @override
  Widget build(BuildContext context) {
    final resolvedTitleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: titleColor ?? const Color(0xFF171717),
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAccent) ...[
          Container(
            width: 52,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(title, style: resolvedTitleStyle),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
              ),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              selected
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              selected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.16))
                  : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSubItem extends StatelessWidget {
  const _DrawerSubItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              selected
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFFF59E0B) : Colors.white54,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBottomBar extends StatelessWidget {
  const _AdminBottomBar({
    required this.viewerRole,
    required this.selectedArena,
    required this.onArenaSelected,
    required this.onTimelinePressed,
  });

  final AppViewerRole viewerRole;
  final AppArena selectedArena;
  final ValueChanged<AppArena> onArenaSelected;
  final VoidCallback onTimelinePressed;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppArena.dashboard, Icons.dashboard_rounded, 'Home'),
      (AppArena.association, Icons.apartment_rounded, 'Assoc'),
      (
        viewerRole.isVendor ? AppArena.member : AppArena.vendor,
        viewerRole.isVendor ? Icons.groups_rounded : Icons.storefront_rounded,
        viewerRole.isVendor ? 'Members' : 'Vendor',
      ),
      (AppArena.events, Icons.event_available_rounded, 'Events'),
    ];
    final leadingItems = items.take(2).toList();
    final trailingItems = items.skip(2).toList();

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: SizedBox(
        height: 90,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD7DCE2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x180F172A),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            leadingItems
                                .map(
                                  (item) => Expanded(
                                    child: _BottomNavItem(
                                      icon: item.$2,
                                      label: item.$3,
                                      active: selectedArena == item.$1,
                                      onTap: () => onArenaSelected(item.$1),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(width: 76),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            trailingItems
                                .map(
                                  (item) => Expanded(
                                    child: _BottomNavItem(
                                      icon: item.$2,
                                      label: item.$3,
                                      active: selectedArena == item.$1,
                                      onTap: () => onArenaSelected(item.$1),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -12,
              child: _TimelineDockButton(
                active: selectedArena == AppArena.timeline,
                onTap: onTimelinePressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineDockButton extends StatefulWidget {
  const _TimelineDockButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  State<_TimelineDockButton> createState() => _TimelineDockButtonState();
}

class _TimelineDockButtonState extends State<_TimelineDockButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _offsetAnimation = Tween<double>(
      begin: 0,
      end: -4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offsetAnimation.value),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 74,
          height: 74,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.active ? const Color(0xFFF97316) : Colors.white,
            border: Border.all(
              color:
                  widget.active
                      ? const Color(0xFFE21E23)
                      : const Color(0xFFE21E23),
              width: widget.active ? 2.2 : 1.6,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F0F172A),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active)
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              Text(
                'N',
                style: TextStyle(
                  color: widget.active ? Colors.white : const Color(0xFFE21E23),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF111827) : const Color(0xFF6B7280);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE2E8F0) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
