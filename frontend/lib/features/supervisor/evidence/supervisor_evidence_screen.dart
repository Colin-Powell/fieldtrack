import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/constants/app_constants.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import 'package:fieldtrack/core/network/api_result_builder.dart';
import 'package:fieldtrack/shared/widgets/skeleton_loader.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fieldtrack/core/utils/image_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ==========================================
// DESIGN TOKENS
// ==========================================
class _C {
  static const green = Color(0xFF1BA654);
  static const greenLight = Color(0xFFE6F5EC);
  static const textDark = Color(0xFF111827);
  static const textBody = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFEDD5);
  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFFEFF6FF);

  static const cardRadius = 48.0; // Outer structural containers
  static const innerCardRadius =
      24.0; // Scaled down for tiny cards to prevent circle-clipping
}

class SupervisorEvidenceScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String activityId;

  const SupervisorEvidenceScreen({
    super.key,
    required this.studentId,
    required this.activityId,
  });

  @override
  ConsumerState<SupervisorEvidenceScreen> createState() =>
      _SupervisorEvidenceScreenState();
}

class _SupervisorEvidenceScreenState
    extends ConsumerState<SupervisorEvidenceScreen> {
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(activityDetailsProvider(widget.activityId));

    return ApiResultBuilder<Map<String, dynamic>>(
      asyncValue: activityAsync,
      onRetry: () => ref.refresh(activityDetailsProvider(widget.activityId)),
      customLoading: const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _C.green)),
      ),
      onData: (activity) {
        final evidenceList = activity['evidence'] as List<dynamic>? ?? [];
        final images = evidenceList
            .where((e) => (e['mimeType'] as String? ?? '').startsWith('image/'))
            .toList();
        final videos = evidenceList
            .where((e) => (e['mimeType'] as String? ?? '').startsWith('video/'))
            .toList();
        final audios = evidenceList
            .where((e) => (e['mimeType'] as String? ?? '').startsWith('audio/'))
            .toList();
        final docs = evidenceList
            .where(
              (e) =>
                  (e['mimeType'] as String? ?? '').startsWith('application/') ||
                  (e['mimeType'] as String? ?? '').startsWith('text/'),
            )
            .toList();

        String studentName = 'Unknown Student';
        if (activity['user'] != null && activity['user']['name'] != null) {
          studentName = activity['user']['name'];
        }

        String submittedDateStr = 'N/A';
        if (activity['timestamp'] != null) {
          final dt = DateTime.parse(activity['timestamp']).toLocal();
          submittedDateStr = DateFormat('dd MMM yyyy').format(dt);
        }

        String accuracy = 'N/A';

        return Stack(
          children: [
            // ── MAIN SCROLLABLE CONTENT ─────────────────────────────────────
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LEFT COLUMN: Media (Images, Videos, Voice Notes) ────────
                  Expanded(
                    flex: 11,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_C.cardRadius),
                        border: Border.all(color: _C.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- IMAGES ---
                          if (images.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Images (${images.length})',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _C.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            GridView.builder(
                              itemCount: images.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.75,
                                  ),
                              itemBuilder: (context, index) {
                                final ev = images[index];
                                final url = ImageUtils.getFullImageUrl(
                                  ev['storagePath'],
                                );
                                final time = submittedDateStr;
                                return _buildImageCard(
                                  context,
                                  ev['fileName'] ?? 'Image_$index.jpg',
                                  time,
                                  accuracy,
                                  url,
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                          ],

                          // --- VIDEOS ---
                          if (videos.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Videos (${videos.length})',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _C.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            GridView.builder(
                              itemCount: videos.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.2,
                                  ),
                              itemBuilder: (context, index) {
                                final ev = videos[index];
                                final rawPath =
                                    ev['storagePath'] ??
                                    ev['url'] ??
                                    ev['storedName'] ??
                                    ev['originalName'];
                                final url = ImageUtils.getFullImageUrl(
                                  rawPath as String?,
                                );
                                debugPrint(
                                  'SupervisorEvidence: resolved video URL: $url',
                                );
                                final time = submittedDateStr;
                                final title =
                                    (ev['fileName'] ??
                                            ev['originalName'] ??
                                            ev['storedName'] ??
                                            'Video_$index.mp4')
                                        as String;
                                return _buildVideoCard(
                                  context,
                                  title,
                                  time,
                                  'N/A',
                                  url,
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                          ],

                          // --- VOICE NOTES ---
                          if (audios.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Voice Notes (${audios.length})',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _C.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              itemCount: audios.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final ev = audios[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildVoiceNoteCard(
                                    context,
                                    ev['fileName'] ?? 'Audio_$index.mp3',
                                    ImageUtils.getFullImageUrl(
                                      ev['storagePath'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // ── RIGHT COLUMN: Documents, Summary & Info ───────────────────
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Documents Section
                        if (docs.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _C.cardRadius,
                              ),
                              border: Border.all(color: _C.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Documents (${docs.length})',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _C.textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  itemCount: docs.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final ev = docs[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: _buildDocumentCard(
                                        ev['originalName'] ??
                                            ev['fileName'] ??
                                            'Doc_$index',
                                        ImageUtils.getFullImageUrl(
                                          ev['storagePath'],
                                        ),
                                        ev['fileExtension'] ?? '',
                                        studentName,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        _buildEvidenceSummaryCard(
                          images.length,
                          videos.length,
                          audios.length,
                          docs.length,
                        ),
                        const SizedBox(height: 24),
                        _buildSubmissionInfoCard(submittedDateStr, accuracy),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── FLOATING SCROLL DOWN BUTTON ─────────────────────────────────
            Positioned(
              bottom: 40,
              right: 40,
              child: FloatingActionButton(
                backgroundColor: _C.green,
                elevation: 8,
                shape: const CircleBorder(),
                onPressed: _scrollToBottom,
                child: const Icon(
                  PhosphorIconsRegular.caretDown,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── MEDIA WIDGET BUILDERS ─────────────────────────────────────────────

  Widget _buildImageCard(
    BuildContext context,
    String title,
    String time,
    String accuracy,
    String url,
  ) {
    return GestureDetector(
      onTap: () => _showTheaterMode(context, url, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_C.innerCardRadius),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_C.innerCardRadius),
                ),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: _C.border,
                    child: const Icon(
                      PhosphorIconsRegular.image,
                      color: _C.textFaint,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          time,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: _C.textFaint,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        accuracy,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _C.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(
    BuildContext context,
    String title,
    String time,
    String duration,
    String url,
  ) {
    return GestureDetector(
      onTap: () => _showVideoPlayer(context, url, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_C.innerCardRadius),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_C.innerCardRadius),
                    ),
                    child: Container(
                      color: Colors.black12,
                      child: const Center(
                        child: Icon(
                          PhosphorIconsFill.videoCamera,
                          size: 48,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        PhosphorIconsFill.play,
                        color: _C.textDark,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: _C.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _C.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      duration,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _C.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceNoteCard(BuildContext context, String title, String url) {
    return GestureDetector(
      onTap: () => _showAudioPlayer(context, title, url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: _C.blueLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(_C.innerCardRadius),
          border: Border.all(color: _C.blue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsFill.microphoneStage,
                color: _C.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Audio File',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _C.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: _C.textFaint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tap to listen',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: _C.textFaint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: _C.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsFill.play,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RIGHT COLUMN META WIDGETS ─────────────────────────────────────────

  Widget _buildDocumentCard(
    String originalName,
    String url,
    String extension,
    String studentName,
  ) {
    IconData icon = PhosphorIconsFill.fileText;
    if (extension.toLowerCase().contains('pdf')) {
      icon = PhosphorIconsFill.filePdf;
    } else if (extension.toLowerCase().contains('doc') ||
        extension.toLowerCase().contains('word')) {
      icon = PhosphorIconsFill.fileDoc;
    } else if (extension.toLowerCase().contains('xls') ||
        extension.toLowerCase().contains('sheet')) {
      icon = PhosphorIconsFill.fileXls;
    } else if (extension.toLowerCase().contains('ppt') ||
        extension.toLowerCase().contains('presentation')) {
      icon = PhosphorIconsFill.filePpt;
    } else if (extension.toLowerCase().contains('zip') ||
        extension.toLowerCase().contains('rar') ||
        extension.toLowerCase().contains('tar')) {
      icon = PhosphorIconsFill.fileZip;
    }

    final displayName = '${studentName.replaceAll(' ', '_')}_$originalName';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _C.orangeLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(_C.innerCardRadius),
        border: Border.all(color: _C.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _C.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to open ${extension.isNotEmpty ? extension.toUpperCase() : "Document"}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: _C.textFaint,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              if (url.isNotEmpty) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            icon: const Icon(
              PhosphorIconsRegular.arrowSquareOut,
              color: _C.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSummaryCard(
    int numImages,
    int numVideos,
    int numAudios,
    int numDocs,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evidence Summary',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(PhosphorIconsRegular.image, 'Images', '$numImages'),
          const SizedBox(height: 12),
          _buildSummaryRow(
            PhosphorIconsRegular.videoCamera,
            'Videos',
            '$numVideos',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            PhosphorIconsRegular.microphone,
            'Voice Notes',
            '$numAudios',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            PhosphorIconsRegular.fileText,
            'Documents',
            '$numDocs',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _C.textFaint),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: _C.textBody,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _C.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionInfoCard(String date, String accuracy) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_C.cardRadius),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submission Info',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            'Submitted',
            Text(
              date,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'GPS Accuracy',
            Text(
              accuracy,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.green,
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_C.cardRadius),
                ),
              ),
              child: const Text(
                'Download Evidence',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget trailingWidget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: _C.textFaint,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailingWidget,
      ],
    );
  }

  // ── MODALS (THEATER MODE, VIDEO PLAYER, AUDIO PLAYER) ────────────────

  void _showTheaterMode(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      PhosphorIconsRegular.x,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, String url, String title) {
    debugPrint('SupervisorEvidence: opening video player with URL: $url');

    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No video URL available')));
      return;
    }

    Future<VideoPlayerController> initializeController() async {
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'jwt_token');

      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: headers,
      );
      await controller.initialize();
      controller.setLooping(false);
      return controller;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return FutureBuilder<VideoPlayerController>(
                future: initializeController(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    if (snapshot.hasError) {
                      return SizedBox(
                        height: 320,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                PhosphorIconsRegular.warning,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Unable to load video.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _C.green,
                                  ),
                                  child: const Text('Close'),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    return const SizedBox(
                      height: 320,
                      child: Center(
                        child: CircularProgressIndicator(color: _C.green),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 600,
                            maxWidth: 800,
                          ),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: snapshot.data!.value.aspectRatio,
                              child: VideoPlayer(snapshot.data!),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 24,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                PhosphorIconsRegular.x,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                snapshot.data?.dispose();
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          children: [
                            VideoProgressIndicator(
                              snapshot.data!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: _C.green,
                                bufferedColor: Colors.white30,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      snapshot.data!.value.isPlaying
                                          ? snapshot.data!.pause()
                                          : snapshot.data!.play();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _C.green,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _C.green.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      snapshot.data!.value.isPlaying
                                          ? PhosphorIconsFill.pause
                                          : PhosphorIconsFill.play,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showAudioPlayer(BuildContext context, String title, String url) {
    final player = AudioPlayer();
    bool isPlaying = false;
    Duration position = Duration.zero;
    Duration total = Duration.zero;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Wire up listeners
          player.onPositionChanged.listen((pos) {
            setDialogState(() => position = pos);
          });
          player.onDurationChanged.listen((dur) {
            setDialogState(() => total = dur);
          });
          player.onPlayerComplete.listen((_) {
            setDialogState(() {
              isPlaying = false;
              position = Duration.zero;
            });
          });

          String _fmt(Duration d) {
            final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
            final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
            return '$m:$s';
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      player.dispose();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.x,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 400,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(_C.cardRadius),
                    border: Border.all(color: Colors.white24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        PhosphorIconsFill.microphoneStage,
                        color: _C.blue,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Voice Note',
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Text(
                            _fmt(position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16,
                                ),
                                activeTrackColor: _C.blue,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                overlayColor: _C.blue.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: total.inMilliseconds > 0
                                    ? position.inMilliseconds /
                                          total.inMilliseconds
                                    : 0.0,
                                onChanged: (v) async {
                                  final seek = Duration(
                                    milliseconds: (v * total.inMilliseconds)
                                        .round(),
                                  );
                                  await player.seek(seek);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _fmt(total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () async => await player.seek(
                              Duration(
                                seconds: (position.inSeconds - 10).clamp(
                                  0,
                                  total.inSeconds,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white12,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                PhosphorIconsFill.rewindCircle,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () async {
                              if (isPlaying) {
                                await player.pause();
                                setDialogState(() => isPlaying = false);
                              } else {
                                if (url.isNotEmpty) {
                                  await player.play(UrlSource(url));
                                }
                                setDialogState(() => isPlaying = true);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: _C.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying
                                    ? PhosphorIconsFill.pause
                                    : PhosphorIconsFill.play,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () async => await player.seek(
                              Duration(
                                seconds: (position.inSeconds + 10).clamp(
                                  0,
                                  total.inSeconds,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white12,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                PhosphorIconsFill.fastForwardCircle,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) => player.dispose());
  }
}
