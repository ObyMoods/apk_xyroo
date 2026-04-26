import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';

class InstagramDownloaderPage extends StatefulWidget {
  const InstagramDownloaderPage({super.key});

  @override
  State<InstagramDownloaderPage> createState() => _InstagramDownloaderPageState();
}

class _InstagramDownloaderPageState extends State<InstagramDownloaderPage> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _mediaData;
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

  Future<void> _downloadInstagram() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "URL Instagram tidak boleh kosong.";
        _mediaData = null;
      });
      return;
    }

    if (!url.contains('instagram.com/')) {
      setState(() {
        _errorMessage = "URL tidak valid! Harus URL Instagram";
        _mediaData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mediaData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    final encodedUrl = Uri.encodeComponent(url);
    final apiUrl = Uri.parse("https://igram.website/content.php?url=$encodedUrl");

    try {
      // Menggunakan headers yang sama seperti di JavaScript
      final response = await http.get(
        apiUrl,
        headers: {
          "accept": "*/*",
          "accept-language": "id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7",
          "cache-control": "no-cache",
          "content-type": "application/x-www-form-urlencoded",
          "pragma": "no-cache",
          "sec-ch-ua": '"Chromium";v="139", "Not;A=Brand";v="99"',
          "sec-ch-ua-mobile": "?1",
          "sec-ch-ua-platform": '"Android"',
          "sec-fetch-dest": "empty",
          "sec-fetch-mode": "cors",
          "sec-fetch-site": "same-origin",
          "Referer": "https://igram.website/",
          "Referrer-Policy": "strict-origin-when-cross-origin",
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['html'] != null) {
          // Parse HTML response
          final parsedData = _parseInstagramHTML(json['html']);
          
          if (parsedData.isNotEmpty) {
            setState(() {
              _mediaData = parsedData;
            });

            // Initialize video player jika ada video
            if (parsedData['videoUrl'] != null && parsedData['videoUrl'].toString().isNotEmpty) {
              _initializeVideoPlayer(parsedData['videoUrl']);
            } else if (parsedData['media'] != null && (parsedData['media'] as List).isNotEmpty) {
              // Cari URL video dari media list
              for (var mediaUrl in parsedData['media']) {
                if (mediaUrl.toString().contains('.mp4')) {
                  _initializeVideoPlayer(mediaUrl);
                  break;
                }
              }
            }
          } else {
            setState(() {
              _errorMessage = "Tidak dapat menemukan media di halaman ini.";
            });
          }
        } else {
          setState(() {
            _errorMessage = "Gagal mengambil data Instagram.";
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
          _errorMessage = "Timeout saat download. Coba lagi.";
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

  Map<String, dynamic> _parseInstagramHTML(String html) {
    final result = <String, dynamic>{
      'username': '',
      'name': '',
      'caption': '',
      'likes': '',
      'comments': '',
      'time': '',
      'videoUrl': '',
      'imageUrl': '',
      'downloadLink': '',
      'media': <String>[],
    };

    try {
      // Username - dari #user_info p.h4 atau p.h4
      RegExp usernameRegex = RegExp(r'<p class="h4"[^>]*>([^<]+)</p>');
      var match = usernameRegex.firstMatch(html);
      if (match != null) {
        result['username'] = _decodeHtmlEntities(match.group(1)?.trim() ?? '');
      }

      // Name - dari #user_info p.text-muted
      RegExp nameRegex = RegExp(r'<p class="text-muted"[^>]*>([^<]+)</p>');
      match = nameRegex.firstMatch(html);
      if (match != null) {
        result['name'] = _decodeHtmlEntities(match.group(1)?.trim() ?? '');
      }

      // Caption - dari .d-flex.justify-content-between.align-items-center p.text-sm
      RegExp captionRegex = RegExp(r'<div class="d-flex justify-content-between align-items-center[^>]*>.*?<p class="text-sm"[^>]*>(.*?)</p>', dotAll: true);
      match = captionRegex.firstMatch(html);
      if (match != null) {
        String caption = match.group(1) ?? '';
        caption = caption.replaceAll('<br>', '\n').replaceAll('<br/>', '\n').replaceAll('<br />', '\n');
        // Hapus tag HTML lainnya
        caption = caption.replaceAll(RegExp(r'<[^>]*>'), '');
        result['caption'] = _decodeHtmlEntities(caption.trim());
      }

      // Stats (likes, comments, time) - dari .stats.text-sm small
      RegExp statsRegex = RegExp(r'<div class="stats text-sm[^>]*>.*?<small[^>]*>([^<]+)</small>.*?<small[^>]*>([^<]+)</small>.*?<small[^>]*>([^<]+)</small>', dotAll: true);
      match = statsRegex.firstMatch(html);
      if (match != null) {
        result['likes'] = match.group(1)?.trim() ?? '';
        result['comments'] = match.group(2)?.trim() ?? '';
        result['time'] = match.group(3)?.trim() ?? '';
      }

      // Video URL - dari video source
      RegExp videoRegex = RegExp(r'<video[^>]*>.*?<source[^>]*src="([^"]+)"', dotAll: true);
      match = videoRegex.firstMatch(html);
      if (match != null) {
        result['videoUrl'] = _cleanUrl(match.group(1) ?? '');
      }

      // Image URL (poster) - dari video poster atau img.rounded-circle
      RegExp posterRegex = RegExp(r'<video[^>]*poster="([^"]+)"');
      match = posterRegex.firstMatch(html);
      if (match != null) {
        result['imageUrl'] = _cleanUrl(match.group(1) ?? '');
      } else {
        RegExp imgRegex = RegExp(r'<img[^>]*class="rounded-circle"[^>]*src="([^"]+)"');
        match = imgRegex.firstMatch(html);
        if (match != null) {
          result['imageUrl'] = _cleanUrl(match.group(1) ?? '');
        }
      }

      // Download link - dari a.btn.bg-gradient-success
      RegExp downloadRegex = RegExp(r'<a[^>]*class="btn[^"]*bg-gradient-success[^"]*"[^>]*href="([^"]+)"');
      match = downloadRegex.firstMatch(html);
      if (match != null) {
        result['downloadLink'] = _cleanUrl(match.group(1) ?? '');
      }

      // Semua media URLs (mp4, jpg, jpeg, png, webp)
      RegExp mediaRegex = RegExp(r'(https?://[^\s"\<>]+\.(?:mp4|jpg|jpeg|png|webp))', caseSensitive: false);
      Iterable<RegExpMatch> mediaMatches = mediaRegex.allMatches(html);
      Set<String> uniqueUrls = {};
      for (var m in mediaMatches) {
        String url = _cleanUrl(m.group(1) ?? '');
        if (url.isNotEmpty) {
          uniqueUrls.add(url);
        }
      }
      result['media'] = uniqueUrls.toList();

    } catch (e) {
      debugPrint('Error parsing HTML: $e');
    }

    return result;
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—');
  }

  String _cleanUrl(String url) {
    try {
      if (url.isEmpty) return url;
      
      // Decode URL jika perlu
      String decoded = Uri.decodeFull(url);
      
      // Parse URL
      final uri = Uri.parse(decoded);
      
      // Hapus parameter tracking
      final paramsToRemove = ['ccb', 'oh', 'oe', 'edm', '_nc_ht', 'ig_cache_key', 'se', 'efg'];
      
      Map<String, String> newQueryParams = {};
      uri.queryParameters.forEach((key, value) {
        if (!paramsToRemove.contains(key)) {
          newQueryParams[key] = value;
        }
      });
      
      final newUri = uri.replace(queryParameters: newQueryParams.isEmpty ? null : newQueryParams);
      return newUri.toString();
    } catch (e) {
      return url;
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
    String? videoUrl;
    
    if (_mediaData?['videoUrl'] != null && _mediaData!['videoUrl'].toString().isNotEmpty) {
      videoUrl = _mediaData!['videoUrl'];
    } else if (_mediaData?['media'] != null) {
      for (var url in _mediaData!['media']) {
        if (url.toString().contains('.mp4')) {
          videoUrl = url;
          break;
        }
      }
    }

    if (videoUrl == null || videoUrl.isEmpty) return;

    try {
      final response = await http.get(Uri.parse(videoUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/instagram_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(response.bodyBytes);

      String shareText = "Instagram Video";
      if (_mediaData?['username'] != null && _mediaData!['username'].toString().isNotEmpty) {
        shareText = "Instagram Video by @${_mediaData!['username']}";
      }
      if (_mediaData?['caption'] != null && _mediaData!['caption'].toString().isNotEmpty) {
        shareText += "\n\n${_mediaData!['caption']}";
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
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
          labelText: 'Masukkan URL Instagram',
          labelStyle: TextStyle(color: lightGray),
          hintText: 'Contoh: https://www.instagram.com/reel/xxx/',
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: neonBlue, size: 16),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: TextStyle(color: lightGray, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
                          Icon(Icons.camera_alt, color: neonBlue, size: 32),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [neonBlue, neonBlueLight],
                            ).createShader(bounds),
                            child: const Text(
                              "INSTAGRAM DOWNLOADER",
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
                            onPressed: _downloadInstagram,
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

                    if (_mediaData != null && _mediaData!.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildGlassCard(
                                child: Column(
                                  children: [
                                    // Video Player atau Thumbnail
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
                                    else if (_mediaData!['imageUrl'] != null && _mediaData!['imageUrl'].toString().isNotEmpty)
                                      Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          image: DecorationImage(
                                            image: NetworkImage(_mediaData!['imageUrl']),
                                            fit: BoxFit.cover,
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
                                        child: Center(
                                          child: Icon(Icons.image, color: neonBlue, size: 50),
                                        ),
                                      ),

                                    const SizedBox(height: 16),

                                    // Info Instagram
                                    if (_mediaData!['username'] != null || 
                                        _mediaData!['caption'] != null ||
                                        _mediaData!['likes'] != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: darkGray.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            if (_mediaData!['username'] != null && _mediaData!['username'].toString().isNotEmpty)
                                              Row(
                                                children: [
                                                  Icon(Icons.person, color: neonBlue, size: 16),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      '@${_mediaData!['username']}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (_mediaData!['name'] != null && 
                                                _mediaData!['name'].toString().isNotEmpty && 
                                                _mediaData!['name'] != _mediaData!['username'])
                                              Padding(
                                                padding: const EdgeInsets.only(left: 24, top: 4),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      _mediaData!['name'],
                                                      style: TextStyle(color: lightGray, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (_mediaData!['caption'] != null && _mediaData!['caption'].toString().isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  _mediaData!['caption'],
                                                  style: TextStyle(color: lightGray, fontSize: 12),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            if (_mediaData!['likes'] != null || _mediaData!['comments'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                  children: [
                                                    if (_mediaData!['likes'] != null && _mediaData!['likes'].toString().isNotEmpty)
                                                      Row(
                                                        children: [
                                                          Icon(Icons.favorite, color: neonBlue, size: 14),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            _mediaData!['likes'],
                                                            style: TextStyle(color: lightGray, fontSize: 11),
                                                          ),
                                                        ],
                                                      ),
                                                    if (_mediaData!['comments'] != null && _mediaData!['comments'].toString().isNotEmpty)
                                                      Row(
                                                        children: [
                                                          Icon(Icons.comment, color: neonBlue, size: 14),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            _mediaData!['comments'],
                                                            style: TextStyle(color: lightGray, fontSize: 11),
                                                          ),
                                                        ],
                                                      ),
                                                    if (_mediaData!['time'] != null && _mediaData!['time'].toString().isNotEmpty)
                                                      Row(
                                                        children: [
                                                          Icon(Icons.access_time, color: neonBlue, size: 14),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            _mediaData!['time'],
                                                            style: TextStyle(color: lightGray, fontSize: 11),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 16),

                                    // Share button jika ada video
                                    if ((_mediaData!['videoUrl'] != null && _mediaData!['videoUrl'].toString().isNotEmpty) || 
                                        (_mediaData!['media'] != null && 
                                         (_mediaData!['media'] as List).any((url) => url.toString().contains('.mp4'))))
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