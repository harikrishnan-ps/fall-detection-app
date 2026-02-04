import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/alert_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new user
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toMap());
      debugPrint('User created in Firestore: ${user.uid}');
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(user.toMap());
      debugPrint('User updated: ${user.uid}');
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // Create alert
  Future<String> createAlert(AlertModel alert) async {
    try {
      DocumentReference ref = await _firestore
          .collection(AppConstants.alertsCollection)
          .add(alert.toMap());
      debugPrint('Alert created: ${ref.id}');
      return ref.id;
    } catch (e) {
      debugPrint('Error creating alert: $e');
      rethrow;
    }
  }

  // Update alert
  Future<void> updateAlert(AlertModel alert) async {
    try {
      await _firestore
          .collection(AppConstants.alertsCollection)
          .doc(alert.alertId)
          .update(alert.toMap());
      debugPrint('Alert updated: ${alert.alertId}');
    } catch (e) {
      debugPrint('Error updating alert: $e');
      rethrow;
    }
  }

  // Get alerts for a person
  Stream<List<AlertModel>> getAlertsForPerson(String personId) {
    return _firestore
        .collection(AppConstants.alertsCollection)
        .where('personId', isEqualTo: personId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AlertModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get pending alerts for caregiver
  Stream<List<AlertModel>> getPendingAlertsForCaregiver(List<String> linkedPersonIds) {
    if (linkedPersonIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.alertsCollection)
        .where('personId', whereIn: linkedPersonIds)
        .where('status', isEqualTo: AppConstants.alertStatusPending)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AlertModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get all alerts for caregiver (from all linked persons)
  Stream<List<AlertModel>> getAllAlertsForCaregiver(List<String> linkedPersonIds) {
    if (linkedPersonIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.alertsCollection)
        .where('personId', whereIn: linkedPersonIds)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AlertModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Acknowledge alert
  Future<void> acknowledgeAlert(String alertId, String caregiverId) async {
    try {
      await _firestore
          .collection(AppConstants.alertsCollection)
          .doc(alertId)
          .update({
        'status': AppConstants.alertStatusAcknowledged,
        'acknowledgedBy': caregiverId,
        'acknowledgedAt': Timestamp.now(),
      });
      debugPrint('Alert acknowledged: $alertId by $caregiverId');
    } catch (e) {
      debugPrint('Error acknowledging alert: $e');
      rethrow;
    }
  }

  // Resolve alert
  Future<void> resolveAlert(String alertId) async {
    try {
      await _firestore
          .collection(AppConstants.alertsCollection)
          .doc(alertId)
          .update({
        'status': AppConstants.alertStatusResolved,
      });
      debugPrint('Alert resolved: $alertId');
    } catch (e) {
      debugPrint('Error resolving alert: $e');
      rethrow;
    }
  }

  // Save FCM token
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore
          .collection(AppConstants.userTokensCollection)
          .doc(userId)
          .set({
        'fcmToken': token,
        'platform': defaultTargetPlatform.name,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
      debugPrint('FCM token saved for user: $userId');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Get FCM tokens for users
  Future<List<String>> getFCMTokens(List<String> userIds) async {
    try {
      List<String> tokens = [];
      
      for (String userId in userIds) {
        DocumentSnapshot doc = await _firestore
            .collection(AppConstants.userTokensCollection)
            .doc(userId)
            .get();
        
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String? token = data['fcmToken'];
          if (token != null && token.isNotEmpty) {
            tokens.add(token);
          }
        }
      }
      
      return tokens;
    } catch (e) {
      debugPrint('Error getting FCM tokens: $e');
      return [];
    }
  }

  // Search user by email (for linking)
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error searching user by email: $e');
      return null;
    }
  }

  Future<String> linkUsersByEmail({
  required String caregiverId,
  required String email,
}) async {
  try {
    // 1. Find target user
    final person = await getUserByEmail(email);

    if (person == null) {
      return 'No user found with this email';
    }

    if (person.uid == caregiverId) {
      return 'You cannot add yourself';
    }

    // 2. Get caregiver
    final caregiver = await getUser(caregiverId);

    if (caregiver == null) {
      return 'Caregiver account not found';
    }

    // 3. Prevent duplicates
    if (caregiver.linkedUsers.contains(person.uid)) {
      return 'User already linked';
    }

    // 4. Update BOTH users
    final updatedCaregiver = caregiver.copyWith(
      linkedUsers: [...caregiver.linkedUsers, person.uid],
    );

    final updatedPerson = person.copyWith(
      linkedUsers: [...person.linkedUsers, caregiver.uid],
    );

    await updateUser(updatedCaregiver);
    await updateUser(updatedPerson);

    return 'success';
  } catch (e) {
    return 'Error: $e';
  }
}

Future<String> linkCaregiverByEmail({
  required String personId,
  required String email,
}) async {
  try {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: email.trim())
        .get();

    if (snapshot.docs.isEmpty) {
      return 'No user found with this email';
    }

    final caregiver = UserModel.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
    );

    if (caregiver.role != UserRole.caregiver) {
      return 'This user is not a caregiver account';
    }

    if (caregiver.uid == personId) {
      return 'You cannot add yourself';
    }

    final person = await getUser(personId);
    if (person == null) return 'Profile missing';

    if (person.linkedUsers.contains(caregiver.uid)) {
      return 'Caregiver already linked';
    }

    // Update both sides
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(personId)
        .update({
      'linkedUsers': FieldValue.arrayUnion([caregiver.uid])
    });

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(caregiver.uid)
        .update({
      'linkedUsers': FieldValue.arrayUnion([personId])
    });

    return 'success';
  } catch (e) {
    return 'Error: $e';
  }
}

}
