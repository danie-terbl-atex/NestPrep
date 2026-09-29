import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../model/share_target.dart';
import '../state/offline_copies_controller.dart';
import 'share_and_keep_actions.dart';
import 'share_link_sheet.dart';

/// Wires a document's sheet to sharing and offline copies (documents
/// ADR-0006, ADR-0007): the switches from `FeatureFlagsController`, what is
/// kept from `OfflineCopiesController`, and the share sheet. Both sheets —
/// a household document's and a vault document's — use this one, so the two
/// can never offer different things for the same document.
class DocumentShareAndKeep extends StatelessWidget {
  const DocumentShareAndKeep({
    required this.target,
    required this.canShare,
    required this.onKeep,
    super.key,
  });

  final ShareTarget target;

  /// Whether this person may send it outside the household — the same
  /// answer `createDocumentShare` gives, asked early so the button is not a
  /// refusal waiting to happen (`FE-04`).
  final bool canShare;

  /// Saves the copy: a household document and a vault document are fetched
  /// differently, so the sheet says how.
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final flags = context.watch<FeatureFlagsController>();
    final offline = context.watch<OfflineCopiesController>();
    final showsShare = canShare && flags.isOn(FeatureFlag.documentShareLinks);
    final showsKeep = flags.isOn(FeatureFlag.documentOfflineCopies);
    if (!showsShare && !showsKeep) return const SizedBox.shrink();
    return ShareAndKeepActions(
      showsShare: showsShare,
      showsKeep: showsKeep,
      isKept: offline.holds(
        ownerMemberId: target.ownerMemberId,
        documentId: target.documentId,
      ),
      isSaving: offline.isSaving(target.documentId),
      onShare: () => showShareLinkSheet(context: context, target: target),
      onKeep: onKeep,
      onRemove: () => offline.removeDocument(
        ownerMemberId: target.ownerMemberId,
        documentId: target.documentId,
      ),
    );
  }
}
