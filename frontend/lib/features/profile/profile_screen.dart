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
const Color _textLight = Color(0xFF88929A); // Grey text for values
const String _fontFamily = 'Poppins'; // Specified font family

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = user?.name ?? 'Collins Kodero';
    final regNo = user?.registrationNo ?? 'MB21/PU/1234/22';
    final programme = user?.programme ?? 'MSc Environmental Sciences';
    final department = user?.department ?? 'Environmental Sciences';
    final faculty = user?.faculty ?? 'Sciences';
    final supervisor = user?.supervisorName ?? 'Prof. Dr. Okeyo Benards';
    final topic = user?.topic ?? 'Mangrove Ecosystems & Carbon Sequestration';
    final phone = user?.phone ?? '+254 712 345 678';

    // Dynamic Colors
    final bgColor = isDark ? const Color(0xFF121212) : Theme.of(context).scaffoldBackgroundColor;
    final badgeBgColor = isDark ? const Color(0xFF14532D) : _lightGreen;
    final badgeTextColor = isDark ? const Color(0xFF4ADE80) : Colors.black;
    final primaryTextColor = isDark ? const Color(0xFF4ADE80) : _primaryGreen;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: PhosphorIcon(
                          PhosphorIcons.gear(),
                          color: badgeTextColor,
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
                  // Edit button overlay
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
                          color: badgeBgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: bgColor, // matches scaffold background perfectly
                            width: 3,
                          ),
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.pencilSimple(),
                          color: primaryTextColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                programme,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 16,
                  color: primaryTextColor,
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
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'REG: $regNo',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // --- Details List ---
              _ProfileDetailRow(label: 'Full Name', value: name, isDark: isDark),
              _ProfileDetailRow(label: 'Registration Number', value: regNo, isDark: isDark),
              _ProfileDetailRow(label: 'Phone Number', value: phone, isDark: isDark),
              _ProfileDetailRow(label: 'Programme', value: programme, isDark: isDark),
              _ProfileDetailRow(label: 'Department', value: department, isDark: isDark),
              _ProfileDetailRow(label: 'Faculty', value: faculty, isDark: isDark),
              _ProfileDetailRow(
                label: 'University',
                value: 'Pwani University',
                isDark: isDark,
              ),
              _ProfileDetailRow(label: 'Research Topic', value: topic, isDark: isDark),
              _ProfileDetailRow(label: 'Supervisor', value: supervisor, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper Widget for the Details Layout ---
class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

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
              style: TextStyle(
                fontFamily: _fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFA1A1AA) : _textLight,
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  File? _imageFile;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  static final _emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w.\-]+$');

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    bool success = true;

    // Upload avatar if a new one was picked
    if (_imageFile != null) {
      success = await ref.read(authProvider.notifier).uploadAvatar(_imageFile!);
    }

    // Update email + phone via API
    if (success) {
      success = await ref
          .read(authProvider.notifier)
          .updateProfile(
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
          );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: _primaryGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider).error ?? 'Failed to update profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF333333) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? const Color(0xFFA1A1AA) : _textLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: _fontFamily,
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
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
                          color: isDark 
                              ? const Color(0xFF14532D) 
                              : const Color(0xFF169B45).withValues(alpha: 0.1),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : user?.avatarUrl != null &&
                                    user!.avatarUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                    ImageUtils.getFullImageUrl(user.avatarUrl!),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            _imageFile == null &&
                                (user?.avatarUrl == null ||
                                    user!.avatarUrl!.isEmpty)
                            ? Icon(
                                PhosphorIconsFill.userCircle,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF169B45),
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
                            border: Border.all(color: bgColor, width: 3),
                          ),
                          child: PhosphorIcon(
                            PhosphorIcons.camera(),
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
              Center(
                child: Text(
                  'Tap to change photo',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: hintColor,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Email Field
              TextFormField(
                controller: _emailController,
                style: TextStyle(fontFamily: _fontFamily, fontSize: 16, color: textColor),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!_emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  labelStyle: TextStyle(fontFamily: _fontFamily, color: hintColor),
                  hintStyle: TextStyle(fontFamily: _fontFamily, color: hintColor),
                  filled: true,
                  fillColor: surfaceColor,
                  prefixIcon: PhosphorIcon(
                    PhosphorIcons.envelope(),
                    color: hintColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primaryGreen),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                style: TextStyle(fontFamily: _fontFamily, fontSize: 16, color: textColor),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  labelStyle: TextStyle(fontFamily: _fontFamily, color: hintColor),
                  hintStyle: TextStyle(fontFamily: _fontFamily, color: hintColor),
                  filled: true,
                  fillColor: surfaceColor,
                  prefixIcon: PhosphorIcon(
                    PhosphorIcons.phone(),
                    color: hintColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primaryGreen),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 54),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primaryGreen.withValues(
                      alpha: 0.6,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}