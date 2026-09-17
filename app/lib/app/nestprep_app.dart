import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../shared/copy/app_copy.dart';
import 'app_providers.dart';
import 'app_router.dart';

class NestPrepApp extends StatelessWidget {
  const NestPrepApp({required this.firestore, super.key});

  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders(firestore),
      child: MaterialApp.router(
        title: AppCopy.appName,
        theme: nestThemeData(NestTheme.light()),
        darkTheme: nestThemeData(NestTheme.dark()),
        routerConfig: appRouter,
      ),
    );
  }
}
