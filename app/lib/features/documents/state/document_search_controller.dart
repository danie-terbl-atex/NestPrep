import 'package:flutter/foundation.dart';

import '../model/document_search.dart';

/// What somebody is searching for on the search screen (documents ADR-0005).
///
/// Only the query lives here — the documents are the library's and the vault's
/// listeners, never copied (`FE-07`). It starts from the route's parameters, so
/// "expiring soon" and "search this vault" are links rather than states a
/// screen has to be told about (`FE-17`).
final class DocumentSearchController extends ChangeNotifier {
  DocumentSearchController({DocumentQuery initial = const DocumentQuery()})
    : _query = initial;

  DocumentQuery _query;

  DocumentQuery get query => _query;

  void setText(String text) => _set(_query.copyWith(text: text));

  void setOwner(OwnerFilter owner) => _set(_query.copyWith(owner: owner));

  /// Tapping the selected tag again clears it.
  void toggleTag(String tag) => _set(
    _query.copyWith(
      tag: () => _query.tag?.toLowerCase() == tag.toLowerCase() ? null : tag,
    ),
  );

  void setExpiringSoonOnly(bool value) =>
      _set(_query.copyWith(expiringSoonOnly: value));

  void clear() => _set(DocumentQuery(text: _query.text));

  void _set(DocumentQuery next) {
    _query = next;
    notifyListeners();
  }
}
