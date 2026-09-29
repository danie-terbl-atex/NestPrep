// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShiftBooking _$ShiftBookingFromJson(Map<String, dynamic> json) =>
    _ShiftBooking(
      id: json['id'] as String,
      carerMemberId: json['carerMemberId'] as String,
      startsAt: const InstantConverter().fromJson(json['startsAt']),
      endsAt: const InstantConverter().fromJson(json['endsAt']),
      note: json['note'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$ShiftBookingToJson(_ShiftBooking instance) =>
    <String, dynamic>{
      'carerMemberId': instance.carerMemberId,
      'startsAt': const InstantConverter().toJson(instance.startsAt),
      'endsAt': const InstantConverter().toJson(instance.endsAt),
      'note': instance.note,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
