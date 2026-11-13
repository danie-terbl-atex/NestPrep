import 'avatar_catalogue.g.dart';

AvatarHemisphere avatarHemisphereOf(String timeZone) =>
    _southernZones.contains(timeZone) ||
        _southernPrefixes.any(timeZone.startsWith)
    ? AvatarHemisphere.south
    : AvatarHemisphere.north;

const _southernPrefixes = ['Australia/', 'America/Argentina/', 'Antarctica/'];

const _southernZones = {
  'Africa/Johannesburg',
  'Africa/Maseru',
  'Africa/Mbabane',
  'Africa/Windhoek',
  'Africa/Gaborone',
  'Africa/Harare',
  'Africa/Lusaka',
  'Africa/Maputo',
  'Africa/Blantyre',
  'Africa/Lubumbashi',
  'Africa/Luanda',
  'Africa/Dar_es_Salaam',
  'Africa/Kigali',
  'Africa/Bujumbura',
  'Indian/Antananarivo',
  'Indian/Mauritius',
  'Indian/Reunion',
  'Indian/Mayotte',
  'Indian/Comoro',
  'Pacific/Auckland',
  'Pacific/Chatham',
  'Pacific/Fiji',
  'Pacific/Tongatapu',
  'Pacific/Apia',
  'Pacific/Noumea',
  'Pacific/Port_Moresby',
  'Pacific/Tahiti',
  'America/Sao_Paulo',
  'America/Santiago',
  'America/Montevideo',
  'America/Asuncion',
  'America/La_Paz',
  'America/Lima',
  'Asia/Jakarta',
  'Atlantic/St_Helena',
};
