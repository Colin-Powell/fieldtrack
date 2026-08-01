import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/image_utils.dart';
import 'package:fieldtrack/core/widgets/app_avatar.dart';

// --- Theme Colors ---
const Color _lightGreen = Color(0xFFCDE8D5); // Background for badges/buttons
const Color _primaryGreen = Color(0xFF1B934F); // Text for primary highlights
const Color _textDark = Color(0xFF333333); // Dark text for labels
const Color _textLight = Color(0xFF88929A); // Grey text for values
const String _fontFamily = 'Roboto'; // Specified font family

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final name = user?.name ?? 'Collins Kodero';
    final regNo = user?.registrationNo ?? 'MB21/PU/1234/22';
    final programme = user?.programme ?? 'MSc Environmental Sciences';
    final department = user?.department ?? 'Environmental Sciences';
    final faculty = user?.faculty ?? 'Sciences';
    final supervisor = user?.supervisorName ?? 'Prof. Dr. Okeyo Benards';
    final topic = user?.topic ?? 'Mangrove Ecosystems & Carbon Sequestration';
    final phone = user?.phone ?? '+254 712 345 678';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Custom Header ---
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Profile',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 18, // Increased size
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: PhosphorIcon(
                          PhosphorIcons.gear(), // Added parentheses
                          color: Colors.black,
                          size: 26,
                        ),
                        onPressed: () {
                          context.push('/settings');
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- Profile Picture & Edit Button ---
              Stack(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: AppAvatar(
                      imagePath: user?.avatarUrl,
                      size: 100,
                      shape: AvatarShape.circle,
                      initials: name.isNotEmpty
                          ? name
                                .split(' ')
                                .map((s) => s.isNotEmpty ? s[0] : '')
                                .take(2)
                                .join()
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _lightGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.pencilSimple(), // Added parentheses
                          color: _primaryGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // --- Name & Subtitle ---
              Text(
                name,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 24, // Increased size
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                programme,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 16, // Increased size
                  color: _primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // --- Registration Badge ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'REG: $regNo',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14, // Increased size
                    color: _primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // --- Details List ---
              _ProfileDetailRow(label: 'Full Name', value: name),
              _ProfileDetailRow(label: 'Registration Number', value: regNo),
              _ProfileDetailRow(label: 'Phone Number', value: phone),
              _ProfileDetailRow(label: 'Programme', value: programme),
              _ProfileDetailRow(label: 'Department', value: department),
              _ProfileDetailRow(label: 'Faculty', value: faculty),
              const _ProfileDetailRow(
                label: 'University',
                value: 'Pwani University',
              ),
              _ProfileDetailRow(label: 'Research Topic', value: topic),
              _ProfileDetailRow(label: 'Supervisor', value: supervisor),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper Widget for the Details Layout ---
class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 15, // Increased size
                color: _textDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 15, // Increased size
                fontWeight: FontWeight.w500,
                color: _textLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Page: Edit Profile Screen ---
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: _fontFamily,
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22, // Increased size
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Upload Picture Section
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF169B45).withValues(alpha: 0.1),
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : ref.read(authProvider).user?.avatarUrl != null &&
                                  ref
                                      .read(authProvider)
                                      .user!
                                      .avatarUrl!
                                      .isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                  ImageUtils.getFullImageUrl(
                                    ref.read(authProvider).user!.avatarUrl!,
                                  ),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          _imageFile == null &&
                              (ref.read(authProvider).user?.avatarUrl == null ||
                                  ref
                                      .read(authProvider)
                                      .user!
                                      .avatarUrl!
                                      .isEmpty)
                          ? const Icon(
                              PhosphorIconsFill.userCircle,
                              color: Color(0xFF169B45),
                              size: 64,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.camera(), // Added parentheses
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Tap to change photo',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: _textLight,
                  fontSize: 15, // Increased size
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Form Fields
            TextFormField(
              initialValue: 'collins@example.com',
              style: const TextStyle(fontFamily: _fontFamily, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                labelStyle: const TextStyle(fontFamily: _fontFamily),
                prefixIcon: PhosphorIcon(
                  PhosphorIcons.envelope(), // Added parentheses
                  color: _textLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primaryGreen),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 28),
            TextFormField(
              initialValue: '+254 712 345 678',
              style: const TextStyle(fontFamily: _fontFamily, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                labelStyle: const TextStyle(fontFamily: _fontFamily),
                prefixIcon: PhosphorIcon(
                  PhosphorIcons.phone(), // Added parentheses
                  color: _textLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primaryGreen),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 54),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56, // Larger button
              child: ElevatedButton(
                onPressed: () async {
                  if (_imageFile != null) {
                    final success = await ref
                        .read(authProvider.notifier)
                        .uploadAvatar(_imageFile!);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully'),
                        ),
                      );
                      Navigator.pop(context);
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.read(authProvider).error ??
                                'Failed to upload profile',
                          ),
                        ),
                      );
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 18, // Increased size
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
