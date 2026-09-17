import 'package:flutter/material.dart';

import 'nest_skeleton.dart';

/// The loading state: holds the layout the content will take rather than
/// collapsing it (`FE-08`).
class NestLoadingView extends StatelessWidget {
  const NestLoadingView({this.rows = 4, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) => NestSkeleton.rows(count: rows);
}
