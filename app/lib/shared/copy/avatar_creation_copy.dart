import '../../features/avatars/model/avatar_buddy.dart';
import '../../features/avatars/model/avatar_catalogue.g.dart';
import '../../features/avatars/model/avatar_creation.dart';

abstract final class AvatarCreationCopy {
  static const createTab = 'Create';
  static const keepsakesTab = 'Keepsakes';

  static const menuTitle = 'Make something new';
  static const menuBody =
      'Pick one and our AI turns it into a brand-new picture.';
  static String picturesLeft(int count) => count == 1
      ? '1 picture left this month'
      : '$count pictures left this month';
  static const needsPremium = 'Making pictures is part of Premium.';
  static String noneLeft(String from) =>
      'No more pictures this month. You can make more from $from!';

  static String recipeTitle(CreationRecipe recipe) => switch (recipe) {
    CreationRecipe.drawing => 'Drawing to toy',
    CreationRecipe.buddy => 'Build a buddy',
    CreationRecipe.pet => 'Pet twin',
    CreationRecipe.portrait => 'Make our Nest portrait',
  };
  static String recipeBody(CreationRecipe recipe) => switch (recipe) {
    CreationRecipe.drawing => 'Snap a drawing and watch it become a toy.',
    CreationRecipe.buddy => 'Tap to choose who they are and what they love.',
    CreationRecipe.pet => 'Your pet, made into a toy.',
    CreationRecipe.portrait =>
      'Everyone’s characters together in one picture, for your frame.',
  };
  static const pickSomethingElse = 'Pick something else';

  static const pickStyle = 'Pick a style';
  static String style(CreationStyle style) => switch (style) {
    CreationStyle.plush => 'Plush',
    CreationStyle.clay => 'Clay',
    CreationStyle.knitted => 'Knitted',
    CreationStyle.wooden => 'Wooden',
    CreationStyle.vinyl => 'Vinyl toy',
    CreationStyle.sticker => 'Sticker',
  };
  static String styleTitle(CreationStyle style) =>
      '${AvatarCreationCopy.style(style)} style';

  static String photoTitle(CreationRecipe recipe) =>
      recipe == CreationRecipe.pet ? 'Now your pet' : 'Now the drawing';
  static String photoHint(CreationRecipe recipe) => recipe == CreationRecipe.pet
      ? 'One pet, close up, with its face showing.'
      : 'Lay it flat in good light so it fills the photo.';
  static const pictureDisclosure =
      'Google’s AI checks it first. Drawings of people become words, and '
      'photos of people are refused.';
  static const wordsDisclosure =
      'Google’s AI checks the words first, then draws your buddy.';
  static const disclosureMore = 'More about this';
  static String pickedLabel(CreationRecipe recipe) =>
      recipe == CreationRecipe.pet ? 'Your pet photo' : 'Your drawing';
  static const makeIt = 'Make it!';

  static String buddyQuestion(AvatarBuddyKind kind) => switch (kind) {
    AvatarBuddyKind.creature => 'Who are they?',
    AvatarBuddyKind.colour => 'What colour?',
    AvatarBuddyKind.loves => 'What do they love?',
    AvatarBuddyKind.wears => 'What do they wear?',
    AvatarBuddyKind.power => 'What’s their superpower?',
  };
  static const buddyStart = 'Tap below to build your buddy.';
  static const surpriseMe = 'Surprise me';
  static const oneMoreThing = 'One more thing (if you like)';
  static const oneMoreThingHint = 'Like: spotty socks';
  static const hatchBuddy = 'Hatch my buddy!';

  static String buddySentence(AvatarBuddy buddy) {
    if (buddy.isEmpty) return buddyStart;
    final creature = buddy.word(AvatarBuddyKind.creature)?.label;
    final colour = buddy.word(AvatarBuddyKind.colour)?.label;
    final who = [?colour, creature ?? 'buddy'].join(' ').toLowerCase();
    final loves = buddy.word(AvatarBuddyKind.loves);
    final wears = buddy.word(AvatarBuddyKind.wears);
    final power = buddy.word(AvatarBuddyKind.power);
    final doing = [
      if (loves != null) 'loves ${loves.label.toLowerCase()}',
      if (wears != null) 'wears ${_wearing(wears.label.toLowerCase())}',
      if (power != null) _power(power),
    ];
    final sentence = '${_a(who)} $who';
    return doing.isEmpty ? sentence : '$sentence who ${_andList(doing)}';
  }

  static String _a(String word) =>
      RegExp('^[aeio]').hasMatch(word) ? 'An' : 'A';

  static String _wearing(String thing) =>
      thing.endsWith('s') ? thing : '${_a(thing).toLowerCase()} $thing';

  static String _andList(List<String> parts) => parts.length < 2
      ? parts.join()
      : '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';

  static String _power(AvatarChoiceWord power) => switch (power.id) {
    'flying' => 'can fly',
    'super-speed' => 'runs super fast',
    'invisible' => 'can turn invisible',
    'bubbles' => 'blows magic bubbles',
    'rainbows' => 'makes rainbows',
    'giggles' => 'gives everyone the giggles',
    'tiny' => 'can shrink tiny',
    'glow' => 'glows in the dark',
    'animal-talk' => 'talks to animals',
    'magic' => 'can do magic',
    _ => 'has ${power.label.toLowerCase()} powers',
  };

  static String hatching(CreationRecipe recipe) => switch (recipe) {
    CreationRecipe.drawing => 'Hatching your toy…',
    CreationRecipe.buddy => 'Hatching your buddy…',
    CreationRecipe.pet => 'Hatching your pet twin…',
    CreationRecipe.portrait => 'Painting your Nest portrait…',
  };
  static const waitBody = 'This usually takes about half a minute.';
  static const stepSending = 'Sending it';
  static String stepChecking(CreationRecipe recipe) => switch (recipe) {
    CreationRecipe.buddy => 'Checking the words',
    CreationRecipe.portrait => 'Gathering everyone',
    _ => 'Checking the picture',
  };
  static const stepDrawing = 'Drawing it';
  static const aiAtWork = 'NestPrep’s AI is making it';

  static String readyTitle(CreationRecipe recipe) => switch (recipe) {
    CreationRecipe.drawing => 'Your toy hatched!',
    CreationRecipe.buddy => 'Your buddy hatched!',
    CreationRecipe.pet => 'Your pet twin hatched!',
    CreationRecipe.portrait => 'Your Nest portrait is ready',
  };
  static const madeLabel = 'What our AI made';
  static const useIt = 'Use it';
  static const keepOnShelf = 'Keep it on the shelf';
  static const portraitOnFrame =
      'It’s on your frame’s slideshow now, and kept on your Keepsakes shelf.';
  static const done = 'Done';

  static const tooSlowTitle = 'Still hatching';
  static const tooSlowBody =
      'It’s taking longer than usual. When it’s ready, it will be waiting on '
      'the Keepsakes shelf.';
  static const seeShelf = 'See the shelf';

  static const refusedTitle = 'Not this time';
  static String refused(
    CreationRefusal reason,
    CreationRecipe recipe, {
    required String nextMonth,
    required bool canBuy,
  }) => switch (reason) {
    CreationRefusal.notAllowed => switch (recipe) {
      CreationRecipe.buddy => 'We can’t use those words. Try different ones.',
      CreationRecipe.pet =>
        'We need a photo of a pet for a pet twin — not people or other things.',
      _ => 'We can only use drawings, toys and pets — not photos of people.',
    },
    CreationRefusal.declined =>
      'That one didn’t come out right. Try another picture.',
    CreationRefusal.creationsOff =>
      'AI pictures are turned off in your household. A grown-up can turn '
          'them on under Stars.',
    CreationRefusal.limitReached => noneLeft(nextMonth),
    CreationRefusal.premiumRequired =>
      canBuy
          ? needsPremium
          : 'Making pictures is part of Premium. Ask a parent about it.',
    CreationRefusal.unavailable =>
      'The picture maker is having a rest. Try again in a little while.',
  };
  static const seePremium = 'See Premium';

  static const offTitle = 'AI pictures are off';
  static const offBody =
      'Turn them on to make toys, buddies and pet twins with our AI.';
  static const switchTitle = 'Let children make AI pictures';
  static const switchBody =
      'Drawings, buddies and pets made into pictures by Google’s AI. Off '
      'turns it off for everyone in the household.';

  static const yourShelf = 'Your keepsakes';
  static String shelfOf(String name) => '$name’s keepsakes';
  static const shelfBody = 'Each picture beside what it was made from.';
  static const then = 'Then';
  static const now = 'Now';
  static String originalLabel(CreationRecipe recipe) => switch (recipe) {
    CreationRecipe.pet => 'The pet photo',
    CreationRecipe.buddy => 'The words it was made from',
    _ => 'The drawing',
  };
  static const portraitLabel = 'Your Nest portrait';
  static const useAgain = 'Use again';
  static const wearing = 'Wearing it';
  static const delete = 'Delete';
  static const deleting = 'Deleting…';
  static const deleteConfirm = 'Delete this keepsake?';
  static const deleteBody =
      'The picture and what it was made from both go, for good. If it’s being '
      'worn, the initial comes back.';
  static const keepIt = 'Keep it';
  static const emptyTitle = 'Nothing on the shelf yet';
  static const emptyBody =
      'Everything you make lands here, beside what it was made from.';
  static const emptyAction = 'Make something';
}
