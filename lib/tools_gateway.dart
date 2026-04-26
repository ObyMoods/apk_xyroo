import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _cardController;
  late AnimationController _particleController;
  late Animation<double> _bgAnimation;
  late Animation<double> _cardAnimation;

  // Warna tema biru neon dan abu-abu
  final Color neonBlue = const Color(0xFF00F3FF); // Neon cyan/blue utama
  final Color neonBlueDark = const Color(0xFF0099FF); // Biru neon gelap
  final Color neonBlueLight = const Color(0xFF7DF9FF); // Biru neon terang
  final Color steelGray = const Color(0xFF2C3E50); // Abu-abu steel gelap
  final Color lightGray = const Color(0xFF95A5A6); // Abu-abu terang
  final Color darkGray = const Color(0xFF1E2B3A); // Abu-abu gelap dengan sentuhan biru
  final Color primaryWhite = Colors.white;
  final Color glassWhite = Colors.white.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(_bgController);
    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      body: Stack(
        children: [
          // Background dengan efek neon
          _buildNeonBackground(),

          // Konten utama
          SafeArea(
            child: Column(
              children: [
                // Header dengan desain baru
                _buildNeonHeader(),

                // Kategori tools
                Expanded(
                  child: _buildToolCategories(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonBackground() {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Background gradient dengan warna biru neon dan abu-abu
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    darkGray,
                    steelGray,
                    const Color(0xFF0A1929),
                  ],
                ),
              ),
            ),

            // Partikel neon beranimasi
            ...List.generate(30, (index) {
              final top = (_bgAnimation.value + index * 0.03) % 1.0;
              final left = (index * 0.1 + _bgAnimation.value * 0.2) % 1.0;
              final size = 8.0 + (index % 6) * 4.0;
              final opacity = 0.05 + (index % 4) * 0.05;

              return Positioned(
                top: top * MediaQuery.of(context).size.height,
                left: left * MediaQuery.of(context).size.width,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: neonBlue.withOpacity(opacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: neonBlue.withOpacity(opacity * 0.8),
                        blurRadius: size * 2,
                        spreadRadius: size,
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Efek neon grid di background
            CustomPaint(
              painter: NeonGridPainter(neonBlue, lightGray),
              size: Size.infinite,
            ),

            // Efek cahaya berputar
            Positioned(
              top: -150,
              right: -150,
              child: AnimatedBuilder(
                animation: _bgAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _bgAnimation.value * 2 * 3.14159,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            neonBlue.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Efek cahaya kedua
            Positioned(
              bottom: -200,
              left: -200,
              child: AnimatedBuilder(
                animation: _bgAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_bgAnimation.value * 1.5 * 3.14159,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            neonBlueDark.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNeonHeader() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Logo dan judul dengan efek neon
              Row(
                children: [
                  // Logo dengan animasi
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [neonBlue, neonBlueDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: neonBlue.withOpacity(0.5),
                                blurRadius: 15 * value,
                                spreadRadius: 2 * value,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.security,
                            color: primaryWhite,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 16),

                  // Judul dengan efek neon
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [neonBlue, neonBlueLight],
                          ).createShader(bounds),
                          child: Text(
                            "NEON TOOLS",
                            style: TextStyle(
                              color: primaryWhite,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Text(
                          "Advanced Security Suite",
                          style: TextStyle(
                            color: lightGray,
                            fontSize: 14,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status user dengan efek neon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [neonBlue.withOpacity(0.2), neonBlueDark.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: neonBlue.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.userRole.toUpperCase(),
                      style: TextStyle(
                        color: neonBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        shadows: [
                          Shadow(
                            color: neonBlue.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Garis dekoratif neon
              const SizedBox(height: 16),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      neonBlue,
                      neonBlueLight,
                      neonBlue,
                      Colors.transparent,
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

  Widget _buildToolCategories() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimation.value) * 50),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Grid tools dengan desain baru
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return _buildNeonToolCard(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNeonToolCard(int index) {
    final List<Map<String, dynamic>> tools = [
      {
        "icon": Icons.flash_on,
        "title": "DDoS",
        "subtitle": "Attack Panel",
        "color": neonBlue,
        "gradient": [neonBlue, neonBlueDark],
        "onTap": () => _showDDoSTools(context),
      },
      {
        "icon": Icons.wifi,
        "title": "Network",
        "subtitle": "WiFi & Spam",
        "color": neonBlueLight,
        "gradient": [neonBlueLight, neonBlue],
        "onTap": () => _showNetworkTools(context),
      },
      {
        "icon": Icons.search,
        "title": "OSINT",
        "subtitle": "Investigation",
        "color": neonBlue,
        "gradient": [neonBlue, neonBlueDark],
        "onTap": () => _showOSINTTools(context),
      },
      {
        "icon": Icons.download,
        "title": "Downloader",
        "subtitle": "Media Tools",
        "color": neonBlueLight,
        "gradient": [neonBlueLight, neonBlue],
        "onTap": () => _showDownloaderTools(context),
      },
      {
        "icon": Icons.build,
        "title": "Utilities",
        "subtitle": "Extra Tools",
        "color": neonBlue,
        "gradient": [neonBlue, neonBlueDark],
        "onTap": () => _showUtilityTools(context),
      },
      {
        "icon": Icons.rocket_launch,
        "title": "Quick Access",
        "subtitle": "Favorites",
        "color": neonBlueLight,
        "gradient": [neonBlueLight, neonBlue],
        "onTap": () => _showQuickAccess(context),
      },
    ];

    final tool = tools[index];

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: tool["onTap"],
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkGray.withOpacity(0.7),
                    steelGray.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: tool["color"].withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tool["color"].withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: tool["color"].withOpacity(0.1),
                    blurRadius: 25,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon dengan efek neon
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: tool["gradient"],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: tool["color"].withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            tool["icon"],
                            color: primaryWhite,
                            size: 30,
                          ),
                        ),

                        const Spacer(),

                        // Title dengan efek neon
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: tool["gradient"],
                          ).createShader(bounds),
                          child: Text(
                            tool["title"],
                            style: TextStyle(
                              color: primaryWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Subtitle
                        Text(
                          tool["subtitle"],
                          style: TextStyle(
                            color: lightGray,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Neon indicator
                        Container(
                          height: 2,
                          width: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: tool["gradient"],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDDoSTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNeonModalSheet(
        context,
        "DDoS Tools",
        Icons.flash_on,
        neonBlue,
        [
          _buildNeonModalOption(
            icon: Icons.flash_on,
            label: "Attack Panel",
            color: neonBlue,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttackPanel(
                    sessionKey: widget.sessionKey,
                    listDoos: widget.listDoos,
                  ),
                ),
              );
            },
          ),
          _buildNeonModalOption(
            icon: Icons.dns,
            label: "Manage Server",
            color: neonBlueLight,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageServerPage(keyToken: widget.sessionKey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNetworkTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNeonModalSheet(
        context,
        "Network Tools",
        Icons.wifi,
        neonBlueLight,
        [
          _buildNeonModalOption(
            icon: Icons.newspaper_outlined,
            label: "Spam NGL",
            color: neonBlue,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NglPage()),
              );
            },
          ),
          _buildNeonModalOption(
            icon: Icons.wifi_off,
            label: "WiFi Killer (Internal)",
            color: neonBlueLight,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WifiKillerPage()),
              );
            },
          ),
          if (widget.userRole == "vip" || widget.userRole == "owner")
            _buildNeonModalOption(
              icon: Icons.router,
              label: "WiFi Killer (External)",
              color: neonBlue,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WifiInternalPage(sessionKey: widget.sessionKey),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showOSINTTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNeonModalSheet(
        context,
        "OSINT Tools",
        Icons.search,
        neonBlue,
        [
          _buildNeonModalOption(
            icon: Icons.badge,
            label: "NIK Detail",
            color: neonBlue,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NikCheckerPage()),
              );
            },
          ),
          _buildNeonModalOption(
            icon: Icons.domain,
            label: "Domain OSINT",
            color: neonBlueLight,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DomainOsintPage()),
              );
            },
          ),
          _buildNeonModalOption(
            icon: Icons.person_search,
            label: "Phone Lookup",
            color: neonBlue,
            onTap: () => _showComingSoon(context),
          ),
          _buildNeonModalOption(
            icon: Icons.email,
            label: "Email OSINT",
            color: neonBlueLight,
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  void _showDownloaderTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNeonModalSheet(
        context,
        "Media Downloader",
        Icons.download,
        neonBlueLight,
        [
          _buildNeonModalOption(
            icon: Icons.video_library,
            label: "TikTok Downloader",
            color: neonBlue,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TiktokDownloaderPage()),
              );
            },
          ),
          _buildNeonModalOption(
            icon: Icons.camera_alt,
            label: "Instagram Downloader",
            color: neonBlueLight,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InstagramDownloaderPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUtilityTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNeonModalSheet(
        context,
        "Utility Tools",
        Icons.build,
        neonBlue,
        [
          _buildNeonModalOption(
            icon: Icons.qr_code,
            label: "QR Generator",
            color: neonBlue,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrGeneratorPage()),
              );
            },
          ),
          _buildNeonModalOption(
            icon: Icons.security,
            label: "IP Scanner",
            color: neonBlueLight,
            onTap: () => _showComingSoon(context),
          ),
          _buildNeonModalOption(
            icon: Icons.network_check,
            label: "Port Scanner",
            color: neonBlue,
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  void _showQuickAccess(BuildContext context) {
    _showComingSoon(context);
  }

  Widget _buildNeonModalSheet(
      BuildContext context,
      String title,
      IconData icon,
      Color accentColor,
      List<Widget> options,
      ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkGray, steelGray],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: neonBlue.withOpacity(0.2),
            blurRadius: 35,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header modal dengan efek neon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor == neonBlue ? neonBlueDark : neonBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.4),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: primaryWhite),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 22,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Opsi-opsi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: options,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonModalOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkGray.withOpacity(0.8),
                    steelGray.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color == neonBlue ? neonBlueDark : neonBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: primaryWhite, size: 24),
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    color: primaryWhite,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 14,
                  ),
                ),
                onTap: onTap,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_top, color: neonBlue),
            const SizedBox(width: 8),
            Text(
              'Feature Coming Soon!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                color: neonBlue,
              ),
            ),
          ],
        ),
        backgroundColor: darkGray,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: neonBlue.withOpacity(0.3)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Custom painter untuk efek grid neon
class NeonGridPainter extends CustomPainter {
  final Color neonBlue;
  final Color lightGray;

  NeonGridPainter(this.neonBlue, this.lightGray);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = neonBlue.withOpacity(0.07)
      ..strokeWidth = 0.8;

    final paint2 = Paint()
      ..color = lightGray.withOpacity(0.03)
      ..strokeWidth = 0.3;

    const gridSize = 40.0;

    // Gambar garis vertikal
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Gambar garis horizontal
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Gambar garis diagonal untuk efek neon tambahan
    for (double i = -size.width; i < size.width + size.height; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint2);
    }

    // Gambar titik-titik neon di persimpangan grid
    final dotPaint = Paint()
      ..color = neonBlue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}