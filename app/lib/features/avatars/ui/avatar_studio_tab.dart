import '../../../shared/copy/avatar_copy.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../../subscriptions/model/premium_feature.dart';

enum AvatarStudioTab {
  nestlings(AvatarCopy.nestlings),
  photo(AvatarCopy.photo),
  wardrobe(AvatarCopy.wardrobe),
  create(AvatarCreationCopy.createTab),
  keepsakes(AvatarCreationCopy.keepsakesTab);

  const AvatarStudioTab(this.label);

  final String label;

  static const always = [nestlings, photo, wardrobe];

  PremiumFeature? get premiumFeature => switch (this) {
    nestlings || photo => null,
    wardrobe => PremiumFeature.avatarWardrobe,
    create => PremiumFeature.avatarCreate,
    keepsakes => PremiumFeature.avatarKeepsakes,
  };

  static AvatarStudioTab fromName(String? name) =>
      values.firstWhere((tab) => tab.name == name, orElse: () => nestlings);
}
