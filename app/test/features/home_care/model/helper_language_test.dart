import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/model/language/helper_language_converter.dart';
import 'package:nestprep/features/home_care/model/language/reviewed_safety_translations.dart';
import 'package:nestprep/features/home_care/model/language/translated_line.dart';
import 'package:nestprep/features/home_care/model/language/translation_book.dart';
import 'package:nestprep/features/home_care/model/language/translation_id.dart';
import 'package:nestprep/features/home_care/model/product_kind.dart';
import 'package:nestprep/features/home_care/model/stock_level.dart';

/// The helper's language (home-care ADR-0006): how a line is read — a
/// reviewed translation above a machine one above the English — and the
/// cache id the phone and the Function must agree on to the byte.
void main() {
  group('a language', () {
    test('is stored and read back by its code', () {
      const converter = HelperLanguageConverter();
      expect(converter.toJson(HelperLanguage.sepedi), 'nso');
      expect(converter.fromJson('zu'), HelperLanguage.isiZulu);
    });

    test('a code this build does not know reads as English, not a crash', () {
      expect(HelperLanguage.fromCode('fr'), HelperLanguage.english);
      expect(HelperLanguage.fromCode(null), HelperLanguage.english);
      expect(
        const HelperLanguageConverter().fromJson(42),
        HelperLanguage.english,
      );
    });

    test('only English needs no translation', () {
      expect(HelperLanguage.english.needsTranslation, isFalse);
      expect(
        HelperLanguage.values.where((language) => language.needsTranslation),
        hasLength(HelperLanguage.values.length - 1),
      );
    });

    test(
      'every language is shown by its own name, with a voice to ask for',
      () {
        for (final language in HelperLanguage.values) {
          expect(language.ownName, isNotEmpty);
          expect(language.voice, startsWith('${language.code}-'));
        }
      },
    );
  });

  group('the id a translation is cached under', () {
    // The same vectors are in `functions/test/unit/home_care/translation.test.ts`.
    test('is the SHA-256 of the text, then the code', () {
      expect(
        translationIdOf('Open a window', HelperLanguage.isiZulu),
        '447f9a95bdd5f7621df94b927415e328c7d53d413598ecbb61fb42f1512ed6bf_zu',
      );
      expect(
        translationIdOf('Wipe the counters', HelperLanguage.sepedi),
        '54950ce4a5d51481c2aebc88e60e9a1bf0ea25e35b6a9e3fb9433b63e141a88c_nso',
      );
      expect(
        translationIdOf(
          'Vula ifasitela — ngokushesha',
          HelperLanguage.isiXhosa,
        ),
        '773368141dd3ef30d74e9eadab960bf5b199df5f3d3ac82ec1e0866ea4ad007d_xh',
      );
    });
  });

  group('a translation book', () {
    test('reads English as it is, and asks for nothing', () {
      final book = TranslationBook(language: HelperLanguage.english);
      expect(book.lineFor('Wipe'), const TranslatedLine.english('Wipe'));
      expect(book.missing(['Wipe']), isEmpty);
    });

    test('reads a line nobody has translated yet in English', () {
      final line = TranslationBook(language: HelperLanguage.isiZulu)
          .lineFor('Wipe');
      expect(line.text, 'Wipe');
      expect(line.isTranslated, isFalse);
    });

    test('reads a machine translation, badged as one', () {
      final line = TranslationBook(
        language: HelperLanguage.isiZulu,
        machine: {'Wipe': 'Sula'},
      ).lineFor('Wipe');
      expect(line.text, 'Sula');
      expect(line.source, TranslationSource.machine);
      expect(line.english, 'Wipe');
    });

    test('prefers a line a speaker checked over the machine’s', () {
      final book = TranslationBook(
        language: HelperLanguage.isiZulu,
        machine: {'Wipe': 'Sula (machine)'},
        reviewed: {
          HelperLanguage.isiZulu: {'Wipe': 'Sula'},
        },
      );
      expect(
        book.lineFor('Wipe'),
        const TranslatedLine(
          english: 'Wipe',
          text: 'Sula',
          source: TranslationSource.reviewed,
        ),
      );
      expect(book.missing(['Wipe', 'Mop']), ['Mop']);
      expect(book.adding({'Mop': 'Mopha'}).lineFor('Wipe').text, 'Sula');
    });

    test('asks once for a line repeated on the screen', () {
      final book = TranslationBook(language: HelperLanguage.sesotho);
      expect(book.missing(['Mop', 'Mop', 'Wipe']), ['Mop', 'Wipe']);
      expect(book.adding({'Mop': 'Hlatswa'}).missing(['Mop', 'Wipe']), [
        'Wipe',
      ]);
    });

    test('the shipped catalogue has no reviewed line yet — every safety '
        'line is badged machine-translated until a speaker checks it', () {
      expect(ReviewedSafetyTranslations.shipped, isEmpty);
    });
  });

  group('a product’s stock', () {
    test('a product from before the tracker reads as full', () {
      final product = HomeCareProduct.fromJson({
        'id': 'jik',
        'name': 'Jik',
        'kind': 'bleach',
        'createdBy': 'm-sam',
      });
      expect(product.stock, StockLevel.full);
      expect(product.stockChangedBy, isNull);
    });

    test('a level this build does not know reads as full', () {
      final product = HomeCareProduct.fromJson({
        'id': 'jik',
        'name': 'Jik',
        'kind': 'bleach',
        'createdBy': 'm-sam',
        'stock': 'nearlyGone',
      });
      expect(product.stock, StockLevel.full);
    });

    test('is never written with the rest of the product', () {
      const product = HomeCareProduct(
        id: 'jik',
        name: 'Jik',
        kind: ProductKind.bleach,
        createdBy: 'm-sam',
        stock: StockLevel.low,
      );
      expect(product.toJson().keys, isNot(contains('stock')));
    });

    test('only low and out are on their way to the list', () {
      expect(StockLevel.values.where((level) => level.isRunningOut), [
        StockLevel.low,
        StockLevel.out,
      ]);
    });
  });
}
