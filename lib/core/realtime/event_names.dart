abstract final class RealtimeClientEvent {
  static const join = 'join';
  static const leave = 'leave';
  static const messageSend = 'message.send';
  static const typingStart = 'typing.start';
  static const typingStop = 'typing.stop';
}

abstract final class RealtimeServerEvent {
  static const searchMatched = 'search.matched';
  static const offerNew = 'offer.new';
  static const offerUpdated = 'offer.updated';
  static const reviewCreated = 'review.created';
  static const messageNew = 'message.new';
  static const notificationNew = 'notification.new';
  static const typingStart = 'typing.start';
  static const typingStop = 'typing.stop';
}

abstract final class RealtimeControlEvent {
  static const authExpired = 'auth.expired';
  static const wsError = 'ws.error';
}

const realtimeContractVersion = 1;
