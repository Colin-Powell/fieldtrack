import 'package:flutter/widgets.dart';

/// Global Intents
class SearchIntent extends Intent {
  const SearchIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class ExportIntent extends Intent {
  const ExportIntent();
}

/// Navigation Intents
class NavigateDashboardIntent extends Intent {
  const NavigateDashboardIntent();
}

class NavigateStudentsIntent extends Intent {
  const NavigateStudentsIntent();
}

class NavigateMapIntent extends Intent {
  const NavigateMapIntent();
}

class NavigateFeedIntent extends Intent {
  const NavigateFeedIntent();
}

class NavigateUsersIntent extends Intent {
  const NavigateUsersIntent();
}

class NavigateProjectsIntent extends Intent {
  const NavigateProjectsIntent();
}

class NavigateReportsIntent extends Intent {
  const NavigateReportsIntent();
}
