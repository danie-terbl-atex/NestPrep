import '../../household/model/member.dart';
import 'kid_device.dart';

/// One child on the parent's kid sign-in screen, with the devices signed in as
/// them (accounts ADR-0003).
class KidSignInEntry {
  const KidSignInEntry({required this.member, required this.devices});

  final Member member;

  /// Newest first, so the device just paired is at the top.
  final List<KidDevice> devices;

  /// Mirrors the Functions' `KID_DEVICE_LIMIT`, which is what enforces it.
  static const deviceLimit = 5;

  bool get canAddDevice => devices.length < deviceLimit;

  /// Every profile that may have a kid sign-in — unclaimed, and a child's role
  /// — with its devices, in the household's own order. The server decides who
  /// is eligible; this only chooses whom to offer (`FE-04`).
  static List<KidSignInEntry> from({
    required List<Member> members,
    required List<KidDevice> devices,
  }) => [
    for (final member in members)
      if (!member.isClaimed && member.role.canHaveKidSignIn)
        KidSignInEntry(
          member: member,
          devices:
              [
                for (final device in devices)
                  if (device.memberId == member.id) device,
              ]..sort(
                (a, b) => (b.pairedAt ?? DateTime(0)).compareTo(
                  a.pairedAt ?? DateTime(0),
                ),
              ),
        ),
  ];
}
