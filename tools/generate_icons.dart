import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../assets/icons/app_icon.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Generate icons for Android
  final androidSizes = {
    'mipmap-mdpi': 48.0,
    'mipmap-hdpi': 72.0,
    'mipmap-xhdpi': 96.0,
    'mipmap-xxhdpi': 144.0,
    'mipmap-xxxhdpi': 192.0,
  };

  for (final entry in androidSizes.entries) {
    await generateAppIcon(
      'android/app/src/main/res/${entry.key}/ic_launcher.png',
      entry.value,
    );
  }

  // Generate icons for iOS
  final iosSizes = {
    '20x20@1x': 20.0,
    '20x20@2x': 40.0,
    '20x20@3x': 60.0,
    '29x29@1x': 29.0,
    '29x29@2x': 58.0,
    '29x29@3x': 87.0,
    '40x40@1x': 40.0,
    '40x40@2x': 80.0,
    '40x40@3x': 120.0,
    '60x60@2x': 120.0,
    '60x60@3x': 180.0,
    '76x76@1x': 76.0,
    '76x76@2x': 152.0,
    '83.5x83.5@2x': 167.0,
    '1024x1024@1x': 1024.0,
  };

  for (final entry in iosSizes.entries) {
    await generateAppIcon(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-${entry.key}.png',
      entry.value,
    );
  }

  print('App icons generated successfully!');
}