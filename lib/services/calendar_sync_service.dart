import 'package:device_calendar/device_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import '../models/entities.dart';

/// Service for syncing FamilyCal events with device calendar
class CalendarSyncService {
  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _currentUserId;
  String? _currentFamilyId;
  
  void setCurrentUser(String userId, String familyId) {
    _currentUserId = userId;
    _currentFamilyId = familyId;
  }
  
  /// Initialize calendar permissions and settings
  Future<CalendarPermissionResult> initialize() async {
    try {
      final permissionsGranted = await _deviceCalendar.hasPermissions();
      
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        final permissionResult = await _deviceCalendar.requestPermissions();
        
        return CalendarPermissionResult(
          granted: permissionResult.isSuccess && permissionResult.data!,
          error: permissionResult.isSuccess ? null : 'Permission denied',
        );
      }
      
      return CalendarPermissionResult(
        granted: permissionsGranted.data ?? false,
        error: null,
      );
    } catch (e) {
      debugPrint('❌ Calendar permission error: $e');
      return CalendarPermissionResult(
        granted: false,
        error: e.toString(),
      );
    }
  }
  
  /// Get available calendars on device
  Future<List<Calendar>> getAvailableCalendars() async {
    try {
      final calendarsResult = await _deviceCalendar.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        return calendarsResult.data!;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting calendars: $e');
      return [];
    }
  }
  
  /// Sync event to device calendar when assigned
  Future<CalendarSyncResult> syncEventToCalendar(
    RecurringEvent event,
    FamilyChild child,
  ) async {
    if (_currentUserId == null || _currentFamilyId == null) {
      throw Exception('User not initialized');
    }
    
    try {
      // Get user's calendar settings
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final settings = userDoc.data()?['settings'] as Map<String, dynamic>? ?? {};
      
      if (settings['calendar_sync_enabled'] != true) {
        debugPrint('📅 Calendar sync disabled for user');
        return CalendarSyncResult(
          success: false,
          error: 'Calendar sync is disabled',
        );
      }
      
      // Get device calendar permissions
      final permissionsGranted = await _deviceCalendar.hasPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        return CalendarSyncResult(
          success: false,
          error: 'Calendar permissions not granted',
        );
      }
      
      // Get target calendar
      final calendars = await getAvailableCalendars();
      if (calendars.isEmpty) {
        throw Exception('No calendars available');
      }
      
      final targetCalendarId = settings['calendar_id'] as String? ?? calendars.first.id;
      
      // Check if already synced
      final eventDoc = await _firestore
        .collection('families')
        .doc(_currentFamilyId)
        .collection('events')
        .doc(event.id)
        .get();
      
      final calendarSyncData = eventDoc.data()?['calendar_synced_for'] as Map<String, dynamic>?;
      final existingSyncInfo = calendarSyncData?[_currentUserId] as Map<String, dynamic>?;
      
      if (existingSyncInfo != null) {
        // Update existing calendar event
        final deviceEventId = existingSyncInfo['device_event_id'] as String?;
        if (deviceEventId != null) {
          return await _updateCalendarEvent(
            event,
            child,
            targetCalendarId!,
            deviceEventId,
          );
        }
      }
      
      // Create new calendar event
      final calendarEvent = _buildCalendarEvent(
        event,
        child,
        targetCalendarId!,
      );
      
      final result = await _deviceCalendar.createOrUpdateEvent(calendarEvent);
      
      if (result?.isSuccess == true && result?.data != null) {
        // Update Firestore with sync status
        await _firestore
          .collection('families')
          .doc(_currentFamilyId)
          .collection('events')
          .doc(event.id)
          .set({
            'calendar_synced_for': {
              _currentUserId: {
                'synced_at': FieldValue.serverTimestamp(),
                'device_calendar_id': targetCalendarId,
                'device_event_id': result!.data,
              }
            }
          }, SetOptions(merge: true));
        
        debugPrint('✅ Synced event ${event.id} to calendar: ${result.data}');
        
        return CalendarSyncResult(
          success: true,
          deviceEventId: result.data!,
        );
      } else {
        throw Exception('Calendar sync failed: ${result?.errors}');
      }
      
    } catch (e) {
      debugPrint('❌ Calendar sync error: $e');
      
      // Queue for retry
      await _queueCalendarSync(event, 'calendar_add');
      
      return CalendarSyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Remove event from device calendar
  Future<bool> removeEventFromCalendar(String eventId) async {
    if (_currentUserId == null || _currentFamilyId == null) return false;
    
    try {
      final eventDoc = await _firestore
        .collection('families')
        .doc(_currentFamilyId)
        .collection('events')
        .doc(eventId)
        .get();
      
      if (!eventDoc.exists) return false;
      
      final syncData = eventDoc.data()?['calendar_synced_for'] as Map<String, dynamic>?;
      final userSyncInfo = syncData?[_currentUserId] as Map<String, dynamic>?;
      
      if (userSyncInfo == null) return false;
      
      final deviceEventId = userSyncInfo['device_event_id'] as String?;
      final calendarId = userSyncInfo['device_calendar_id'] as String?;
      
      if (deviceEventId != null && calendarId != null) {
        final result = await _deviceCalendar.deleteEvent(calendarId, deviceEventId);
        
        if (result?.isSuccess == true) {
          // Remove sync info from Firestore
          await _firestore
            .collection('families')
            .doc(_currentFamilyId)
            .collection('events')
            .doc(eventId)
            .update({
              'calendar_synced_for.$_currentUserId': FieldValue.delete(),
            });
          
          debugPrint('🗑️ Removed event from calendar');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Failed to remove from calendar: $e');
      return false;
    }
  }
  
  /// Update event in device calendar
  Future<CalendarSyncResult> updateEventInCalendar(
    RecurringEvent event,
    FamilyChild child,
  ) async {
    if (_currentUserId == null || _currentFamilyId == null) {
      throw Exception('User not initialized');
    }
    
    try {
      final eventDoc = await _firestore
        .collection('families')
        .doc(_currentFamilyId)
        .collection('events')
        .doc(event.id)
        .get();
      
      final syncData = eventDoc.data()?['calendar_synced_for'] as Map<String, dynamic>?;
      final userSyncInfo = syncData?[_currentUserId] as Map<String, dynamic>?;
      
      if (userSyncInfo == null) {
        // Not synced yet, create new
        return await syncEventToCalendar(event, child);
      }
      
      final deviceEventId = userSyncInfo['device_event_id'] as String?;
      final calendarId = userSyncInfo['device_calendar_id'] as String?;
      
      if (deviceEventId != null && calendarId != null) {
        return await _updateCalendarEvent(event, child, calendarId, deviceEventId);
      }
      
      // Fallback: recreate event
      await removeEventFromCalendar(event.id);
      return await syncEventToCalendar(event, child);
      
    } catch (e) {
      debugPrint('❌ Failed to update calendar event: $e');
      return CalendarSyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  Future<CalendarSyncResult> _updateCalendarEvent(
    RecurringEvent event,
    FamilyChild child,
    String calendarId,
    String deviceEventId,
  ) async {
    try {
      final calendarEvent = _buildCalendarEvent(event, child, calendarId);
      calendarEvent.eventId = deviceEventId;
      
      final result = await _deviceCalendar.createOrUpdateEvent(calendarEvent);
      
      if (result?.isSuccess == true) {
        debugPrint('✅ Updated calendar event: $deviceEventId');
        return CalendarSyncResult(
          success: true,
          deviceEventId: deviceEventId,
        );
      } else {
        throw Exception('Update failed: ${result?.errors}');
      }
    } catch (e) {
      debugPrint('❌ Error updating calendar event: $e');
      return CalendarSyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  Event _buildCalendarEvent(
    RecurringEvent event,
    FamilyChild child,
    String calendarId,
  ) {
    final roleLabel = event.role == EventRole.dropOff ? 'drop-off' : 'pick-up';
    final title = event.title?.isNotEmpty == true
        ? event.title!
        : '${child.displayName} $roleLabel at ${event.placeId}';
    
    // Calculate start and end datetime
    final startDate = event.startDate;
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      event.startTime.hour,
      event.startTime.minute,
    );
    
    final endDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      event.endTime.hour,
      event.endTime.minute,
    );
    
    final location = tz.local;
    
    return Event(
      calendarId,
      eventId: null, // Will be set by calendar
      title: title,
      description: 'FamilyCal event - confirm in app when complete',
      start: tz.TZDateTime.from(startDateTime, location),
      end: tz.TZDateTime.from(endDateTime, location),
      recurrenceRule: _buildRecurrenceRule(event),
      location: event.placeId,
    );
  }
  
  RecurrenceRule? _buildRecurrenceRule(RecurringEvent event) {
    if (event.weekdays.length == 1 && event.endDate == null) {
      return null; // One-time event
    }
    
    final daysOfWeek = event.weekdays.map((day) {
      switch (day) {
        case 1: return DayOfWeek.Monday;
        case 2: return DayOfWeek.Tuesday;
        case 3: return DayOfWeek.Wednesday;
        case 4: return DayOfWeek.Thursday;
        case 5: return DayOfWeek.Friday;
        case 6: return DayOfWeek.Saturday;
        case 7: return DayOfWeek.Sunday;
        default: return DayOfWeek.Monday;
      }
    }).toList();
    
    return RecurrenceRule(
      RecurrenceFrequency.Weekly,
      daysOfWeek: daysOfWeek,
      endDate: event.endDate != null 
        ? tz.TZDateTime.from(event.endDate!, tz.local)
        : null,
    );
  }
  
  /// Queue calendar sync for offline retry
  Future<void> _queueCalendarSync(RecurringEvent event, String operation) async {
    if (_currentUserId == null || _currentFamilyId == null) return;
    
    try {
      await _firestore
        .collection('families')
        .doc(_currentFamilyId)
        .collection('pending_syncs')
        .add({
          'user_id': _currentUserId,
          'operation': operation,
          'event_id': event.id,
          'data': {
            'child_id': event.childId,
            'place': event.placeId,
            'role': event.role.name,
            'start_time': '${event.startTime.hour}:${event.startTime.minute}',
            'end_time': '${event.endTime.hour}:${event.endTime.minute}',
            'title': event.title,
          },
          'created_at': FieldValue.serverTimestamp(),
          'retry_count': 0,
        });
      
      debugPrint('📝 Queued calendar sync for retry');
    } catch (e) {
      debugPrint('❌ Failed to queue calendar sync: $e');
    }
  }
  
  /// Process pending calendar syncs (call when coming back online)
  Future<void> processPendingSyncs() async {
    if (_currentUserId == null || _currentFamilyId == null) return;
    
    try {
      final pendingSyncsSnapshot = await _firestore
        .collection('families')
        .doc(_currentFamilyId)
        .collection('pending_syncs')
        .where('user_id', isEqualTo: _currentUserId)
        .get();
      
      for (final doc in pendingSyncsSnapshot.docs) {
        final data = doc.data();
        final operation = data['operation'] as String;
        final eventId = data['event_id'] as String;
        
        try {
          // Get event details
          final eventDoc = await _firestore
            .collection('families')
            .doc(_currentFamilyId)
            .collection('events')
            .doc(eventId)
            .get();
          
          if (!eventDoc.exists) {
            // Event deleted, remove sync task
            await doc.reference.delete();
            continue;
          }
          
          // Process based on operation
          switch (operation) {
            case 'calendar_add':
              // Retry sync
              // await syncEventToCalendar(event, child);
              break;
            case 'calendar_update':
              // await updateEventInCalendar(event, child);
              break;
            case 'calendar_delete':
              await removeEventFromCalendar(eventId);
              break;
          }
          
          // Remove from pending queue
          await doc.reference.delete();
          
        } catch (e) {
          debugPrint('❌ Failed to process pending sync: $e');
          
          // Increment retry count
          final retryCount = (data['retry_count'] as int? ?? 0) + 1;
          
          if (retryCount >= 3) {
            // Give up after 3 retries
            await doc.reference.delete();
          } else {
            await doc.reference.update({'retry_count': retryCount});
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing pending syncs: $e');
    }
  }
}

class CalendarPermissionResult {
  final bool granted;
  final String? error;
  
  CalendarPermissionResult({
    required this.granted,
    this.error,
  });
}

class CalendarSyncResult {
  final bool success;
  final String? deviceEventId;
  final String? error;
  
  CalendarSyncResult({
    required this.success,
    this.deviceEventId,
    this.error,
  });
}

