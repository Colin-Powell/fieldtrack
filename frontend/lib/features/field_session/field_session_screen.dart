import 'dart:io';
import 'dart:async';

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
import 'package:fieldtrack/core/network/error_handler.dart';

class FieldSessionScreen extends ConsumerStatefulWidget {
  final bool isDraft; // Pass true if loading a saved draft
  final String? activityId;

  const FieldSessionScreen({super.key, this.isDraft = false, this.activityId});

  @override
  ConsumerState<FieldSessionScreen> createState() => _FieldSessionScreenState();
}

enum LogStep { general, evidence, review, success, error }

enum EvidenceType { photo, video, voice, document }

enum UploadStatus { pending, uploading, success, failed }

class _EvidenceItem {
  final EvidenceType type;
  final String path;
  final String name;
  UploadStatus uploadStatus = UploadStatus.pending;
  String? storageUrl;

  _EvidenceItem({required this.type, required this.path, required this.name});
}

class _FieldSessionScreenState extends ConsumerState<FieldSessionScreen> {
  LogStep _currentStep = LogStep.general;
  bool _isLoading = false;
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

  // New states for background uploads
  String? _draftActivityId;
  bool _isCreatingDraft = false;

  @override
  void initState() {
    super.initState();

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

  Future<String?> _ensureDraftActivity() async {
    if (_draftActivityId != null) return _draftActivityId;
    if (widget.activityId != null) {
      _draftActivityId = widget.activityId;
      return _draftActivityId;
    }
    if (_isCreatingDraft) {
      while (_isCreatingDraft) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      return _draftActivityId;
    }

    _isCreatingDraft = true;
    try {
      final user = ref.read(authProvider).user;
      final locationState = ref.read(locationProvider);
      if (user == null) return null;

      final title = _titleController.text.trim();
      if (title.isEmpty) return null;

      final activityService = ref.read(activityServiceProvider);
      final draftRes = await activityService.createDraftActivity(
        studentId: user.id,
        title: title,
        description: _descController.text,
        methodology: _methodController.text,
        latitude: locationState.latitude != 0 ? locationState.latitude : 0.0,
        longitude: locationState.longitude != 0 ? locationState.longitude : 0.0,
        gpsAccuracy: locationState.accuracy != 0 ? locationState.accuracy : 0.0,
      );

      if (draftRes is Success) {
        _draftActivityId = (draftRes as Success).data['id'];
      }
    } catch (e) {
      debugPrint('Failed to create draft: $e');
    } finally {
      _isCreatingDraft = false;
    }
    return _draftActivityId;
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
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFFEF4444),
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
      item.uploadStatus = UploadStatus.uploading;
      _evidenceItems.add(item);
    });
    _uploadEvidenceInBackground(item);
  }

  Future<void> _uploadEvidenceInBackground(_EvidenceItem item) async {
    try {
      final user = ref.read(authProvider).user;
      final locationState = ref.read(locationProvider);
      if (user == null) {
        if (mounted) setState(() => item.uploadStatus = UploadStatus.failed);
        return;
      }

      final activityId = await _ensureDraftActivity();
      if (activityId == null) {
        if (mounted) setState(() => item.uploadStatus = UploadStatus.failed);
        return;
      }

      final activityService = ref.read(activityServiceProvider);
      final result = await activityService.uploadEvidence(
        activityId: activityId,
        uploaderId: user.id,
        filePath: item.path,
        latitude: locationState.latitude != 0 ? locationState.latitude : 0.0,
        longitude: locationState.longitude != 0 ? locationState.longitude : 0.0,
        gpsAccuracy: locationState.accuracy != 0 ? locationState.accuracy : 0.0,
        evidenceType: item.type.name,
      );

      if (mounted) {
        setState(() {
          if (result is Success) {
            item.uploadStatus = UploadStatus.success;
            item.storageUrl = (result as Success).data['storagePath'];
          } else {
            item.uploadStatus = UploadStatus.failed;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          item.uploadStatus = UploadStatus.failed;
        });
      }
    }
  }

  void _removeEvidenceItem(_EvidenceItem item) {
    setState(() {
      if (_playingVoicePath == item.path) _playingVoicePath = null;
      _evidenceItems.remove(item);
    });
  }

  Future<void> _captureMedia() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picker = ImagePicker();
    
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Capture Media',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)),
              ListTile(
                leading: Icon(
                  PhosphorIconsFill.camera,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
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
                leading: Icon(
                  PhosphorIconsFill.videoCamera,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
                ),
                title: Text(
                  'Record Video (Not Supported)',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Video recording is not currently supported.',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIconsFill.image,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
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
        const SnackBar(
          content: Text(
            'Microphone permission is required to record voice notes.',
          ),
        ),
      );
      return;
    }

    String? recordPath;
    bool isRecording = await _audioRecorder.isRecording();
    StreamSubscription<Amplitude>? amplitudeSub;
    double currentAmplitude = 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final sheetContext = context;
            return Container(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: 40,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Voice Note',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture environmental sounds or field observations',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Recording Indicator / Button
                    SizedBox(
                      height: 160,
                      width: 160,
                      child: Center(
                        child: GestureDetector(
                          onTap: () async {
                            if (!isRecording) {
                              final directory = await getTemporaryDirectory();
                              final outputPath =
                                  '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
                              recordPath = outputPath;
                              await _audioRecorder.start(
                                const RecordConfig(
                                  encoder: AudioEncoder.aacLc,
                                  bitRate: 128000,
                                  sampleRate: 44100,
                                  numChannels: 1,
                                ),
                                path: outputPath,
                              );
                              setModalState(() {
                                isRecording = true;
                                currentAmplitude = 0.0;
                              });
                              amplitudeSub = _audioRecorder
                                  .onAmplitudeChanged(
                                    const Duration(milliseconds: 100),
                                  )
                                  .listen((amp) {
                                    setModalState(() {
                                      double val = (amp.current + 50) / 50.0;
                                      if (val < 0) val = 0;
                                      if (val > 1) val = 1;
                                      currentAmplitude = val;
                                    });
                                  });
                            } else {
                              await amplitudeSub?.cancel();
                              await _audioRecorder.stop();
                              setModalState(() {
                                isRecording = false;
                                currentAmplitude = 0.0;
                              });
                              if (recordPath != null) {
                                _addEvidenceItem(
                                  _EvidenceItem(
                                    type: EvidenceType.voice,
                                    path: recordPath!,
                                    name:
                                        'Voice Note ${DateTime.now().toIso8601String()}.m4a',
                                  ),
                                );
                              }
                              if (Navigator.canPop(sheetContext)) {
                                Navigator.pop(sheetContext);
                              }
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: 120 + (currentAmplitude * 40),
                            height: 120 + (currentAmplitude * 40),
                            decoration: BoxDecoration(
                              color: isRecording
                                  ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
                                  : (isDark ? const Color(0xFF14532D) : const Color(0xFFE6F5EC)),
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (isRecording)
                                  BoxShadow(
                                    color: (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444))
                                        .withValues(alpha: 0.4),
                                    blurRadius: 30 + (currentAmplitude * 20),
                                    spreadRadius: 10 + (currentAmplitude * 10),
                                  ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isRecording ? 60 : 80,
                                height: isRecording ? 60 : 80,
                                decoration: BoxDecoration(
                                  color: isRecording
                                      ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444))
                                      : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isRecording
                                      ? PhosphorIconsFill.stop
                                      : PhosphorIconsFill.microphone,
                                  color: isDark && !isRecording ? const Color(0xFF121212) : Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isRecording
                          ? 'Recording in progress...'
                          : 'Tap to start recording',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isRecording
                            ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444))
                            : (isDark ? Colors.white : const Color(0xFF374151)),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Import Audio button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: Icon(
                          PhosphorIconsRegular.folder,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                        ),
                        label: Text(
                          'Import from storage',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF4B5563),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (isRecording) await _audioRecorder.stop();
                          if (Navigator.canPop(sheetContext)) {
                            Navigator.pop(sheetContext);
                          }
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
                          if (Navigator.canPop(sheetContext)) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
                          ),
                        ),
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
        if (updateRes is Failure) {
          throw Exception((updateRes as Failure).message);
        }
        activityId = widget.activityId!;
      } else if (_draftActivityId != null) {
        final updateRes = await activityService.updateActivity(
          activityId: _draftActivityId!,
          studentId: user.id,
          title: _titleController.text,
          description: _descController.text,
          methodology: _methodController.text,
        );
        if (updateRes is Failure) {
          throw Exception((updateRes as Failure).message);
        }
        activityId = _draftActivityId!;
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
        _draftActivityId = activityId;
      }

      // 2. Background uploads are already handling evidence!
      final isUploading = _evidenceItems.any(
        (e) => e.uploadStatus == UploadStatus.uploading,
      );
      if (isUploading) {
        // Wait for uploads to complete
        while (_evidenceItems.any(
          (e) => e.uploadStatus == UploadStatus.uploading,
        )) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      final hasFailedUploads = _evidenceItems.any(
        (e) => e.uploadStatus == UploadStatus.failed,
      );
      if (hasFailedUploads) {
        throw Exception(
          'Some evidence items failed to upload. Please remove them and try again.',
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
        if (updateRes is Failure) {
          throw Exception((updateRes as Failure).message);
        }
        activityId = widget.activityId!;
      } else if (_draftActivityId != null) {
        final updateRes = await activityService.updateActivity(
          activityId: _draftActivityId!,
          studentId: user.id,
          title: _titleController.text,
          description: _descController.text,
          methodology: _methodController.text,
        );
        if (updateRes is Failure) {
          throw Exception((updateRes as Failure).message);
        }
        activityId = _draftActivityId!;
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
        _draftActivityId = activityId;
      }

      while (_evidenceItems.any(
        (item) => item.uploadStatus == UploadStatus.uploading,
      )) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (_evidenceItems.any(
        (item) => item.uploadStatus == UploadStatus.failed,
      )) {
        throw Exception(
          'Some evidence items failed to upload. Please remove them and try again.',
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Activity saved as draft.'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF14532D)
                : const Color(0xFF1BA654),
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
            content: Text(
              'Failed to save draft: ${ErrorHandler.getFriendlyErrorMessage(e)}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme, isDark),
            if (_currentStep == LogStep.general ||
                _currentStep == LogStep.evidence ||
                _currentStep == LogStep.review)
              _buildStepper(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: _buildCurrentContent(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentContent(bool isDark) {
    switch (_currentStep) {
      case LogStep.general:
        return _buildStep1General(isDark);
      case LogStep.evidence:
        return _buildStep2Evidence(isDark);
      case LogStep.review:
        return _buildStep3Review(isDark);
      case LogStep.success:
        return _buildStep4Success(isDark);
      case LogStep.error:
        return _buildStep5Error(isDark);
    }
  }

  // --- TOP NAVIGATION ---
  Widget _buildTopBar(ThemeData theme, bool isDark) {
    final pillBg = isDark ? const Color(0xFF14532D) : const Color(0xFFCBE5D2);
    final pillTextColor = isDark ? const Color(0xFF4ADE80) : Colors.black;

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
                  decoration: BoxDecoration(
                    color: pillBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIconsRegular.caretLeft,
                    color: pillTextColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _currentStep == LogStep.error
                  ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
                  : pillBg,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _currentStep == LogStep.error
                    ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444))
                    : pillTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          _buildStepCircle(
            1,
            isActive: _currentStep.index >= LogStep.general.index,
            isDark: isDark,
          ),
          Expanded(child: Container(height: 1, color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB))),
          _buildStepCircle(
            2,
            isActive: _currentStep.index >= LogStep.evidence.index,
            isDark: isDark,
          ),
          Expanded(child: Container(height: 1, color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB))),
          _buildStepCircle(
            3,
            isActive: _currentStep.index >= LogStep.review.index,
            isDark: isDark,
          ),
          Expanded(child: Container(height: 1, color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB))),
          _buildStepCircle(
            4, 
            isActive: _currentStep == LogStep.success,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNumber, {required bool isActive, required bool isDark}) {
    final activeBg = isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654);
    final inactiveBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFCBE5D2);
    final activeText = isDark ? const Color(0xFF121212) : Colors.white;
    final inactiveText = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF737373);

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? activeBg : inactiveBg,
        shape: BoxShape.circle,
        border: !isActive && isDark ? Border.all(color: const Color(0xFF333333)) : null,
      ),
      child: Text(
        stepNumber.toString(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isActive ? activeText : inactiveText,
        ),
      ),
    );
  }

  // --- STEP 1: GENERAL INFORMATION ---
  Widget _buildStep1General(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Activity Title',
          hint: 'e.g., Mangrove Vegetation Survey',
          controller: _titleController,
          maxLines: 2,
          isDark: isDark,
        ),
        const SizedBox(height: 24),
        _buildInputField(
          label: 'Description/Observations',
          hint: 'e.g., Observed healthy growth of Rhicophors mucronate...',
          controller: _descController,
          maxLines: 6,
          isDark: isDark,
        ),
        const SizedBox(height: 24),
        _buildInputField(
          label: 'Method Used',
          hint: 'e.g., Transect and Quadrant Method',
          controller: _methodController,
          maxLines: 2,
          isDark: isDark,
        ),
        const SizedBox(height: 24),
        _buildLocationSection(isDark),
        const SizedBox(height: 32),
        _buildPrimaryButton(label: 'Next', onPressed: _nextStep, isDark: isDark),
      ],
    );
  }

  /// Location label + live FlutterMap preview (or skeleton while acquiring GPS).
  Widget _buildLocationSection(bool isDark) {
    final locState = ref.watch(locationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location (Auto Captured)',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          locState.isLocating ? 'Locating...' : locState.locationName,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        locState.isLocating ? _buildMapSkeleton(isDark) : _buildLiveMap(locState, isDark),
      ],
    );
  }

  /// Real interactive map showing the user's GPS position.
  Widget _buildLiveMap(LocationState locState, bool isDark) {
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
                    flags: InteractiveFlag.none,
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
                    color: isDark ? const Color(0xFF14532D) : const Color(0xFF1BA654),
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
                      Icon(
                        Icons.gps_fixed,
                        color: isDark ? const Color(0xFF4ADE80) : Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${locState.latitude.toStringAsFixed(4)}, ${locState.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF4ADE80) : Colors.white,
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

  Widget _buildMapSkeleton(bool isDark) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654)
          ),
          const SizedBox(height: 16),
          Text(
            'Acquiring GPS Location...',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
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
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          minLines: maxLines,
          maxLines: maxLines,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF)
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: ADD EVIDENCE (FIGMA ACCURATE) ---
  Widget _buildStep2Evidence(bool isDark) {
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
        Text(
          'Photos',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
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
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)
                  ),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIconsRegular.camera,
                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // DOCUMENTS SECTION
        Text(
          'Documents',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...documents.map((item) => _buildDocumentPill(item, isDark)),
        if (documents.isEmpty)
          _buildAddEmptyButton(
            'Add Document',
            PhosphorIconsRegular.fileArrowUp,
            _uploadDocument,
            isDark,
          ),

        const SizedBox(height: 32),

        // VOICE NOTES SECTION
        Text(
          'Voice Note',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (voices.isNotEmpty) ...[
          ...voices.map((item) => _buildVoicePill(item, isDark)),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                text: 'Record Voice Note',
                icon: PhosphorIconsRegular.microphone,
                onTap: _recordVoiceNote,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                text: 'Import Audio',
                icon: PhosphorIconsRegular.folder,
                onTap: _importAudioFile,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPrimaryButton(label: 'Next', onPressed: _nextStep, isDark: isDark),
      ],
    );
  }

  // Reusable button for empty sections
  Widget _buildAddEmptyButton(String text, IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14532D) : const Color(0xFFF3F9F5),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFCBE5D2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654), 
              size: 20
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
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
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14532D) : const Color(0xFFF3F9F5),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFCBE5D2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654), 
              size: 20
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
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
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsBold.x,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
        // Upload Status Indicator
        Positioned(
          bottom: 6,
          right: 6,
          child: _buildUploadStatusIndicator(item),
        ),
      ],
    );
  }

  // Document Pill exactly from Figma
  Widget _buildDocumentPill(_EvidenceItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14532D) : const Color(0xFFCBE5D2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsFill.fileText,
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
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
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1.2 MB',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          _buildUploadStatusIndicator(item),
          IconButton(
            icon: Icon(
              PhosphorIconsRegular.x,
              color: isDark ? Colors.white70 : Colors.black,
              size: 24,
            ),
            onPressed: () => _removeEvidenceItem(item),
          ),
        ],
      ),
    );
  }

  // Voice Note Pill exactly from Figma + play toggle capabilities
  Widget _buildVoicePill(_EvidenceItem item, bool isDark) {
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
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14532D) : const Color(0xFFCBE5D2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsFill.speakerHigh,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
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
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
                  size: 36,
                ),
              ),
              const SizedBox(width: 12),
              _buildUploadStatusIndicator(item),
              GestureDetector(
                onTap: () {
                  if (_playingVoicePath == item.path) {
                    _stopVoiceNote();
                  }
                  _removeEvidenceItem(item);
                },
                child: Icon(
                  PhosphorIconsRegular.x,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
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
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
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
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF4ADE80), const Color(0xFF86EFAC)]
                      : [const Color(0xFF1BA654), const Color(0xFF8BD9A1)],
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
                  thumbColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
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

  // --- WIDGET BUILDERS ---

  Widget _buildUploadStatusIndicator(_EvidenceItem item) {
    if (item.uploadStatus == UploadStatus.uploading) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    } else if (item.uploadStatus == UploadStatus.success) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          PhosphorIconsBold.check,
          color: Colors.white,
          size: 14,
        ),
      );
    } else if (item.uploadStatus == UploadStatus.failed) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          PhosphorIconsBold.warning,
          color: Colors.white,
          size: 14,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // --- STEP 3: REVIEW & SUBMIT ---
  Widget _buildStep3Review(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        _buildSummaryItem(
          'Activity Title',
          _titleController.text.isNotEmpty
              ? _titleController.text
              : 'No Title Provided',
          isDark
        ),
        _buildSummaryItem('Date & Time', '23 Jul 2026 • 02:52 PM', isDark),
        _buildSummaryItem('Location', ref.read(locationProvider).locationName, isDark),
        _buildSummaryItem(
          'Description',
          _descController.text.isNotEmpty
              ? _descController.text
              : 'No description provided.',
          isDark
        ),
        _buildSummaryItem('Attachments', _buildAttachmentSummary(), isDark),
        const SizedBox(height: 48),

        _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654)
                ),
              )
            : _buildPrimaryButton(
                label: 'Submit Activity',
                onPressed: _submitActivity,
                isDark: isDark
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
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654), 
                  width: 1.5
                ),
              ),
              child: Center(
                child: Text(
                  'Save Draft',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
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

  Widget _buildSummaryItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 4: SUCCESS ---
  Widget _buildStep4Success(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Provided SVG Asset
        SvgPicture.asset('lib/assets/Images/submit.svg', height: 180),

        const SizedBox(height: 32),
        Text(
          'Activity Submitted!',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Great Job! Your activity has been\nsubmitted successfully.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)
            ),
          ),
          child: Column(
            children: [
              Text(
                'Submission ID',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'FT-2026-07-23-00123',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB), 
                  height: 1
                ),
              ),
              Text(
                'Submitted At',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '23 Jul 2026 • 02:52 PM',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          label: 'View Activities',
          onPressed: () => Navigator.pop(context),
          isDark: isDark
        ),
      ],
    );
  }

  // --- STEP 5: ERROR ---
  Widget _buildStep5Error(bool isDark) {
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
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIconsFill.warning,
                    size: 80,
                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFFCA5A5),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFEF4444) : const Color(0xFFEF4444),
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
        Text(
          'Submission Failed!',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Oops! Something went wrong while submitting.\nPlease check your connection and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 48),
        _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444)
                ),
              )
            : InkWell(
                onTap: _submitActivity,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Text(
                      'Retry Submission',
                      style: TextStyle(
                        fontFamily: 'Poppins',
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
            child: Text(
              'Go Back',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF737373),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1BA654),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF121212) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}