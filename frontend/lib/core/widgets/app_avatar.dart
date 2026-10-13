import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/image_utils.dart';

enum AvatarShape { circle, square }

class AppAvatar extends StatelessWidget {
  final String? imagePath;
  final String? initials;
  final double size;
  final AvatarShape shape;
  final BoxFit fit;

  const AppAvatar({
    super.key,
    this.imagePath,
    this.initials,
    this.size = 40,
    this.shape = AvatarShape.circle,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = ImageUtils.getFullImageUrl(imagePath);
    final BorderRadius borderRadius = BorderRadius.circular(6);

    Widget child;
    if (url.isNotEmpty) {
      if (url.startsWith('gs://')) {
        child = FutureBuilder<String>(
          future: _resolveGsUrl(url),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: size,
                height: size,
                color: Colors.grey.shade200,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return _initialsOrDefault();
            }
            return CachedNetworkImage(
              imageUrl: snapshot.data!,
              placeholder: (ctx, _) => Container(
                width: size,
                height: size,
                color: Colors.grey.shade200,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (ctx, url, error) => _initialsOrDefault(),
              width: size,
              height: size,
              fit: fit,
            );
          },
        );
      } else {
        child = CachedNetworkImage(
          imageUrl: url,
          placeholder: (ctx, _) => Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (ctx, url, error) => _initialsOrDefault(),
          width: size,
          height: size,
          fit: fit,
        );
      }
    } else {
      child = _initialsOrDefault();
    }

    if (shape == AvatarShape.circle) {
      return ClipOval(
        child: SizedBox(width: size, height: size, child: child),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _initialsOrDefault() {
    if (initials != null && initials!.isNotEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: Center(
          child: Text(initials!, style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade300,
      child: Center(child: Icon(Icons.person, color: Colors.white70)),
    );
  }

  Future<String> _resolveGsUrl(String gsUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(gsUrl);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Failed to resolve gs:// URL: $e');
      return '';
    }
  }
}
