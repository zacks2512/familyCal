import 'package:flutter/material.dart';

enum EventRole { dropOff, pickUp }

extension EventRoleDisplay on EventRole {
  String get label => switch (this) {
        EventRole.dropOff => 'Drop-off',
        EventRole.pickUp => 'Pick-up',
      };

  IconData get icon => switch (this) {
        EventRole.dropOff => Icons.backpack,
        EventRole.pickUp => Icons.directions_car,
      };

  Color get color => switch (this) {
        EventRole.dropOff => const Color(0xFF3B82F6),
        EventRole.pickUp => const Color(0xFF22C55E),
      };
}

@immutable
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.displayName,
    this.email,
    this.phone,
    this.isOwner = false,
    this.isPrimary = false,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? phone;
  final bool isOwner;
  final bool isPrimary;
}

@immutable
class FamilyChild {
  const FamilyChild({
    required this.id,
    required this.displayName,
    required this.color,
    this.allergies,
    this.birthDate,
  });

  final String id;
  final String displayName;
  final Color color;
  final String? allergies;
  final DateTime? birthDate;
}

@immutable
class FamilyPlace {
  const FamilyPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.radiusMeters,
    this.latitude,
    this.longitude,
    this.notes,
  });

  final String id;
  final String name;
  final String address;
  final int radiusMeters;
  final double? latitude;
  final double? longitude;
  final String? notes;

  FamilyPlace copyWith({
    String? name,
    String? address,
    int? radiusMeters,
    double? latitude,
    double? longitude,
    String? notes,
  }) {
    return FamilyPlace(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
    );
  }
}

@immutable
class RecurringEvent {
  RecurringEvent({
    required this.id,
    required this.childId,
    required this.placeId,
    required this.role,
    required this.startTime,
    required this.endTime,
    required this.weekdays,
    required this.startDate,
    this.responsibleMemberId,
    this.title,
    this.endDate,
    this.notes,
    this.reminderMinutes = const [15],
  }) : assert(weekdays.length <= 7 && weekdays.isNotEmpty);

  final String id;
  final String childId;
  final String placeId;
  final EventRole role;
  final String? responsibleMemberId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Set<int> weekdays;
  final DateTime startDate;
  final String? title;
  final DateTime? endDate;
  final String? notes;
  final List<int> reminderMinutes;

  bool occursOn(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    final normalizedStart = DateUtils.dateOnly(startDate);
    if (normalized.isBefore(normalizedStart)) {
      return false;
    }
    if (endDate != null && normalized.isAfter(DateUtils.dateOnly(endDate!))) {
      return false;
    }
    return weekdays.contains(normalized.weekday);
  }

  EventInstance toInstanceOn(DateTime date) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );
    return EventInstance(event: this, windowStart: start, windowEnd: end);
  }
}

@immutable
class EventInstance {
  const EventInstance({
    required this.event,
    required this.windowStart,
    required this.windowEnd,
  });

  final RecurringEvent event;
  final DateTime windowStart;
  final DateTime windowEnd;

  Duration get duration => windowEnd.difference(windowStart);

  bool windowOpenAt(DateTime now) {
    return !now.isBefore(windowStart) && !now.isAfter(windowEnd);
  }

  bool windowExpired(DateTime now) {
    return now.isAfter(windowEnd);
  }

  bool isUpcoming(DateTime now) {
    return now.isBefore(windowStart);
  }
}

@immutable
class ConfirmationLog {
  const ConfirmationLog({
    required this.id,
    required this.eventId,
    required this.childId,
    required this.placeId,
    this.responsibleMemberId,
    required this.windowStart,
    required this.confirmedById,
    required this.confirmedAt,
    this.geoOk = true,
    this.offline = false,
    this.note,
  });

  final String id;
  final String eventId;
  final String childId;
  final String placeId;
  final String? responsibleMemberId;
  final DateTime windowStart;
  final String confirmedById;
  final DateTime confirmedAt;
  final bool geoOk;
  final bool offline;
  final String? note;
}
