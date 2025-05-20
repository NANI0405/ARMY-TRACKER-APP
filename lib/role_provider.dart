import 'package:flutter/material.dart';

class RoleProvider extends InheritedWidget {
  final String userRole;
  final ValueChanged<String> updateRole;

  const RoleProvider({
    required this.userRole,
    required this.updateRole,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  static RoleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RoleProvider>();
  }
}