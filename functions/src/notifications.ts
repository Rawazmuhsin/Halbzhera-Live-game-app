import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

/**
 * Cloud Function to send a notification to all users
 * This function can be called from your Flutter app with the title and body of the notification
 */
export const sendGlobalNotification = functions.https.onCall(async (data: any, context: any) => {
  // Check if request is coming from an admin user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  // Optional: Check if user is an admin (if you want to restrict this function to admins)
  try {
    const userRef = admin.firestore().collection('users').doc(context.auth.uid);
    const userDoc = await userRef.get();
    const userData = userDoc.data();

    if (!userData || userData.role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can send global notifications.'
      );
    }
  } catch (error) {
    console.error('Error verifying admin status:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error verifying admin status.'
    );
  }

  // Check if the required data is provided
  if (!data.title || !data.body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with "title" and "body" arguments.'
    );
  }

  try {
    // Log the notification being sent
    console.log(`Sending notification: "${data.title}" to all users`);

    // Prepare the notification message
    const message = {
      notification: {
        title: data.title,
        body: data.body
      },
      data: {
        ...(data.data || {}),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      topic: data.topic || 'all', // By default, send to 'all' topic
      android: {
        priority: "high", // Fixed: Use literal "high" instead of string 'high'
        notification: {
          sound: 'default',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
          channelId: 'games_channel'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    } as admin.messaging.Message; // Type cast to Message type

    // Send the message
    const response = await admin.messaging().send(message);
    
    // Log the success
    console.log('Successfully sent notification:', response);

    // Return success response
    return {
      success: true,
      messageId: response
    };
  } catch (error: any) {
    // Log the error
    console.error('Error sending notification:', error);
    
    // Return error response
    throw new functions.https.HttpsError(
      'internal',
      `Error sending notification: ${error.message}`
    );
  }
});
