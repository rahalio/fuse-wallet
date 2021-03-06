import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fusecash/models/app_state.dart';
import 'package:fusecash/redux/actions/cash_wallet_actions.dart';
import 'package:fusecash/redux/actions/error_actions.dart';
import 'package:fusecash/redux/actions/user_actions.dart';
import 'package:fusecash/redux/state/store.dart';
import 'package:fusecash/screens/routes.gr.dart';
import 'package:fusecash/services.dart';
import 'package:redux/redux.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

List<Middleware<AppState>> createAuthMiddleware() {
  final loginRequest = _createLoginRequestMiddleware();
  final verifyRequest = _createVerifyPhoneNumberMiddleware();

  return [
    TypedMiddleware<AppState, LoginRequest>(loginRequest),
    TypedMiddleware<AppState, VerifyRequest>(verifyRequest),
  ];
}

Middleware<AppState> _createLoginRequestMiddleware() {
  return (Store store, action, NextDispatcher next) async {
    final logger = await AppFactory().getLogger('action');
    if (action is LoginRequest) {
      try {
        store.dispatch(SetIsLoginRequest(isLoading: true));
        String normalizedPhoneNumber = action.phoneNumber.e164;
        await firebaseAuth.verifyPhoneNumber(
          phoneNumber: normalizedPhoneNumber,
          codeAutoRetrievalTimeout: action.codeAutoRetrievalTimeout,
          codeSent: action.codeSent,
          timeout: Duration(minutes: 2),
          verificationCompleted: action.verificationCompleted,
          verificationFailed: action.verificationFailed
        );
        store.dispatch(new LoginRequestSuccess(
          countryCode: action.countryCode,
          phoneNumber: action.phoneNumber.e164,
          email: "",
          displayName: "",
          normalizedPhoneNumber: normalizedPhoneNumber
        ));
        store.dispatch(segmentAliasCall(normalizedPhoneNumber));
        store.dispatch(segmentTrackCall("Wallet: user insert his phone number", properties: new Map<String, dynamic>.from({ "Phone number": normalizedPhoneNumber })));
      }
      catch (e, s) {
        store.dispatch(SetIsLoginRequest(isLoading: false));
        logger.severe('ERROR - LoginRequest $e');
        await AppFactory().reportError(e, stackTrace: s);
        store.dispatch(new ErrorAction(e.toString()));
        store.dispatch(segmentTrackCall("ERROR in LoginRequest", properties: new Map.from({ "error": e.toString() })));
      }
    }
    next(action);
  };
}

Middleware<AppState> _createVerifyPhoneNumberMiddleware() {
  return (Store store, action, NextDispatcher next) async {
    final logger = await AppFactory().getLogger('action');
    if (action is VerifyRequest) {
      try {
        store.dispatch(SetIsVerifyRequest(isLoading: true));
        store.dispatch(setDeviceId(false));
        PhoneAuthCredential credential = store.state.userState.credentials;
        if (credential == null) {
          credential = PhoneAuthProvider.credential(
            verificationId: action.verificationId,
            smsCode: action.verificationCode
          );
        }
        final User user = (await firebaseAuth.signInWithCredential(credential)).user;
        final User currentUser = firebaseAuth.currentUser;
        assert(user.uid == currentUser.uid);
        final String accountAddress = store.state.userState.accountAddress;
        final String identifier = store.state.userState.identifier;
        String token = await user.getIdToken();
        String jwtToken = await api.login(token, accountAddress, identifier);
        store.dispatch(LoginVerifySuccess(jwtToken));
        store.dispatch(SetIsVerifyRequest(isLoading: false));
        store.dispatch(segmentTrackCall("Wallet: verified phone number"));
        ExtendedNavigator.root.pushUserNameScreen();
      }
      catch (error, s) {
        FirebaseAuthException firebaseAuthException = error as FirebaseAuthException;
        store.dispatch(SetIsVerifyRequest(isLoading: false, message: firebaseAuthException));
        logger.severe('ERROR - Verification failed ${firebaseAuthException.code} - ${firebaseAuthException.message}');
        await AppFactory().reportError(firebaseAuthException.message, stackTrace: s);
        store.dispatch(ErrorAction(firebaseAuthException.message));
        store.dispatch(segmentTrackCall("ERROR in VerifyRequest", properties: Map.from({ "error": firebaseAuthException.message })));
      }
    }
    next(action);
  };
}