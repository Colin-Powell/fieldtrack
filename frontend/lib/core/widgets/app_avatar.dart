import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
}
