import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/training_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// Màn hình CHI TIẾT BUỔI ĐÀO TẠO ĐÃ KẾT THÚC
/// Hiển thị thông tin tóm tắt và nút "Xem Video Bài Giảng" mở YouTube App / Browser.
class TrainingArchiveDetailView extends StatefulWidget {
  final TrainingRoom room;

  const TrainingArchiveDetailView({super.key, required this.room});

  @override
  State<TrainingArchiveDetailView> createState() =>
      _TrainingArchiveDetailViewState();
}

class _TrainingArchiveDetailViewState extends State<TrainingArchiveDetailView> {
  final TrainingController controller = Get.find<TrainingController>();
  final AuthController authController = Get.find<AuthController>();

  bool _isLaunching = false;
  final TextEditingController _videoUrlController = TextEditingController();

  @override
  void dispose() {
    _videoUrlController.dispose();
    super.dispose();
  }

  // ─── Deep-link logic: Mở App tương ứng (YouTube/Facebook) → fallback Browser ───

  /// Kiểm tra URL có phải của YouTube không.
  static bool isYouTubeUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  /// Kiểm tra URL có phải của Facebook không.
  static bool isFacebookUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('facebook.com') || host.contains('fb.watch') || host.contains('fb.com');
  }

  /// Chuyển URL YouTube dạng web sang YouTube App deep-link scheme.
  /// Ví dụ:
  ///   https://www.youtube.com/watch?v=abcXYZ → youtube://www.youtube.com/watch?v=abcXYZ
  ///   https://youtu.be/abcXYZ               → youtube://youtu.be/abcXYZ
  String _toYouTubeAppScheme(String url) {
    return url
        .replaceFirst('https://', 'youtube://')
        .replaceFirst('http://', 'youtube://');
  }

  /// Mở video bài giảng. Hỗ trợ cả link YouTube lẫn Facebook (nhóm nội bộ).
  ///
  /// - YouTube: thử mở YouTube App trước (trải nghiệm mượt hơn), lỗi thì mở web.
  /// - Facebook & các link khác: mở thẳng bằng ứng dụng ngoài — iOS/Android sẽ
  ///   tự chuyển sang app Facebook nếu đã cài, nếu không thì mở trình duyệt.
  ///   (KHÔNG ép qua scheme youtube:// vì sẽ mở nhầm app YouTube.)
  Future<void> launchVideo(String url) async {
    if (url.isEmpty) return;
    setState(() => _isLaunching = true);

    try {
      // Chỉ dùng deep-link YouTube khi link ĐÚNG là của YouTube
      if (isYouTubeUrl(url)) {
        final youtubeAppUri = Uri.parse(_toYouTubeAppScheme(url));
        if (await canLaunchUrl(youtubeAppUri)) {
          await launchUrl(youtubeAppUri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Mặc định (Facebook / link khác / fallback YouTube): mở bằng app ngoài
      final webUri = Uri.parse(url);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Không thể mở video. Vui lòng kiểm tra đường link.');
      }
    } catch (e) {
      _showError('Lỗi khi mở video: $e');
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Lỗi',
      message,
      backgroundColor: const Color(0xFFDC2626),
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  // ─── Admin: Dialog cập nhật link video ────────────────────────────────────

  void _showUpdateVideoDialog() {
    _videoUrlController.text = widget.room.videoUrl ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.video_call_rounded, color: Color(0xFF0F2C59), size: 22),
            SizedBox(width: 10),
            Text(
              'Cập nhật Video',
              style: TextStyle(
                color: Color(0xFF0F2C59),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LINK VIDEO BÀI GIẢNG',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _videoUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'Dán link video YouTube hoặc Facebook...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFFDC2626),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0F2C59),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hỗ trợ link YouTube và Facebook.\n'
              'Ví dụ: https://youtu.be/dQw4w9WgXcQ\n'
              'hoặc https://www.facebook.com/groups/.../posts/...\n'
              'Lưu ý: video trong nhóm Facebook riêng tư chỉ xem được khi đã là thành viên nhóm.',
              style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'HỦY',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final url = _videoUrlController.text.trim();
              Navigator.of(ctx).pop();
              if (url.isEmpty) return;

              final success =
                  await controller.updateVideoUrl(widget.room.id, url);
              if (success) {
                Get.snackbar(
                  'Thành công',
                  'Đã cập nhật link video bài giảng!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                );
                // Rebuild để hiện nút mới (nếu trước đó chưa có video)
                if (mounted) setState(() {});
              } else {
                _showError('Không thể cập nhật, vui lòng thử lại!');
              }
            },
            icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
            label: const Text(
              'LƯU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2C59),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

 

  @override
  Widget build(BuildContext context) {
    final role = authController.currentUser['role'] ?? 'SALE';
    final isAdmin = role == 'ADMIN' || role == 'TRUONG_PHONG';
    final date = widget.room.dateTime;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    // Lấy videoUrl từ completedRooms (reactive) để nút cập nhật ngay sau khi Admin lưu
    TrainingRoom? currentRoom;
    try {
      currentRoom = controller.completedRooms.firstWhere((r) => r.id == widget.room.id);
    } catch (_) {
      currentRoom = null;
    }
    final videoUrl = currentRoom?.videoUrl ?? widget.room.videoUrl;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F2C59),
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Chi tiết bài giảng',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  onPressed: _showUpdateVideoDialog,
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFFD4AF37),
                  ),
                  tooltip: 'Cập nhật video',
                ),
              const SizedBox(width: 4),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Completed Badge ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Buổi học đã kết thúc',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Info Card ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F2C59).withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.room.title,
                        style: const TextStyle(
                          color: Color(0xFF0F2C59),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metadata chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.person_rounded,
                            text: widget.room.presenter,
                            color: const Color(0xFFD4AF37),
                          ),
                          _InfoChip(
                            icon: Icons.calendar_today_rounded,
                            text: dateStr,
                            color: const Color(0xFF0F2C59),
                          ),
                          _InfoChip(
                            icon: Icons.access_time_rounded,
                            text: timeStr,
                            color: const Color(0xFF1565C0),
                          ),
                          _InfoChip(
                            icon: Icons.people_rounded,
                            text: '${widget.room.currentSlots} học viên',
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.notes_rounded,
                                  size: 15,
                                  color: Color(0xFF0F2C59),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'NỘI DUNG TÓM TẮT',
                                  style: TextStyle(
                                    color: Color(0xFF0F2C59),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.room.description.isNotEmpty
                                  ? widget.room.description
                                  : 'Chưa có mô tả nội dung.',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Video Section ──────────────────────────────────────
                if (hasVideo && videoUrl != null) ...[
                  // Thumbnail preview strip
                  _YouTubeThumbnailPreview(videoUrl: videoUrl),
                  const SizedBox(height: 16),

                  // CTA Button
                  _WatchVideoButton(
                    isLaunching: _isLaunching,
                    onTap: () => launchVideo(videoUrl),
                  ),
                ] else ...[
                  // No video placeholder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.videocam_off_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có video bài giảng',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Admin sẽ đăng tải video sau khi\nbiên tập xong bài giảng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showUpdateVideoDialog,
                            icon: const Icon(
                              Icons.add_link_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'THÊM LINK VIDEO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2C59),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Admin: Hiện URL để copy
                if (isAdmin && hasVideo && videoUrl != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: videoUrl));
                      Get.snackbar(
                        'Đã sao chép',
                        'Link video đã được sao chép vào clipboard.',
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2C59).withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0F2C59).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: Color(0xFF0F2C59),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              videoUrl,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F2C59),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── YouTube Thumbnail Preview ────────────────────────────────────────────────

class _YouTubeThumbnailPreview extends StatelessWidget {
  final String videoUrl;

  const _YouTubeThumbnailPreview({required this.videoUrl});

  /// Tách Video ID từ URL YouTube để lấy thumbnail
  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      // Format: https://www.youtube.com/watch?v=VIDEO_ID
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
      // Format: https://youtu.be/VIDEO_ID
      if (uri.host == 'youtu.be') {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractVideoId(videoUrl);
    final thumbnailUrl = videoId != null
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : null;

    // Nhận diện nguồn video để hiển thị đúng nhãn & màu thương hiệu
    final isFacebook =
        _TrainingArchiveDetailViewState.isFacebookUrl(videoUrl);
    final brandColor =
        isFacebook ? const Color(0xFF1877F2) : const Color(0xFFFF0000);
    final brandLabel = isFacebook ? 'Facebook' : 'YouTube';

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail image
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A2E),
                  child: const Icon(
                    Icons.movie_outlined,
                    color: Colors.white24,
                    size: 60,
                  ),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF0F2C59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white24,
                  size: 60,
                ),
              ),

            // Dark overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Logo nguồn video + Play overlay
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: brandColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: brandColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),

            // Bottom label
            Positioned(
              left: 14,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: brandColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  brandLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Watch Video Button ───────────────────────────────────────────────────────

class _WatchVideoButton extends StatelessWidget {
  final bool isLaunching;
  final VoidCallback onTap;

  const _WatchVideoButton({
    required this.isLaunching,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLaunching ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLaunching
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [const Color(0xFFFF0000), const Color(0xFFCC0000)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLaunching
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFFF0000).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLaunching)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
            const SizedBox(width: 12),
            Text(
              isLaunching ? 'Đang mở...' : 'Xem Video Bài Giảng',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            if (!isLaunching) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.open_in_new_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
