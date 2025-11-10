import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/entities.dart';
import 'dart:async';

/// Repository for Firebase data operations
class FirebaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? get currentUserId => _auth.currentUser?.uid;
  
  // ==================== FAMILIES ====================
  
  /// Create a new family
  Future<String> createFamily(String ownerName) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    final familyRef = _firestore.collection('families').doc();
    final familyId = familyRef.id;
    
    final batch = _firestore.batch();
    
    // Create family
    batch.set(familyRef, {
      'id': familyId,
      'owner_id': userId,
      'member_ids': [userId],
      'created_at': FieldValue.serverTimestamp(),
      'settings': {
        'timezone': 'UTC',
        'locale': 'en',
      },
    });
    
    // Create user document
    batch.set(_firestore.collection('users').doc(userId), {
      'id': userId,
      'family_id': familyId,
      'display_name': ownerName,
      'created_at': FieldValue.serverTimestamp(),
      'settings': {
        'calendar_sync_enabled': true,
        'calendar_id': null,
        'notifications': {
          'assignments': true,
          'confirmations': true,
          'unassigned_alerts': true,
        },
      },
    });
    
    await batch.commit();
    
    debugPrint('✅ Created family: $familyId');
    return familyId;
  }
  
  /// Get family data
  Future<Map<String, dynamic>?> getFamily(String familyId) async {
    final doc = await _firestore.collection('families').doc(familyId).get();
    return doc.data();
  }
  
  /// Listen to family changes
  Stream<Map<String, dynamic>?> watchFamily(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
  
  // ==================== CHILDREN ====================
  
  /// Add a child to family
  Future<String> addChild({
    required String familyId,
    required String name,
    required String color,
    DateTime? birthDate,
    String? allergies,
  }) async {
    final docRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc();
    
    await docRef.set({
      'id': docRef.id,
      'display_name': name,
      'color': color,
      'birth_date': birthDate != null ? Timestamp.fromDate(birthDate) : null,
      'allergies': allergies,
      'created_at': FieldValue.serverTimestamp(),
    });
    
    debugPrint('✅ Added child: ${docRef.id}');
    return docRef.id;
  }
  
  /// Update child
  Future<void> updateChild({
    required String familyId,
    required String childId,
    String? name,
    String? color,
    DateTime? birthDate,
    String? allergies,
  }) async {
    final updates = <String, dynamic>{};
    
    if (name != null) updates['display_name'] = name;
    if (color != null) updates['color'] = color;
    if (birthDate != null) updates['birth_date'] = Timestamp.fromDate(birthDate);
    if (allergies != null) updates['allergies'] = allergies;
    
    if (updates.isNotEmpty) {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('children')
          .doc(childId)
          .update(updates);
      
      debugPrint('✅ Updated child: $childId');
    }
  }
  
  /// Delete child
  Future<void> deleteChild(String familyId, String childId) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .delete();
    
    debugPrint('🗑️ Deleted child: $childId');
  }
  
  /// Listen to children
  Stream<List<FamilyChild>> watchChildren(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .orderBy('created_at')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FamilyChild(
          id: doc.id,
          displayName: data['display_name'] as String,
          color: _parseColor(data['color'] as String),
          birthDate: data['birth_date'] != null
              ? (data['birth_date'] as Timestamp).toDate()
              : null,
          allergies: data['allergies'] as String?,
        );
      }).toList();
    });
  }
  
  // ==================== EVENTS ====================
  
  /// Create event
  Future<String> createEvent({
    required String familyId,
    required String childId,
    required String place,
    required EventRole role,
    required String startTime,
    required String endTime,
    required DateTime startDate,
    required List<int> weekdays,
    String? responsibleMemberId,
    DateTime? endDate,
    String? title,
    String? notes,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    final docRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .doc();
    
    await docRef.set({
      'id': docRef.id,
      'family_id': familyId,
      'child_id': childId,
      'place': place,
      'role': role.name,
      'responsible_member_id': responsibleMemberId,
      'start_time': startTime,
      'end_time': endTime,
      'weekdays': weekdays,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': endDate != null ? Timestamp.fromDate(endDate) : null,
      'title': title,
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'created_by': userId,
      'calendar_synced_for': {},
    });
    
    debugPrint('✅ Created event: ${docRef.id}');
    return docRef.id;
  }
  
  /// Update event
  Future<void> updateEvent({
    required String familyId,
    required String eventId,
    String? childId,
    String? place,
    EventRole? role,
    String? responsibleMemberId,
    String? startTime,
    String? endTime,
    DateTime? startDate,
    List<int>? weekdays,
    DateTime? endDate,
    String? title,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
    };
    
    if (childId != null) updates['child_id'] = childId;
    if (place != null) updates['place'] = place;
    if (role != null) updates['role'] = role.name;
    if (responsibleMemberId != null) {
      updates['responsible_member_id'] = responsibleMemberId;
    }
    if (startTime != null) updates['start_time'] = startTime;
    if (endTime != null) updates['end_time'] = endTime;
    if (startDate != null) updates['start_date'] = Timestamp.fromDate(startDate);
    if (weekdays != null) updates['weekdays'] = weekdays;
    if (endDate != null) {
      updates['end_date'] = Timestamp.fromDate(endDate);
    }
    if (title != null) updates['title'] = title;
    if (notes != null) updates['notes'] = notes;
    
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .doc(eventId)
        .update(updates);
    
    debugPrint('✅ Updated event: $eventId');
  }
  
  /// Delete event
  Future<void> deleteEvent(String familyId, String eventId) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .doc(eventId)
        .delete();
    
    debugPrint('🗑️ Deleted event: $eventId');
  }
  
  /// Listen to events
  Stream<List<Map<String, dynamic>>> watchEvents(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .orderBy('start_date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
  
  /// Get events in date range
  Future<List<Map<String, dynamic>>> getEventsInRange({
    required String familyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .where('start_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('start_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('start_date')
        .get();
    
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
  
  // ==================== CONFIRMATIONS ====================
  
  /// Create confirmation
  Future<String> createConfirmation({
    required String familyId,
    required String eventId,
    required String childId,
    required String place,
    required EventRole role,
    required DateTime windowStart,
    String? responsibleMemberId,
    String? note,
    bool offlineQueued = false,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    final docRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('confirmations')
        .doc();
    
    await docRef.set({
      'id': docRef.id,
      'family_id': familyId,
      'event_id': eventId,
      'child_id': childId,
      'place': place,
      'role': role.name,
      'responsible_member_id': responsibleMemberId,
      'confirmed_by_id': userId,
      'window_start': Timestamp.fromDate(windowStart),
      'confirmed_at': FieldValue.serverTimestamp(),
      'device_ok': true,
      'offline_queued': offlineQueued,
      'note': note,
    });
    
    debugPrint('✅ Created confirmation: ${docRef.id}');
    return docRef.id;
  }
  
  /// Get confirmations for a month
  Future<List<ConfirmationLog>> getMonthlyConfirmations({
    required String familyId,
    required String childId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('confirmations')
        .where('child_id', isEqualTo: childId)
        .where('confirmed_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('confirmed_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('confirmed_at', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ConfirmationLog(
        id: doc.id,
        eventId: data['event_id'] as String,
        childId: data['child_id'] as String,
        placeId: data['place'] as String,
        responsibleMemberId: data['responsible_member_id'] as String?,
        windowStart: (data['window_start'] as Timestamp).toDate(),
        confirmedById: data['confirmed_by_id'] as String,
        confirmedAt: (data['confirmed_at'] as Timestamp).toDate(),
        geoOk: data['device_ok'] as bool? ?? true,
        offline: data['offline_queued'] as bool? ?? false,
        note: data['note'] as String?,
      );
    }).toList();
  }
  
  // ==================== MEMBERS ====================
  
  /// Get user by ID
  Future<FamilyMember?> getMember(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    
    final data = doc.data()!;
    return FamilyMember(
      id: doc.id,
      displayName: data['display_name'] as String,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      isOwner: false, // Will be set by caller
    );
  }
  
  /// Get all family members
  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    final familyDoc = await _firestore.collection('families').doc(familyId).get();
    final familyData = familyDoc.data();
    if (familyData == null) return [];
    
    final memberIds = List<String>.from(familyData['member_ids'] ?? []);
    final ownerId = familyData['owner_id'] as String;
    
    final members = <FamilyMember>[];
    
    for (final memberId in memberIds) {
      final member = await getMember(memberId);
      if (member != null) {
        members.add(FamilyMember(
          id: member.id,
          displayName: member.displayName,
          email: member.email,
          phone: member.phone,
          isOwner: memberId == ownerId,
        ));
      }
    }
    
    return members;
  }
  
  /// Listen to family members
  Stream<List<FamilyMember>> watchFamilyMembers(String familyId) async* {
    await for (final familySnapshot in _firestore.collection('families').doc(familyId).snapshots()) {
      final familyData = familySnapshot.data();
      if (familyData == null) {
        yield [];
        continue;
      }
      
      final memberIds = List<String>.from(familyData['member_ids'] ?? []);
      final ownerId = familyData['owner_id'] as String;
      
      final members = <FamilyMember>[];
      
      for (final memberId in memberIds) {
        final member = await getMember(memberId);
        if (member != null) {
          members.add(FamilyMember(
            id: member.id,
            displayName: member.displayName,
            email: member.email,
            phone: member.phone,
            isOwner: memberId == ownerId,
          ));
        }
      }
      
      yield members;
    }
  }
  
  // ==================== HELPERS ====================
  
  Color _parseColor(String colorString) {
    final hex = colorString.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

