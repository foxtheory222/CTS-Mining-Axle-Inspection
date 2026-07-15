import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void startNewInspection(BuildContext context) {
  if (GoRouterState.of(context).matchedLocation == '/inspection/new') {
    return;
  }
  context.go('/inspection/new');
}
