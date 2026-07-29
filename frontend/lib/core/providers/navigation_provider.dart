import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the current active tab index for the MainNavigationScreen
final navigationIndexProvider = StateProvider<int>((ref) => 0);
