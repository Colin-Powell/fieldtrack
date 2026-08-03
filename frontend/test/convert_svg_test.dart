import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('convert svg to png', (tester) async {
    final String svgString = await File('lib/assets/Images/icon.svg').readAsString();
    
    // For flutter_svg ^2.0.0
    final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
    
    final ui.Picture picture = pictureInfo.picture;
    // Scale up for a high-res icon (1024x1024)
    final image = await picture.toImage(1024, 1024);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      await File('lib/assets/Images/icon.png').writeAsBytes(byteData.buffer.asUint8List());
    }
  });
}
