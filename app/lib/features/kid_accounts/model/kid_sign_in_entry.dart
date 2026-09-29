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

  /// A new device only for a profile that may still have one, and room for it.
  bool get canAddDevice => isEligible(member) && devices.length < deviceLimit;

  /// Unclaimed, and a kid (accounts ADR-0004).
  static bool isEligible(Member member) =>
      !member.isClaimed && member.role.canHaveKidSignIn;

  /// Every profile that may have a kid sign-in — unclaimed, and a kid — with
  /// its devices, in the household's own order. A profile that has devices
  /// but is no longer eligible (moved to another role, or claimed) stays on
  /// the list so a parent can still sign its devices out; it offers no new
  /// one. The server decides who is eligible; this only chooses whom to offer
  /// (`FE-04`).
  static List<KidSignInEntry> from({
    required List<Member> members,
    required List<KidDevice> devices,
  }) => [
    for (final member in members)
      if (_devicesOf(member, devices) case final own
          when isEligible(member) || own.isNotEmpty)
        KidSignInEntry(member: member, devices: own),
  ];

  /// Newest first, so the device just paired is at the top.
  static List<KidDevice> _devicesOf(Member member, List<KidDevice> devices) =>
      [
        for (final device in devices)
          if (device.memberId == member.id) device,
      ]..sort(
        (a, b) =>
            (b.pairedAt ?? DateTime(0)).compareTo(a.pairedAt ?? DateTime(0)),
      );
}
