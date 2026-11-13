import 'dart:io';
import 'dart:typed_data';

/// `pageLink` only checks names, and any web page can open
/// `nestprep://share?url=`: a public name may still answer with a router's
/// address.
bool isPublicAddress(InternetAddress address) {
  final raw = address.rawAddress;
  return raw.length == 4 ? _isPublicV4(raw) : _isPublicV6(raw);
}

bool _isPublicV4(List<int> ip) {
  final [a, b, c, _] = ip;
  return switch (a) {
    0 || 10 || 127 => false,
    100 when b >= 64 && b <= 127 => false,
    169 when b == 254 => false,
    172 when b >= 16 && b <= 31 => false,
    192 when b == 168 || (b == 0 && (c == 0 || c == 2)) => false,
    198 when b == 18 || b == 19 || (b == 51 && c == 100) => false,
    203 when b == 0 && c == 113 => false,
    >= 224 => false,
    _ => true,
  };
}

bool _isPublicV6(Uint8List ip) {
  final leadingZeros = ip.takeWhile((byte) => byte == 0).length;
  if (leadingZeros >= 15) return false;
  if (leadingZeros >= 12) return _isPublicV4(ip.sublist(12));
  if (leadingZeros == 10 && ip[10] == 0xff && ip[11] == 0xff) {
    return _isPublicV4(ip.sublist(12));
  }
  final isNat64 =
      ip[0] == 0x00 &&
      ip[1] == 0x64 &&
      ip[2] == 0xff &&
      ip[3] == 0x9b &&
      ip.sublist(4, 12).every((byte) => byte == 0);
  if (isNat64) return _isPublicV4(ip.sublist(12));
  if (ip[0] == 0x20 && ip[1] == 0x02) return _isPublicV4(ip.sublist(2, 6));
  if (ip[0] == 0x20 && ip[1] == 0x01 && ip[2] == 0x0d && ip[3] == 0xb8) {
    return false;
  }
  if (ip[0] == 0xff) return false;
  if (ip[0] & 0xfe == 0xfc) return false;
  return !(ip[0] == 0xfe && ip[1] & 0x80 == 0x80);
}
