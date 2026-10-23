import '../../family_profiles/model/allergen.dart';
import 'lunch_item.dart';
import 'lunch_slot.dart';

/// One item a new household's library starts with.
typedef LunchSeed = ({
  String key,
  String name,
  LunchSlot slot,
  Set<Allergen> allergens,
  String? prepNote,
});

/// What a South African school lunch box is usually made of, so a family's
/// first week can be planned in a few taps (lunch-box ADR-0001). Written into
/// the household's library once, the first time lunch is opened; after that
/// it is the family's to change, tag and put away.
///
/// The allergens are what the thing usually contains, so a new household's
/// checks work from the first box. A family whose bread has sesame in it says
/// so on the item. A prep note marks it as worth making on Sunday.
abstract final class LunchSeedCatalogue {
  static const _nuts = {Allergen.peanut};
  static const _bread = {Allergen.wheat, Allergen.soy};
  static const _dairy = {Allergen.milk};

  static final List<LunchSeed> seeds = [
    // Mains.
    _main('cheese-tomato', 'Cheese and tomato sandwich', {
      ..._bread,
      ..._dairy,
    }),
    _main('peanut-butter', 'Peanut butter and jam sandwich', {
      ..._bread,
      ..._nuts,
    }),
    _main('chicken-mayo', 'Chicken mayo wrap', {Allergen.wheat, Allergen.egg}),
    _main('egg-mayo', 'Egg mayo sandwich', {
      ..._bread,
      Allergen.egg,
    }, prep: 'Boil the eggs on Sunday; they keep five days in the fridge.'),
    _main('tuna-sandwich', 'Tuna sandwich', {
      ..._bread,
      Allergen.fish,
      Allergen.egg,
    }),
    _main('pasta-salad', 'Pasta salad', {
      Allergen.wheat,
      Allergen.egg,
    }, prep: 'Cook a big pot of pasta on Sunday for three days of boxes.'),
    _main('frikkadels', 'Mini frikkadels', {
      Allergen.wheat,
      Allergen.egg,
    }, prep: 'Bake a tray on Sunday and freeze half.'),
    _main(
      'chicken-drumstick',
      'Roast chicken drumstick',
      const {},
      prep: 'Roast extra with Sunday lunch.',
    ),
    _main(
      'rice-salad',
      'Rice and veg salad',
      const {},
      prep: 'Cook the rice on Sunday and keep it cold.',
    ),
    _main('mealie-bread', 'Mealie bread slice', {
      Allergen.wheat,
      Allergen.egg,
      ..._dairy,
    }, prep: 'Bake a loaf on Sunday and slice it.'),
    _main('cheese-rolls', 'Cheese rolls', {Allergen.wheat, ..._dairy}),
    _main('hummus-pita', 'Hummus and pita', {Allergen.wheat, Allergen.sesame}),
    // Fruit.
    _fruit('apple', 'Apple slices'),
    _fruit('banana', 'Banana'),
    _fruit('naartjie', 'Naartjie'),
    _fruit('grapes', 'Grapes'),
    _fruit('pear', 'Pear'),
    _fruit('strawberries', 'Strawberries'),
    _fruit('mango', 'Mango cubes', prep: 'Cube two mangoes on Sunday.'),
    _fruit('watermelon', 'Watermelon wedges', prep: 'Cut and box on Sunday.'),
    _fruit('litchis', 'Litchis'),
    // Veg.
    _veg(
      'carrot-sticks',
      'Carrot sticks',
      prep: 'Cut on Sunday and keep in water.',
    ),
    _veg('cucumber', 'Cucumber rounds'),
    _veg('cherry-tomatoes', 'Cherry tomatoes'),
    _veg('sugar-snaps', 'Sugar snap peas'),
    _veg('baby-corn', 'Baby corn'),
    _veg('pepper-strips', 'Sweet pepper strips', prep: 'Slice on Sunday.'),
    _veg('mielie', 'Mielie on the cob', prep: 'Boil a batch on Sunday.'),
    // Snacks.
    _snack('biltong', 'Biltong', const {}),
    _snack('droewors', 'Droëwors', const {}),
    _snack('cheese-cubes', 'Cheese cubes', _dairy),
    _snack('yoghurt', 'Yoghurt tub', _dairy),
    _snack(
      'popcorn',
      'Popcorn',
      const {},
      prep: 'Pop a big bowl on Sunday and bag it.',
    ),
    _snack('crackers', 'Crackers and cheese', {Allergen.wheat, ..._dairy}),
    _snack('rice-cakes', 'Rice cakes', const {}),
    _snack('raisins', 'Raisins', const {}),
    _snack('pretzels', 'Pretzels', {Allergen.wheat}),
    _snack('trail-mix', 'Trail mix', {Allergen.peanut, Allergen.treeNut}),
    // Treats.
    _treat('rusk', 'Rusk', {Allergen.wheat, Allergen.egg, ..._dairy}),
    _treat('marie-biscuits', 'Marie biscuits', {Allergen.wheat, ..._dairy}),
    _treat('muffin', 'Banana muffin', {
      Allergen.wheat,
      Allergen.egg,
      ..._dairy,
    }, prep: 'Bake a dozen on Sunday; freeze what the week will not eat.'),
    _treat('crunchie', 'Oat crunchie', {
      Allergen.wheat,
      ..._dairy,
    }, prep: 'Bake a tray on Sunday.'),
    _treat('chocolate', 'Small chocolate', {..._dairy, Allergen.soy}),
    _treat('jelly', 'Jelly sweets', const {}),
    _treat('koeksister', 'Mini koeksister', {Allergen.wheat, ..._dairy}),
  ];

  /// The library a household starts with, as items it adds in [memberId]'s
  /// name. Ids are the seed keys, so seeding twice writes the same documents.
  static List<LunchItem> itemsFor(String memberId) => [
    for (final seed in seeds)
      LunchItem.named(
        id: idFor(seed.key),
        name: seed.name,
        slot: seed.slot,
        allergens: seed.allergens,
        addedBy: memberId,
        prepAhead: seed.prepNote != null,
        prepNote: seed.prepNote,
        seedKey: seed.key,
      ),
  ];

  static String idFor(String key) => 'seed-$key';

  static LunchSeed _main(
    String key,
    String name,
    Set<Allergen> allergens, {
    String? prep,
  }) => _seed(key, name, LunchSlot.main, allergens, prep);

  static LunchSeed _fruit(String key, String name, {String? prep}) =>
      _seed(key, name, LunchSlot.fruit, const {}, prep);

  static LunchSeed _veg(String key, String name, {String? prep}) =>
      _seed(key, name, LunchSlot.veg, const {}, prep);

  static LunchSeed _snack(
    String key,
    String name,
    Set<Allergen> allergens, {
    String? prep,
  }) => _seed(key, name, LunchSlot.snack, allergens, prep);

  static LunchSeed _treat(
    String key,
    String name,
    Set<Allergen> allergens, {
    String? prep,
  }) => _seed(key, name, LunchSlot.treat, allergens, prep);

  static LunchSeed _seed(
    String key,
    String name,
    LunchSlot slot,
    Set<Allergen> allergens,
    String? prep,
  ) => (key: key, name: name, slot: slot, allergens: allergens, prepNote: prep);
}
