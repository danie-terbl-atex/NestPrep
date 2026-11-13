const pageLinkMax = 2048;

const _privateSuffixes = [
  '.localhost',
  '.local',
  '.lan',
  '.home',
  '.internal',
  '.intranet',
  '.corp',
  '.home.arpa',
  '.arpa',
];

final _forbiddenInHost = RegExp(r'[\x00-\x20\x7f#/:<>?@\[\\\]^|%]');
final _numberLabel = RegExp(r'^(\d+|0[xX][0-9a-fA-F]*)$');
final _edgeSpace = RegExp(r'^[\x00-\x20]+|[\x00-\x20]+$');
final _tabOrNewline = RegExp(r'[\t\n\r]');

bool isPublicPageLink(String raw) => pageLink(raw) != null;

/// The server's `pageLink`, `shared/page_link.ts`. Dart's `Uri` is not the
/// WHATWG parser the server has, so the differences that matter are made up
/// here: the path a bare host gets, punycode, and numbers that are addresses.
String? pageLink(String raw) {
  final url = Uri.tryParse(
    raw.replaceAll(_edgeSpace, '').replaceAll(_tabOrNewline, ''),
  );
  if (url == null || !(url.isScheme('http') || url.isScheme('https'))) {
    return null;
  }
  if (url.userInfo.isNotEmpty || url.hasPort) return null;
  final host = _asciiHost(url.host);
  if (host == null || !_isPublicHost(host)) return null;
  final href = url
      .replace(host: host, path: url.path.isEmpty ? '/' : url.path)
      .toString();
  return href.length > pageLinkMax ? null : href;
}

String siteNameOf(String link) =>
    Uri.parse(link).host.replaceFirst(RegExp(r'^www\.'), '');

String? _asciiHost(String host) {
  final String decoded;
  try {
    decoded = Uri.decodeComponent(host).toLowerCase();
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
  if (decoded.isEmpty || _forbiddenInHost.hasMatch(decoded)) return null;
  return decoded
      .split('.')
      .map((label) => _isAscii(label) ? label : 'xn--${_punycode(label)}')
      .join('.');
}

bool _isPublicHost(String hostname) {
  final host = hostname.endsWith('.')
      ? hostname.substring(0, hostname.length - 1)
      : hostname;
  if (!host.contains('.') || host == 'localhost') return false;
  if (_numberLabel.hasMatch(host.split('.').last)) return false;
  return !_privateSuffixes.any(host.endsWith);
}

bool _isAscii(String text) => text.codeUnits.every((unit) => unit < 0x80);

const _base = 36;
const _tMin = 1;
const _tMax = 26;

/// RFC 3492. Dart has none, and `HttpClient` cannot look up a Unicode name.
String _punycode(String label) {
  final points = label.runes.toList();
  final output = StringBuffer(
    String.fromCharCodes(points.where((point) => point < 0x80)),
  );
  final basic = output.length;
  if (basic > 0) output.write('-');
  var next = 0x80;
  var delta = 0;
  var bias = 72;
  var handled = basic;
  while (handled < points.length) {
    final smallest = points
        .where((point) => point >= next)
        .reduce((a, b) => a < b ? a : b);
    delta += (smallest - next) * (handled + 1);
    next = smallest;
    for (final point in points) {
      if (point < next) delta++;
      if (point != next) continue;
      var rest = delta;
      for (var k = _base; ; k += _base) {
        final threshold = k <= bias
            ? _tMin
            : (k >= bias + _tMax ? _tMax : k - bias);
        if (rest < threshold) break;
        output.writeCharCode(
          _digit(threshold + (rest - threshold) % (_base - threshold)),
        );
        rest = (rest - threshold) ~/ (_base - threshold);
      }
      output.writeCharCode(_digit(rest));
      bias = _adapted(delta, handled + 1, isFirst: handled == basic);
      delta = 0;
      handled++;
    }
    delta++;
    next++;
  }
  return output.toString();
}

int _digit(int value) => value < 26 ? value + 0x61 : value - 26 + 0x30;

int _adapted(int delta, int points, {required bool isFirst}) {
  var scaled = isFirst ? delta ~/ 700 : delta ~/ 2;
  scaled += scaled ~/ points;
  var k = 0;
  while (scaled > ((_base - _tMin) * _tMax) ~/ 2) {
    scaled ~/= _base - _tMin;
    k += _base;
  }
  return k + (_base - _tMin + 1) * scaled ~/ (scaled + 38);
}
