import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/assistants/data/assistant_repository.dart';
import '../features/assistants/data/firestore_assistant_repository.dart';

/// *Connected assistants* in the app-wide graph (assistants ADR-0001). Its
/// own list, spread into `appProviders`, so the shared file changes by one
/// line.
List<SingleChildWidget> assistantsProviders() => [
  Provider<AssistantRepository>(
    create: (context) =>
        FirestoreAssistantRepository(context.read<FirebaseFirestore>()),
  ),
];
