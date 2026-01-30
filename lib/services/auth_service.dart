import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  AuthService() {
    // Listen to auth state changes (only works if Firebase is initialized)
    try {
      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          _loadUserModel(user.uid);
        } else {
          _currentUserModel = null;
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('⚠ Auth state listener not available (Firebase not initialized): $e');
    }
  }

  // Load user model from database
  Future<void> _loadUserModel(String uid) async {
    try {
      _currentUserModel = await _databaseService.getUser(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user model: $e');
    }
  }

  // Register new user
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      // Create Firebase auth account
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return 'Failed to create account';
      }

      // Create user model
      UserModel userModel = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
      );

      // Save to Firestore
      await _databaseService.createUser(userModel);

      // Update display name
      await credential.user!.updateDisplayName(name);

      _currentUserModel = userModel;
      notifyListeners();

      debugPrint('User registered successfully: ${credential.user!.uid}');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration error: ${e.code}');
      switch (e.code) {
        case 'weak-password':
          return 'Password is too weak';
        case 'email-already-in-use':
          return 'Email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return 'Registration failed: ${e.message}';
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return 'An unexpected error occurred';
    }
  }

  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserModel(credential.user!.uid);
        debugPrint('User signed in: ${credential.user!.uid}');
        return null; // Success
      }

      return 'Sign in failed';
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This account has been disabled';
        default:
          return 'Sign in failed: ${e.message}';
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      return 'An unexpected error occurred';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUserModel = null;
      notifyListeners();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to: $email');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return 'Password reset failed: ${e.message}';
      }
    } catch (e) {
      debugPrint('Password reset error: $e');
      return 'An unexpected error occurred';
    }
  }

  // Update user profile
  Future<String?> updateProfile({
    String? name,
    String? phoneNumber,
    List<EmergencyContact>? emergencyContacts,
  }) async {
    try {
      if (_currentUserModel == null) {
        return 'User not authenticated';
      }

      UserModel updatedUser = _currentUserModel!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        emergencyContacts: emergencyContacts,
      );

      await _databaseService.updateUser(updatedUser);
      _currentUserModel = updatedUser;
      notifyListeners();

      if (name != null) {
        await currentUser?.updateDisplayName(name);
      }

      debugPrint('Profile updated successfully');
      return null; // Success
    } catch (e) {
      debugPrint('Profile update error: $e');
      return 'Failed to update profile';
    }
  }

  // Link user (add caregiver or person)
  Future<String?> linkUser(String userIdToLink) async {
    try {
      if (_currentUserModel == null) {
        return 'User not authenticated';
      }

      // Verify the user to link exists
      UserModel? userToLink = await _databaseService.getUser(userIdToLink);
      if (userToLink == null) {
        return 'User not found';
      }

      // Add to linked users
      List<String> updatedLinkedUsers = List.from(_currentUserModel!.linkedUsers);
      if (!updatedLinkedUsers.contains(userIdToLink)) {
        updatedLinkedUsers.add(userIdToLink);
      }

      // Update current user
      UserModel updatedCurrentUser = _currentUserModel!.copyWith(
        linkedUsers: updatedLinkedUsers,
      );
      await _databaseService.updateUser(updatedCurrentUser);

      // Also update the other user's linked list
      List<String> otherUserLinkedUsers = List.from(userToLink.linkedUsers);
      if (!otherUserLinkedUsers.contains(_currentUserModel!.uid)) {
        otherUserLinkedUsers.add(_currentUserModel!.uid);
      }
      UserModel updatedOtherUser = userToLink.copyWith(
        linkedUsers: otherUserLinkedUsers,
      );
      await _databaseService.updateUser(updatedOtherUser);

      _currentUserModel = updatedCurrentUser;
      notifyListeners();

      debugPrint('User linked successfully: $userIdToLink');
      return null; // Success
    } catch (e) {
      debugPrint('Link user error: $e');
      return 'Failed to link user';
    }
  }
}
