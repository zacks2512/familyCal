import 'package:flutter/material.dart';

import '../models/entities.dart';
import '../state/app_state.dart';

FamilyCalState createMockState() {
  final members = <FamilyMember>[
    const FamilyMember(
      id: 'alex',
      displayName: 'Alex Rivera',
      email: 'alex@example.com',
      phone: '+1 555 111 2233',
      isOwner: true,
      isPrimary: true,
    ),
    const FamilyMember(
      id: 'jamie',
      displayName: 'Jamie Rivera',
      email: 'jamie@example.com',
      phone: '+1 555 222 3344',
    ),
  ];

  final children = <FamilyChild>[
    FamilyChild(
      id: 'mia',
      displayName: 'Mia',
      color: Colors.pink.shade300,
      birthDate: DateTime(2016, 3, 12),
    ),
    FamilyChild(
      id: 'noah',
      displayName: 'Noah',
      color: Colors.orange.shade400,
      birthDate: DateTime(2018, 11, 2),
    ),
  ];

  final places = <FamilyPlace>[
    const FamilyPlace(
      id: 'school',
      name: 'Sunrise Montessori',
      address: '1250 Park Ave',
      radiusMeters: 150,
      latitude: 37.7788,
      longitude: -122.4194,
    ),
    const FamilyPlace(
      id: 'gym',
      name: 'Jumpstart Gym',
      address: '350 Main St',
      radiusMeters: 120,
    ),
    const FamilyPlace(
      id: 'home',
      name: 'Rivera Home',
      address: '824 Grove St',
      radiusMeters: 80,
    ),
  ];

  final now = DateTime.now();
  final currentYear = now.year;
  final currentMonth = now.month;
  
  final recurringEvents = <RecurringEvent>[
    RecurringEvent(
      id: 'event-mia-drop',
      childId: 'mia',
      placeId: 'school',
      role: EventRole.dropOff,
      responsibleMemberId: 'alex',
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 8, minute: 40),
      weekdays: {DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday},
      startDate: DateTime(currentYear, currentMonth, 1),
      notes: 'Take backpack & allergy meds on Mondays.',
    ),
    RecurringEvent(
      id: 'event-mia-pick',
      childId: 'mia',
      placeId: 'school',
      role: EventRole.pickUp,
      responsibleMemberId: 'jamie',
      startTime: const TimeOfDay(hour: 15, minute: 0),
      endTime: const TimeOfDay(hour: 15, minute: 30),
      weekdays: {DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday},
      startDate: DateTime(currentYear, currentMonth, 1),
    ),
    RecurringEvent(
      id: 'event-noah-gym',
      childId: 'noah',
      placeId: 'gym',
      role: EventRole.pickUp,
      responsibleMemberId: 'alex',
      startTime: const TimeOfDay(hour: 17, minute: 15),
      endTime: const TimeOfDay(hour: 17, minute: 45),
      weekdays: {DateTime.tuesday},
      startDate: DateTime(currentYear, currentMonth, 1),
      notes: 'Bring water bottle.',
    ),
  ];

  final today = DateUtils.dateOnly(DateTime.now());
  final initialConfirmations = <ConfirmationLog>[
    ConfirmationLog(
      id: 'log-1',
      eventId: 'event-mia-drop',
      childId: 'mia',
      placeId: 'school',
      responsibleMemberId: 'alex',
      windowStart: today.subtract(const Duration(days: 1)).add(const Duration(hours: 8)),
      confirmedById: 'alex',
      confirmedAt: today.subtract(const Duration(days: 1)).add(const Duration(hours: 8, minutes: 12)),
      geoOk: true,
      offline: false,
    ),
    ConfirmationLog(
      id: 'log-2',
      eventId: 'event-mia-pick',
      childId: 'mia',
      placeId: 'school',
      responsibleMemberId: 'jamie',
      windowStart: today.subtract(const Duration(days: 1)).add(const Duration(hours: 15)),
      confirmedById: 'jamie',
      confirmedAt: today.subtract(const Duration(days: 1)).add(const Duration(hours: 15, minutes: 22)),
      geoOk: false,
      offline: true,
      note: 'Garage GPS was weak',
    ),
  ];

  return FamilyCalState(
    members: members,
    children: children,
    places: places,
    events: recurringEvents,
    confirmations: initialConfirmations,
    currentMemberId: 'alex',
  );
}
