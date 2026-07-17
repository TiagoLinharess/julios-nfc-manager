import 'package:flutter/material.dart';

class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({required this.child, this.onRefresh, super.key});

  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh ?? _defaultRefresh,
      child: child,
    );
  }

  static Future<void> _defaultRefresh() {
    return Future<void>.delayed(const Duration(milliseconds: 450));
  }
}
