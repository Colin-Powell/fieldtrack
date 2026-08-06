import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import 'package:fieldtrack/core/providers/location_provider.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';
import 'package:fieldtrack/core/providers/activity_provider.dart';

class FieldSessionScreen extends ConsumerStatefulWidget {
  final bool isDraft; // Pass true if loading a saved draft
  final String? activityId;

  const FieldSessionScreen({super.key, this.isDraft = false, this.activityId});

  @override
  ConsumerState<FieldSessionScreen> createState() => _FieldSessionScreenState();
}

enum LogStep { general, evidence, review, success, error }

enum EvidenceType { photo, video, voice, document }

class _EvidenceItem {
  final EvidenceType type;
  final String path;
  final String name;
  final Duration? duration;

  _EvidenceItem({
    required this.type,
    required this.path,
    required this.name,
    this.duration,
  });
}

class _FieldSessionScreenState extends ConsumerState<FieldSessionScreen> {
  LogStep _currentStep = LogStep.general;
  bool _isLoading = false;
  bool _forceErrorOnce = true;
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _methodController = TextEditingController();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<_EvidenceItem> _evidenceItems = [];
  String? _playingVoicePath;
  Duration _voicePosition = Duration.zero;
  Duration _voiceDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    if (widget.isDraft) {
      _titleController.text = 'Mangrove Vegetation Survey';
      _descController.text =
          'Observed healthy growth of Rhicophors mucronate...';
      _methodController.text = 'Transect and Quadrant Method';
    }

    if (widget.activityId != null) {
      _loadActivityDetails();
    }

    // Location is now handled by the shared locationProvider (Riverpod)
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingVoicePath = null;
          _voicePosition = Duration.zero;
          _voiceDuration = Duration.zero;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && _playingVoicePath != null) {
        setState(() => _voicePosition = position);
      }
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _voiceDuration = duration);
      }
    });
  }

  Future<void> _loadActivityDetails() async {
    setState(() => _isLoading = true);
    final activityService = ref.read(activityServiceProvider);
    final result = await activityService.getActivityById(widget.activityId!);
    if (result is Success) {
      final activity = (result as Success).data;
      if (mounted) {
        setState(() {
          _titleController.text = activity['title'] ?? '';
          _descController.text = activity['description'] ?? '';
          _methodController.text = activity['methodology'] ?? '';
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _methodController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Location capture is now handled by the shared locationProvider (Riverpod).
  // All screens read from the same provider — no duplicated GPS logic.

  void _nextStep() {
    if (_currentStep == LogStep.general) {
      if (_titleController.text.trim().isEmpty ||
          _descController.text.trim().isEmpty ||
          _methodController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please fill out all fields before proceeding.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFFEF4444), // Red
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          ),
        );
        return;
      }
    }

    setState(() {
      if (_currentStep == LogStep.general) {
        _currentStep = LogStep.evidence;
      } else if (_currentStep == LogStep.evidence) {
        _currentStep = LogStep.review;
      }
    });
  }

  Future<void> _playVoiceNote(_EvidenceItem item) async {
    if (_playingVoicePath == item.path) {
      await _audioPlayer.pause();
      setState(() {
        _playingVoicePath = null;
      });
      return;
    }

    await _audioPlayer.stop();
    final file = File(item.path);
    if (!file.existsSync()) {
      return;
    }

    setState(() {
      _playingVoicePath = item.path;
      _voicePosition = Duration.zero;
      _voiceDuration = Duration.zero;
    });

    await _audioPlayer.setSource(DeviceFileSource(item.path));
    await _audioPlayer.resume();
  }

  Future<void> _stopVoiceNote() async {
    await _audioPlayer.stop();
    setState(() {
      _playingVoicePath = null;
      _voicePosition = Duration.zero;
      _voiceDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _importAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        final audioFile = File(file.path!);
        _addEvidenceItem(
          _EvidenceItem(
            type: EvidenceType.voice,
            path: audioFile.path,
            name: file.name,
          ),
        );
      }
    }
  }

  void _prevStep() {
    setState(() {
      if (_currentStep == LogStep.evidence) {
        _currentStep = LogStep.general;
      } else if (_currentStep == LogStep.review) {
        _currentStep = LogStep.evidence;
      } else if (_currentStep == LogStep.error) {
        _currentStep = LogStep.review;
      }
    });
  }

  // --- EVIDENCE ACTIONS ---

  void _addEvidenceItem(_EvidenceItem item) {
    setState(() {
      _evidenceItems.add(item);
    });
  }

  void _removeEvidenceItem(_EvidenceItem item) {
    setState(() {
      if (_playingVoicePath == item.path) _playingVoicePath = null;
      _evidenceItems.remove(item);
    });
  }

  Future<void> _captureMedia() async {
    final picker = ImagePicker();
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Capture Media',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: const Icon(
                  PhosphorIconsFill.camera,
                  color: Color(0xFF1BA654),
                ),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                    maxWidth: 1920,
                    maxHeight: 1920,
                  );
                  if (picked != null) {
                    _addEvidenceItem(
                      _EvidenceItem(
                        type: EvidenceType.photo,
                        path: picked.path,
                        name: picked.name,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  PhosphorIconsFill.videoCamera,
                  color: Color(0xFF1BA654),
                ),
                title: const Text('Record Video'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickVideo(
                    source: ImageSource.camera,
                    maxDuration: const Duration(seconds: 30),
                  );
                  if (picked != null) {
                    _addEvidenceItem(
                      _EvidenceItem(
                        type: EvidenceType.video,
                        path: picked.path,
                        name: picked.name,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  PhosphorIconsFill.image,
                  color: Color(0xFF1BA654),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 1920,
                    maxHeight: 1920,
                  );
                  if (picked != null) {
                    _addEvidenceItem(
                      _EvidenceItem(
                        type: EvidenceType.photo,
                        path: picked.path,
                        name: picked.name,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recordVoiceNote() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Microphone permission is required to record voice notes.')),
      );
      return;
    }

    String? recordPath;
    bool isRecording = await _audioRecorder.isRecording();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final sheetContext = context;
            return Container(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Voice Note', style: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                    const SizedBox(height: 8),
                    const Text('Capture environmental sounds or field observations', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Color(0xFF6B7280))),
                    const SizedBox(height: 32),
                    
                    // Recording Indicator / Button
                    GestureDetector(
                      onTap: () async {
                        if (!isRecording) {
                          final directory = await getTemporaryDirectory();
                          final outputPath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
                          recordPath = outputPath;
                          await _audioRecorder.start(
                            const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100, numChannels: 1),
                            path: outputPath,
                          );
                          setModalState(() => isRecording = true);
                        } else {
                          await _audioRecorder.stop();
                          setModalState(() => isRecording = false);
                          if (recordPath != null) {
                            _addEvidenceItem(_EvidenceItem(type: EvidenceType.voice, path: recordPath!, name: 'Voice Note ${DateTime.now().toIso8601String()}.m4a'));
                          }
                          if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isRecording ? const Color(0xFFFEE2E2) : const Color(0xFFE6F5EC),
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isRecording)
                              BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 10),
                          ],
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isRecording ? 60 : 80,
                            height: isRecording ? 60 : 80,
                            decoration: BoxDecoration(
                              color: isRecording ? const Color(0xFFEF4444) : const Color(0xFF1BA654),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isRecording ? PhosphorIconsFill.stop : PhosphorIconsFill.microphone, color: Colors.white, size: 36),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isRecording ? 'Recording in progress...' : 'Tap to start recording',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isRecording ? const Color(0xFFEF4444) : const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Import Audio button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(PhosphorIconsRegular.folder, color: Color(0xFF6B7280)),
                        label: const Text('Import from storage', style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          if (isRecording) await _audioRecorder.stop();
                          if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
                          await _importAudioFile();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          if (isRecording) await _audioRecorder.stop();
                          if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
                        },
                        child: const Text('Cancel', style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() async {
      // Ensure we stop recording if modal is dismissed abruptly
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    });
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        _addEvidenceItem(
          _EvidenceItem(
            type: EvidenceType.document,
            path: file.path!,
            name: file.name,
          ),
        );
      }
    }
  }

  Future<void> _submitActivity() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).user;
      final locationState = ref.read(locationProvider);
      
      if (user == null) {
        throw Exception('User data is missing');
      }

      final activityService = ref.read(activityServiceProvider);
      String activityId;

      if (widget.activityId != null) {
        // Update existing activity
        final updateRes = await activityService.updateActivity(
          activityId: widget.activityId!,
          studentId: user.id,
          title: _titleController.text,
          description: _descController.text,
          methodology: _methodController.text,
        );
        if (updateRes is Failure) throw Exception((updateRes as Failure).message);
        activityId = widget.activityId!;
      } else {
        // 1. Create Draft Activity
        final draftRes = await activityService.createDraftActivity(
          studentId: user.id,
          title: _titleController.text,
          description: _descController.text,
          methodology: _methodController.text,
          latitude: locationState.latitude,
          longitude: locationState.longitude,
          gpsAccuracy: locationState.accuracy,
        );

        if (draftRes is Failure) {
          throw Exception((draftRes as Failure).message);
        }
        final draftData = (draftRes as Success).data;
        activityId = draftData['id'];
      }

      // 2. Upload Evidence (Ideally only upload new ones, but for now we upload all items that are new)
      for (final item in _evidenceItems) {
        await activityService.uploadEvidence(
          activityId: activityId,
          uploaderId: user.id,
          filePath: item.path,
          latitude: locationState.latitude,
          longitude: locationState.longitude,
          gpsAccuracy: locationState.accuracy,
          evidenceType: item.type.name,
        );
      }

      // 3. Submit Activity
      await activityService.submitActivity(
        activityId: activityId,
        studentId: user.id,
      );

      // Invalidate the cache so the activities list refreshes when the user returns
      ref.invalidate(studentActivitiesProvider);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = LogStep.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = LogStep.error;
        });
      }
    }
  }

  Future<void> _saveDraft() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).user;
      final locationState = ref.read(locationProvider);
      
      if (user == null) {
        throw Exception('User data is missing');
      }

      final activityService = ref.read(activityServiceProvider);
      String activityId;

      if (widget.activityId != null) {
        final updateRes = await activityService.updateActivity(
          activityId: widget.activityId!,
          studentId: user.id,
          title: _titleController.text,
          description: _descController.text,
          methodology: _methodController.text,
        );
        if (updateRes is Failure) throw Exception((updateRes as Failure).message);
        activityId = widget.activityId!;
      } else {
        final draftRes = await activityService.createDraftActivity(
          studentId: user.id,
          title: _titleController.text,
          description: _descController.text,
          methodology: _methodController.text,
          latitude: locationState.latitude,
          longitude: locationState.longitude,
          gpsAccuracy: locationState.accuracy,
        );
        if (draftRes is Failure) throw Exception((draftRes as Failure).message);
        final draftData = (draftRes as Success).data;
        activityId = draftData['id'];
      }

      for (final item in _evidenceItems) {
        await activityService.uploadEvidence(
          activityId: activityId,
          uploaderId: user.id,
          filePath: item.path,
          latitude: locationState.latitude,
          longitude: locationState.longitude,
          gpsAccuracy: locationState.accuracy,
          evidenceType: item.type.name,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity saved as draft.'),
            backgroundColor: Color(0xFF1BA654),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save draft: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_currentStep == LogStep.general ||
                _currentStep == LogStep.evidence ||
                _currentStep == LogStep.review)
              _buildStepper(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: _buildCurrentContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentContent() {
    switch (_currentStep) {
      case LogStep.general:
        return _buildStep1General();
      case LogStep.evidence:
        return _buildStep2Evidence();
      case LogStep.review:
        return _buildStep3Review();
      case LogStep.success:
        return _buildStep4Success();
      case LogStep.error:
        return _buildStep5Error();
    }
  }

  // --- TOP NAVIGATION ---
  Widget _buildTopBar() {
    String title = '';
    switch (_currentStep) {
      case LogStep.general:
        title = 'General Information';
        break;
      case LogStep.evidence:
        title = 'Add Evidence';
        break;
      case LogStep.review:
        title = 'Review & Submit';
        break;
      case LogStep.success:
        title = 'Success';
        break;
      case LogStep.error:
        title = 'Submission Failed';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_currentStep != LogStep.success)
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: _currentStep == LogStep.general
                    ? () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go('/portal');
                        }
                      }
                    : _prevStep,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFCBE5D2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.caretLeft,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _currentStep == LogStep.error
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFCBE5D2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _currentStep == LogStep.error
                    ? const Color(0xFFEF4444)
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          _buildStepCircle(
            1,
            isActive: _currentStep.index >= LogStep.general.index,
          ),
          Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
          _buildStepCircle(
            2,
            isActive: _currentStep.index >= LogStep.evidence.index,
          ),
          Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
          _buildStepCircle(
            3,
            isActive: _currentStep.index >= LogStep.review.index,
          ),
          Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
          _buildStepCircle(4, isActive: _currentStep == LogStep.success),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNumber, {required bool isActive}) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1BA654) : const Color(0xFFCBE5D2),
        shape: BoxShape.circle,
      ),
      child: Text(
        stepNumber.toString(),
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.white : const Color(0xFF737373),
        ),
      ),
    );
  }

  // --- STEP 1: GENERAL INFORMATION ---
  Widget _buildStep1General() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Activity Title',
          hint: 'e.g., Mangrove Vegetation Survey',
          controller: _titleController,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        _buildInputField(
          label: 'Description/Observations',
          hint: 'e.g., Observed healthy growth of Rhicophors mucronate...',
          controller: _descController,
          maxLines: 6,
        ),
        const SizedBox(height: 24),
        _buildInputField(
          label: 'Method Used',
          hint: 'e.g., Transect and Quadrant Method',
          controller: _methodController,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        _buildLocationSection(),
        const SizedBox(height: 32),
        _buildPrimaryButton(label: 'Next', onPressed: _nextStep),
      ],
    );
  }

  /// Location label + live FlutterMap preview (or skeleton while acquiring GPS).
  Widget _buildLocationSection() {
    final locState = ref.watch(locationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location (Auto Captured)',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          locState.isLocating ? 'Locating...' : locState.locationName,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        locState.isLocating ? _buildMapSkeleton() : _buildLiveMap(locState),
      ],
    );
  }

  /// Real interactive map showing the user's GPS position.
  Widget _buildLiveMap(LocationState locState) {
    final userLatLng = LatLng(locState.latitude, locState.longitude);

    return GestureDetector(
      onTap: () => ref.read(locationProvider.notifier).refresh(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: userLatLng,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // static preview
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fieldtrack.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLatLng,
                        width: 40,
                        height: 40,
                        child: _buildUserDot(),
                      ),
                    ],
                  ),
                ],
              ),
              // "GPS locked in" overlay badge
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1BA654),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.gps_fixed,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${locState.latitude.toStringAsFixed(4)}, ${locState.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  /// Blue dot marker for user's live position.
  Widget _buildUserDot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3B82F6).withOpacity(0.15),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3B82F6),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.35),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSkeleton() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1BA654)),
          SizedBox(height: 16),
          Text(
            'Acquiring GPS Location...',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          minLines: maxLines,
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFF1BA654),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: ADD EVIDENCE (FIGMA ACCURATE) ---
  Widget _buildStep2Evidence() {
    final photos = _evidenceItems
        .where(
          (e) => e.type == EvidenceType.photo || e.type == EvidenceType.video,
        )
        .toList();
    final documents = _evidenceItems
        .where((e) => e.type == EvidenceType.document)
        .toList();
    final voices = _evidenceItems
        .where((e) => e.type == EvidenceType.voice)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PHOTOS & VIDEOS SECTION
        const Text(
          'Photos',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ...photos.map(_buildMediaThumb),
            // The "Camera Add" button to match Figma
            GestureDetector(
              onTap: _captureMedia,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                  child: Icon(
                    PhosphorIconsRegular.camera,
                    color: Color(0xFF9CA3AF),
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // DOCUMENTS SECTION
        const Text(
          'Documents',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...documents.map(_buildDocumentPill),
        if (documents.isEmpty)
          _buildAddEmptyButton(
            'Add Document',
            PhosphorIconsRegular.fileArrowUp,
            _uploadDocument,
          ),

        const SizedBox(height: 32),

        // VOICE NOTES SECTION
        const Text(
          'Voice Note',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (voices.isNotEmpty) ...[
          ...voices.map(_buildVoicePill),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                text: 'Record Voice Note',
                icon: PhosphorIconsRegular.microphone,
                onTap: _recordVoiceNote,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                text: 'Import Audio',
                icon: PhosphorIconsRegular.folder,
                onTap: _importAudioFile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPrimaryButton(label: 'Next', onPressed: _nextStep),
      ],
    );
  }

  // Reusable button for empty sections
  Widget _buildAddEmptyButton(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F9F5),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFCBE5D2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1BA654), size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1BA654),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F9F5),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFCBE5D2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1BA654), size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1BA654),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Media Thumbnail in the Wrap (matches Figma rounded squares + 'X' button to cancel)
  Widget _buildMediaThumb(_EvidenceItem item) {
    final isVideo = item.type == EvidenceType.video;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(
              image: FileImage(File(item.path)),
              fit: BoxFit.cover,
            ),
          ),
          child: isVideo
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(
                      PhosphorIconsFill.playCircle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                )
              : null,
        ),
        // Overlay Cancel button
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeEvidenceItem(item),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsBold.x,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Document Pill exactly from Figma
  Widget _buildDocumentPill(_EvidenceItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFCBE5D2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsFill.fileText,
              color: Color(0xFF1BA654),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '1.2 MB', // Hardcoded mock to match Figma look, you can derive actual size using File(item.path).lengthSync() if needed
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              PhosphorIconsRegular.x,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () => _removeEvidenceItem(item),
          ),
        ],
      ),
    );
  }

  // Voice Note Pill exactly from Figma + play toggle capabilities
  Widget _buildVoicePill(_EvidenceItem item) {
    final isPlaying = _playingVoicePath == item.path;
    final duration = _voiceDuration.inMilliseconds > 0
        ? _voiceDuration
        : const Duration(seconds: 1);
    final position = isPlaying ? _voicePosition : Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFCBE5D2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.speakerHigh,
                  color: Color(0xFF1BA654),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _playVoiceNote(item),
                child: Icon(
                  isPlaying
                      ? PhosphorIconsFill.pauseCircle
                      : PhosphorIconsRegular.playCircle,
                  color: const Color(0xFF1BA654),
                  size: 36,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (_playingVoicePath == item.path) {
                    _stopVoiceNote();
                  }
                  _removeEvidenceItem(item);
                },
                child: const Icon(
                  PhosphorIconsRegular.x,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              Container(
                height: 24,
                width: progress.isNaN
                    ? 0
                    : progress.clamp(0.0, 1.0) *
                          MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1BA654), Color(0xFF8BD9A1)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackShape: const RectangularSliderTrackShape(),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  thumbColor: const Color(0xFF1BA654),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: duration.inMilliseconds > 0
                      ? (value) async {
                          final newPosition = Duration(
                            milliseconds: (duration.inMilliseconds * value)
                                .round(),
                          );
                          await _audioPlayer.seek(newPosition);
                          setState(() => _voicePosition = newPosition);
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 3: REVIEW & SUBMIT ---
  Widget _buildStep3Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        _buildSummaryItem(
          'Activity Title',
          _titleController.text.isNotEmpty
              ? _titleController.text
              : 'No Title Provided',
        ),
        _buildSummaryItem('Date & Time', '23 Jul 2026 • 02:52 PM'),
        _buildSummaryItem('Location', ref.read(locationProvider).locationName),
        _buildSummaryItem(
          'Description',
          _descController.text.isNotEmpty
              ? _descController.text
              : 'No description provided.',
        ),
        _buildSummaryItem('Attachments', _buildAttachmentSummary()),
        const SizedBox(height: 48),

        _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1BA654)),
              )
            : _buildPrimaryButton(
                label: 'Submit Activity',
                onPressed: _submitActivity,
              ),

        const SizedBox(height: 16),

        if (!_isLoading)
          InkWell(
            onTap: _saveDraft,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFF1BA654), width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'Save Draft',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1BA654),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _buildAttachmentSummary() {
    final photoCount = _evidenceItems
        .where((item) => item.type == EvidenceType.photo)
        .length;
    final videoCount = _evidenceItems
        .where((item) => item.type == EvidenceType.video)
        .length;
    final voiceCount = _evidenceItems
        .where((item) => item.type == EvidenceType.voice)
        .length;
    final documentCount = _evidenceItems
        .where((item) => item.type == EvidenceType.document)
        .length;

    final entries = <String>[];
    if (photoCount > 0) {
      entries.add('$photoCount photo${photoCount > 1 ? 's' : ''}');
    }
    if (videoCount > 0) {
      entries.add('$videoCount video${videoCount > 1 ? 's' : ''}');
    }
    if (voiceCount > 0) {
      entries.add('$voiceCount voice note${voiceCount > 1 ? 's' : ''}');
    }
    if (documentCount > 0) {
      entries.add('$documentCount document${documentCount > 1 ? 's' : ''}');
    }

    return entries.isNotEmpty ? entries.join(', ') : 'No attachments added.';
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 4: SUCCESS ---
  Widget _buildStep4Success() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Provided SVG Asset
        SvgPicture.asset('lib/assets/Images/submit.svg', height: 180),

        const SizedBox(height: 32),
        const Text(
          'Activity Submitted!',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Great Job! Your activity has been\nsubmitted successfully.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              const Text(
                'Submission ID',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'FT-2026-07-23-00123',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Color(0xFFE5E7EB), height: 1),
              ),
              const Text(
                'Submitted At',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '23 Jul 2026 • 02:52 PM',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          label: 'View Activities',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // --- STEP 5: ERROR ---
  Widget _buildStep5Error() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        SizedBox(
          height: 180,
          width: 200,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 20,
                child: Container(
                  width: 160,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsFill.warning,
                    size: 80,
                    color: Color(0xFFFCA5A5),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsBold.x,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Submission Failed!',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Oops! Something went wrong while submitting.\nPlease check your connection and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 48),
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFEF4444)),
              )
            : InkWell(
                onTap: _submitActivity,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Text(
                      'Retry Submission',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 16),
        if (!_isLoading)
          TextButton(
            onPressed: _prevStep,
            child: const Text(
              'Go Back',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF737373),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1BA654),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

