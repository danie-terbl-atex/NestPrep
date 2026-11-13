import '../../../shared/copy/avatar_copy.dart';
import '../../../shared/copy/avatar_creation_copy.dart';

enum AvatarStudioTab {
  nestlings(AvatarCopy.nestlings),
  photo(AvatarCopy.photo),
  wardrobe(AvatarCopy.wardrobe),
  create(AvatarCreationCopy.createTab),
  keepsakes(AvatarCreationCopy.keepsakesTab);

  const AvatarStudioTab(this.label);

  final String label;

  static const always = [nestlings, photo, wardrobe];

  static AvatarStudioTab fromName(String? name) =>
      values.firstWhere((tab) => tab.name == name, orElse: () => nestlings);
}
