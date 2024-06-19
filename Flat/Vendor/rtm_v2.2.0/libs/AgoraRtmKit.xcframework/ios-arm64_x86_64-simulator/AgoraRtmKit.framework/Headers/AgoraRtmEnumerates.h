#import <Foundation/Foundation.h>

/**
 * IP areas.
 */
typedef NS_OPTIONS(NSUInteger, AgoraRtmAreaCode) {
  /**
   * Mainland China.
   */
  AgoraRtmAreaCodeCN = 0x00000001,
  /**
   * North America.
   */
  AgoraRtmAreaCodeNA = 0x00000002,
  /**
   * Europe.
   */
  AgoraRtmAreaCodeEU = 0x00000004,
  /**
   * Asia, excluding Mainland China.
   */
  AgoraRtmAreaCodeAS = 0x00000008,
  /**
   * Japan.
   */
  AgoraRtmAreaCodeJP = 0x00000010,
  /**
   * India.
   */
  AgoraRtmAreaCodeIN = 0x00000020,
  /**
   * (Default) Global.
   */
  AgoraRtmAreaCodeGLOB = (0xFFFFFFFF)
};  

/**
 * The encryption mode.
 */
typedef NS_ENUM(NSInteger, AgoraRtmEncryptionMode) {
  /*
   * Disable message encryption.
   */
  AgoraRtmEncryptionNone = 0,
  /*
   * 128-bit AES encryption, GCM mode.
   */
  AgoraRtmEncryptionAES128GCM = 1,
  /*
   * 256-bit AES encryption, GCM mode.
   */
  AgoraRtmEncryptionAES256GCM  = 2,
};

typedef NS_ENUM(NSInteger, AgoraRtmMessagePriority) {
  /**
   * The highest priority
   */
  AgoraRtmMessagePriorityHighest = 0,
  /**
   * The high priority
   */
  AgoraRtmMessagePriorityHigh = 1,
  /**
   * The normal priority (Default)
   */
  AgoraRtmMessagePriorityNormal = 4,
  /**
   * The low priority
   */
  AgoraRtmMessagePriorityLow = 8,

};

/**
 * The error codes of rtm client.
 */
typedef NS_ENUM(NSInteger, AgoraRtmErrorCode) {
  /**
   * 0: No error occurs.
   */
  AgoraRtmErrorOk = 0,

  /**
   * -10001 ~ -11000 : reserved for generic error.
   * -10001: The SDK is not initialized.
   */
  AgoraRtmErrorNotInitialized = -10001,
  /**
   * -10002: The user didn't login the RTM system.
   */
  AgoraRtmErrorNotLogin = -10002,
  /**
   * -10003: The app ID is invalid.
   */
  AgoraRtmErrorInvalidAppId = -10003,
  /**
   * -10004: The event handler is invalid.
   */
  AgoraRtmErrorInvalidEventHandler = -10004,
  /**
   * -10005: The token is invalid.
   */
  AgoraRtmErrorInvalidToken = -10005,
  /**
   * -10006: The user ID is invalid.
   */
  AgoraRtmErrorInvalidUserId = -10006,
  /**
   * -10007: The service is not initialized.
   */
  AgoraRtmErrorInitServiceFailed = -10007,
  /**
   * -10008: The channel name is invalid.
   */
  AgoraRtmErrorInvalidChannelName = -10008,
  /**
   * -10009: The token has expired.
   */
  AgoraRtmErrorTokenExpired = -10009,
  /**
   * -10010: There is no server resources now.
   */
  AgoraRtmErrorLoginNoServerResources = -10010,
  /**
   * -10011: The login timeout.
   */
  AgoraRtmErrorLoginTimeout = -10011,
  /**
   * -10012: The login is rejected by server.
   */
  AgoraRtmErrorLoginRejected = -10012,
  /**
   * -10013: The login is aborted due to unrecoverable error.
   */
  AgoraRtmErrorLoginAborted = -10013,
  /**
   * -10014: The parameter is invalid.
   */
  AgoraRtmErrorInvalidParameter = -10014,
  /**
   * -10015: The login is not authorized. Happens user login the RTM system without granted from console.
   */
  AgoraRtmErrorLoginNotAuthorized= -10015,
  /**
   * -10016: Try to login or join with inconsistent app ID.
   */
  AgoraRtmErrorLoginInconsistentAppId = -10016,
  /**
   * -10017: Already call same request.
   */
  AgoraRtmErrorDuplicateOperation = -10017,
  /**
   * -10018: Already call destroy or release, this instance is forbidden to call any api, please create new instance.
   */
  AgoraRtmErrorInstanceAlreadyReleased = -10018,
  /**
   * -10019: Invalid channel type
   */
  AgoraRtmErrorInvalidChannelType = -10019,
  /**
   * -10020: The encryption parameter is invalid.
   */
  AgoraRtmErrorInvalidEncryptionParameter = -10020,
  /**
   * -10021: The operation is too frequent.
   */
  AgoraRtmErrorOperationRateExceedLimitation = -10021,
  /**
   * -10022: The service is not configured in private config mode.
   */
  AgoraRtmErrorServiceNotSupport = -10022,
  /**
   * -10023: This login operation stopped by a new login operation or logout operation.
   */
  AgoraRtmErrorLoginCanceled = -10023,
  /**
   * -10024: The private config is invalid, set private config should both set serviceType and accessPointHosts.
   */
  AgoraRtmErrorInvalidPrivateConfig = -10024,
  /**
   * -10025: Perform operation failed due to RTM service is not connected.
   */
  AgoraRtmErrorNotConnected = -10025,

  /**
   * -11001 ~ -12000 : reserved for channel error.
   * -11001: The user has not joined the channel.
   */
  AgoraRtmErrorChannelNotJoined = -11001,
  /**
   * -11002: The user has not subscribed the channel.
   */
  AgoraRtmErrorChannelNotSubscribed = -11002,
  /**
   * -11003: The topic member count exceeds the limit.
   */
  AgoraRtmErrorChannelExceedTopicUserLimitation = -11003,
  /**
   * -11004: The channel is reused in RTC.
   */
  AgoraRtmErrorChannelReused = -11004,
  /**
   * -11005: The channel instance count exceeds the limit.
   */
  AgoraRtmErrorChannelInstanceExceedLimitation = -11005,
  /**
   * -11006: The channel is in error state.
   */
  AgoraRtmErrorChannelInErrorState = -11006,
  /**
   * -11007: The channel join failed.
   */
  AgoraRtmErrorChannelJoinFailed = -11007,
  /**
   * -11008: The topic name is invalid.
   */
  AgoraRtmErrorChannelInvalidTopicName = -11008,
  /**
   * -11009: The message is invalid.
   */
  AgoraRtmErrorChannelInvalidMessage = -11009,
  /**
   * -11010: The message length exceeds the limit.
   */
  AgoraRtmErrorChannelMessageLengthExceedLimitation= -11010,
  /**
   * -11011: The user list is invalid.
   */
  AgoraRtmErrorChannelInvalidUserList = -11011,
  /**
   * -11012: The stream channel is not available.
   */
  AgoraRtmErrorChannelNotAvailable = -11012,
  /**
   * -11013: The topic is not subscribed.
   */
  AgoraRtmErrorChannelTopicNotSubscribed = -11013,
  /**
   * -11014: The topic count exceeds the limit.
   */
  AgoraRtmErrorChannelExceedTopicLimitation = -11014,
  /**
   * -11015: Join topic failed.
   */
  AgoraRtmErrorChannelJoinTopicFailed = -11015,
  /**
   * -11016: The topic is not joined.
   */
  AgoraRtmErrorChannelTopicNotJoined = -11016,
  /**
   * -11017: The topic does not exist.
   */
  AgoraRtmErrorChannelTopicNotExist = -11017,
  /**
   * -11018: The topic meta is invalid.
   */
  AgoraRtmErrorChannelInvalidTopicMeta = -11018,
  /**
   * -11019: Subscribe channel timeout.
   */
  AgoraRtmErrorChannelSubscribeTimeout = -11019,
  /**
   * -11020: Subscribe channel too frequent.
   */
  AgoraRtmErrorChannelSubscribeTooFrequent = -11020,
  /**
   * -11021: Subscribe channel failed.
   */
  AgoraRtmErrorChannelSubscribeFailed = -11021,
  /**
   * -11022: Unsubscribe channel failed.
   */
  AgoraRtmErrorChannelUnsubscribeFailed = -11022,
  /**
   * -11023: Encrypt message failed.
   */
  AgoraRtmErrorChannelEncryptMessageFailed = -11023,
  /**
   * -11024: Publish message failed.
   */
  AgoraRtmErrorChannelPublishMessageFailed = -11024,
  /**
   * -11025: Publish message too frequent.
   */
  AgoraRtmErrorChannelPublishMessageTooFrequent = -11025,
  /**
   * -11026: Publish message timeout.
   */
  AgoraRtmErrorChannelPublishMessageTimeout = -11026, 
  /**
   * -10027: The connection state is invalid.
   */
  AgoraRtmErrorChannelNotConnected = -11027,
  /**
   * -11028: Leave channel failed.
   */
  AgoraRtmErrorChannelLeaveFailed = -11028,
  /**
   * -11029: The custom type length exceeds the limit.
   */
  AgoraRtmErrorChannelCustomTypeLengthOverflow = -11029,
  /**
   * -11030: The custom type is invalid.
   */
  AgoraRtmErrorChannelInvalidCustomType = -11030,
  /**
   * -11031: unsupported message type (in MacOS/iOS platform，message only support NSString and NSData)
   */
  AgoraRtmErrorChannelUnsupportedMessageType = -11031,
  /**
   * -11032: The channel presence is not ready.
   */
  AgoraRtmErrorChannelPresenceNotReady = -11032,
  /**
   * -11033: The destination user of publish message is offline.
   */
   AgoraRtmErrorChannelReceiverOffline = -11033,
   /**
   * -11034: The channel join operation is canceled.
   */
  AgoraRtmErrorChannelJoinCanceled = -11034,
  /**
   * -12001 ~ -13000 : reserved for storage error.
   * -12001: The storage operation failed.
   */
  AgoraRtmErrorStorageOperationFailed = -12001,
  /**
   * -12002: The metadata item count exceeds the limit.
   */
  AgoraRtmErrorStorageMetadataItemExceedLimitation= -12002,
  /**
   * -12003: The metadata item is invalid.
   */
  AgoraRtmErrorStorageInvalidMetadataItem = -12003,
  /**
   * -12004: The argument in storage operation is invalid.
   */
  AgoraRtmErrorStorageInvalidArgument = -12004,
  /**
   * -12005: The revision in storage operation is invalid.
   */
  AgoraRtmErrorStorageInvalidRevision = -12005,
  /**
   * -12006: The metadata length exceeds the limit.
   */
  AgoraRtmErrorStorageMetadataLengthOverflow = -12006,
  /**
   * -12007: The lock name in storage operation is invalid.
   */
  AgoraRtmErrorStorageInvalidLockName= -12007,
  /**
   * -12008: The lock in storage operation is not acquired.
   */
  AgoraRtmErrorStorageLockNotAcquired = -12008,
  /**
   * -12009: The metadata key is invalid.
   */
  AgoraRtmErrorStorageInvalidKey = -12009,
  /**
   * -12010: The metadata value is invalid.
   */
  AgoraRtmErrorStorageInvalidValue = -12010,
  /**
   * -12011: The metadata key length exceeds the limit.
   */
  AgoraRtmErrorStorageKeyLengthOverflow= -12011,
  /**
   * -12012: The metadata value length exceeds the limit.
   */
  AgoraRtmErrorStorageValueLengthOverflow= -12012,
  /**
   * -12013: The metadata key already exists.
   */
  AgoraRtmErrorStorageDuplicateKey = -12013,
  /**
   * -12014: The revision in storage operation is outdated.
   */
  AgoraRtmErrorStorageOutdatedRevision = -12014,
  /**
   * -12015: The storage operation performed without subscribing.
   */
  AgoraRtmErrorStorageNotSubscribe = -12015,
  /**
   * -12016: The metadata item is invalid.
   */
  AgoraRtmErrorStorageInvalidMetadataInstance = -12016,
  /**
   * -12017: The user count exceeds the limit when try to subscribe.
   */
  AgoraRtmErrorStorageSubscribeUserExceedLimitation = -12017,
  /**
   * -12018: The storage operation timeout.
   */
  AgoraRtmErrorStorageOperationTimeout = -12018,
  /**
   * -12019: The storage service not available.
   */
  AgoraRtmErrorStorageNotAvailable = -12019,

  /**
   * -13001 ~ -14000 : reserved for presence error.
   * -13001: The user is not connected.
   */
  AgoraRtmErrorPresenceNotConnected = -13001,
  /**
   * -13002: The presence is not writable.
   */
  AgoraRtmErrorPresenceNotWritable = -13002,
  /**
   * -13003: The argument in presence operation is invalid.
   */
  AgoraRtmErrorPresenceInvalidArgument = -13003,
  /**
   * -13004: The cached presence state count exceeds the limit.
   */
  AgoraRtmErrorPresenceCacheTooManyStates = -13004,
  /**
   * -13005: The state count exceeds the limit.
   */
  AgoraRtmErrorPresenceStateCountOverflow= -13005,
  /**
   * -13006: The state key is invalid.
   */
  AgoraRtmErrorPresenceInvalidStateKey = -13006,
  /**
   * -13007: The state value is invalid.
   */
  AgoraRtmErrorPresenceInvalidStateValue = -13007,
  /**
   * -13008: The state key length exceeds the limit.
   */
  AgoraRtmErrorPresenceStateKeySizeOverflow= -13008,
  /**
   * -13009: The state value length exceeds the limit.
   */
  AgoraRtmErrorPresenceStateValueSizeOverflow= -13009,
  /**
   * -13010: The state key already exists.
   */
  AgoraRtmErrorPresenceStateDuplicateKey = -13010,
  /**
   * -13011: The user is not exist.
   */
  AgoraRtmErrorPresenceUserNotExist = -13011,
  /**
   * -13012: The presence operation timeout.
   */
  AgoraRtmErrorPresenceOperationTimeout = -13012,
  /**
   * -13013: The presence operation failed.
   */
  AgoraRtmErrorPresenceOperationFailed = -13013,

  /**
   * -14001 ~ -15000 : reserved for lock error.
   * -14001: The lock operation failed.
   */
  AgoraRtmErrorLockOperationFailed = -14001,
  /**
   * -14002: The lock operation timeout.
   */
  AgoraRtmErrorLockOperationTimeout = -14002,
  /**
   * -14003: The lock operation is performing.
   */
  AgoraRtmErrorLockOperationPerforming = -14003,
  /**
   * -14004: The lock already exists.
   */
  AgoraRtmErrorLockAlreadyExist = -14004,
  /**
   * -14005: The lock name is invalid.
   */
  AgoraRtmErrorLockInvalidName = -14005,
  /**
   * -14006: The lock is not acquired.
   */
  AgoraRtmErrorLockNotAcquired = -14006,
  /**
   * -14007: Acquire lock failed.
   */
  AgoraRtmErrorLockAcquireFailed = -14007,
  /**
   * -14008: The lock is not exist.
   */
  AgoraRtmErrorLockNotExist = -14008,
  /**
   * -14009: The lock service is not available.
   */
  AgoraRtmErrorLockNotAvailable = -14009,
};

/**
  @brief Storage type indicate the storage event was triggered by user or channel
  */
typedef NS_ENUM(NSInteger, AgoraRtmStorageType)  {
  /**
    0: The user storage event.
    */
  AgoraRtmStorageTypeNone = 0,
  /**
    1: The user storage event.
    */
  AgoraRtmStorageTypeUser = 1,
  /**
    2: The channel storage event.
    */
  AgoraRtmStorageTypeChannel = 2,   
};

/**
 * The lock event type, indicate lock operation
 */
typedef NS_ENUM(NSInteger, AgoraRtmLockEventType) {
  /**
   * 0: Unknown event type
   */
  AgoraRtmLockEventTypeNone = 0,
  /**
   * 1: Triggered when user subscribe lock state
   */
  AgoraRtmLockEventTypeSnapshot = 1,
  /**
   * 2: Triggered when a remote user set lock
   */
  AgoraRtmLockEventTypeLockSet = 2,
  /**
   * 3: Triggered when a remote user remove lock
   */
  AgoraRtmLockEventTypeLockRemoved = 3,
  /**
   * 4: Triggered when a remote user acquired lock
   */
  AgoraRtmLockEventTypeLockAcquired = 4,
  /**
   * 5: Triggered when a remote user released lock
   */
  AgoraRtmLockEventTypeLockReleased = 5,
  /**
   * 6: Triggered when user reconnect to rtm service,
   * detect the lock has been acquired and released by others.
   */
  AgoraRtmLockEventTypeLockExpired = 6,
};

/**
 * The proxy type
 */
typedef NS_ENUM(NSInteger, AgoraRtmProxyType) {
  /**
   * 0: Link without proxy
   */
  AgoraRtmProxyTypeNone = 0,
  /**
   * 1: Link with http proxy
   */
  AgoraRtmProxyTypeHttp = 1,
};

typedef NS_OPTIONS(NSInteger, AgoraRtmServiceType) {
  /**
   * None rtm service.
   */
  AgoraRtmServiceTypeNone = 0x00000000,
  /**
   * The basic functionality of rtm service.
   */
  AgoraRtmServiceTypeMessage = 0x00000001,
  /**
   * The advanced functionality of rtm service.
   */
  AgoraRtmServiceTypeStream = 0x00000002,
};

/**
 * Rtm protocol type for underlying connection.
 */
typedef NS_ENUM(NSInteger, AgoraRtmProtocolType) {
  /**
   * TCP and UDP (default).
   */
  AgoraRtmProtocolTypeTcpUdp = 0,
  /**
   * Use TCP only.
   */
  AgoraRtmProtocolTypeTcpOnly = 1,
};

/**
 * Rtm link state.
 */
typedef NS_ENUM(NSInteger, AgoraRtmLinkState) {
  /**
   * The initial state.
   */
  AgoraRtmLinkStateIdle = 0,
  /**
   * The SDK is connecting to the server.
   */
  AgoraRtmLinkStateConnecting = 1,
  /**
   * The SDK has connected to the server.
   */
  AgoraRtmLinkStateConnected = 2,
  /**
   * The SDK is disconnected from the server.
   */
  AgoraRtmLinkStateDisconnected = 3,
  /**
   * The SDK link is suspended.
   */
  AgoraRtmLinkStateSuspended = 4,
  /**
   * The SDK is failed to connect to the server.
   */
  AgoraRtmLinkStateFailed = 5,
};

/**
 * Rtm link operation.
 */
typedef NS_ENUM(NSInteger, AgoraRtmLinkOperation) {
  /**
   * Login.
   */
  AgoraRtmLinkOperationLogin = 0,
  /**
   * Logout.
   */
  AgoraRtmLinkOperationLogout = 1,
  /**
   * Join
   */
  AgoraRtmLinkOperationJoin = 2,
  /**
   * Leave.
   */
  AgoraRtmLinkOperationLeave = 3,
  /**
   * Server reject
   */
  AgoraRtmLinkOperationServerReject = 4,
  /**
   * Auto reconnect
   */
  AgoraRtmLinkOperationAutoReconnect = 5,
  /**
   * Reconnected
   */
  AgoraRtmLinkOperationReconnected = 6,
  /**
   * Heartbeat timeout
   */
  AgoraRtmLinkOperationHeartbeatTimeout = 7,
  /**
   * Server timeout
   */
  AgoraRtmLinkOperationServerTimeout = 8,
  /**
   * Network change
   */
  AgoraRtmLinkOperationNetworkChange = 9,
};

/**
  @brief Topic event type
  */
typedef NS_ENUM(NSInteger, AgoraRtmTopicEventType) {
  /**
     * 0: Unknown event type
   */
  AgoraRtmTopicEventTypeNone = 0,
  /**
   * 1: The topic snapshot of this channel
   */
  AgoraRtmTopicEventTypeSnapshot = 1,
  /**
   * 2: Triggered when remote user join a topic
   */
  AgoraRtmTopicEventTypeRemoteJoinTopic = 2,
  /**
   * 3: Triggered when remote user leave a topic
   */
  AgoraRtmTopicEventTypeRemoteLeaveTopic = 3,
};

/**
  @brief Presence event type
  */
 typedef NS_ENUM(NSInteger, AgoraRtmPresenceEventType) {
  /**
   * 0: Unknown event type
   */
  AgoraRtmPresenceEventTypeNone = 0,

  /**
   * 1: The presence snapshot of this channel
   */
  AgoraRtmPresenceEventTypeSnapshot = 1,
  /**
   * 2: The presence event triggered in interval mode
   */
  AgoraRtmPresenceEventTypeInterval = 2,
  /**
   * 3: Triggered when remote user join channel
   */
  AgoraRtmPresenceEventTypeRemoteJoinChannel = 3,
  /**
   * 4: Triggered when remote user leave channel
   */
  AgoraRtmPresenceEventTypeRemoteLeaveChannel = 4,
  /**
   * 5: Triggered when remote user's connection timeout
   */
  AgoraRtmPresenceEventTypeRemoteConnectionTimeout = 5,
  /**
   * 6: Triggered when user changed state
   */ 
  AgoraRtmPresenceEventTypeRemoteStateChanged = 6,
  /**
   * 7: Triggered when user joined channel without presence service
   */
  AgoraRtmPresenceEventTypeErrorOutOfService = 7,
  
};

/**join stream channel features*/
typedef NS_OPTIONS(NSUInteger, AgoraRtmJoinChannelFeature) {
  /**
   * 0: join stream channel with no other features.
   */
  AgoraRtmJoinChannelFeatureNone = 0,
  /**
   * 1: join stream channel with presence event notification.
   */  
  AgoraRtmJoinChannelFeaturePresence = 1,
  /**
   * 1 << 1: join stream channel with metadata event notification.
   */
  AgoraRtmJoinChannelFeatureMetadata = 1 << 1,
  /**
   * 1 << 2: join stream channel with lock event notification.
   */
  AgoraRtmJoinChannelFeatureLock = 1 << 2,
  /**
   * Whether to subscribe channel in quiet mode
   * Quiet mode means remote user will not receive any notification when we subscribe or
   * unsubscribe or change our presence state
   */
  AgoraRtmJoinChannelFeatureBeQuiet = 1 << 3,
};

/**subscribe message channel features*/
typedef NS_OPTIONS(NSUInteger, AgoraRtmSubscribeChannelFeature) {
  /**
   * 0: subscribe message channel with no other features.
   */
  AgoraRtmSubscribeChannelFeatureNone = 0,
  /**
   * 1: subscribe message channel with presence event notification.
   */
  AgoraRtmSubscribeChannelFeaturePresence = 1,
  /**
   * 1 << 1: subscribe message channel with metadata event notification.
   */
  AgoraRtmSubscribeChannelFeatureMetadata = 1 << 1,
  /**
   * 1 << 2: subscribe message channel with message event notification.
   */
  AgoraRtmSubscribeChannelFeatureMessage = 1 << 2,
  /**
   * 1 << 3: subscribe message channel with lock event notification.
   */
  AgoraRtmSubscribeChannelFeatureLock =  1 << 3,
  /**
   * Whether to join channel in quiet mode
   * Quiet mode means remote user will not receive any notification when we join or
   * leave or change our presence state
   */
  AgoraRtmSubscribeChannelFeatureBeQuiet = 1 << 4,
};


/**
 Connection states between rtm sdk and agora server.
 */
typedef NS_ENUM(NSInteger, AgoraRtmClientConnectionState) {
  /**
   * 1: The SDK is disconnected with server.
   */
  AgoraRtmClientConnectionStateDisconnected = 1,
  /**
   * 2: The SDK is connecting to the server.
   */
  AgoraRtmClientConnectionStateConnecting = 2,
  /**
   * 3: The SDK is connected to the server and has joined a channel. You can now publish or subscribe to
   * a track in the channel.
   */
  AgoraRtmClientConnectionStateConnected = 3,
  /**
   * 4: The SDK keeps rejoining the channel after being disconnected from the channel, probably because of
   * network issues.
   */
  AgoraRtmClientConnectionStateReconnecting = 4,
  /**
   * 5: The SDK fails to connect to the server or join the channel.
   */
  AgoraRtmClientConnectionStateFailed = 5,
};

/**
 Reasons for connection state change.
 */

typedef NS_ENUM(NSInteger, AgoraRtmClientConnectionChangeReason) {
  /**
   * 0: The SDK is connecting to the server.
   */
  AgoraRtmClientConnectionChangedConnecting = 0,
  /**
   * 1: The SDK has joined the channel successfully.
   */
  AgoraRtmClientConnectionChangedJoinSuccess = 1,
  /**
   * 2: The connection between the SDK and the server is interrupted.
   */
  AgoraRtmClientConnectionChangedInterrupted = 2,
  /**
   * 3: The connection between the SDK and the server is banned by the server.
   */
  AgoraRtmClientConnectionChangedBannedByServer = 3,
  /**
   * 4: The SDK fails to join the channel for more than 20 minutes and stops reconnecting to the channel.
   */
  AgoraRtmClientConnectionChangedJoinFailed = 4,
  /**
   * 5: The SDK has left the channel.
   */
  AgoraRtmClientConnectionChangedLeaveChannel = 5,
  /**
   * 6: The connection fails because the App ID is not valid.
   */
  AgoraRtmClientConnectionChangedInvalidAppId = 6,
  /**
   * 7: The connection fails because the channel name is not valid.
   */
  AgoraRtmClientConnectionChangedInvalidChannelName = 7,
  /**
   * 8: The connection fails because the token is not valid.
   */
  AgoraRtmClientConnectionChangedInvalidToken = 8,
  /**
   * 9: The connection fails because the token has expired.
   */
  AgoraRtmClientConnectionChangedTokenExpired = 9,
  /**
   * 10: The connection is rejected by the server.
   */
  AgoraRtmClientConnectionChangedRejectedByServer = 10,
  /**
   * 11: The connection changes to reconnecting because the SDK has set a proxy server.
   */
  AgoraRtmClientConnectionChangedSettingProxyServer = 11,
  /**
   * 12: When the connection state changes because the app has renewed the token.
   */
  AgoraRtmClientConnectionChangedRenewToken = 12,
  /**
   * 13: The IP Address of the app has changed. A change in the network type or IP/Port changes the IP
   * address of the app.
   */
  AgoraRtmClientConnectionChangedClientIpAddressChanged = 13,
  /**
   * 14: A timeout occurs for the keep-alive of the connection between the SDK and the server.
   */
  AgoraRtmClientConnectionChangedKeepAliveTimeout = 14,
  /**
   * 15: The SDK has rejoined the channel successfully.
   */
  AgoraRtmClientConnectionChangedRejoinSuccess = 15,
  /**
   * 16: The connection between the SDK and the server is lost.
   */
  AgoraRtmClientConnectionChangedChangedLost = 16,
  /**
   * 17: The change of connection state is caused by echo test.
   */
  AgoraRtmClientConnectionChangedEchoTest = 17,
  /**
   * 18: The local IP Address is changed by user.
   */
  AgoraRtmClientConnectionChangedClientIpAddressChangedByUser = 18,
  /**
   * 19: The connection is failed due to join the same channel on another device with the same uid.
   */
  AgoraRtmClientConnectionChangedSameUidLogin = 19,
  /**
   * 20: The connection is failed due to too many broadcasters in the channel.
   */
  AgoraRtmClientConnectionChangedTooManyBroadcasters = 20,
  /**
   * 21: The connection is failed due to license validation failure.
   */
  AgoraRtmClientConnectionChangedLicenseValidationFailure = 21,
  /**
   * 22: The connection is failed due to certification verify failure.
   */
  AgoraRtmClientConnectionChangedCertificationVerifyFailure = 22,
  /**
   * 23: The connection is failed due to user vid not support stream channel.
   */
  AgoraRtmClientConnectionChangedStreamChannelNotAvailable = 23,
  /**
   * 24: The connection is failed due to token and appid inconsistent.
   */
  AgoraRtmClientConnectionChangedInconsistentAppId = 24,
  /**
   * 10001: The connection of rtm edge service has been successfully established.
   */
  AgoraRtmClientConnectionChangedLoginSuccess = 10001,
  /**
   * 10002: User logout Agora RTM system.
   */
  AgoraRtmClientConnectionChangedLogout = 10002,
  /**
   * 10003: User log out Agora RTM system.
   */
  AgoraRtmClientConnectionChangedPresenceNotReady = 10003,
};

/**
 rtm channel type.
 */
typedef NS_ENUM(NSInteger, AgoraRtmChannelType) {
  /**
   * 0: Unknown channel type.
   */
  AgoraRtmChannelTypeNone = 0,
  /**
   * 1: message channel.
   */
  AgoraRtmChannelTypeMessage = 1,
  /**
   * 2: stream channel.
   */
  AgoraRtmChannelTypeStream = 2,
  /**
   * 3: User.
   */
  AgoraRtmChannelTypeUser = 3,
};

/**
  * The storage event type, indicate storage operation
  */
typedef NS_ENUM(NSInteger, AgoraRtmStorageEventType) {
  /**
    0: Unknown event type.
    */
  AgoraRtmStorageEventTypeNone= 0,
  /**
    1: Triggered when user subscribe user metadata state or join channel with options.withMetadata = true
    */
  AgoraRtmStorageEventTypeSnapshot = 1,
  /**
    2: Triggered when a remote user set metadata
    */
  AgoraRtmStorageEventTypeSet = 2,
  /**
    3: Triggered when a remote user update metadata
    */
  AgoraRtmStorageEventTypeUpdate = 3,
  /**
    4: Triggered when a remote user remove metadata
    */
  AgoraRtmStorageEventTypeRemove = 4,
};

/**
 * RTM presence type.
 */
typedef NS_ENUM(NSInteger, AgoraRtmPresenceType) {
  /**
   * 0: Triggered when remote user join channel
   */
  AgoraRtmPresenceTypeRemoteJoinChannel = 0,
  /**
   * 1: Triggered when remote leave join channel
   */
  AgoraRtmPresenceTypeRemoteLeaveChannel = 1,
  /**
   * 2: Triggered when remote user's connection timeout
   */
  AgoraRtmPresenceTypeRemoteConnectionTimeout = 2,
  /**
   * 3: Triggered when remote user join a topic
   */
  AgoraRtmPresenceTypeRemoteJoinTopic = 3,
  /**
   * 4: Triggered when remote user leave a topic
   */
  AgoraRtmPresenceTypeRemoteLeaveTopic = 4,
  /**
   * 5: Triggered when local user join channel
   */
  AgoraRtmPresenceTypeSelfJoinChannel = 5,
};

/**
 * The qos of rtm message.
 */
typedef NS_ENUM(NSInteger, AgoraRtmMessageQos) {
    /**
     * not ensure messages arrive in order.
     */
    AgoraRtmMessageQosUnordered = 0,
    /**
     * ensure messages arrive in order.
     */
    AgoraRtmMessageQosOrdered = 1,
};

typedef NS_ENUM (NSInteger, AgoraRtmLogLevel) {
  /**
   * Do not output any log file.
   */
  AgoraRtmLogLevelNone = 0x0000,
  /**
   * (Recommended) Output log files of the Info level.
   */
  AgoraRtmLogLevelInfo = 0x0001,
  /**
   * Output log files of the Warning level.
   */
  AgoraRtmLogLevelWarn = 0x0002,
  /**
   * Output log files of the Error level.
   */
  AgoraRtmLogLevelError = 0x0004,
  /**
   * Output log files of the Critical level.
   */
  AgoraRtmLogLevelFatal = 0x0008,
};