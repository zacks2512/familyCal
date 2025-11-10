import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../state/app_state.dart';
import '../models/entities.dart';
import '../services/firebase_repository.dart';
import '../services/firebase_auth_service.dart';

/// Provides a Firestore-backed FamilyCalState to descendants.
class FirestoreAppStateProvider extends StatefulWidget {
  const FirestoreAppStateProvider({super.key, required this.child});

  final Widget child;

  @override
  State<FirestoreAppStateProvider> createState() => _FirestoreAppStateProviderState();
}

class _FirestoreAppStateProviderState extends State<FirestoreAppStateProvider> {
  final _repo = FirebaseRepository();
  final _auth = FirebaseAuthService();

  final List<StreamSubscription> _subs = [];
  FamilyCalState? _state;
  String? _familyId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'User not authenticated';
        });
        return;
      }

      final familyId = await _repo.getCurrentUserFamilyId(createIfMissing: true);
      if (familyId == null || familyId.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No family found for user';
        });
        return;
      }
      _familyId = familyId;

      // Seed an initial state with the current user as sole member.
      final initialMember = FamilyMember(
        id: user.uid,
        displayName: user.displayName ?? (user.email ?? 'User'),
        email: user.email,
        isOwner: true,
        isPrimary: true,
      );
      _state = FamilyCalState(
        members: [initialMember],
        children: const [],
        places: const [],
        events: const [],
        confirmations: const [],
        currentMemberId: initialMember.id,
      );

      // Subscribe to members
      _subs.add(_repo.watchFamilyMembers(familyId).listen((members) {
        _state?.replaceMembers(members.isNotEmpty ? members : [initialMember]);
      }));

      // Subscribe to children
      _subs.add(_repo.watchChildren(familyId).listen((children) {
        _state?.replaceChildren(children);
      }));

      // Subscribe to events
      _subs.add(_repo.watchEvents(familyId).listen((events) {
        final mapped = events.map(_mapEvent).whereType<RecurringEvent>().toList();
        _state?.replaceEvents(mapped);
      }));

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  RecurringEvent? _mapEvent(Map<String, dynamic> data) {
    try {
      final roleName = (data['role'] as String?) ?? 'dropOff';
      final role = roleName == 'pickUp' ? EventRole.pickUp : EventRole.dropOff;
      final startTimeStr = data['start_time'] as String? ?? '08:00';
      final endTimeStr = data['end_time'] as String? ?? '09:00';

      TimeOfDay parseTime(String s) {
        final parts = s.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return TimeOfDay(hour: h, minute: m);
      }

      final startTime = parseTime(startTimeStr);
      final endTime = parseTime(endTimeStr);

      final startDate = (data['start_date'] as Timestamp).toDate();
      final endDateTs = data['end_date'];
      final endDate = endDateTs is Timestamp ? endDateTs.toDate() : null;
      final weekdays = Set<int>.from((data['weekdays'] as List).map((e) => e as int));

      return RecurringEvent(
        id: data['id'] as String,
        childId: data['child_id'] as String,
        placeId: (data['place'] as String?) ?? 'unknown',
        role: role,
        responsibleMemberId: data['responsible_member_id'] as String?,
        startTime: startTime,
        endTime: endTime,
        weekdays: weekdays,
        startDate: startDate,
        endDate: endDate,
        title: data['title'] as String?,
        notes: data['notes'] as String?,
        reminderMinutes: List<int>.from((data['reminder_minutes'] as List?) ?? const [15]),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }
    final state = _state!;
    return ChangeNotifierProvider<FamilyCalState>.value(
      value: state,
      child: widget.child,
    );
  }
}


