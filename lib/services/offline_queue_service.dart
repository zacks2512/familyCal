import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/entities.dart';
import 'firebase_repository.dart';

/// Service for managing offline operations queue
class OfflineQueueService {
  static Database? _database;
  final FirebaseRepository _repository = FirebaseRepository();
  final Connectivity _connectivity = Connectivity();
  
  bool _isProcessing = false;
  
  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'familycal_offline.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table for pending confirmations
        await db.execute('''
          CREATE TABLE pending_confirmations (
            id TEXT PRIMARY KEY,
            family_id TEXT NOT NULL,
            event_id TEXT NOT NULL,
            child_id TEXT NOT NULL,
            place TEXT NOT NULL,
            role TEXT NOT NULL,
            window_start INTEGER NOT NULL,
            responsible_member_id TEXT,
            note TEXT,
            created_at INTEGER NOT NULL,
            retry_count INTEGER DEFAULT 0
          )
        ''');
        
        // Table for pending calendar syncs
        await db.execute('''
          CREATE TABLE pending_calendar_syncs (
            id TEXT PRIMARY KEY,
            operation TEXT NOT NULL,
            event_id TEXT NOT NULL,
            event_data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            retry_count INTEGER DEFAULT 0
          )
        ''');
        
        debugPrint('✅ Created offline queue database');
      },
    );
  }
  
  // ==================== CONFIRMATIONS ====================
  
  /// Queue confirmation for offline processing
  Future<void> queueConfirmation({
    required String familyId,
    required String eventId,
    required String childId,
    required String place,
    required EventRole role,
    required DateTime windowStart,
    String? responsibleMemberId,
    String? note,
  }) async {
    final db = await database;
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    await db.insert(
      'pending_confirmations',
      {
        'id': id,
        'family_id': familyId,
        'event_id': eventId,
        'child_id': childId,
        'place': place,
        'role': role.name,
        'window_start': windowStart.millisecondsSinceEpoch,
        'responsible_member_id': responsibleMemberId,
        'note': note,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
      },
    );
    
    debugPrint('📝 Queued confirmation offline: $id');
    
    // Try to process immediately if online
    await processQueue();
  }
  
  /// Get all pending confirmations
  Future<List<Map<String, dynamic>>> getPendingConfirmations() async {
    final db = await database;
    return await db.query(
      'pending_confirmations',
      orderBy: 'created_at ASC',
    );
  }
  
  /// Process confirmation queue
  Future<void> processConfirmationQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    
    try {
      final pending = await getPendingConfirmations();
      
      for (final item in pending) {
        try {
          // Create confirmation in Firestore
          await _repository.createConfirmation(
            familyId: item['family_id'] as String,
            eventId: item['event_id'] as String,
            childId: item['child_id'] as String,
            place: item['place'] as String,
            role: EventRole.values.byName(item['role'] as String),
            windowStart: DateTime.fromMillisecondsSinceEpoch(item['window_start'] as int),
            responsibleMemberId: item['responsible_member_id'] as String?,
            note: item['note'] as String?,
            offlineQueued: true,
          );
          
          // Remove from queue
          await _removeConfirmationFromQueue(item['id'] as String);
          
          debugPrint('✅ Processed offline confirmation: ${item['id']}');
          
        } catch (e) {
          debugPrint('❌ Failed to process confirmation ${item['id']}: $e');
          
          // Increment retry count
          final retryCount = (item['retry_count'] as int? ?? 0) + 1;
          
          if (retryCount >= 3) {
            // Give up after 3 retries
            await _removeConfirmationFromQueue(item['id'] as String);
            debugPrint('⚠️ Gave up on confirmation after 3 retries');
          } else {
            await _incrementConfirmationRetryCount(item['id'] as String);
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
  
  Future<void> _removeConfirmationFromQueue(String id) async {
    final db = await database;
    await db.delete(
      'pending_confirmations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> _incrementConfirmationRetryCount(String id) async {
    final db = await database;
    await db.execute(
      'UPDATE pending_confirmations SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }
  
  // ==================== CALENDAR SYNCS ====================
  
  /// Queue calendar sync operation
  Future<void> queueCalendarSync({
    required String operation, // 'add', 'update', 'delete'
    required String eventId,
    required Map<String, dynamic> eventData,
  }) async {
    final db = await database;
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    await db.insert(
      'pending_calendar_syncs',
      {
        'id': id,
        'operation': operation,
        'event_id': eventId,
        'event_data': jsonEncode(eventData),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
      },
    );
    
    debugPrint('📝 Queued calendar sync offline: $operation for $eventId');
  }
  
  /// Get all pending calendar syncs
  Future<List<Map<String, dynamic>>> getPendingCalendarSyncs() async {
    final db = await database;
    return await db.query(
      'pending_calendar_syncs',
      orderBy: 'created_at ASC',
    );
  }
  
  /// Process calendar sync queue
  Future<void> processCalendarSyncQueue() async {
    final pending = await getPendingCalendarSyncs();
    
    for (final item in pending) {
      try {
        final operation = item['operation'] as String;
        final eventId = item['event_id'] as String;
        final eventData = jsonDecode(item['event_data'] as String) as Map<String, dynamic>;
        
        // Calendar sync will be handled by CalendarSyncService
        // This is just for tracking
        
        debugPrint('📅 Processing calendar sync: $operation for $eventId');
        
        // Remove from queue after successful processing
        await _removeCalendarSyncFromQueue(item['id'] as String);
        
      } catch (e) {
        debugPrint('❌ Failed to process calendar sync ${item['id']}: $e');
        
        final retryCount = (item['retry_count'] as int? ?? 0) + 1;
        
        if (retryCount >= 3) {
          await _removeCalendarSyncFromQueue(item['id'] as String);
          debugPrint('⚠️ Gave up on calendar sync after 3 retries');
        } else {
          await _incrementCalendarSyncRetryCount(item['id'] as String);
        }
      }
    }
  }
  
  Future<void> _removeCalendarSyncFromQueue(String id) async {
    final db = await database;
    await db.delete(
      'pending_calendar_syncs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> _incrementCalendarSyncRetryCount(String id) async {
    final db = await database;
    await db.execute(
      'UPDATE pending_calendar_syncs SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }
  
  // ==================== GENERAL ====================
  
  /// Process all queues
  Future<void> processQueue() async {
    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('📵 Offline - skipping queue processing');
      return;
    }
    
    debugPrint('🔄 Processing offline queue...');
    
    await Future.wait([
      processConfirmationQueue(),
      processCalendarSyncQueue(),
    ]);
    
    debugPrint('✅ Finished processing offline queue');
  }
  
  /// Get queue status
  Future<Map<String, int>> getQueueStatus() async {
    final confirmations = await getPendingConfirmations();
    final calendarSyncs = await getPendingCalendarSyncs();
    
    return {
      'confirmations': confirmations.length,
      'calendar_syncs': calendarSyncs.length,
      'total': confirmations.length + calendarSyncs.length,
    };
  }
  
  /// Clear all queues (use with caution!)
  Future<void> clearAllQueues() async {
    final db = await database;
    
    await db.delete('pending_confirmations');
    await db.delete('pending_calendar_syncs');
    
    debugPrint('🗑️ Cleared all offline queues');
  }
  
  /// Setup connectivity listener
  void setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        debugPrint('📶 Back online - processing queue');
        processQueue();
      }
    });
  }
}

