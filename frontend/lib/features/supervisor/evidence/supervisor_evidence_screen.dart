import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  static const innerCardRadius = 24.0; // Scaled down for tiny cards to prevent circle-clipping
}

class SupervisorEvidenceScreen extends StatefulWidget {
  final String studentId;
  final String activityId;
  
  const SupervisorEvidenceScreen({super.key, required this.studentId, required this.activityId});

  @override
  State<SupervisorEvidenceScreen> createState() => _SupervisorEvidenceScreenState();
}

class _SupervisorEvidenceScreenState extends State<SupervisorEvidenceScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
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
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text('Images (6)', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: _C.textDark)),
                      ),
                      const SizedBox(height: 16),
                      
                      // 6 Images per row layout
                      GridView.count(
                        crossAxisCount: 6,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Disables inner scrolling
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75, // Keeps vertical space for text
                        children: [
                          _buildImageCard(context, 'Mangrove_01.jpg', '08:15 AM', '4.2m', 'https://images.unsplash.com/photo-1627914041132-720da5d7df53?auto=format&fit=crop&w=300&q=80'),
                          _buildImageCard(context, 'Mangrove_02.jpg', '08:18 AM', '3.2m', 'https://images.unsplash.com/photo-1544257124-741165bc6f23?auto=format&fit=crop&w=300&q=80'),
                          _buildImageCard(context, 'Mangrove_03.jpg', '08:22 AM', '3.1m', 'https://images.unsplash.com/photo-1590680608249-144a2df72186?auto=format&fit=crop&w=300&q=80'),
                          _buildImageCard(context, 'Mangrove_04.jpg', '08:35 AM', '4.1m', 'https://images.unsplash.com/photo-1616423640778-28d1b53229bd?auto=format&fit=crop&w=300&q=80'),
                          _buildImageCard(context, 'Mangrove_05.jpg', '08:42 AM', '4.3m', 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&w=300&q=80'),
                          _buildImageCard(context, 'Mangrove_06.jpg', '08:58 AM', '4.1m', 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=300&q=80'),
                        ],
                      ),
                      
                      const SizedBox(height: 32), 
                      
                      // --- VIDEOS ---
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text('Videos (1)', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: _C.textDark)),
                      ),
                      const SizedBox(height: 16),
                      
                      // Videos layout (3 per row)
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildVideoCard(context, 'Site_Overview.mp4', '09:00 AM', '02:14', 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=400&q=80'),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- VOICE NOTES ---
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text('Voice Notes (1)', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: _C.textDark)),
                      ),
                      const SizedBox(height: 16),
                      _buildVoiceNoteCard(context),
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
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_C.cardRadius),
                        border: Border.all(color: _C.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text('Documents (1)', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: _C.textDark)),
                          ),
                          const SizedBox(height: 16),
                          _buildDocumentCard(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    _buildEvidenceSummaryCard(),
                    
                    const SizedBox(height: 24),
                    _buildSubmissionInfoCard(),
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
            child: const Icon(PhosphorIconsRegular.caretDown, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  // ── MEDIA WIDGET BUILDERS ─────────────────────────────────────────────

  Widget _buildImageCard(BuildContext context, String title, String time, String accuracy, String url) {
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(_C.innerCardRadius)),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: _C.border, child: const Icon(PhosphorIconsRegular.image, color: _C.textFaint)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: _C.textDark), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: _C.textFaint)),
                      Text(accuracy, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w600, color: _C.green)),
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

  Widget _buildVideoCard(BuildContext context, String title, String time, String duration, String url) {
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(_C.innerCardRadius)),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(_C.innerCardRadius)),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(PhosphorIconsFill.play, color: Colors.white, size: 24),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                      child: Text(duration, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _C.textDark), overflow: TextOverflow.ellipsis),
                  ),
                  Text(time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _C.textFaint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceNoteCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAudioPlayer(context, 'Field_Observation_Audio.mp3'),
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
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(PhosphorIconsFill.microphoneStage, color: _C.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Field_Observation_Audio.mp3', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: _C.textDark)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('03:45 mins', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: _C.blue)),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: _C.textFaint, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('2.4 MB', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _C.textFaint)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: _C.blue, shape: BoxShape.circle),
              child: const Icon(PhosphorIconsFill.play, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ── RIGHT COLUMN META WIDGETS ─────────────────────────────────────────

  Widget _buildDocumentCard() {
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
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(PhosphorIconsFill.filePdf, color: _C.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Survey_data.pdf', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _C.textDark), overflow: TextOverflow.ellipsis),
                SizedBox(height: 2),
                Text('1.2 MB', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _C.textFaint)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(PhosphorIconsRegular.downloadSimple, color: _C.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSummaryCard() {
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
          const Text('Evidence Summary', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: _C.textDark)),
          const SizedBox(height: 20),
          _buildSummaryRow(PhosphorIconsRegular.image, 'Images', '6'),
          const SizedBox(height: 12),
          _buildSummaryRow(PhosphorIconsRegular.videoCamera, 'Videos', '1'),
          const SizedBox(height: 12),
          _buildSummaryRow(PhosphorIconsRegular.microphone, 'Voice Notes', '1'),
          const SizedBox(height: 12),
          _buildSummaryRow(PhosphorIconsRegular.fileText, 'Documents', '1'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _C.textFaint),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.textBody, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: _C.textDark)),
      ],
    );
  }

  Widget _buildSubmissionInfoCard() {
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
          const Text('Submission Info', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: _C.textDark)),
          const SizedBox(height: 20),
          _buildInfoRow('Submitted', const Text('21 Jul 2026', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: _C.textDark))),
          const SizedBox(height: 16),
          _buildInfoRow('GPS Accuracy', const Text('4.2 M', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: _C.green))),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_C.cardRadius)),
              ),
              child: const Text('Download Evidence', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
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
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _C.textFaint, fontWeight: FontWeight.w500)),
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
                  Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, color: Colors.white, size: 32),
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
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Mock Video Frame
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
            Container(decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(24))),
            
            // Big Play Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(PhosphorIconsFill.play, color: Colors.white, size: 64),
            ),

            // Top Bar
            Positioned(
              top: 16, left: 24, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            // Bottom Controls Bar
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Row(
                children: [
                  const Icon(PhosphorIconsFill.pause, color: Colors.white, size: 24),
                  const SizedBox(width: 16),
                  const Text('00:45', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 0.35,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(_C.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('02:14', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12)),
                  const SizedBox(width: 16),
                  const Icon(PhosphorIconsRegular.cornersOut, color: Colors.white, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioPlayer(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent, // Floating translucent UI
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Floating Close Button (Top Right)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                  child: const Icon(PhosphorIconsRegular.x, color: Colors.white, size: 24),
                ),
              ),
            ),

            // Floating Audio Controls container
            Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(_C.cardRadius),
                border: Border.all(color: Colors.white24),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(PhosphorIconsFill.microphoneStage, color: _C.blue, size: 48),
                  const SizedBox(height: 16),
                  Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Voice Note', style: TextStyle(color: Colors.white54, fontFamily: 'Poppins', fontSize: 13)),
                  const SizedBox(height: 32),
                  
                  // Floating Progress Bar
                  Row(
                    children: [
                      const Text('01:20', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: 0.45,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(_C.blue),
                          borderRadius: BorderRadius.circular(8),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('03:45', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Floating Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                        child: const Icon(PhosphorIconsFill.rewindCircle, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(color: _C.blue, shape: BoxShape.circle),
                        child: const Icon(PhosphorIconsFill.pause, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                        child: const Icon(PhosphorIconsFill.fastForwardCircle, color: Colors.white, size: 32),
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
}
