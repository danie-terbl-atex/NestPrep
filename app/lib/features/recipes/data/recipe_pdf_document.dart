import 'dart:math';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/recipe_document.dart';
import 'recipe_pdf.dart';
import 'recipe_pdf_pictures.dart';

typedef PictureWork = Future<R> Function<M, R>(
  ComputeCallback<M, R> work,
  M message,
);

Future<R> _onIsolate<M, R>(ComputeCallback<M, R> work, M message) =>
    compute(work, message);

Uint8List _whole((PdfRasterPage, int, int) job) =>
    RecipePdfPictures.whole(job.$1, longEdge: job.$2, quality: job.$3);

(Uint8List, Uint8List) _halvesOf((PdfRasterPage, int) job) =>
    RecipePdfPictures.halves(job.$1, longEdge: job.$2);

Uint8List _cropped((PdfRasterPage, DocumentPhotoBox) job) =>
    RecipePdfPictures.cropped(job.$1, job.$2);

/// An opened PDF, held only while the import screen is (recipes ADR-0009).
/// Pages are numbered from 1, as the model is told them.
final class RecipePdfDocument {
  RecipePdfDocument._(this._rasterizer, this._bytes, this._sizes, this._work);

  static const maxPages = 50;
  static const scanEdge = 768;
  static const readEdge = 1024;
  static const photoEdge = 1400;
  static const photoPageCap = 2800;

  /// Small enough to be quick, fine enough to know a page's size within 1%.
  static const _probeDpi = 8.0;

  /// Drawn a little large and scaled down, as the probe's sizes are close,
  /// not exact.
  static const _headroom = 1.03;

  /// Android writes the whole PDF to a file on every call, and a call's pages
  /// arrive faster than they are encoded, so a scan goes in batches.
  static const _batch = 8;

  final PdfRasterizer _rasterizer;
  final Uint8List _bytes;
  final List<Size> _sizes;
  final PictureWork _work;
  final _halves = <int, (Uint8List, Uint8List)>{};
  final _wholes = <int, Uint8List>{};
  Future<void> _turn = Future<void>.value();

  static Future<RecipePdfDocument> open(
    PdfRasterizer rasterizer,
    Uint8List bytes, {
    PictureWork work = _onIsolate,
  }) async {
    final sizes = <Size>[];
    try {
      await for (final page in rasterizer.raster(bytes, null, _probeDpi)) {
        sizes.add(
          Size(page.width * 72 / _probeDpi, page.height * 72 / _probeDpi),
        );
        if (sizes.length > maxPages) {
          throw const OwnRecipeFailure(OwnRecipeProblem.documentTooLong);
        }
      }
    } on AppFailure {
      rethrow;
    } on Object {
      throw const OwnRecipeFailure(OwnRecipeProblem.documentUnreadable);
    }
    if (sizes.isEmpty) {
      throw const OwnRecipeFailure(OwnRecipeProblem.documentUnreadable);
    }
    return RecipePdfDocument._(rasterizer, bytes, sizes, work);
  }

  int get pageCount => _sizes.length;

  Stream<DocumentScanPage> scanPages() async* {
    final numbers = [for (var page = 1; page <= pageCount; page++) page];
    for (var at = 0; at < numbers.length; at += _batch) {
      final batch = numbers.sublist(at, min(at + _batch, numbers.length));
      await for (final (number, page) in _render(batch, scanEdge)) {
        yield DocumentScanPage(
          number: number,
          jpeg: await _work(_whole, (page, scanEdge, 72)),
        );
      }
    }
  }

  /// Halves of every page, and the whole of each in [wholes]. A page read for
  /// one recipe is not drawn again for the next: a base dough is shared.
  Future<List<DocumentReadPage>> readPages(
    List<int> numbers, {
    required Set<int> wholes,
  }) => _inTurn(() async {
    final missing = [
      for (final number in numbers)
        if (!_halves.containsKey(number) ||
            (wholes.contains(number) && !_wholes.containsKey(number)))
          number,
    ];
    if (missing.isNotEmpty) {
      await for (final (number, page) in _render(missing, readEdge)) {
        _halves[number] ??= await _work(_halvesOf, (page, readEdge));
        if (wholes.contains(number)) {
          _wholes[number] ??= await _work(_whole, (page, readEdge, 78));
        }
      }
    }
    return [
      for (final number in numbers)
        if (_halves[number] case (final top, final bottom))
          DocumentReadPage(
            number: number,
            top: top,
            bottom: bottom,
            whole: wholes.contains(number) ? _wholes[number] : null,
          )
        else
          throw const OwnRecipeFailure(OwnRecipeProblem.documentUnreadable),
    ];
  });

  /// The photo alone, drawn so its long edge is about [photoEdge].
  Future<Uint8List> photo(DocumentPhoto photo) =>
      _inTurn(() => _photoNow(photo));

  Future<Uint8List> _photoNow(DocumentPhoto photo) async {
    final size = _sizes[photo.page - 1];
    final box = photo.box;
    final longest = max(size.width, size.height);
    final cropPoints = max(
      (box.bottom - box.top) / 1000 * size.height,
      (box.right - box.left) / 1000 * size.width,
    );
    final pageEdge = min(
      photoPageCap.toDouble(),
      longest * photoEdge / max(cropPoints, 1),
    );
    final pages = await _rasterizer.raster(_bytes, [
      photo.page - 1,
    ], pageEdge * 72 / longest).toList();
    if (pages.isEmpty) {
      throw const OwnRecipeFailure(OwnRecipeProblem.documentUnreadable);
    }
    return _work(_cropped, (pages.first, box));
  }

  /// One drawing at a time: the platform renderer is not asked twice at once,
  /// and a page two recipes share is drawn by the first and read by both.
  Future<T> _inTurn<T>(Future<T> Function() draw) {
    final drawn = _turn.then((_) => draw());
    // The caller hears any failure through `drawn`; the queue only moves on.
    _turn = drawn.then<void>((_) {}, onError: (Object _) {});
    return drawn;
  }

  /// Pages of one size share a call, at the scale that gives them [longEdge].
  Stream<(int, PdfRasterPage)> _render(List<int> numbers, int longEdge) async* {
    final bySize = <Size, List<int>>{};
    for (final number in numbers) {
      final size = _sizes[number - 1];
      final key = bySize.keys.firstWhere(
        (seen) =>
            (seen.width - size.width).abs() < 2 &&
            (seen.height - size.height).abs() < 2,
        orElse: () => size,
      );
      bySize.putIfAbsent(key, () => []).add(number);
    }
    for (final MapEntry(key: size, value: group) in bySize.entries) {
      final dpi = longEdge * 72 / max(size.width, size.height) * _headroom;
      var at = 0;
      await for (final page in _rasterizer.raster(_bytes, [
        for (final number in group) number - 1,
      ], dpi)) {
        if (at < group.length) yield (group[at], page);
        at++;
      }
    }
  }
}
