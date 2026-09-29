import '../../features/home_care/model/safety/mixing_danger.dart';
import '../../features/home_care/model/safety/precaution.dart';
import '../../features/home_care/model/safety/safety_source.dart';

/// The words of the safety catalogue (home-care ADR-0002): what must never
/// meet, what to wear and do, and where each piece of advice comes from.
///
/// **These are safety claims.** Each one summarises a source named in
/// `sourceSays`; a change here needs its source, and the catalogue is read
/// against the sources by somebody other than its author before launch.
abstract final class HomeCareSafetyCopy {
  static const title = 'Safety';
  static const needsCare = 'Needs care';

  static String neverTogether(String first, String second) =>
      'Never use $first and $second together';

  static String hazard(MixingHazard hazard) => switch (hazard) {
    MixingHazard.chloramine =>
      'Bleach and ammonia make chloramine gas, which harms the lungs. Use '
          'one, rinse with water and air the room before the other.',
    MixingHazard.chlorineGas =>
      'Bleach and acids, like vinegar or toilet cleaner, give off chlorine '
          'gas. Never mix them, or use one on the other without rinsing.',
    MixingHazard.chloroform =>
      'Bleach and alcohol make chloroform and other poisonous vapours.',
    MixingHazard.bleachWithAnotherCleaner =>
      'Bleach is only ever mixed with water. Use other cleaners before or '
          'after it, rinsed off in between — never together.',
    MixingHazard.peraceticAcid =>
      'Hydrogen peroxide and vinegar, or another acid, make peracetic acid, '
          'which can burn skin, eyes and lungs.',
    MixingHazard.drainCleanerReaction =>
      'A drain cleaner can react violently with anything else — even another '
          'drain cleaner. Use one, on its own.',
  };

  static String precaution(Precaution precaution) => switch (precaution) {
    Precaution.corrosive => 'It burns skin and eyes',
    Precaution.flammable => 'It catches fire',
    Precaution.onlyWithWater => 'Dilute it only with water',
    Precaution.gloves => 'Wear gloves',
    Precaution.eyeProtection => 'Protect your eyes',
    Precaution.freshAir => 'Open a window',
    Precaution.patchTest => 'Test a hidden spot first',
    Precaution.keepFromChildren => 'Keep it away from children',
    Precaution.keepFromPets => 'Keep it away from pets',
  };

  static String precautionWhy(Precaution precaution) => switch (precaution) {
    Precaution.corrosive =>
      'Rinse any splash off skin or eyes at once with plenty of water.',
    Precaution.flammable => 'Keep it away from flames, the stove and heaters.',
    Precaution.onlyWithWater =>
      'Never with another cleaner, and no stronger than the bottle says.',
    Precaution.gloves => 'Household gloves, for the whole job.',
    Precaution.eyeProtection =>
      'Glasses or goggles, and keep your face away from the spray.',
    Precaution.freshAir => 'Keep air moving while you work, and after.',
    Precaution.patchTest =>
      'It can mark or fade some surfaces, fabrics and stone.',
    Precaution.keepFromChildren =>
      'Put it back where it lives as soon as you are done.',
    Precaution.keepFromPets => 'And keep pets off the floor until it is dry.',
  };

  static const originalBottles = 'Keep every product in its own bottle';
  static const originalBottlesWhy =
      'Never pour a product into another bottle, or mix leftovers.';
  static const accidentTitle =
      'If someone swallows it or gets it in their eyes';
  static const accidentBody =
      'Rinse with plenty of water and call the Poisons Information Helpline '
      'on 0861 555 777, day or night.';

  static const beforeYouStart = 'Before you start';
  static const beforeYouStartBody =
      'Read this first. It is about keeping you safe.';
  static const readIt = 'I have read it — show the steps';
  static const jobHasDangers =
      'Some of this job’s products must never be used together. Read Safety '
      'below before you start.';
  static const composerWarning =
      'Some of these products must never be used together. The helper will '
      'be told — but think about choosing only one of them.';
  static const keepFromChildrenChoice = 'Keep away from children';
  static const keepFromPetsChoice = 'Keep away from pets';

  static String helperWillBeTold(List<Precaution> precautions) =>
      'The helper will be told: '
      '${precautions.map((item) => precaution(item).toLowerCase()).join('; ')}.';

  static const sourcesLink = 'Where this comes from';
  static const sourcesTitle = 'Where this comes from';
  static const sourcesIntro =
      'This is a summary of public safety advice, not advice of NestPrep’s '
      'own. Always read the product’s label too.';

  static String sourceName(SafetySource source) => switch (source) {
    SafetySource.cdcBleach =>
      'US Centers for Disease Control and Prevention (CDC)',
    SafetySource.washingtonHealth => 'Washington State Department of Health',
    SafetySource.poisonControl => 'National Capital Poison Center (poison.org)',
    SafetySource.poisonsHelpline =>
      'Poisons Information Helpline, South Africa',
  };

  static String sourceSays(SafetySource source) => switch (source) {
    SafetySource.cdcBleach =>
      'Cleaning with bleach: dilute it only with water, never mix it with '
          'ammonia or any other cleanser, wear gloves and keep air moving.',
    SafetySource.washingtonHealth =>
      'Bleach with ammonia makes chloramine gas, with acids chlorine gas, '
          'and with rubbing alcohol chloroform — each harmful to breathe.',
    SafetySource.poisonControl =>
      'Which household products must never be mixed — hydrogen peroxide '
          'with vinegar, drain cleaners with anything — and what to do after '
          'an exposure.',
    SafetySource.poisonsHelpline =>
      'Advice after a poisoning, 24 hours a day: 0861 555 777.',
  };
}
