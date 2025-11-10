const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { CloudTasksClient } = require('@google-cloud/tasks');

admin.initializeApp();

// ==================== EVENT ASSIGNMENT NOTIFICATIONS ====================

/**
 * Trigger when event is created or updated
 * Handles assignment, reassignment, and unassignment notifications
 */
exports.onEventAssignment = functions.firestore
  .document('families/{familyId}/events/{eventId}')
  .onWrite(async (change, context) => {
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;
    
    if (!after) {
      // Event deleted - handled by onEventDeleted
      return null;
    }
    
    const { familyId, eventId } = context.params;
    
    // Check what changed
    const isNewEvent = !before;
    const wasAssigned = !before?.responsible_member_id && after.responsible_member_id;
    const wasReassigned = before?.responsible_member_id !== after.responsible_member_id 
                          && after.responsible_member_id;
    const wasUnassigned = before?.responsible_member_id && !after.responsible_member_id;
    const wasUpdated = before && (
      before.start_time !== after.start_time ||
      before.end_time !== after.end_time ||
      before.place !== after.place
    );
    
    // SCENARIO 1: New event WITH assignment
    if (isNewEvent && after.responsible_member_id) {
      await sendAssignmentNotification(familyId, eventId, after, 'assigned');
    }
    
    // SCENARIO 2: Event reassigned
    else if (wasReassigned) {
      await sendAssignmentNotification(familyId, eventId, after, 'reassigned');
      
      // Send calendar removal notification to old assignee
      if (before.responsible_member_id) {
        await sendCalendarRemovalNotification(familyId, eventId, before.responsible_member_id);
      }
    }
    
    // SCENARIO 3: New event WITHOUT assignment
    else if (isNewEvent && !after.responsible_member_id) {
      await scheduleUnassignedAlert(familyId, eventId, after);
    }
    
    // SCENARIO 4: Event unassigned
    else if (wasUnassigned) {
      await scheduleUnassignedAlert(familyId, eventId, after);
      
      // Send calendar removal notification to old assignee
      await sendCalendarRemovalNotification(familyId, eventId, before.responsible_member_id);
    }
    
    // SCENARIO 5: Event details updated
    else if (wasUpdated && after.responsible_member_id) {
      await sendEventUpdatedNotification(familyId, eventId, after);
    }
    
    return null;
  });

/**
 * Send assignment notification to assigned user
 */
async function sendAssignmentNotification(familyId, eventId, eventData, type) {
  const assignedUserId = eventData.responsible_member_id;
  
  // Skip if user assigned to themselves (unless it's a new event)
  if (assignedUserId === eventData.created_by && type === 'assigned') {
    console.log('User assigned event to themselves, skipping notification');
    return;
  }
  
  try {
    // Get assigned user's FCM tokens
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(assignedUserId)
      .get();
    
    if (!userDoc.exists) {
      console.log('User not found:', assignedUserId);
      return;
    }
    
    const userData = userDoc.data();
    
    // Check notification settings
    if (!userData.settings?.notifications?.assignments) {
      console.log('Assignment notifications disabled for user');
      return;
    }
    
    const fcmTokens = Object.values(userData.fcm_tokens || {})
      .map(device => device.token)
      .filter(token => token);
    
    if (fcmTokens.length === 0) {
      console.log('No FCM tokens for user:', assignedUserId);
      return;
    }
    
    // Get child name
    const childDoc = await admin.firestore()
      .collection('families').doc(familyId)
      .collection('children').doc(eventData.child_id)
      .get();
    
    const childName = childDoc.exists ? childDoc.data().display_name : 'Child';
    const roleLabel = eventData.role === 'dropOff' ? 'drop-off' : 'pick-up';
    
    // Get assigner name (if reassigned)
    let assignerName = '';
    if (type === 'reassigned' && eventData.created_by) {
      const assignerDoc = await admin.firestore()
        .collection('users')
        .doc(eventData.created_by)
        .get();
      assignerName = assignerDoc.exists ? assignerDoc.data().display_name : 'Someone';
    }
    
    // Format date
    const startDate = eventData.start_date.toDate();
    const dateStr = startDate.toLocaleDateString('en-US', { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric' 
    });
    
    const title = type === 'reassigned' 
      ? `Reassigned: ${childName} ${roleLabel}`
      : `You're now responsible for ${childName} ${roleLabel}`;
    
    const body = type === 'reassigned'
      ? `${assignerName} assigned you ${childName}'s ${roleLabel} at ${eventData.place} on ${dateStr} ${eventData.start_time}. Added to your calendar.`
      : `${childName} ${roleLabel} at ${eventData.place} on ${dateStr} ${eventData.start_time}. Added to your calendar.`;
    
    const message = {
      notification: { title, body },
      data: {
        type: 'event_assigned',
        event_id: eventId,
        family_id: familyId,
        action: 'calendar_sync',
        event_data: JSON.stringify(eventData)
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } }
      },
      android: {
        notification: { channelId: 'assignments' }
      }
    };
    
    // Send to all devices
    const response = await admin.messaging().sendEachForMulticast({
      tokens: fcmTokens,
      ...message
    });
    
    console.log(`✅ Sent assignment notification: ${response.successCount} successful, ${response.failureCount} failed`);
    
    // Clean up invalid tokens
    if (response.failureCount > 0) {
      await cleanupInvalidTokens(assignedUserId, fcmTokens, response.responses);
    }
    
  } catch (error) {
    console.error('Error sending assignment notification:', error);
  }
}

/**
 * Send calendar removal notification
 */
async function sendCalendarRemovalNotification(familyId, eventId, userId) {
  try {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    if (!userDoc.exists) return;
    
    const userData = userDoc.data();
    const fcmTokens = Object.values(userData.fcm_tokens || {})
      .map(device => device.token)
      .filter(token => token);
    
    if (fcmTokens.length === 0) return;
    
    const message = {
      data: {
        type: 'calendar_removal',
        event_id: eventId,
        family_id: familyId,
        action: 'remove_from_calendar'
      },
      apns: {
        payload: { 
          aps: { 'content-available': 1 },
          data: { silent: true }
        }
      },
      android: {
        priority: 'high'
      }
    };
    
    await admin.messaging().sendEachForMulticast({
      tokens: fcmTokens,
      ...message
    });
    
    console.log('✅ Sent calendar removal notification');
    
  } catch (error) {
    console.error('Error sending calendar removal notification:', error);
  }
}

/**
 * Schedule unassigned alert for family owner
 */
async function scheduleUnassignedAlert(familyId, eventId, eventData) {
  const eventStartDate = eventData.start_date.toDate();
  const now = new Date();
  const daysUntilEvent = Math.ceil((eventStartDate - now) / (1000 * 60 * 60 * 24));
  
  // Only alert if event is within 7 days
  if (daysUntilEvent > 7) {
    console.log('Event too far in future, skipping unassigned alert');
    return;
  }
  
  // Schedule alert for 24h from now
  const alertTime = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  
  try {
    const tasksClient = new CloudTasksClient();
    const project = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
    const location = 'us-central1';
    const queue = 'unassigned-alerts';
    
    const url = `https://${location}-${project}.cloudfunctions.net/sendUnassignedAlert`;
    
    const task = {
      httpRequest: {
        httpMethod: 'POST',
        url,
        body: Buffer.from(JSON.stringify({
          familyId,
          eventId,
        })).toString('base64'),
        headers: { 'Content-Type': 'application/json' },
      },
      scheduleTime: {
        seconds: Math.floor(alertTime.getTime() / 1000),
      },
    };
    
    const queuePath = tasksClient.queuePath(project, location, queue);
    await tasksClient.createTask({ parent: queuePath, task });
    
    console.log(`⏰ Scheduled unassigned alert for event ${eventId} at ${alertTime}`);
    
  } catch (error) {
    console.error('Error scheduling unassigned alert:', error);
  }
}

/**
 * Send event updated notification
 */
async function sendEventUpdatedNotification(familyId, eventId, eventData) {
  const userId = eventData.responsible_member_id;
  if (!userId) return;
  
  try {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    if (!userDoc.exists) return;
    
    const userData = userDoc.data();
    const fcmTokens = Object.values(userData.fcm_tokens || {})
      .map(device => device.token)
      .filter(token => token);
    
    if (fcmTokens.length === 0) return;
    
    // Get child name
    const childDoc = await admin.firestore()
      .collection('families').doc(familyId)
      .collection('children').doc(eventData.child_id)
      .get();
    
    const childName = childDoc.exists ? childDoc.data().display_name : 'Child';
    const roleLabel = eventData.role === 'dropOff' ? 'drop-off' : 'pick-up';
    
    const message = {
      notification: {
        title: `Updated: ${childName} ${roleLabel}`,
        body: `Changed to ${eventData.start_time} at ${eventData.place}.`,
      },
      data: {
        type: 'event_updated',
        event_id: eventId,
        family_id: familyId,
        action: 'calendar_sync',
        event_data: JSON.stringify(eventData)
      },
      android: {
        notification: { channelId: 'alerts' }
      }
    };
    
    await admin.messaging().sendEachForMulticast({
      tokens: fcmTokens,
      ...message
    });
    
    console.log('✅ Sent event updated notification');
    
  } catch (error) {
    console.error('Error sending event updated notification:', error);
  }
}

// ==================== EVENT DELETION ====================

/**
 * Trigger when event is deleted
 */
exports.onEventDeleted = functions.firestore
  .document('families/{familyId}/events/{eventId}')
  .onDelete(async (snapshot, context) => {
    const eventData = snapshot.data();
    const { familyId, eventId } = context.params;
    
    if (eventData.responsible_member_id) {
      await sendEventDeletedNotification(familyId, eventId, eventData);
    }
    
    return null;
  });

async function sendEventDeletedNotification(familyId, eventId, eventData) {
  const userId = eventData.responsible_member_id;
  if (!userId) return;
  
  try {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    if (!userDoc.exists) return;
    
    const userData = userDoc.data();
    const fcmTokens = Object.values(userData.fcm_tokens || {})
      .map(device => device.token)
      .filter(token => token);
    
    if (fcmTokens.length === 0) return;
    
    // Get child name
    const childDoc = await admin.firestore()
      .collection('families').doc(familyId)
      .collection('children').doc(eventData.child_id)
      .get();
    
    const childName = childDoc.exists ? childDoc.data().display_name : 'Child';
    const roleLabel = eventData.role === 'dropOff' ? 'drop-off' : 'pick-up';
    
    const startDate = eventData.start_date.toDate();
    const dateStr = startDate.toLocaleDateString('en-US', { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric' 
    });
    
    const message = {
      notification: {
        title: `Event removed`,
        body: `${childName} ${roleLabel} at ${eventData.place} on ${dateStr} was removed.`,
      },
      data: {
        type: 'event_deleted',
        event_id: eventId,
        family_id: familyId,
        action: 'remove_from_calendar'
      },
      android: {
        notification: { channelId: 'alerts' }
      }
    };
    
    await admin.messaging().sendEachForMulticast({
      tokens: fcmTokens,
      ...message
    });
    
    console.log('✅ Sent event deleted notification');
    
  } catch (error) {
    console.error('Error sending event deleted notification:', error);
  }
}

// ==================== CONFIRMATIONS ====================

/**
 * Trigger when confirmation is created
 */
exports.onEventConfirmed = functions.firestore
  .document('families/{familyId}/confirmations/{confirmationId}')
  .onCreate(async (snapshot, context) => {
    const confirmation = snapshot.data();
    const { familyId } = context.params;
    
    try {
      // Get all family members EXCEPT the one who confirmed
      const familyDoc = await admin.firestore()
        .collection('families')
        .doc(familyId)
        .get();
      
      if (!familyDoc.exists) return null;
      
      const partnerIds = familyDoc.data().member_ids
        .filter(id => id !== confirmation.confirmed_by_id);
      
      if (partnerIds.length === 0) return null;
      
      // Get confirmer's name
      const confirmerDoc = await admin.firestore()
        .collection('users')
        .doc(confirmation.confirmed_by_id)
        .get();
      
      const confirmerName = confirmerDoc.exists ? confirmerDoc.data().display_name : 'Someone';
      
      // Get child name
      const childDoc = await admin.firestore()
        .collection('families').doc(familyId)
        .collection('children').doc(confirmation.child_id)
        .get();
      
      const childName = childDoc.exists ? childDoc.data().display_name : 'Child';
      const roleLabel = confirmation.role === 'dropOff' ? 'drop-off' : 'pick-up';
      
      const timeStr = confirmation.confirmed_at.toDate()
        .toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
      
      // Send to all partners
      for (const partnerId of partnerIds) {
        const partnerDoc = await admin.firestore()
          .collection('users')
          .doc(partnerId)
          .get();
        
        if (!partnerDoc.exists) continue;
        
        const partnerData = partnerDoc.data();
        
        // Check notification settings
        if (!partnerData.settings?.notifications?.confirmations) continue;
        
        const fcmTokens = Object.values(partnerData.fcm_tokens || {})
          .map(device => device.token)
          .filter(token => token);
        
        if (fcmTokens.length === 0) continue;
        
        const message = {
          notification: {
            title: `Done ✅ — ${childName} ${roleLabel}`,
            body: `${confirmerName} confirmed ${childName} ${roleLabel} at ${confirmation.place} at ${timeStr}.`,
          },
          data: {
            type: 'event_confirmed',
            event_id: confirmation.event_id,
            confirmation_id: snapshot.id,
            family_id: familyId,
          },
          android: {
            notification: { channelId: 'confirmations' }
          }
        };
        
        await admin.messaging().sendEachForMulticast({
          tokens: fcmTokens,
          ...message
        });
        
        console.log(`✅ Sent confirmation notification to partner: ${partnerId}`);
      }
      
    } catch (error) {
      console.error('Error sending confirmation notification:', error);
    }
    
    return null;
  });

// ==================== DAILY UNASSIGNED CHECK ====================

/**
 * Scheduled function to check for unassigned events tomorrow
 * Runs daily at 8 AM UTC
 */
exports.checkUnassignedEvents = functions.pubsub
  .schedule('0 8 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('🔍 Checking for unassigned events tomorrow...');
    
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    const tomorrowTimestamp = admin.firestore.Timestamp.fromDate(tomorrow);
    
    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 1);
    const dayAfterTimestamp = admin.firestore.Timestamp.fromDate(dayAfter);
    
    try {
      // Get all families
      const familiesSnapshot = await admin.firestore()
        .collection('families')
        .get();
      
      for (const familyDoc of familiesSnapshot.docs) {
        const familyId = familyDoc.id;
        const familyData = familyDoc.data();
        const ownerId = familyData.owner_id;
        
        // Get owner's notification settings
        const ownerDoc = await admin.firestore()
          .collection('users')
          .doc(ownerId)
          .get();
        
        if (!ownerDoc.exists) continue;
        
        const ownerData = ownerDoc.data();
        if (!ownerData.settings?.notifications?.unassigned_alerts) continue;
        
        // Query unassigned events for tomorrow
        const eventsSnapshot = await admin.firestore()
          .collection('families').doc(familyId)
          .collection('events')
          .where('start_date', '>=', tomorrowTimestamp)
          .where('start_date', '<', dayAfterTimestamp)
          .get();
        
        const unassignedEvents = eventsSnapshot.docs.filter(doc => {
          return !doc.data().responsible_member_id;
        });
        
        if (unassignedEvents.length === 0) continue;
        
        // Get child names
        const eventSummaries = await Promise.all(
          unassignedEvents.map(async (eventDoc) => {
            const eventData = eventDoc.data();
            
            const childDoc = await admin.firestore()
              .collection('families').doc(familyId)
              .collection('children').doc(eventData.child_id)
              .get();
            
            const childName = childDoc.exists ? childDoc.data().display_name : 'Child';
            const roleLabel = eventData.role === 'dropOff' ? 'drop-off' : 'pick-up';
            
            return `${childName} ${roleLabel} at ${eventData.place} at ${eventData.start_time}`;
          })
        );
        
        // Get owner's FCM tokens
        const fcmTokens = Object.values(ownerData.fcm_tokens || {})
          .map(device => device.token)
          .filter(token => token);
        
        if (fcmTokens.length === 0) continue;
        
        const eventList = eventSummaries.join(', ');
        
        const message = {
          notification: {
            title: `⚠️ ${unassignedEvents.length} Unassigned Event${unassignedEvents.length > 1 ? 's' : ''} Tomorrow`,
            body: `Please assign: ${eventList}`,
          },
          data: {
            type: 'unassigned_events_alert',
            family_id: familyId,
            event_ids: JSON.stringify(unassignedEvents.map(doc => doc.id)),
            click_action: 'OPEN_CALENDAR',
          },
          android: {
            notification: { channelId: 'alerts' },
            priority: 'high'
          },
          apns: {
            payload: { aps: { sound: 'default', badge: 1 } }
          }
        };
        
        await admin.messaging().sendEachForMulticast({
          tokens: fcmTokens,
          ...message
        });
        
        console.log(`✅ Sent unassigned alert to owner of family ${familyId}`);
      }
      
    } catch (error) {
      console.error('Error checking unassigned events:', error);
    }
    
    return null;
  });

// ==================== UTILITIES ====================

/**
 * Clean up invalid FCM tokens
 */
async function cleanupInvalidTokens(userId, tokens, responses) {
  const invalidTokens = [];
  
  responses.forEach((response, idx) => {
    if (!response.success) {
      const error = response.error;
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        invalidTokens.push(tokens[idx]);
      }
    }
  });
  
  if (invalidTokens.length > 0) {
    console.log(`Removing ${invalidTokens.length} invalid tokens`);
    
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    const fcmTokens = userDoc.data().fcm_tokens || {};
    
    // Remove invalid tokens
    for (const [deviceId, deviceData] of Object.entries(fcmTokens)) {
      if (invalidTokens.includes(deviceData.token)) {
        delete fcmTokens[deviceId];
      }
    }
    
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .update({ fcm_tokens: fcmTokens });
  }
}

