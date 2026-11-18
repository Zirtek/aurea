import 'dart:async';
import 'dart:js_interop';

@JS('AureaPush.getEnvironmentInfo')
external JSString _getEnvironmentInfo();

@JS('AureaPush.subscribe')
external JSPromise<JSString> _subscribe();

@JS('AureaPush.getCurrentSubscription')
external JSPromise<JSString> _getCurrentSubscription();

@JS('AureaPush.unsubscribe')
external JSPromise _unsubscribe();

Future<String> getPushEnvInfoImpl() async {
  return _getEnvironmentInfo().toDart;
}

Future<String> subscribePushImpl() async {
  final jsStr = await _subscribe().toDart;
  return jsStr.toDart;
}

Future<String> getCurrentSubscriptionImpl() async {
  final jsStr = await _getCurrentSubscription().toDart;
  return jsStr.toDart;
}

Future<void> unsubscribePushImpl() async {
  await _unsubscribe().toDart;
}