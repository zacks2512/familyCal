import 'dart:math';

import 'package:flutter/material.dart';

import '../models/entities.dart';

enum CalendarViewMode { day, week, month }

class FamilyCalState extends ChangeNotifier {
  FamilyCalState({
    required List<FamilyMember> members,
    required List<FamilyChild> children,
    required List<FamilyPlace> places,
    required List<RecurringEvent> events,
    List<ConfirmationLog>? confirmations,
    String? currentMemberId,
  })  : _members = List.unmodifiable(members),
        _children = List.of(children),
        _places = List.of(places),
        _events = List.of(events),
        _confirmations = List.of(confirmations ?? []),
        _currentMemberId = currentMemberId ?? members.first.id;

  final List<FamilyMember> _members;
  final List<FamilyChild> _children;
  final List<FamilyPlace> _places;
  final List<RecurringEvent> _events;
  final List<ConfirmationLog> _confirmations;

  String _currentMemberId;
  DateTime _selectedCalendarDay = DateUtils.dateOnly(DateTime.now());
  CalendarViewMode _calendarViewMode = CalendarViewMode.month;
  DateTime _visibleMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  /// Exposed getters
  List<FamilyMember> get members => _members;
  List<FamilyChild> get children => List.unmodifiable(_children);
  List<FamilyPlace> get places => List.unmodifiable(_places);
  List<RecurringEvent> get events => List.unmodifiable(_events);
  List<ConfirmationLog> get confirmations => List.unmodifiable(_confirmations);
  String get currentMemberId => _currentMemberId;
  FamilyMember get currentMember =>
      _members.firstWhere((member) => member.id == _currentMemberId);
  DateTime get selectedCalendarDay => _selectedCalendarDay;
  CalendarViewMode get calendarViewMode => _calendarViewMode;
  DateTime get visibleMonth => _visibleMonth;

  void selectCalendarDay(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    if (normalized == _selectedCalendarDay) {
      return;
    }
    _selectedCalendarDay = normalized;
    _visibleMonth = DateTime(normalized.year, normalized.month);
    notifyListeners();
  }

  void setCalendarViewMode(CalendarViewMode mode) {
    if (_calendarViewMode == mode) {
      return;
    }
    _calendarViewMode = mode;
    notifyListeners();
  }

  void setVisibleMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    if (_visibleMonth.year == normalized.year &&
        _visibleMonth.month == normalized.month) {
      return;
    }
    _visibleMonth = normalized;
    notifyListeners();
  }

  void jumpMonth(int offset) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    setVisibleMonth(nextMonth);
    if (!DateUtils.isSameMonth(_selectedCalendarDay, nextMonth)) {
      _selectedCalendarDay = DateTime(nextMonth.year, nextMonth.month, 1);
      notifyListeners();
    }
  }

  void jumpToToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    _selectedCalendarDay = today;
    _visibleMonth = DateTime(today.year, today.month);
    notifyListeners();
  }

  List<EventInstance> instancesForDay(DateTime date) {
    final instances = _events
        .where((event) => event.occursOn(date))
        .map((event) => event.toInstanceOn(date))
        .toList();
    instances.sort(
      (a, b) => a.windowStart.compareTo(b.windowStart),
    );
    return instances;
  }

  List<EventInstance> nowAndNextInstances(DateTime now) {
    final todayInstances = instancesForDay(now);
    final upcoming = todayInstances.where((instance) {
      if (isConfirmed(instance)) {
        return false;
      }
      return !instance.windowExpired(now);
    }).toList();
    upcoming.sort((a, b) {
      final aActive = instanceIsActive(a, now) ? 0 : 1;
      final bActive = instanceIsActive(b, now) ? 0 : 1;
      if (aActive != bActive) {
        return aActive.compareTo(bActive);
      }
      return a.windowStart.compareTo(b.windowStart);
    });
    return upcoming;
  }

  List<EventInstance> agendaFor(DateTime anchorDay) {
    final today = DateUtils.dateOnly(anchorDay);
    final tomorrow = today.add(const Duration(days: 1));
    final items = [
      ...instancesForDay(today),
      ...instancesForDay(tomorrow),
    ];
    items.sort((a, b) => a.windowStart.compareTo(b.windowStart));
    return items;
  }

  bool instanceIsActive(EventInstance instance, DateTime now) {
    return !now.isBefore(instance.windowStart) && !now.isAfter(instance.windowEnd);
  }

  bool isConfirmed(EventInstance instance) {
    return findConfirmation(instance) != null;
  }

  ConfirmationLog? findConfirmation(EventInstance instance) {
    for (final log in _confirmations) {
      if (log.eventId == instance.event.id &&
          log.windowStart.isAtSameMomentAs(instance.windowStart)) {
        return log;
      }
    }
    return null;
  }

  void confirmOccurrence(
    EventInstance instance, {
    required String confirmedById,
    bool geoOk = true,
    bool offline = false,
    String? note,
  }) {
    if (isConfirmed(instance)) {
      return;
    }
    final log = ConfirmationLog(
      id: _generateId(),
      eventId: instance.event.id,
      childId: instance.event.childId,
      placeId: instance.event.placeId,
      responsibleMemberId: instance.event.responsibleMemberId,
      windowStart: instance.windowStart,
      confirmedById: confirmedById,
      confirmedAt: DateTime.now(),
      geoOk: geoOk,
      offline: offline,
      note: note,
    );
    _confirmations.add(log);
    notifyListeners();
  }

  void recordMissed(EventInstance instance) {
    if (isConfirmed(instance)) {
      return;
    }
    final log = ConfirmationLog(
      id: _generateId(),
      eventId: instance.event.id,
      childId: instance.event.childId,
      placeId: instance.event.placeId,
      responsibleMemberId: instance.event.responsibleMemberId,
      windowStart: instance.windowStart,
      confirmedById:
          instance.event.responsibleMemberId ?? _currentMemberId,
      confirmedAt: instance.windowEnd,
      geoOk: false,
      offline: false,
      note: 'Missed window',
    );
    _confirmations.add(log);
    notifyListeners();
  }

  void switchCurrentMember(String memberId) {
    if (memberId == _currentMemberId) {
      return;
    }
    _currentMemberId = memberId;
    notifyListeners();
  }

  FamilyChild childById(String id) =>
      _children.firstWhere((child) => child.id == id);

  FamilyPlace placeById(String id) =>
      _places.firstWhere((place) => place.id == id);

  FamilyMember memberById(String id) =>
      _members.firstWhere((member) => member.id == id);

  FamilyMember? memberByIdOrNull(String? id) {
    if (id == null) {
      return null;
    }
    for (final member in _members) {
      if (member.id == id) {
        return member;
      }
    }
    return null;
  }

  void addChild(FamilyChild child) {
    _children.add(child);
    notifyListeners();
  }

  void addPlace(FamilyPlace place) {
    _places.add(place);
    notifyListeners();
  }

  void updatePlace(FamilyPlace place) {
    final index = _places.indexWhere((element) => element.id == place.id);
    if (index == -1) {
      return;
    }
    _places[index] = place;
    notifyListeners();
  }

  void addEvent(RecurringEvent event) {
    _events.add(event);
    notifyListeners();
  }

  List<ConfirmationLog> logsForChildAndMonth(
    String? childId,
    DateTime month, {
    String? responsibleId,
  }) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _confirmations.where((log) {
      if (childId != null && log.childId != childId) {
        return false;
      }
      if (responsibleId != null && log.responsibleMemberId != responsibleId) {
        return false;
      }
      return !log.windowStart.isBefore(start) && log.windowStart.isBefore(end);
    }).toList()
      ..sort((a, b) => b.windowStart.compareTo(a.windowStart));
  }

  String _generateId() {
    final random = Random();
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buffer.write(random.nextInt(36).toRadixString(36));
    }
    return buffer.toString();
  }
}
