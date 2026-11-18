import 'dart:async';

Future<String> getPushEnvInfoImpl() async {
  return '{"isIOS":false,"isStandalone":false,"isSupported":false,"permission":"unsupported"}';
}

Future<String> subscribePushImpl() async {
  throw UnsupportedError('Web Push disponibile solo su Web');
}

Future<String> getCurrentSubscriptionImpl() async {
  return '';
}

Future<void> unsubscribePushImpl() async {}