import 'avatar_catalogue.g.dart';

final class AvatarLibrary {
  AvatarLibrary({
    required this.nestlings,
    required this.accessories,
    required this.moments,
  }) : _nestlings = {for (final nestling in nestlings) nestling.name: nestling},
       _accessories = {
         for (final accessory in accessories) accessory.id: accessory,
       };

  static final bundled = AvatarLibrary(
    nestlings: avatarNestlings,
    accessories: avatarAccessories,
    moments: avatarMoments,
  );

  final List<AvatarNestling> nestlings;
  final List<AvatarAccessory> accessories;
  final List<AvatarMoment> moments;
  final Map<String, AvatarNestling> _nestlings;
  final Map<String, AvatarAccessory> _accessories;

  AvatarNestling? nestling(String name) => _nestlings[name];

  AvatarAccessory? accessory(String id) => _accessories[id];

  List<AvatarAccessory> on(AvatarSlot slot, {required bool hasFace}) => [
    for (final accessory in accessories)
      if (accessory.slot == slot && (hasFace || slot != AvatarSlot.face))
        accessory,
  ];
}

extension AvatarAccessoryPrice on AvatarAccessory {
  bool get isFree => stars == 0;
}
