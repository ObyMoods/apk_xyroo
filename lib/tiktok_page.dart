import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';

class TiktokDownloaderPage extends StatefulWidget {
  const TiktokDownloaderPage({super.key});

  @override
  State<TiktokDownloaderPage> createState() => _TiktokDownloaderPageState();
}

class _TiktokDownloaderPageState extends State<TiktokDownloaderPage> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _videoData;
  String? _errorMessage;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  late AnimationController _glowController;

  // Warna biru neon dan abu-abu
  final Color neonBlue = const Color(0xFF00F3FF);
  final Color neonBlueDark = const Color(0xFF0099FF);
  final Color neonBlueLight = const Color(0xFF7DF9FF);
  final Color steelGray = const Color(0xFF2C3E50);
  final Color lightGray = const Color(0xFF95A5A6);
  final Color darkGray = const Color(0xFF1E2B3A);
  final Color cardDark = const Color(0xFF1E2B3A);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _downloadTiktok() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "URL TikTok tidak boleh kosong.";
        _videoData = null;
      });
      return;
    }

    if (!url.contains('tiktok.com/')) {
      setState(() {
        _errorMessage = "URL tidak valid! Harus URL TikTok";
        _videoData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    try {
      // Menggunakan POST request ke tikwm.com API
      final response = await http.post(
        Uri.parse("https://www.tikwm.com/api/"),
        body: {"url": url},
        headers: {
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // Cek response dari API tikwm
        if (json['code'] == 0 && json['data'] != null) {
          final vid = json['data'];
          
          // Ambil URL video dengan prioritas: play > hdplay > wmplay > play_addr
          String? videoUrl;
          if (vid['play'] != null) {
            videoUrl = vid['play'];
          } else if (vid['hdplay'] != null) {
            videoUrl = vid['hdplay'];
          } else if (vid['wmplay'] != null) {
            videoUrl = vid['wmplay'];
          } else if (vid['play_addr'] != null) {
            videoUrl = vid['play_addr'];
          }

          final isImage = vid['images'] != null && vid['images'] is List && vid['images'].isNotEmpty;

          // Jika ini adalah image slideshow, beri pesan error
          if (isImage) {
            setState(() {
              _errorMessage = "Tipe konten ini adalah image slideshow. Hanya video yang didukung.";
              _isLoading = false;
            });
            return;
          }

          if (videoUrl == null) {
            setState(() {
              _errorMessage = "Tidak dapat menemukan URL video";
              _isLoading = false;
            });
            return;
          }

          // Struktur data sederhana seperti di kode awal
          final result = {
            'urls': [videoUrl],
            'metadata': {
              'creator': vid['author']?['nickname'] ?? 'Unknown',
              'title': vid['title'] ?? 'Video TikTok',
            },
            'title': vid['title'] ?? 'Video TikTok',
            'author': vid['author']?['nickname'] ?? 'Unknown',
            'likes': vid['digg_count'] ?? 0,
            'comments': vid['comment_count'] ?? 0,
            'shares': vid['share_count'] ?? 0,
            'plays': vid['play_count'] ?? 0,
            'cover': vid['cover'] ?? null,
          };

          setState(() {
            _videoData = result;
          });

          // Inisialisasi video player
          _initializeVideoPlayer(videoUrl);
        } else {
          setState(() {
            _errorMessage = json['msg'] ?? "Video tidak ditemukan";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal terhubung ke server. (${response.statusCode})";
        });
      }
    } catch (e) {
      if (e.toString().contains("timeout")) {
        setState(() {
          _errorMessage = "Timeout saat download video. Coba lagi.";
        });
      } else {
        setState(() {
          _errorMessage = "Terjadi kesalahan: ${e.toString()}";
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeVideoPlayer(String videoUrl) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
            looping: false,
            showControls: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: neonBlue,
              handleColor: neonBlueLight,
              backgroundColor: lightGray,
              bufferedColor: steelGray,
            ),
          );
        });
      }).catchError((error) {
        setState(() {
          _errorMessage = "Gagal memuat video: $error";
        });
      });
  }

  Future<void> _shareVideo() async {
    if (_videoData?['urls'] == null || _videoData!['urls'].isEmpty) return;

    try {
      final videoUrl = _videoData!['urls'][0];
      final response = await http.get(Uri.parse(videoUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tiktok_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(response.bodyBytes);

      final authorName = _videoData!['author'] ?? 'Unknown';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🎵 TikTok Video by $authorName',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          backgroundColor: darkGray,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: neonBlue.withOpacity(0.3)),
          ),
        ),
      );
    }
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
            darkGray.withOpacity(0.9),
            steelGray.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: neonBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGlassInputField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            darkGray,
            steelGray,
          ],
        ),
      ),
      child: TextField(
        controller: _urlController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: neonBlue,
        decoration: InputDecoration(
          labelText: 'Masukkan URL TikTok',
          labelStyle: TextStyle(color: lightGray),
          hintText: 'Contoh: https://vt.tiktok.com/xxx/',
          hintStyle: TextStyle(color: lightGray.withOpacity(0.5)),
          prefixIcon: Icon(Icons.link, color: neonBlue),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, color: lightGray),
            onPressed: () => _urlController.clear(),
          ),
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: neonBlue.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: neonBlue, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: neonBlue.withOpacity(0.3)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isLoading = false,
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color,
                color == neonBlue ? neonBlueDark : neonBlue,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3 + (0.2 * _glowController.value)),
                blurRadius: 15 + (5 * _glowController.value),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      body: Stack(
        children: [
          // Background effects
          Positioned(
            top: -100,
            right: -100,
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
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    neonBlueDark.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildGlassCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library, color: neonBlue, size: 32),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [neonBlue, neonBlueLight],
                            ).createShader(bounds),
                            child: const Text(
                              "TIKTOK DOWNLOADER",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildGlassCard(
                      child: Column(
                        children: [
                          _buildGlassInputField(),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            text: "DOWNLOAD",
                            icon: Icons.download,
                            onPressed: _downloadTiktok,
                            color: neonBlue,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_errorMessage != null)
                      _buildGlassCard(
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: neonBlueLight),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: lightGray, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    if (_videoData != null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildGlassCard(
                                child: Column(
                                  children: [
                                    if (_chewieController != null)
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: neonBlue.withOpacity(0.3)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: AspectRatio(
                                            aspectRatio: _videoController!.value.aspectRatio,
                                            child: Chewie(controller: _chewieController!),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: [
                                              darkGray,
                                              steelGray,
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(color: Colors.white),
                                        ),
                                      ),

                                    const SizedBox(height: 16),

                                    // Info singkat video
                                    if (_videoData!['author'] != null || _videoData!['title'] != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: darkGray.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            if (_videoData!['title'] != null)
                                              Text(
                                                _videoData!['title'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (_videoData!['author'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.person, color: neonBlue, size: 14),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '@${_videoData!['author']}',
                                                      style: TextStyle(color: lightGray, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 16),

                                    _buildActionButton(
                                      text: "SHARE VIDEO",
                                      icon: Icons.share,
                                      onPressed: _shareVideo,
                                      color: neonBlueLight,
                                      isLoading: false,
                                    ),
                                  ],
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
          ),
        ],
      ),
    );
  }
}