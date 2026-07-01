import 'package:flutter/widgets.dart';

/// Shared responsive breakpoints and helpers for the tablet-first UI.
///
/// All thresholds are expressed in the logical *content* width available to a
/// screen body (the area to the right of the navigation rail), not the raw
/// device width. Attached field tablets run around ~1000dp wide in landscape,
/// so the layout has to stay comfortable well below the classic 1200dp desktop
/// breakpoint.
class Breakpoints {
  const Breakpoints._();

  /// Below this a screen body collapses side panels into a single column.
  static const double twoPane = 1080;

  /// At or above this the inspection form can show its section rail.
  static const double formRail = 1160;

  /// At or above this the inspection form can also show the summary panel.
  static const double formSummary = 1480;

  /// Comfortable maximum width for a single reading column so form fields and
  /// text never stretch edge-to-edge on very wide tablets.
  static const double readableColumn = 1080;

  /// Below this narrow width, dense two-up rows stack vertically instead.
  static const double stackRow = 640;
}

/// Number of columns to use for a compact field grid at the given [width].
int fieldColumnsForWidth(double width) {
  if (width >= 1180) {
    return 4;
  }
  if (width >= 780) {
    return 3;
  }
  if (width >= 500) {
    return 2;
  }
  return 1;
}

/// Even column width for [columns] items separated by [spacing] within [width].
///
/// Floored to avoid sub-pixel overflow that would push the last item onto a new
/// [Wrap] run.
double gridItemWidth(double width, int columns, double spacing) {
  if (columns <= 1) {
    return width;
  }
  final available = width - spacing * (columns - 1);
  return (available / columns).floorToDouble();
}
