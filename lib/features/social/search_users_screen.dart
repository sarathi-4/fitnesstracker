import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/social_service.dart';
import '../../core/services/user_service.dart';
import 'social_feed_screen.dart';
import 'user_profile_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  final int initialSubTab; // 0: Suggested, 1: Contacts, 2: QR Code
  final int initialMainTab; // Legacy parameter, kept for compatibility

  const SearchUsersScreen({
    super.key,
    this.initialSubTab = 0,
    this.initialMainTab = 0,
  });

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Friends Sub-Tabs: 0: Suggested, 1: Contacts, 2: QR Code
  late int _selectedFriendsSubTab;

  // QR Code Sub-Segment: 0: My QR Code, 1: Scan QR Code
  int _selectedQrSegment = 0;

  // --- Athletes State ---
  List<SocialUser> _searchResults = [];
  bool _isLoadingAthletes = false;

  // --- Contacts State ---
  List<Contact> _deviceContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoadingContacts = false;
  bool _contactsPermissionGranted = false;
  bool _contactsPermissionDenied = false;

  // --- QR Scanner Controller ---
  MobileScannerController? _scannerController;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _selectedFriendsSubTab = widget.initialSubTab;

    _performSearch('');
    _checkContactsPermissionInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (_selectedFriendsSubTab == 0) {
        _performSearch(query);
      } else if (_selectedFriendsSubTab == 1) {
        _filterDeviceContacts(query);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // ATHLETES (SUGGESTED FRIENDS)
  // ---------------------------------------------------------------------------
  Future<void> _performSearch(String query) async {
    setState(() => _isLoadingAthletes = true);
    final results = await SocialService.instance.searchUsers(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isLoadingAthletes = false;
    });
  }

  Future<void> _toggleFollow(SocialUser user) async {
    final originalState = user.isFollowing;
    setState(() {
      user.isFollowing = !originalState;
    });

    bool success;
    if (originalState) {
      success = await SocialService.instance.unfollowUser(user.uid);
    } else {
      success = await SocialService.instance.followUser(user);
    }

    if (!success && mounted) {
      setState(() {
        user.isFollowing = originalState; // rollback on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Could not update follow status.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CONTACTS INVITATION
  // ---------------------------------------------------------------------------
  Future<void> _checkContactsPermissionInitial() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      _fetchDeviceContacts();
    }
  }

  Future<void> _requestContactsPermission() async {
    setState(() => _isLoadingContacts = true);
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      await _fetchDeviceContacts();
    } else {
      if (mounted) {
        setState(() {
          _contactsPermissionGranted = false;
          _contactsPermissionDenied = true;
          _isLoadingContacts = false;
        });
      }
    }
  }

  Future<void> _fetchDeviceContacts() async {
    setState(() {
      _isLoadingContacts = true;
      _contactsPermissionGranted = true;
      _contactsPermissionDenied = false;
    });

    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      if (!mounted) return;
      setState(() {
        _deviceContacts = contacts;
        _filteredContacts = contacts;
        _isLoadingContacts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingContacts = false);
    }
  }

  void _filterDeviceContacts(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      setState(() => _filteredContacts = _deviceContacts);
      return;
    }
    setState(() {
      _filteredContacts = _deviceContacts.where((c) {
        final name = (c.displayName ?? '').toLowerCase();
        final phone = c.phones.isNotEmpty ? c.phones.first.number.replaceAll(RegExp(r'\s+'), '') : '';
        return name.contains(clean) || phone.contains(clean);
      }).toList();
    });
  }

  void _inviteContact(Contact contact) {
    final name = (contact.displayName != null && contact.displayName!.isNotEmpty)
        ? contact.displayName!
        : 'friend';
    final user = UserService.instance;
    final message =
        'Hey $name! 🏃‍♂️ Join me on JAIHIND – the official running and fitness club application. '
        'Track GPS routes, analyze pace, and let\'s train together! '
        'Download here: https://jaihind-runner.web.app (Referral: ${user.username.toUpperCase()})';

    Share.share(
      message,
      subject: 'Join me on JAIHIND Fitness!',
    );
  }



  // ---------------------------------------------------------------------------
  // QR CODE SCANNING & PARSING
  // ---------------------------------------------------------------------------
  void _onQrScanned(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() => _isProcessingScan = true);

    final athlete = await SocialService.instance.getUserByQrCode(rawValue);
    if (!mounted) return;

    if (athlete != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Athlete found: @${athlete.username}! Opening profile... 🎯'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(user: athlete),
        ),
      ).then((_) {
        if (mounted) setState(() => _isProcessingScan = false);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid JAIHIND QR Code. Please scan an athlete\'s personal code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessingScan = false);
    }
  }

  // ---------------------------------------------------------------------------
  // NATIVE SHARE SHEET (INVITE FRIENDS)
  // ---------------------------------------------------------------------------
  void _openNativeShareSheet() {
    final user = UserService.instance;
    final message =
        'Join me on JAIHIND! 🏃‍♂️🇮🇳 Track your workouts, run, walk, cycle and achieve your fitness goals together. '
        'Download JAIHIND and connect with me!\n\n'
        'Athlete: ${user.displayName} (@${user.username})\n'
        'Connect: https://jaihind-runner.web.app/@${user.username}\n'
        'Referral code: ${user.username.toUpperCase()}';

    Share.share(
      message,
      subject: 'Train with me on JAIHIND Fitness!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildTopAppBar(),
      body: Column(
        children: [
          // 1. SEARCH BAR
          _buildSearchBar(),

          // 2. FRIENDS SUB-TABS (Suggested | Contacts | QR Code)
          _buildFriendsSubTabs(),

          // 3. TAB BODY CONTENT
          Expanded(
            child: _buildFriendsContent(),
          ),

          // 4. PROMINENT ORANGE "INVITE FRIENDS" BUTTON
          if (_selectedFriendsSubTab != 2)
            _buildBottomInviteBanner(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP APP BAR
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Find Friends',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18.5,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Community Feed',
          icon: const Icon(Icons.dynamic_feed_rounded, color: Colors.black87),
          onPressed: () => Navigator.push(
            context,
            AppRouteTransitions.slideHorizontal(const SocialFeedScreen()),
          ),
        ),
        IconButton(
          tooltip: 'Share App Invite',
          icon: const Icon(Icons.share_outlined, color: AppColors.primaryOrange),
          onPressed: _openNativeShareSheet,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SEARCH BAR ("Search athletes on JAIHIND")
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    String hint = 'Search athletes on JAIHIND...';
    if (_selectedFriendsSubTab == 1) {
      hint = 'Search phone contacts...';
    } else if (_selectedFriendsSubTab == 0) {
      hint = 'Search athletes, runners, @username...';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontSize: 14.5, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF6B7280), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. FRIENDS SUB-TABS (Suggested | Contacts | QR Code)
  // ---------------------------------------------------------------------------
  Widget _buildFriendsSubTabs() {
    final subTabs = [
      {'label': 'Suggested', 'icon': Icons.person_add_alt_1_rounded},
      {'label': 'Contacts', 'icon': Icons.contacts_rounded},
      {'label': 'QR Code', 'icon': Icons.qr_code_2_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.8)),
      ),
      child: Row(
        children: List.generate(subTabs.length, (idx) {
          final item = subTabs[idx];
          final isSel = _selectedFriendsSubTab == idx;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFriendsSubTab = idx;
                  _searchController.clear();
                });
                if (idx == 1 && !_contactsPermissionGranted && !_contactsPermissionDenied) {
                  _requestContactsPermission();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSel ? AppColors.primaryOrange : Colors.transparent,
                      width: 2.2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: isSel ? AppColors.primaryOrange : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? AppColors.primaryOrange : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. FRIENDS CONTENT ROUTER
  // ---------------------------------------------------------------------------
  Widget _buildFriendsContent() {
    switch (_selectedFriendsSubTab) {
      case 0:
        return _buildSuggestedFriendsView();
      case 1:
        return _buildContactsView();
      case 2:
        return _buildQrCodeView();
      default:
        return const SizedBox();
    }
  }

  // ---------------------------------------------------------------------------
  // SUB-TAB A: SUGGESTED FRIENDS VIEW
  // ---------------------------------------------------------------------------
  Widget _buildSuggestedFriendsView() {
    if (_isLoadingAthletes) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.person_search_rounded, size: 34, color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Athletes Found',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                'No registered athletes matched "${_searchController.text}". Invite friends to run together!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: () => _performSearch(_searchController.text),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 0.6,
          color: Color(0xFFF3F4F6),
          indent: 76,
        ),
        itemBuilder: (context, index) {
          final athlete = _searchResults[index];
          return _buildAthleteTile(athlete);
        },
      ),
    );
  }

  Widget _buildAthleteTile(SocialUser athlete) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(user: athlete)),
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with orange sports ring
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primaryOrange, Color(0xFFFF8A00), AppColors.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFFFF3E0),
                  child: Text(
                    athlete.displayName.isNotEmpty ? athlete.displayName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Athlete details: Name, Username, Location, Fitness short info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          athlete.displayName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0095F6)),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '@${athlete.username}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 3),
                  // City / Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          athlete.location,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Fitness Short Information
                  Row(
                    children: [
                      const Icon(Icons.directions_run_rounded, size: 12, color: AppColors.primaryOrange),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          athlete.fitnessInfo,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryOrange,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Follow / Following Action Button
            BouncingTap(
              onTap: () => _toggleFollow(athlete),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: athlete.isFollowing ? const Color(0xFFEFEFEF) : AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(8),
                  border: athlete.isFollowing
                      ? Border.all(color: const Color(0xFFD1D5DB), width: 1)
                      : null,
                ),
                child: Text(
                  athlete.isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: athlete.isFollowing ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUB-TAB B: CONTACTS INVITATION VIEW
  // ---------------------------------------------------------------------------
  Widget _buildContactsView() {
    if (_isLoadingContacts) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
        ),
      );
    }

    if (_contactsPermissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.contacts_outlined, size: 36, color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 18),
              const Text(
                'Contacts Access Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'To find your friends and invite them to train on JAIHIND, please allow contacts access. Your phone contacts are never stored publicly or uploaded to servers.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Open App Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (!_contactsPermissionGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.perm_contact_calendar_rounded, size: 38, color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 18),
              const Text(
                'Invite Friends from Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect with fellow runners from your address book. You choose who to invite via Android\'s secure share sheet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _requestContactsPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Sync & Find Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 14),
              Text(
                _searchController.text.isEmpty ? 'No Contacts Found' : 'No Contacts Match "${_searchController.text}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching for another name or invite friends directly via WhatsApp.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredContacts.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.6,
        color: Color(0xFFF3F4F6),
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final name = (contact.displayName != null && contact.displayName!.isNotEmpty)
            ? contact.displayName!
            : 'Contact';
        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFFF3E0),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              BouncingTap(
                onTap: () => _inviteContact(contact),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryOrange.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded, size: 12, color: AppColors.primaryOrange),
                      SizedBox(width: 4),
                      Text(
                        'Invite',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SUB-TAB C: QR CODE VIEW (Generate & Scan)
  // ---------------------------------------------------------------------------
  Widget _buildQrCodeView() {
    return Column(
      children: [
        // Sub-toggle: My QR Code | Scan QR Code
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedQrSegment = 0;
                      _scannerController?.stop();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _selectedQrSegment == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'My QR Code',
                        style: TextStyle(
                          fontWeight: _selectedQrSegment == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedQrSegment == 0 ? Colors.black : const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedQrSegment = 1);
                    _scannerController?.start();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _selectedQrSegment == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Scan QR Code',
                        style: TextStyle(
                          fontWeight: _selectedQrSegment == 1 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedQrSegment == 1 ? Colors.black : const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _selectedQrSegment == 0
              ? _buildMyQrCard()
              : _buildQrScannerView(),
        ),
      ],
    );
  }

  Widget _buildMyQrCard() {
    final user = UserService.instance;
    final qrData = 'jaihind://user/${SocialService.instance.currentUserId}?username=${user.username}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Styled JAIHIND Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with Athlete avatar & name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFFFF3E0),
                      child: Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'J',
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // QR Code Widget
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 210,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primaryOrange,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Scan to follow on JAIHIND',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Friends can scan this code using their JAIHIND camera to view your athlete profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Actions: Share QR Code | Save QR Code
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR Code saved to device successfully! 📸'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18, color: Colors.black87),
                  label: const Text('Save QR', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                      'Scan my JAIHIND athlete QR code to connect and follow my workouts! 🏃‍♂️⚡\n'
                      'Profile: https://jaihind-runner.web.app/@${user.username}',
                      subject: 'My JAIHIND QR Code',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share QR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQrScannerView() {
    _scannerController ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQrScanned,
        ),
        // Scanner Viewfinder Overlay
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryOrange, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Point camera at a JAIHIND QR code',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }



  // ---------------------------------------------------------------------------
  // 5. PROMINENT BOTTOM INVITE FRIENDS BANNER (Orange)
  // ---------------------------------------------------------------------------
  Widget _buildBottomInviteBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _openNativeShareSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
            label: const Text(
              'Invite Friends to JAIHIND 🚀',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
