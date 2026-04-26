import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import 'change_password.dart';
import 'bug_sender.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;

  // Controller untuk video background
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  // Color scheme LAVENDOZ V8 - Industrial Red/Black
  final Color primaryRed = const Color(0xFF8B0000); // Dark red
  final Color accentRed = const Color(0xFFB22222); // Firebrick red
  final Color bloodRed = const Color(0xFF660000); // Deep blood red
  final Color darkGray = const Color(0xFF1A1A1A); // Almost black
  final Color mediumGray = const Color(0xFF2D2D2D); // Dark gray
  final Color lightGray = const Color(0xFF808080); // Medium gray
  final Color industrialYellow = const Color(0xFFFFB74D); // Amber/yellow for accents

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _initializeVideo();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    _selectedPage = _buildLavendozPage();
    _initAndroidIdAndConnect();
  }

  void _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/bg.mp4')
      ..initialize().then((_) {
        _videoController.setVolume(0.0);
        _videoController.setLooping(true);
        _videoController.play();
        setState(() {
          _isVideoInitialized = true;
        });
      });
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('wss://ws-evo.nullxteam.fun'));
    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));
    channel.sink.add(jsonEncode({"type": "stats"}));

    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          _handleInvalidSession("Session invalid, please re-login.");
        }
      }
    });
  }

  void _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: darkGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentRed.withOpacity(0.5), width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: accentRed, size: 28),
              const SizedBox(width: 10),
              Text("SESSION EXPIRED",
                  style: TextStyle(color: accentRed, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryRed, accentRed],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) _selectedPage = _buildLavendozPage();
      else if (index == 1) {
        _selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = ToolsPage(sessionKey: sessionKey, userRole: role, listDoos: listDoos);
      }
    });
  }

  void _navigateToAdminPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPage(sessionKey: sessionKey),
      ),
    );
  }

  void _navigateToSellerPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerPage(keyToken: sessionKey),
      ),
    );
  }

  int onlineUsers = 0;
  int activeConnections = 0;

  Widget _buildVideoBackground() {
    if (_isVideoInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        ),
      );
    } else {
      return Container(color: darkGray);
    }
  }

  Widget _buildLavendozPage() {
    return Container(
      color: darkGray,
      child: Stack(
        children: [
          // Video Background dengan overlay industrial
          _buildVideoBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  bloodRed.withOpacity(0.3),
                  darkGray.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content dengan gaya industrial
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER - LAVENDOZ V8
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: accentRed, width: 2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ZARATRAS",
                                  style: TextStyle(
                                    color: accentRed,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    fontFamily: 'Monospace',
                                  ),
                                ),
                                Text(
                                  "CREATED BY ${username.toUpperCase()}",
                                  style: TextStyle(
                                    color: lightGray,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: bloodRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                role[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AL (kemungkinan singkatan)
                  Container(
                    margin: const EdgeInsets.only(left: 16),
                    child: Text(
                      "AL",
                      style: TextStyle(
                        color: industrialYellow,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // FEATURES SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentRed.withOpacity(0.5), width: 1),
                      color: mediumGray.withOpacity(0.3),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              color: accentRed,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "FEATURES",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // V5 || LAVENDOZ
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: bloodRed.withOpacity(0.3),
                            border: Border.all(color: accentRed.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "V5",
                                style: TextStyle(
                                  color: industrialYellow,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "|| LAVENDOZ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // FEATURES GALORE
                        Center(
                          child: Text(
                            "FEATURES GALORE",
                            style: TextStyle(
                              color: accentRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        // STATIC SERVER - LIVE EPISODES
                        _buildFeatureItem(
                          title: "STATIC SERVER",
                          items: [
                            "LIVE EPISODES",
                            "  • The whole timeline",
                            "OFFLINE",
                            "PREMIUM",
                            "  • of developed devices",
                            "MODAL",
                          ],
                        ),

                        const SizedBox(height: 16),

                        // DEVELOPER SECTION
                        _buildFeatureItem(
                          title: "DEVELOPER",
                          items: [
                            "Contact developer",
                          ],
                          showBottomLine: true,
                        ),

                        const SizedBox(height: 16),

                        // E SERVICE
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: accentRed),
                            color: bloodRed.withOpacity(0.2),
                          ),
                          child: Center(
                            child: Text(
                              "E SERVICE",
                              style: TextStyle(
                                color: industrialYellow,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACCOUNT INFO CARD (dengan gaya industrial)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentRed.withOpacity(0.5)),
                      color: mediumGray.withOpacity(0.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: accentRed, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "USER INFO",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildIndustrialInfoRow("USERNAME", username),
                        _buildIndustrialInfoRow("ROLE", role.toUpperCase()),
                        _buildIndustrialInfoRow("EXPIRED", expiredDate),
                        Divider(color: accentRed.withOpacity(0.5), height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildIndustrialInfoRow("ONLINE", "$onlineUsers", compact: true)),
                            Expanded(child: _buildIndustrialInfoRow("CONN", "$activeConnections", compact: true)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // QUICK ACTIONS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentRed.withOpacity(0.5)),
                      color: mediumGray.withOpacity(0.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flash_on, color: accentRed, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "QUICK ACTIONS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildIndustrialActionButton(
                              icon: Icons.bug_report,
                              label: "BUG SENDER",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BugSenderPage(
                                      sessionKey: sessionKey,
                                      username: username,
                                      role: role,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildIndustrialActionButton(
                              icon: Icons.lock_clock,
                              label: "CHANGE PASS",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChangePasswordPage(
                                      username: username,
                                      sessionKey: sessionKey,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildIndustrialActionButton(
                              icon: Icons.person_search,
                              label: "NIK CHECK",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NikCheckerPage(),
                                  ),
                                );
                              },
                            ),
                            if (role == "owner")
                              _buildIndustrialActionButton(
                                icon: Icons.admin_panel_settings,
                                label: "ADMIN",
                                onTap: _navigateToAdminPage,
                              ),
                            if (role == "reseller")
                              _buildIndustrialActionButton(
                                icon: Icons.sell,
                                label: "SELLER",
                                onTap: _navigateToSellerPage,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CONTACT SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentRed.withOpacity(0.5)),
                      color: mediumGray.withOpacity(0.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.contact_mail, color: accentRed, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "CONTACT",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildIndustrialContactButton(
                              icon: FontAwesomeIcons.telegram,
                              label: "TELEGRAM",
                              url: 'https://t.me/const_true_co',
                            ),
                            _buildIndustrialContactButton(
                              icon: FontAwesomeIcons.telegram,
                              label: "CHANNEL",
                              url: 'https://t.me/',
                            ),
                            _buildIndustrialContactButton(
                              icon: FontAwesomeIcons.tiktok,
                              label: "TIKTOK",
                              url: 'https://www.tiktok.com/@',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // BOTTOM LINE
                  Center(
                    child: Text(
                      "LAVENDOZ V8 • INDUSTRIAL EDITION",
                      style: TextStyle(
                        color: lightGray.withOpacity(0.5),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required String title,
    required List<String> items,
    bool showBottomLine = false,
  }) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "- $title",
            style: TextStyle(
              color: industrialYellow,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              item,
              style: TextStyle(
                color: item.startsWith('  •') ? lightGray : Colors.white,
                fontSize: item.startsWith('  •') ? 13 : 14,
                fontWeight: item.startsWith('  •') ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          )),
          if (showBottomLine) ...[
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: accentRed.withOpacity(0.3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndustrialInfoRow(String label, String value, {bool compact = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 6),
      child: Row(
        children: [
          Text(
            "$label:",
            style: TextStyle(
              color: lightGray,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: industrialYellow,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndustrialActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 2,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: accentRed.withOpacity(0.5)),
          color: bloodRed.withOpacity(0.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: industrialYellow, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndustrialContactButton({
    required IconData icon,
    required String label,
    required String url,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: accentRed.withOpacity(0.5)),
              color: bloodRed.withOpacity(0.2),
            ),
            child: Icon(icon, color: industrialYellow, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: lightGray,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      backgroundColor: darkGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: accentRed),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "LAVENDOZ",
          style: TextStyle(
            color: accentRed,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(color: accentRed.withOpacity(0.5)),
            ),
            child: IconButton(
              icon: Icon(Icons.logout, color: industrialYellow, size: 20),
              onPressed: () => _showLogoutDialog(),
            ),
          ),
        ],
      ),
      body: FadeTransition(opacity: _animation, child: _selectedPage),
      bottomNavigationBar: _buildIndustrialBottomNavBar(),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide(color: accentRed.withOpacity(0.5)),
        ),
        title: Text(
          "LOGOUT",
          style: TextStyle(color: accentRed, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        content: Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: lightGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: TextStyle(color: lightGray, letterSpacing: 1),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: accentRed),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: Text(
                "CONFIRM",
                style: TextStyle(color: accentRed, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: darkGray,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: accentRed.withOpacity(0.5), width: 1),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: bloodRed,
                border: Border(
                  bottom: BorderSide(color: accentRed, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "LAVENDOZ V8",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    username.toUpperCase(),
                    style: TextStyle(
                      color: industrialYellow,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildIndustrialDrawerItem(
              icon: Icons.home,
              label: "HOME",
              onTap: () => Navigator.pop(context),
            ),
            if (role == "owner")
              _buildIndustrialDrawerItem(
                icon: Icons.admin_panel_settings,
                label: "ADMIN PAGE",
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAdminPage();
                },
              ),
            if (role == "reseller")
              _buildIndustrialDrawerItem(
                icon: Icons.sell,
                label: "SELLER PAGE",
                onTap: () {
                  Navigator.pop(context);
                  _navigateToSellerPage();
                },
              ),
            _buildIndustrialDrawerItem(
              icon: Icons.lock_clock,
              label: "CHANGE PASSWORD",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordPage(
                      username: username,
                      sessionKey: sessionKey,
                    ),
                  ),
                );
              },
            ),
            _buildIndustrialDrawerItem(
              icon: Icons.person_search,
              label: "NIK CHECK",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NikCheckerPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndustrialDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: accentRed, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          letterSpacing: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildIndustrialBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: accentRed.withOpacity(0.5)),
        color: darkGray,
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: industrialYellow,
        unselectedItemColor: lightGray,
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "HOME",
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.whatsapp),
            label: "WHATSAPP",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_rounded),
            label: "TOOLS",
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    channel.sink.close(status.goingAway);
    _controller.dispose();
    super.dispose();
  }
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) =>
      url.endsWith(".mp4") ||
      url.endsWith(".webm") ||
      url.endsWith(".mov") ||
      url.endsWith(".mkv");

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        );
      } else {
        return Center(child: CircularProgressIndicator(color: Color(0xFFB22222)));
      }
    } else {
      return Image.network(widget.url, fit: BoxFit.cover);
    }
  }
}