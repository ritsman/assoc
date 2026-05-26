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
  MemberMasterDraft? _memberMasterDraft;
  String? _editingMemberMasterId;
  bool _isSavingMemberMaster = false;

  Future<void> _refresh() async {
    ref.invalidate(memberDirectoryProvider);
    ref.invalidate(tenantProvider);
    ref.invalidate(memberArenaDataProvider(widget.viewerRole));
    await ref.read(memberArenaDataProvider(widget.viewerRole).future);
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

  void _openMemberMasterEditor([MemberDirectoryItem? member]) {
    setState(() {
      _editingMemberMasterId = member?.id ?? '';
      _memberMasterDraft =
          member == null
              ? const MemberMasterDraft.empty()
              : MemberMasterDraft.fromMember(member);
    });
  }

  void _closeMemberMasterEditor() {
    setState(() {
      _editingMemberMasterId = null;
      _memberMasterDraft = null;
    });
  }

  Future<void> _saveMemberMaster() async {
    if (_memberMasterDraft == null || _isSavingMemberMaster) {
      return;
    }

    setState(() {
      _isSavingMemberMaster = true;
    });
    try {
      await ref
          .read(apiClientProvider)
          .saveMemberRecord(draft: _memberMasterDraft!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _closeMemberMasterEditor();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _memberMasterDraft!.id.isEmpty
                ? 'Member created.'
                : 'Member updated.',
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
      if (_editingMemberMasterId == memberId) {
        _closeMemberMasterEditor();
      }
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
    final memberDataAsync = ref.watch(
      memberArenaDataProvider(widget.viewerRole),
    );
    return memberDataAsync.when(
      loading: () => const _LoadingState(),
      error:
          (error, _) => _ErrorState(
            title: 'Could not load member arena',
            message: error.toString(),
            onRetry: _refresh,
          ),
      data: (data) {
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
            if (widget.section == MemberArenaSection.media)
              _MemberMediaView(
                viewerRole: widget.viewerRole,
                tenant: ref.watch(tenantProvider).valueOrNull,
                onNavigateToMemberArena:
                    () => widget.onSectionSelected(MemberArenaSection.media),
                child: _MemberMediaSection(
                  posts: data.posts,
                  viewerRole: widget.viewerRole,
                  updatingPostId: _updatingPostId,
                  onUpdateStatus: _updatePostStatus,
                ),
              )
            else if (widget.section == MemberArenaSection.directory)
              _MemberDirectoryView(
                tenant: ref.watch(tenantProvider).valueOrNull,
                onNavigateToMemberArena:
                    () =>
                        widget.onSectionSelected(MemberArenaSection.directory),
                child: _MemberDirectorySection(members: data.members),
              )
            else if (widget.section == MemberArenaSection.master)
              _MemberMasterView(
                tenant: ref.watch(tenantProvider).valueOrNull,
                onNavigateToMemberArena:
                    () => widget.onSectionSelected(MemberArenaSection.master),
                child: _AssociationMasterSection(
                  canManage: widget.viewerRole.isAdmin,
                  members: [...data.members]..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  ),
                  draft: _memberMasterDraft,
                  editingMemberId: _editingMemberMasterId,
                  isSaving: _isSavingMemberMaster,
                  onOpenEditor: _openMemberMasterEditor,
                  onCancelEdit: _closeMemberMasterEditor,
                  onDraftChanged:
                      (draft) => setState(() => _memberMasterDraft = draft),
                  onSave: _saveMemberMaster,
                  onDelete: _deleteMemberMaster,
                ),
              )
            else
              _MemberFilteredDirectoryView(
                tenant: ref.watch(tenantProvider).valueOrNull,
                section: widget.section,
                onNavigateToMemberArena:
                    () => widget.onSectionSelected(widget.section),
                child: _FilteredMemberDirectorySection(
                  members: data.members,
                  section: widget.section,
                ),
              ),
          ],
        );
      },
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
    required this.onOpenProfile,
  });

  final AppViewerRole viewerRole;
  final VoidCallback onOpenProfile;

  @override
  ConsumerState<VendorArenaPanel> createState() => _VendorArenaPanelState();
}

class _VendorArenaPanelState extends ConsumerState<VendorArenaPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  String? _selectedSubCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(vendorDirectoryProvider);
    await ref.read(vendorDirectoryProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewerRole.isVendor) {
      return _VendorSelfServicePanel(onOpenProfile: widget.onOpenProfile);
    }
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
        for (final vendor in vendors) {
          final category = vendor.category.trim();
          final subCategory = vendor.vendorType.trim();
          if (category.isEmpty && subCategory.isEmpty) {
            continue;
          }
          final key = category.isEmpty ? 'Uncategorized' : category;
          categoryMap.putIfAbsent(key, () => <String>{});
          if (subCategory.isNotEmpty) {
            categoryMap[key]!.add(subCategory);
          }
        }
        final sortedCategories =
            categoryMap.entries.toList()..sort(
              (left, right) =>
                  left.key.toLowerCase().compareTo(right.key.toLowerCase()),
            );
        final filteredVendors =
            vendors.where((vendor) {
                final category = vendor.category.trim();
                final subCategory = vendor.vendorType.trim();
                final categoryKey =
                    category.isEmpty ? 'Uncategorized' : category;

                if (_selectedCategory != null &&
                    categoryKey.toLowerCase() !=
                        _selectedCategory!.trim().toLowerCase()) {
                  return false;
                }

                if (_selectedSubCategory != null &&
                    subCategory.toLowerCase() !=
                        _selectedSubCategory!.trim().toLowerCase()) {
                  return false;
                }

                if (query.isEmpty) {
                  return true;
                }
                return [
                  vendor.displayName,
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
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded),
                  hintText: 'Search by name, city, or category',
                ),
              ),
            ),
            if (_selectedCategory != null || _selectedSubCategory != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedCategory != null)
                    _DirectoryFilterChip(
                      label: _selectedCategory!,
                      icon: Icons.category_rounded,
                      selected: true,
                      onTap: () {
                        setState(() {
                          _selectedCategory = null;
                          _selectedSubCategory = null;
                        });
                      },
                    ),
                  if (_selectedSubCategory != null)
                    _DirectoryFilterChip(
                      label: _selectedSubCategory!,
                      icon: Icons.subdirectory_arrow_right,
                      selected: true,
                      onTap: () {
                        setState(() {
                          _selectedSubCategory = null;
                        });
                      },
                    ),
                  _DirectoryFilterChip(
                    label: 'Clear filters',
                    icon: Icons.filter_alt_off_rounded,
                    selected: false,
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedSubCategory = null;
                      });
                    },
                  ),
                ],
              ),
            ],
            if (sortedCategories.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
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
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  title: const Text(
                    'Categories And Sub Categories',
                    style: TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${sortedCategories.length} categories available',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    for (final entry in sortedCategories) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (_selectedCategory == entry.key &&
                                      _selectedSubCategory == null) {
                                    _selectedCategory = null;
                                  } else {
                                    _selectedCategory = entry.key;
                                    _selectedSubCategory = null;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: Color(0xFF171717),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (_selectedCategory == entry.key &&
                                        _selectedSubCategory == null)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF7C3AED),
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (entry.value.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    (entry.value.toList()..sort(
                                          (left, right) => left
                                              .toLowerCase()
                                              .compareTo(right.toLowerCase()),
                                        ))
                                        .map(
                                          (subCategory) => _DirectoryFilterChip(
                                            label: subCategory,
                                            icon:
                                                Icons.subdirectory_arrow_right,
                                            selected:
                                                _selectedCategory ==
                                                    entry.key &&
                                                _selectedSubCategory ==
                                                    subCategory,
                                            onTap: () {
                                              setState(() {
                                                if (_selectedCategory ==
                                                        entry.key &&
                                                    _selectedSubCategory ==
                                                        subCategory) {
                                                  _selectedSubCategory = null;
                                                } else {
                                                  _selectedCategory = entry.key;
                                                  _selectedSubCategory =
                                                      subCategory;
                                                }
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              const Text(
                                'No sub category added yet.',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (filteredVendors.isEmpty)
              _EmptyStateCard(
                title: 'No vendors found',
                subtitle:
                    _selectedCategory != null || _selectedSubCategory != null
                        ? 'No suppliers match the selected category filter right now.'
                        : 'Try another name, city, or category to find matching vendors.',
              )
            else
              ...filteredVendors.map(
                (vendor) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _VendorDirectoryCard(vendor: vendor),
                ),
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
                  'Your vendor area is now private. Other vendors are hidden here, while you can still use the member arena to discover association members.',
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
                      'Use the member arena to browse association members and find contacts.',
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
            _DashboardAssociationHeader(associationName: data.associationName),
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
            const SizedBox(height: 16),
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
        label: 'Association',
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
          label: 'Member',
          icon: Icons.people_alt_rounded,
          colors: const [Color(0xFF065F46), Color(0xFF10B981)],
          onTap: onOpenMemberArena,
        ),
      (
        label: viewerRole.isVendor ? 'My Vendor' : 'Vendor',
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
        label: 'Profile',
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
            'Explore Arenas',
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

class _DashboardAssociationHeader extends StatelessWidget {
  const _DashboardAssociationHeader({required this.associationName});

  final String associationName;

  @override
  Widget build(BuildContext context) {
    final resolvedAssociationName =
        associationName.trim().isEmpty ? 'NIMA' : associationName.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF2F2)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0DCDD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const _NimaBrandLockup(wordmarkWidth: 190, compact: true),
          const SizedBox(height: 14),
          Text(
            resolvedAssociationName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _nimaInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Official member dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _nimaMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class TimelinePanel extends ConsumerWidget {
  const TimelinePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    Future<void> refresh() async {
      ref.invalidate(dashboardDataProvider);
      await ref.read(dashboardDataProvider.future);
    }

    return dashboardDataAsync.when(
      loading: () => const _LoadingState(),
      error:
          (error, _) => _ErrorState(
            title: 'Could not load timeline',
            message: error.toString(),
            onRetry: refresh,
          ),
      data:
          (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ),
              const SizedBox(height: 8),
              _TimelineStackFeed(posts: data.timelinePosts),
            ],
          ),
    );
  }
}

class _AdminArenaPanelState extends ConsumerState<AdminArenaPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _updatingMemberId;
  String? _updatingPostId;
  String? _updatingVendorId;
  String? _updatingBannerId;
  String? _updatingTimelineId;
  String? _savingEventId;

  @override
  void didUpdateWidget(covariant AdminArenaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      await _refresh();
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

  @override
  Widget build(BuildContext context) {
    final adminArenaDataAsync = ref.watch(adminArenaDataProvider);

    return adminArenaDataAsync.when(
      loading: () => const _LoadingState(),
      error:
          (error, _) => _ErrorState(
            title: 'Could not load admin arena',
            message: error.toString(),
            onRetry: _refresh,
          ),
      data: (data) {
        final normalizedQuery = _query.trim().toLowerCase();
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
        final filteredVendors =
            data.vendors.where((vendor) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return [
                vendor.displayName,
                vendor.contactPerson,
                vendor.email,
                vendor.phone,
                vendor.city,
                vendor.category,
                vendor.vendorType,
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
          tenant: ref.watch(tenantProvider).valueOrNull,
          section: widget.section,
          onNavigateToAdminArena:
              () => widget.onSectionSelected(widget.section),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
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
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          icon: Icon(Icons.search_rounded),
                          hintText:
                              'Search members, posts, vendors, banners, or events',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                AdminArenaSection.vendorAccess => _AdminVendorAccessWorkspace(
                  vendors: filteredVendors,
                  updatingVendorId: _updatingVendorId,
                  onUpdateVendorAccess: _updateVendorAccess,
                ),
                AdminArenaSection.bannerAccess => _AdminBannerAccessWorkspace(
                  banners: filteredBanners,
                  updatingBannerId: _updatingBannerId,
                  onUpdateBannerStatus: _updateBannerStatus,
                ),
                AdminArenaSection.timelineAccess =>
                  _AdminTimelineAccessWorkspace(
                    posts: filteredTimelinePosts,
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
  AssociationProfileDraft? _draft;
  AssociationAboutDraft? _aboutDraft;
  AssociationCircularDraft? _circularDraft;
  MemberMasterDraft? _memberMasterDraft;
  String? _editingMemberMasterId;
  String? _editingCircularId;
  final Set<String> _selectedGalleryItemIds = <String>{};
  bool _isEditing = false;
  bool _isEditingAbout = false;
  bool _isSaving = false;
  bool _isSavingGallery = false;

  Future<void> _refresh() async {
    ref.invalidate(tenantProvider);
    ref.invalidate(memberArenaDataProvider);
    await Future.wait([
      ref.refresh(associationProfileProvider.future),
      ref.refresh(associationAboutProvider.future),
      ref.refresh(memberDirectoryProvider.future),
      ref.refresh(associationCircularLibraryProvider.future),
    ]);
  }

  Future<void> _saveProfile() async {
    if (_draft == null || _isSaving) {
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
        const SnackBar(content: Text('Association profile saved.')),
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

  Future<void> _pickGalleryImages(String associationId) async {
    if (_isSavingGallery) {
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
          .uploadAssociationGalleryImages(
            associationId: associationId,
            files: files,
          );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            files.length == 1
                ? 'Gallery image added.'
                : '${files.length} gallery images added.',
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

  void _toggleGallerySelection(String galleryItemId) {
    setState(() {
      if (_selectedGalleryItemIds.contains(galleryItemId)) {
        _selectedGalleryItemIds.remove(galleryItemId);
      } else {
        _selectedGalleryItemIds.add(galleryItemId);
      }
    });
  }

  void _clearGallerySelection() {
    setState(() {
      _selectedGalleryItemIds.clear();
    });
  }

  Future<void> _deleteSelectedGalleryItems(String associationId) async {
    if (_selectedGalleryItemIds.isEmpty || _isSavingGallery) {
      return;
    }

    final idsToDelete = _selectedGalleryItemIds.toList(growable: false);

    setState(() {
      _isSavingGallery = true;
    });

    try {
      for (final galleryItemId in idsToDelete) {
        await ref
            .read(apiClientProvider)
            .deleteAssociationGalleryItem(
              associationId: associationId,
              galleryItemId: galleryItemId,
            );
      }
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      setState(() {
        _selectedGalleryItemIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            idsToDelete.length == 1
                ? 'Gallery image deleted.'
                : '${idsToDelete.length} gallery images deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete gallery images: $error')),
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
    if (file == null || file.bytes == null || _circularDraft == null) {
      return;
    }

    setState(() {
      _circularDraft = _circularDraft!.copyWith(
        selectedFile: AssociationUploadFile.fromPlatformFile(file),
      );
    });
  }

  Future<void> _openCircularDocument(
    AssociationCircularDocument document,
  ) async {
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

  void _openCircularEditor([AssociationCircularDocument? item]) {
    setState(() {
      _editingCircularId = item?.id ?? '';
      _circularDraft =
          item == null
              ? const AssociationCircularDraft.empty()
              : AssociationCircularDraft.fromDocument(item);
    });
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

  void _openMemberMasterEditor([MemberDirectoryItem? member]) {
    setState(() {
      _editingMemberMasterId = member?.id ?? '';
      _memberMasterDraft =
          member == null
              ? const MemberMasterDraft.empty()
              : MemberMasterDraft.fromMember(member);
    });
  }

  void _closeMemberMasterEditor() {
    setState(() {
      _editingMemberMasterId = null;
      _memberMasterDraft = null;
    });
  }

  Future<void> _saveMemberMaster() async {
    if (_memberMasterDraft == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .saveMemberRecord(draft: _memberMasterDraft!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _closeMemberMasterEditor();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _memberMasterDraft!.id.isEmpty
                ? 'Member created.'
                : 'Member updated.',
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
      if (_editingMemberMasterId == memberId) {
        _closeMemberMasterEditor();
      }
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
      final membersAsync = ref.watch(memberDirectoryProvider);
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
                  .where(
                    (member) =>
                        member.roleTitle.trim().toLowerCase() == 'committee' ||
                        member.committeePost.trim().isNotEmpty,
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );

          return _AssociationCommitteeView(
            members: committeeMembers,
            onNavigateToAssociation:
                () => widget.onSectionSelected(AssociationArenaSection.profile),
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
          return _AssociationCircularsSection(
            canManage: canManage,
            library: library,
            draft: _circularDraft,
            editingCircularId: _editingCircularId,
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

    if (widget.section == AssociationArenaSection.master) {
      final membersAsync = ref.watch(memberDirectoryProvider);
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
            draft: _memberMasterDraft,
            editingMemberId: _editingMemberMasterId,
            isSaving: _isSaving,
            onNavigateToAssociation:
                () => widget.onSectionSelected(AssociationArenaSection.profile),
            onOpenEditor: _openMemberMasterEditor,
            onCancelEdit: _closeMemberMasterEditor,
            onDraftChanged:
                (draft) => setState(() => _memberMasterDraft = draft),
            onSave: _saveMemberMaster,
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
          return _AssociationGallerySection(
            canManage: canManage,
            associationId: profile.id,
            items: profile.galleryItems,
            isSaving: _isSavingGallery,
            selectedItemIds: _selectedGalleryItemIds,
            onAddImages: () => _pickGalleryImages(profile.id),
            onToggleSelection: _toggleGallerySelection,
            onClearSelection: _clearGallerySelection,
            onDeleteSelected:
                _selectedGalleryItemIds.isEmpty
                    ? null
                    : () => _deleteSelectedGalleryItems(profile.id),
          );
        },
      );
    }

    return _EmptyStateCard(
      title: '${widget.section.label} is next',
      subtitle:
          'The Association Arena drawer now matches the web app. Profile, About Us, and Management Committee are live first, and ${widget.section.label} can be layered in next.',
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
            : 'Synetra Network';
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
    final associationName =
        tenant?.associationName.trim().isNotEmpty == true
            ? tenant!.associationName
            : 'Synetra Network';
    final locationLabel = tenant?.locationLabel ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MemberDirectoryHero(
          associationName: associationName,
          locationLabel: locationLabel,
        ),
        const SizedBox(height: 14),
        _MemberBreadcrumb(
          currentLabel: 'Directory',
          onRootTap: onNavigateToMemberArena,
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
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
    final associationName =
        tenant?.associationName.trim().isNotEmpty == true
            ? tenant!.associationName
            : 'Synetra Network';
    final locationLabel = tenant?.locationLabel ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MemberFilteredDirectoryHero(
          associationName: associationName,
          locationLabel: locationLabel,
          sectionLabel: section.label,
        ),
        const SizedBox(height: 14),
        _MemberBreadcrumb(
          currentLabel: section.label,
          onRootTap: onNavigateToMemberArena,
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _MemberMasterView extends StatelessWidget {
  const _MemberMasterView({
    required this.tenant,
    required this.onNavigateToMemberArena,
    required this.child,
  });

  final TenantContext? tenant;
  final VoidCallback onNavigateToMemberArena;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final associationName =
        tenant?.associationName.trim().isNotEmpty == true
            ? tenant!.associationName
            : 'Synetra Network';
    final locationLabel = tenant?.locationLabel ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MemberMasterHero(
          associationName: associationName,
          locationLabel: locationLabel,
        ),
        const SizedBox(height: 14),
        _MemberBreadcrumb(
          currentLabel: 'Master',
          onRootTap: onNavigateToMemberArena,
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
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
      arenaLabel: 'Member Arena',
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

class _MemberDirectoryHero extends StatelessWidget {
  const _MemberDirectoryHero({
    required this.associationName,
    required this.locationLabel,
  });

  final String associationName;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    return _AssociationSectionHero(
      arenaLabel: 'Member Arena',
      titleSpans: [
        const TextSpan(text: 'Browse '),
        TextSpan(
          text: associationName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const TextSpan(text: ' directory'),
        if (locationLabel.isNotEmpty) ...[
          const TextSpan(text: ' in '),
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

class _MemberFilteredDirectoryHero extends StatelessWidget {
  const _MemberFilteredDirectoryHero({
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
      arenaLabel: 'Member Arena',
      titleSpans: [
        const TextSpan(text: 'Browse '),
        TextSpan(
          text: sectionLabel,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const TextSpan(text: ' in '),
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

class _MemberMasterHero extends StatelessWidget {
  const _MemberMasterHero({
    required this.associationName,
    required this.locationLabel,
  });

  final String associationName;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    return _AssociationSectionHero(
      arenaLabel: 'Member Arena',
      titleSpans: [
        const TextSpan(text: 'Manage '),
        TextSpan(
          text: associationName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const TextSpan(text: ' master'),
        if (locationLabel.isNotEmpty) ...[
          const TextSpan(text: ' in '),
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
            : 'Synetra Network';
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
      arenaLabel: 'Admin Arena',
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
      rootLabel: 'Admin Arena',
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
      rootLabel: 'Member Arena',
      currentLabel: currentLabel,
      onRootTap: onRootTap,
    );
  }
}

class _FilteredMemberDirectorySection extends StatelessWidget {
  const _FilteredMemberDirectorySection({
    required this.members,
    required this.section,
  });

  final List<MemberDirectoryItem> members;
  final MemberArenaSection section;

  @override
  Widget build(BuildContext context) {
    final config = MemberArenaSectionDirectoryMeta.configFor(section);
    return _MemberDirectorySection(
      members: members,
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
          height: 225,
          child: PageView.builder(
            controller: pageController,
            itemCount: items.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
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
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.02),
                                  Colors.black.withValues(alpha: 0.68),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Slot ${item.displayIndex}',
                                    style: const TextStyle(
                                      color: Color(0xFF171717),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.vendorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.shortText,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _VendorProfileScreen(vendor: vendor),
          ),
        );
      },
      borderRadius: BorderRadius.circular(28),
      child: _EntityCardFrame(
        child: _ReusableMemberCard(
          name: vendor.displayName,
          photoUrl: vendor.avatarUrl,
          primaryLabel: vendor.category,
          factPills: factPills,
          detailLines: detailLines,
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9CA3AF),
            size: 28,
          ),
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

  @override
  Widget build(BuildContext context) {
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
                vendor.city.trim().isNotEmpty)
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
                    if (vendor.category.trim().isNotEmpty)
                      _VendorDetailRow(
                        label: 'Category',
                        value: vendor.category,
                      ),
                    if (vendor.vendorType.trim().isNotEmpty)
                      _VendorDetailRow(label: 'Type', value: vendor.vendorType),
                    if (vendor.city.trim().isNotEmpty)
                      _VendorDetailRow(label: 'City', value: vendor.city),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VendorDetailRow extends StatelessWidget {
  const _VendorDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
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

class _TimelineStackFeed extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
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
    required this.onOpenExternalLink,
  });

  final DashboardTimelineItem post;
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
          Container(
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

class _AssociationGallerySection extends StatelessWidget {
  const _AssociationGallerySection({
    required this.canManage,
    required this.associationId,
    required this.items,
    required this.isSaving,
    required this.selectedItemIds,
    required this.onAddImages,
    required this.onToggleSelection,
    required this.onClearSelection,
    required this.onDeleteSelected,
  });

  final bool canManage;
  final String associationId;
  final List<DashboardGalleryItem> items;
  final bool isSaving;
  final Set<String> selectedItemIds;
  final VoidCallback onAddImages;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onClearSelection;
  final VoidCallback? onDeleteSelected;

  void _openGalleryImage(BuildContext context, DashboardGalleryItem item) {
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
  Widget build(BuildContext context) {
    final isSelectionMode = selectedItemIds.isNotEmpty;

    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canManage) ...[
            Row(
              children: [
                FilledButton.icon(
                  onPressed:
                      isSaving || associationId.isEmpty ? null : onAddImages,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(isSaving ? 'Uploading...' : 'Add Photos'),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          const _EmptyStateCard(
            title: 'No gallery images yet',
            subtitle:
                'Gallery pictures will appear here once they are available for the association.',
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
              isSelectionMode
                  ? '${selectedItemIds.length} selected'
                  : '${items.length} photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF171717),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (canManage && isSelectionMode) ...[
              OutlinedButton(
                onPressed: isSaving ? null : onClearSelection,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: isSaving ? null : onDeleteSelected,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ] else if (canManage) ...[
              OutlinedButton.icon(
                onPressed: isSaving ? null : onAddImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(isSaving ? 'Uploading...' : 'Add'),
              ),
            ],
          ],
        ),
        if (canManage && !isSelectionMode) ...[
          const SizedBox(height: 8),
          Text(
            'Long press any photo to select multiple items.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
          ),
        ],
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.74,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = selectedItemIds.contains(item.id);
            return ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Material(
                color: Colors.white,
                child: InkWell(
                  onTap:
                      canManage && isSelectionMode
                          ? () => onToggleSelection(item.id)
                          : () => _openGalleryImage(context, item),
                  onLongPress:
                      canManage ? () => onToggleSelection(item.id) : null,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                DecoratedBox(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF3F4F6),
                                  ),
                                  child: _BackendImage(
                                    imageUrl: item.imageUrl,
                                    fit: BoxFit.cover,
                                    fallback: _AssociationGalleryFallback(
                                      item: item,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.16),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.headline.isEmpty
                                      ? 'Gallery image'
                                      : item.headline,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF171717),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                if (item.tagline.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.tagline,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    item.description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFF171717)
                                    : Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? const Color(0xFF171717)
                                      : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            size: 16,
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AssociationGalleryFallback extends StatelessWidget {
  const _AssociationGalleryFallback({required this.item});

  final DashboardGalleryItem item;

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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            item.headline.isEmpty ? 'Gallery' : item.headline,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
      ),
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

    final panelHeight = MediaQuery.sizeOf(context).height * 0.56;

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
                padding: const EdgeInsets.only(right: 12),
                child: _DashboardCommitteeCard(member: members[index]),
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
  const _DashboardCommitteeCard({required this.member});

  final MemberDirectoryItem member;

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
      factPills: [
        _DirectoryRolePill(
          label:
              member.committeePost.isNotEmpty
                  ? member.committeePost
                  : 'Committee Member',
        ),
        if (tenureLabel.isNotEmpty)
          _DirectoryFactPill(
            icon: Icons.calendar_today_rounded,
            label: tenureLabel,
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
              onPressed: isSaving ? null : onSave,
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
    this.arenaLabel = 'Association Arena',
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
      rootLabel: 'Association Arena',
      currentLabel: currentLabel,
      onRootTap: onRootTap,
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

class _AssociationCommitteeView extends StatelessWidget {
  const _AssociationCommitteeView({
    required this.members,
    required this.onNavigateToAssociation,
  });

  final List<MemberDirectoryItem> members;
  final VoidCallback onNavigateToAssociation;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const _EmptyStateCard(
        title: 'No committee members found',
        subtitle:
            'Committee members will appear here once the association has published them.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AssociationSectionHero(title: 'Management Committee'),
        const SizedBox(height: 14),
        _AssociationBreadcrumb(
          currentLabel: 'Management Committee',
          onRootTap: onNavigateToAssociation,
        ),
        const SizedBox(height: 18),
        const _SectionHeader(
          title: 'Management Committee',
          subtitle: 'Management Committee',
        ),
        const SizedBox(height: 14),
        ...members.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _AssociationCommitteeCard(member: member),
          ),
        ),
      ],
    );
  }
}

class _AssociationCommitteeCard extends StatelessWidget {
  const _AssociationCommitteeCard({required this.member});

  final MemberDirectoryItem member;

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
                  fit: BoxFit.cover,
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

class _AssociationCircularsSection extends StatelessWidget {
  const _AssociationCircularsSection({
    required this.canManage,
    required this.library,
    required this.draft,
    required this.editingCircularId,
    required this.isSaving,
    required this.onOpenEditor,
    required this.onCancelEdit,
    required this.onDraftChanged,
    required this.onPickFile,
    required this.onOpenDocument,
    required this.onSave,
    required this.onDelete,
  });

  final bool canManage;
  final AssociationCircularLibraryData library;
  final AssociationCircularDraft? draft;
  final String? editingCircularId;
  final bool isSaving;
  final ValueChanged<AssociationCircularDocument?> onOpenEditor;
  final VoidCallback onCancelEdit;
  final ValueChanged<AssociationCircularDraft> onDraftChanged;
  final Future<void> Function() onPickFile;
  final Future<void> Function(AssociationCircularDocument document)
  onOpenDocument;
  final Future<void> Function() onSave;
  final Future<void> Function(String circularId) onDelete;

  @override
  Widget build(BuildContext context) {
    final items = [...library.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Document Library',
                subtitle:
                    'Upload PDFs, DOC files, or scanned circulars and make them available across admin surfaces.',
              ),
            ),
            if (canManage) ...[
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => onOpenEditor(null),
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
        if (canManage && draft != null) ...[
          const SizedBox(height: 16),
          _AssociationCircularEditor(
            draft: draft!,
            isSaving: isSaving,
            onChanged: onDraftChanged,
            onPickFile: onPickFile,
            onSave: onSave,
            onCancel: onCancelEdit,
          ),
        ],
        const SizedBox(height: 16),
        if (items.isEmpty)
          const _EmptyStateCard(
            title: 'No circular documents yet',
            subtitle:
                'Upload your first circular to start building the association document library.',
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AssociationCircularCard(
                item: item,
                isEditing: editingCircularId == item.id,
                onOpenDocument: () => onOpenDocument(item),
                onDelete: canManage ? () => onDelete(item.id) : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _AssociationCircularEditor extends StatelessWidget {
  const _AssociationCircularEditor({
    required this.draft,
    required this.isSaving,
    required this.onChanged,
    required this.onPickFile,
    required this.onSave,
    required this.onCancel,
  });

  final AssociationCircularDraft draft;
  final bool isSaving;
  final ValueChanged<AssociationCircularDraft> onChanged;
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
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Circular CMS',
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
                  child: Text(isSaving ? 'Saving...' : 'Save Circular'),
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

  final AssociationCircularDraft draft;

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
    required this.item,
    required this.isEditing,
    required this.onOpenDocument,
    this.onDelete,
  });

  final AssociationCircularDocument item;
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
                tooltip: 'Open PDF',
                icon: Icons.picture_as_pdf_outlined,
                color: const Color(0xFF475569),
                onTap: onOpenDocument,
              ),
              const SizedBox(width: 4),
              _CircularActionIcon(
                tooltip: 'Open document',
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

  final AssociationCircularDocument item;
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
    required this.draft,
    required this.editingMemberId,
    required this.isSaving,
    this.onNavigateToAssociation,
    required this.onOpenEditor,
    required this.onCancelEdit,
    required this.onDraftChanged,
    required this.onSave,
    required this.onDelete,
  });

  final bool canManage;
  final List<MemberDirectoryItem> members;
  final MemberMasterDraft? draft;
  final String? editingMemberId;
  final bool isSaving;
  final VoidCallback? onNavigateToAssociation;
  final ValueChanged<MemberDirectoryItem?> onOpenEditor;
  final VoidCallback onCancelEdit;
  final ValueChanged<MemberMasterDraft> onDraftChanged;
  final Future<void> Function() onSave;
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
                child: const Text('Add User'),
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
        if (widget.canManage && widget.draft != null) ...[
          const SizedBox(height: 16),
          _MemberMasterEditor(
            draft: widget.draft!,
            isSaving: widget.isSaving,
            onChanged: widget.onDraftChanged,
            onSave: widget.onSave,
            onCancel: widget.onCancelEdit,
          ),
        ],
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
            label: 'Photo URL',
            value: draft.photoUrl,
            onChanged: (value) => onChanged(draft.copyWith(photoUrl: value)),
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
                (value) =>
                    onChanged(draft.copyWith(membershipStartDate: value)),
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
            onChanged:
                (value) => onChanged(draft.copyWith(paymentAmount: value)),
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
                  const ['Primary', 'Associate', 'Guest', 'Committee']
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
                  onPressed:
                      isSaving || !draft.canSubmit ? null : () => onSave(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                  ),
                  child: Text(isSaving ? 'Saving...' : 'Save Member'),
                ),
              ),
            ],
          ),
        ],
      ),
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
  const _AssociationMapTile({required this.label, required this.value});

  final String label;
  final String value;

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

  static Uri? _buildLaunchUri(String rawValue) {
    final trimmedValue = rawValue.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    try {
      final parsedUri = Uri.parse(trimmedValue);
      if (parsedUri.hasScheme) {
        return parsedUri;
      }
    } catch (_) {
      // Fall through to query-based URL generation.
    }

    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': trimmedValue,
    });
  }

  static Uri? _buildEmbedUri(String rawValue) {
    final trimmedValue = rawValue.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    try {
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
      return Uri.https('www.google.com', '/maps', {
        'q': trimmedValue,
        'output': 'embed',
      });
    }

    return Uri.https('www.google.com', '/maps', {
      'q': trimmedValue,
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
    final launchUri = _buildLaunchUri(value);
    final embedUri = _buildEmbedUri(value);

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
                child:
                    _supportsEmbeddedMap
                        ? _AssociationEmbeddedMap(
                          html: _buildEmbedHtml(embedUri),
                        )
                        : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Map preview is not available on this platform. Use the button below to open Google Maps.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4B5563),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _openMap(launchUri),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open in Google Maps'),
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
      child: TextFormField(
        key: ValueKey('$label-$value'),
        initialValue: value,
        minLines: maxLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
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
        'Approve membership',
        'Keep membership activation behind admin approval.',
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
    AdminMemberAccessView.app => 'Member App Access',
    AdminMemberAccessView.content => 'Member Content Access',
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
    return switch (this) {
      AdminMemberTypeFilter.all => [
        'primary',
        'associate',
        'temporary visit',
        'committee',
      ].contains(role),
      AdminMemberTypeFilter.primary => role == 'primary',
      AdminMemberTypeFilter.associate => role == 'associate',
      AdminMemberTypeFilter.guest =>
        role == 'temporary visit' || role == 'guest' || role == 'visitor',
      AdminMemberTypeFilter.committee => role == 'committee',
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
              'Match the same member app access and member content access workflow shown in the web admin arena.',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              AdminMemberAccessView.values.map((view) {
                final selected = _activeView == view;
                return ChoiceChip(
                  label: Text(view.label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _activeView = view;
                    });
                  },
                  showCheckmark: false,
                  selectedColor: const Color(0xFFE9D5FF),
                  side: BorderSide(
                    color:
                        selected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFE5E7EB),
                  ),
                  labelStyle: TextStyle(
                    color:
                        selected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF4B5563),
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 14),
        if (_activeView == AdminMemberAccessView.app) ...[
          _AdminToolbarSearch(
            controller: _appSearchController,
            hintText: 'Search name, company, membership type...',
            onChanged: (value) => setState(() => _appQuery = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilterChip(
                label: const Text('Select filtered'),
                selected: allFilteredSelected,
                onSelected: (_) {
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
              ),
              for (final filter in AdminMemberTypeFilter.values)
                ChoiceChip(
                  label: Text(filter.label),
                  selected: _activeFilter == filter,
                  onSelected: (_) {
                    setState(() {
                      _activeFilter = filter;
                    });
                  },
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed:
                    _selectedMemberIds.isEmpty ||
                            widget.updatingMemberId != null
                        ? null
                        : () => widget.onBulkUpdateAccess(
                          filteredMembers
                              .where(
                                (member) =>
                                    _selectedMemberIds.contains(member.id),
                              )
                              .toList(),
                          MemberAccessStatus.approved,
                        ),
                child: const Text('Approve Membership'),
              ),
              OutlinedButton(
                onPressed:
                    _selectedMemberIds.isEmpty ||
                            widget.updatingMemberId != null
                        ? null
                        : () => widget.onBulkUpdateAccess(
                          filteredMembers
                              .where(
                                (member) =>
                                    _selectedMemberIds.contains(member.id),
                              )
                              .toList(),
                          MemberAccessStatus.suspended,
                        ),
                child: const Text('Suspend Membership'),
              ),
              OutlinedButton(
                onPressed:
                    _selectedMemberIds.isEmpty ||
                            widget.updatingMemberId != null
                        ? null
                        : () => widget.onBulkUpdateAccess(
                          filteredMembers
                              .where(
                                (member) =>
                                    _selectedMemberIds.contains(member.id),
                              )
                              .toList(),
                          MemberAccessStatus.cancelled,
                        ),
                child: const Text('Cancel Membership'),
              ),
            ],
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
                trailing: _AccessStatusBadge(status: member.accessStatus),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          MemberAccessStatus.values.map((status) {
                            final selected = status == member.accessStatus;
                            return ChoiceChip(
                              label: Text(status.label),
                              selected: selected,
                              onSelected:
                                  widget.updatingMemberId != null
                                      ? null
                                      : (_) =>
                                          widget.onUpdateAccess(member, status),
                              showCheckmark: false,
                              selectedColor: status.color.withValues(
                                alpha: 0.16,
                              ),
                              side: BorderSide(
                                color:
                                    selected
                                        ? status.color
                                        : const Color(0xFFE5E7EB),
                              ),
                              labelStyle: TextStyle(
                                color:
                                    selected
                                        ? status.color
                                        : const Color(0xFF4B5563),
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList(),
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
              'Moderate member posts from the same queue used by web and member arena.',
        ),
        const SizedBox(height: 14),
        ...posts
            .take(8)
            .map(
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

class _AdminVendorAccessWorkspace extends StatelessWidget {
  const _AdminVendorAccessWorkspace({
    required this.vendors,
    required this.updatingVendorId,
    required this.onUpdateVendorAccess,
  });

  final List<AdminVendorAccessItem> vendors;
  final String? updatingVendorId;
  final Future<void> Function(AdminVendorAccessItem, MemberAccessStatus)
  onUpdateVendorAccess;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Vendor Requests',
          subtitle:
              'Approve vendor registrations and review paid app banner submissions from the live backend.',
        ),
        const SizedBox(height: 14),
        if (vendors.isEmpty)
          const _EmptyStateCard(
            title: 'No vendor requests found',
            subtitle: 'New vendor registrations will appear here for review.',
          )
        else
          ...vendors.map(
            (vendor) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AdminVendorAccessCard(
                vendor: vendor,
                isUpdating: updatingVendorId == vendor.id,
                onUpdateAccess:
                    (status) => onUpdateVendorAccess(vendor, status),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminBannerAccessWorkspace extends StatelessWidget {
  const _AdminBannerAccessWorkspace({
    required this.banners,
    required this.updatingBannerId,
    required this.onUpdateBannerStatus,
  });

  final List<AdminAppBannerItem> banners;
  final String? updatingBannerId;
  final Future<void> Function(AdminAppBannerItem, BannerReviewStatus)
  onUpdateBannerStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Banner Access',
          subtitle:
              'Approve, reject, or hold paid banner requests from the live backend before they go live in the carousel.',
        ),
        const SizedBox(height: 14),
        if (banners.isEmpty)
          const _EmptyStateCard(
            title: 'No banner requests found',
            subtitle: 'Submitted app banners will appear here for moderation.',
          )
        else
          ...banners.map(
            (banner) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AdminAppBannerCard(
                banner: banner,
                isUpdating: updatingBannerId == banner.id,
                onUpdateStatus:
                    (status) => onUpdateBannerStatus(banner, status),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminTimelineAccessWorkspace extends StatelessWidget {
  const _AdminTimelineAccessWorkspace({
    required this.posts,
    required this.updatingTimelineId,
    required this.onUpdateTimelineStatus,
  });

  final List<AdminTimelineItem> posts;
  final String? updatingTimelineId;
  final Future<void> Function(AdminTimelineItem, TimelineReviewStatus)
  onUpdateTimelineStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Timeline Access',
          subtitle:
              'Approve, reject, or hold association, member, and vendor timeline posts from the live backend.',
        ),
        const SizedBox(height: 14),
        if (posts.isEmpty)
          const _EmptyStateCard(
            title: 'No timeline posts found',
            subtitle:
                'Submitted timeline posts will appear here for moderation.',
          )
        else
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AdminTimelineAccessCard(
                post: post,
                isUpdating: updatingTimelineId == post.id,
                onUpdateStatus:
                    (status) => onUpdateTimelineStatus(post, status),
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
  });

  final AdminVendorAccessItem vendor;
  final bool isUpdating;
  final ValueChanged<MemberAccessStatus> onUpdateAccess;

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  MemberAccessStatus.approved,
                  MemberAccessStatus.pending,
                  MemberAccessStatus.suspended,
                  MemberAccessStatus.cancelled,
                ].map((status) {
                  final selected = vendor.accessStatus == status;
                  return ChoiceChip(
                    label: Text(status.label),
                    selected: selected,
                    onSelected:
                        isUpdating ? null : (_) => onUpdateAccess(status),
                    showCheckmark: false,
                    selectedColor: status.color.withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      color: selected ? status.color : const Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: selected ? status.color : const Color(0xFFE5E7EB),
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
      ),
    );
  }
}

class _AdminAppBannerCard extends StatelessWidget {
  const _AdminAppBannerCard({
    required this.banner,
    required this.isUpdating,
    required this.onUpdateStatus,
  });

  final AdminAppBannerItem banner;
  final bool isUpdating;
  final ValueChanged<BannerReviewStatus> onUpdateStatus;

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
                      fit: BoxFit.cover,
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
              _DirectoryFactPill(
                icon: Icons.flag_rounded,
                label: banner.reviewStatus.label,
              ),
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                BannerReviewStatus.values.map((status) {
                  final selected = banner.reviewStatus == status;
                  return ChoiceChip(
                    label: Text(status.label),
                    selected: selected,
                    onSelected:
                        isUpdating ? null : (_) => onUpdateStatus(status),
                    showCheckmark: false,
                    selectedColor: status.color.withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      color: selected ? status.color : const Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: selected ? status.color : const Color(0xFFE5E7EB),
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
                icon: Icons.flag_rounded,
                label: post.reviewStatus.label,
              ),
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
                  fit: BoxFit.cover,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                TimelineReviewStatus.values.map((status) {
                  final selected = post.reviewStatus == status;
                  return ChoiceChip(
                    label: Text(status.label),
                    selected: selected,
                    onSelected:
                        isUpdating ? null : (_) => onUpdateStatus(status),
                    showCheckmark: false,
                    selectedColor: status.color.withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      color: selected ? status.color : const Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: selected ? status.color : const Color(0xFFE5E7EB),
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
      ),
    );
  }
}

class _AdminEventsSectionState extends State<_AdminEventsSection> {
  late AdminEventDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = AdminEventDraft.empty();
  }

  void _startEdit(AdminEventItem event) {
    setState(() {
      _draft = AdminEventDraft.fromEvent(event);
    });
  }

  void _resetDraft() {
    setState(() {
      _draft = AdminEventDraft.empty();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Event Access Controls',
          subtitle:
              'Search, edit, delete, and create events using the same backend-driven flow as the web app.',
        ),
        const SizedBox(height: 14),
        if (widget.events.isEmpty)
          const _EmptyStateCard(
            title: 'No events found',
            subtitle:
                'Create an event below or in the web app to start filling this list.',
          )
        else
          ...widget.events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _EventTimelineCard(
                event: event,
                accentLabel: event.liveStatus,
                showEntryCharges: true,
                footer: Row(
                  children: [
                    OutlinedButton(
                      onPressed:
                          widget.savingEventId != null
                              ? null
                              : () => _startEdit(event),
                      child: const Text('Edit'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed:
                          widget.savingEventId != null
                              ? null
                              : () => widget.onDeleteEvent(event.id),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
                isSaving: widget.savingEventId == event.id,
              ),
            ),
          ),
        const SizedBox(height: 18),
        _AdminEventForm(
          draft: _draft,
          eventTypes: widget.eventTypes,
          isSaving:
              widget.savingEventId == '__new__' ||
              (_draft.id.isNotEmpty && widget.savingEventId == _draft.id),
          onChanged: (draft) {
            setState(() {
              _draft = draft;
            });
          },
          onSave: () => widget.onSaveEvent(_draft),
          onCancel: _draft.id.isEmpty ? null : _resetDraft,
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Create New Event',
          subtitle:
              'Use the same backend event flow as web, including banner picture and promo video uploads.',
        ),
        const SizedBox(height: 14),
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
    required this.savingEventId,
    required this.onSaveEvent,
    required this.onDeleteEvent,
  });

  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;
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
              'Browse upcoming and completed events, and edit existing records directly from the live timeline.',
        ),
        const SizedBox(height: 14),
        if (_editingDraft != null) ...[
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
                child: _EditableEventTimelineCard(
                  event: event,
                  isSaving: widget.savingEventId == event.id,
                  onEdit:
                      () => setState(() {
                        _editingDraft = AdminEventDraft.fromEvent(event);
                      }),
                  onDelete: () => widget.onDeleteEvent(event.id),
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
                child: _EditableEventTimelineCard(
                  event: event,
                  isSaving: widget.savingEventId == event.id,
                  onEdit:
                      () => setState(() {
                        _editingDraft = AdminEventDraft.fromEvent(event);
                      }),
                  onDelete: () => widget.onDeleteEvent(event.id),
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
                child: TextFormField(
                  key: ValueKey('event-name-${draft.id}-${draft.name}'),
                  initialValue: draft.name,
                  decoration: const InputDecoration(
                    labelText: 'Event Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => onChanged(draft.copyWith(name: value)),
                ),
              ),
              _EventField(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('event-type-${draft.id}-${draft.type}'),
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
                child: TextFormField(
                  key: ValueKey('event-date-${draft.id}-${draft.date}'),
                  initialValue: draft.date,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => onChanged(draft.copyWith(date: value)),
                ),
              ),
              _EventField(
                width: 240,
                child: TextFormField(
                  key: ValueKey('event-venue-${draft.id}-${draft.venue}'),
                  initialValue: draft.venue,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => onChanged(draft.copyWith(venue: value)),
                ),
              ),
              _EventField(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('event-audience-${draft.id}-${draft.audience}'),
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
                  key: ValueKey(
                    'event-entry-type-${draft.id}-${draft.entryType}',
                  ),
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
                child: TextFormField(
                  key: ValueKey(
                    'event-entry-charges-${draft.id}-${draft.entryCharges}',
                  ),
                  initialValue: draft.entryCharges,
                  decoration: const InputDecoration(
                    labelText: 'Entry Charges',
                    border: OutlineInputBorder(),
                  ),
                  onChanged:
                      (value) => onChanged(draft.copyWith(entryCharges: value)),
                ),
              ),
              _EventField(
                width: 200,
                child: TextFormField(
                  key: ValueKey(
                    'event-participation-${draft.id}-${draft.participationCharges}',
                  ),
                  initialValue: draft.participationCharges,
                  decoration: const InputDecoration(
                    labelText: 'Participation Charges',
                    border: OutlineInputBorder(),
                  ),
                  onChanged:
                      (value) => onChanged(
                        draft.copyWith(participationCharges: value),
                      ),
                ),
              ),
              _EventField(
                width: 150,
                child: TextFormField(
                  key: ValueKey('event-start-${draft.id}-${draft.startTime}'),
                  initialValue: draft.startTime,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    border: OutlineInputBorder(),
                  ),
                  onChanged:
                      (value) => onChanged(draft.copyWith(startTime: value)),
                ),
              ),
              _EventField(
                width: 150,
                child: TextFormField(
                  key: ValueKey('event-end-${draft.id}-${draft.endTime}'),
                  initialValue: draft.endTime,
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    border: OutlineInputBorder(),
                  ),
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
          TextFormField(
            initialValue: draft.summary,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Event Summary',
              border: OutlineInputBorder(),
            ),
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
                onPressed: isSaving ? null : onSave,
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
                fit: BoxFit.cover,
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

class _MemberDirectorySection extends StatefulWidget {
  const _MemberDirectorySection({
    required this.members,
    this.initialFilter = MemberDirectoryFilter.all,
    this.lockFilter = false,
    this.title = 'Member Directory',
    this.subtitle =
        'Browse members alphabetically, filter by membership type, and search by name, company, city, or profile details.',
  });

  final List<MemberDirectoryItem> members;
  final MemberDirectoryFilter initialFilter;
  final bool lockFilter;
  final String title;
  final String subtitle;

  @override
  State<_MemberDirectorySection> createState() =>
      _MemberDirectorySectionState();
}

class _MemberDirectorySectionState extends State<_MemberDirectorySection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late MemberDirectoryFilter _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant _MemberDirectorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _activeFilter = widget.initialFilter;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredMembers =
        widget.members.where((member) {
            final matchesFilter = _activeFilter.matches(member);
            if (!matchesFilter) {
              return false;
            }

            if (normalizedQuery.isEmpty) {
              return true;
            }

            final haystack =
                [
                  member.name,
                  member.companyName,
                  member.roleTitle,
                  member.address,
                  member.memberBio,
                  member.membershipDetails,
                  member.email,
                  member.phone,
                ].join(' ').toLowerCase();
            return haystack.contains(normalizedQuery);
          }).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    final groupedMembers = <String, List<MemberDirectoryItem>>{};
    for (final member in filteredMembers) {
      final label =
          member.name.trim().isEmpty
              ? '#'
              : member.name.trim()[0].toUpperCase().replaceAll(
                RegExp(r'[^A-Z]'),
                '#',
              );
      groupedMembers.putIfAbsent(label, () => []).add(member);
    }
    final sortedLetters = groupedMembers.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: widget.title, subtitle: widget.subtitle),
        const SizedBox(height: 14),
        if (!widget.lockFilter) ...[
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
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],
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
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              border: InputBorder.none,
              icon: Icon(Icons.search_rounded),
              hintText: 'Search by name, company, city, role, or intro',
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (filteredMembers.isEmpty) ...[
          const _EmptyStateCard(
            title: 'No matching members',
            subtitle:
                'Try another search term or add more member records in the backend.',
          ),
        ] else ...[
          ...sortedLetters.map(
            (letter) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  ...groupedMembers[letter]!.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _MemberDirectoryCard(member: member),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
    this.heroHeight = 148,
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
  final double heroHeight;

  @override
  Widget build(BuildContext context) {
    return _EntityCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeroImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: double.infinity,
                height: heroHeight,
                child: _CommitteeThumbnail(name: name, photoUrl: photoUrl),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
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
          if (factPills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: factPills),
          ],
          if (summary.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              summary,
              maxLines: showHeroImage ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.45,
              ),
            ),
          ],
          if (detailLines.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            ...detailLines.indexed.expand(
              (entry) => [
                entry.$2,
                if (entry.$1 != detailLines.length - 1)
                  const SizedBox(height: 9),
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
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
                  _MemberAvatarFallback(initials: initials, size: size),
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

class _AccessStatusBadge extends StatelessWidget {
  const _AccessStatusBadge({required this.status});

  final MemberAccessStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
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
          title: 'Arena workspace',
          subtitle:
              'Member Arena is now implemented first. The remaining arenas can be layered into the same shell next.',
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator()),
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
      (AppArena.vendor, Icons.storefront_rounded, 'Vendor'),
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

class _TimelineDockButton extends StatelessWidget {
  const _TimelineDockButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFFF97316) : Colors.white,
          border: Border.all(
            color: active ? const Color(0xFFF97316) : const Color(0xFFD7DCE2),
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
            if (active)
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
            const _SynetraLogoBadge(size: 56),
          ],
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
