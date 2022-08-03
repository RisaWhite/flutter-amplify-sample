import 'dart:async';

import 'auth_credentials.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:logger/logger.dart';

// 1
enum AuthFlowStatus { login, signUp, verification, session }

// 2
class AuthState {
  final AuthFlowStatus authFlowStatus;

  AuthState({required this.authFlowStatus});
}

// 3
class AuthService {
  // 4
  final authStateController = StreamController<AuthState>();

  late AuthCredentials _credentials;

  // 5
  void showSignUp() {
    final state = AuthState(authFlowStatus: AuthFlowStatus.signUp);
    authStateController.add(state);
  }

  // 6
  void showLogin() {
    final state = AuthState(authFlowStatus: AuthFlowStatus.login);
    authStateController.add(state);
  }

  // 1
  void loginWithCredentials(AuthCredentials credentials) {
    final state = AuthState(authFlowStatus: AuthFlowStatus.session);
    authStateController.add(state);
  }

// 2
  void signUpWithCredentials(SignUpCredentials credentials) async {
    try {
      // 2
      final userAttributes = <CognitoUserAttributeKey, String>{
        CognitoUserAttributeKey.email: credentials.email
      };

      // 3
      final result = await Amplify.Auth.signUp(
          username: credentials.username,
          password: credentials.password,
          options: CognitoSignUpOptions(userAttributes: userAttributes));

      // 4
      if (result.isSignUpComplete) {
        loginWithCredentials(credentials);
      } else {
        // 5
        _credentials = credentials;

        // 6
        final state = AuthState(authFlowStatus: AuthFlowStatus.verification);
        authStateController.add(state);
      }

      // 7
    } on AuthException catch (authError) {
      Logger().e('Failed to sign up - ${authError.message}');
    }
  }

// 1
  void verifyCode(String verificationCode) async {
    try {
      // 2
      final result = await Amplify.Auth.confirmSignUp(
          username: _credentials.username, confirmationCode: verificationCode);

      // 3
      if (result.isSignUpComplete) {
        loginWithCredentials(_credentials);
      } else {
        // 4
        // Follow more steps
      }
    } on AuthException catch (authError) {
      Logger().e('Could not verify code - ${authError.message}');
    }
  }

  void logOut() async {
    try {
      // 1
      await Amplify.Auth.signOut();

      // 2
      showLogin();
    } on AuthException catch (authError) {
      Logger().e('Could not log out - ${authError.message}');
    }
  }

  void checkAuthStatus() async {
    try {
      await Amplify.Auth.fetchAuthSession();

      final state = AuthState(authFlowStatus: AuthFlowStatus.session);
      authStateController.add(state);
    } catch (_) {
      final state = AuthState(authFlowStatus: AuthFlowStatus.login);
      authStateController.add(state);
    }
  }
}
