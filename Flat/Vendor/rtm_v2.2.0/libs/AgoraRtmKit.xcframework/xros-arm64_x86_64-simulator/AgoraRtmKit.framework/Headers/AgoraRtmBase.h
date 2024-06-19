// Copyright (c) 2022 Agora.io. All rights reserved

// This program is confidential and proprietary to Agora.io.
// And may not be copied, reproduced, modified, disclosed to others, published
// or used, in whole or in part, without the express prior written permission
// of Agora.io.

#pragma once  // NOLINT(build/header_guard)

#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <cassert>
#include <memory>

#if defined(_WIN32)

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif  // !WIN32_LEAN_AND_MEAN
#if defined(__aarch64__)
#include <arm64intr.h>
#endif
#include <Windows.h>

#if defined(AGORARTC_EXPORT)
#define AGORA_API extern "C" __declspec(dllexport)
#else
#define AGORA_API extern "C" __declspec(dllimport)
#endif  // AGORARTC_EXPORT

#define AGORA_CALL __cdecl

#define __deprecated

#elif defined(__APPLE__)

#include <TargetConditionals.h>

#define AGORA_API extern "C" __attribute__((visibility("default")))
#define AGORA_CALL

#elif defined(__ANDROID__) || defined(__linux__)

#define AGORA_API extern "C" __attribute__((visibility("default")))
#define AGORA_CALL

#define __deprecated

#else  // !_WIN32 && !__APPLE__ && !(__ANDROID__ || __linux__)

#define AGORA_API extern "C"
#define AGORA_CALL

#define __deprecated

#endif  // _WIN32

#ifndef OPTIONAL_ENUM_SIZE_T
#if __cplusplus >= 201103L || (defined(_MSC_VER) && _MSC_VER >= 1800)
#define OPTIONAL_ENUM_SIZE_T enum : size_t
#else
#define OPTIONAL_ENUM_SIZE_T enum
#endif
#endif

#ifndef OPTIONAL_NULLPTR
#if __cplusplus >= 201103L || (defined(_MSC_VER) && _MSC_VER >= 1800)
#define OPTIONAL_NULLPTR nullptr
#else
#define OPTIONAL_NULLPTR NULL
#endif
#endif

namespace agora {
namespace rtm {

const uint32_t DEFAULT_LOG_SIZE_IN_KB = 1024;

/**
 * Rtm link state.
 */
enum RTM_LINK_STATE {
  /**
   * The initial state.
   */
  RTM_LINK_STATE_IDLE = 0,
  /**
   * The SDK is connecting to the server.
   */
  RTM_LINK_STATE_CONNECTING = 1,
  /**
   * The SDK has connected to the server.
   */
  RTM_LINK_STATE_CONNECTED = 2,
  /**
   * The SDK is disconnected from the server.
   */
  RTM_LINK_STATE_DISCONNECTED = 3,
  /**
   * The SDK link is suspended.
   */
  RTM_LINK_STATE_SUSPENDED = 4,
  /**
   * The SDK is failed to connect to the server.
   */
  RTM_LINK_STATE_FAILED = 5,
};

/**
 * Rtm link operation.
 */
enum RTM_LINK_OPERATION {
  /**
   * Login.
   */
  RTM_LINK_OPERATION_LOGIN = 0,
  /**
   * Logout.
   */
  RTM_LINK_OPERATION_LOGOUT = 1,
  /**
   * Join
   */
  RTM_LINK_OPERATION_JOIN = 2,
  /**
   * Leave.
   */
  RTM_LINK_OPERATION_LEAVE = 3,
  /**
   * Server reject
   */
  RTM_LINK_OPERATION_SERVER_REJECT = 4,
  /**
   * Auto reconnect
   */
  RTM_LINK_OPERATION_AUTO_RECONNECT = 5,
  /**
   * Reconnected
   */
  RTM_LINK_OPERATION_RECONNECTED = 6,
  /**
   * Heartbeat lost
   */
  RTM_LINK_OPERATION_HEARTBEAT_LOST = 7,
  /**
   * Server timeout
   */
  RTM_LINK_OPERATION_SERVER_TIMEOUT = 8,
  /**
   * Network change
   */
  RTM_LINK_OPERATION_NETWORK_CHANGE = 9,
};


/**
 * Rtm service type.
 */
enum RTM_SERVICE_TYPE {
  /**
   * The type of rtm service not specified.
   */
  RTM_SERVICE_TYPE_NONE = 0x00000000,
  /**
   * The basic functionality of rtm service.
   */
  RTM_SERVICE_TYPE_MESSAGE = 0x00000001,
  /**
   * The advanced functionality of rtm service.
   */
  RTM_SERVICE_TYPE_STREAM = 0x00000002,
};

/**
 * Rtm protocol type for underlying connection.
 */
enum RTM_PROTOCOL_TYPE {
  /**
   * TCP and UDP (default).
   */
  RTM_PROTOCOL_TYPE_TCP_UDP = 0,
  /**
   * Use TCP only.
   */
  RTM_PROTOCOL_TYPE_TCP_ONLY = 1,
};

/**
 * IP areas.
 */
enum RTM_AREA_CODE {
  /**
   * Mainland China.
   */
  RTM_AREA_CODE_CN = 0x00000001,
  /**
   * North America.
   */
  RTM_AREA_CODE_NA = 0x00000002,
  /**
   * Europe.
   */
  RTM_AREA_CODE_EU = 0x00000004,
  /**
   * Asia, excluding Mainland China.
   */
  RTM_AREA_CODE_AS = 0x00000008,
  /**
   * Japan.
   */
  RTM_AREA_CODE_JP = 0x00000010,
  /**
   * India.
   */
  RTM_AREA_CODE_IN = 0x00000020,
  /**
   * (Default) Global.
   */
  RTM_AREA_CODE_GLOB = (0xFFFFFFFF)
};

/**
 * The log level for rtm sdk.
 */
enum RTM_LOG_LEVEL {
  /**
   * 0x0000: No logging.
   */
  RTM_LOG_LEVEL_NONE = 0x0000,
  /**
   * 0x0001: Informational messages.
   */
  RTM_LOG_LEVEL_INFO = 0x0001,
  /**
   * 0x0002: Warnings.
   */
  RTM_LOG_LEVEL_WARN = 0x0002,
  /**
   * 0x0004: Errors.
   */
  RTM_LOG_LEVEL_ERROR = 0x0004,
  /**
   * 0x0008: Critical errors that may lead to program termination.
   */
  RTM_LOG_LEVEL_FATAL = 0x0008,
};

/**
 * The encryption mode.
 */
enum RTM_ENCRYPTION_MODE {
  /**
   * Disable message encryption.
   */
  RTM_ENCRYPTION_MODE_NONE = 0,
  /**
   * 128-bit AES encryption, GCM mode.
   */
  RTM_ENCRYPTION_MODE_AES_128_GCM = 1,
  /**
   * 256-bit AES encryption, GCM mode.
   */
  RTM_ENCRYPTION_MODE_AES_256_GCM = 2,
};

/**
 * The error codes of rtm client.
 */
enum RTM_ERROR_CODE {
  /**
   * 0: No error occurs.
   */
  RTM_ERROR_OK = 0,

  /**
   * -10001 ~ -11000 : reserved for generic error.
   * -10001: The SDK is not initialized.
   */
  RTM_ERROR_NOT_INITIALIZED = -10001,
  /**
   * -10002: The user didn't login the RTM system.
   */
  RTM_ERROR_NOT_LOGIN = -10002,
  /**
   * -10003: The app ID is invalid.
   */
  RTM_ERROR_INVALID_APP_ID = -10003,
  /**
   * -10004: The event handler is invalid.
   */
  RTM_ERROR_INVALID_EVENT_HANDLER = -10004,
  /**
   * -10005: The token is invalid.
   */
  RTM_ERROR_INVALID_TOKEN = -10005,
  /**
   * -10006: The user ID is invalid.
   */
  RTM_ERROR_INVALID_USER_ID = -10006,
  /**
   * -10007: The service is not initialized.
   */
  RTM_ERROR_INIT_SERVICE_FAILED = -10007,
  /**
   * -10008: The channel name is invalid.
   */
  RTM_ERROR_INVALID_CHANNEL_NAME = -10008,
  /**
   * -10009: The token has expired.
   */
  RTM_ERROR_TOKEN_EXPIRED = -10009,
  /**
   * -10010: There is no server resources now.
   */
  RTM_ERROR_LOGIN_NO_SERVER_RESOURCES = -10010,
  /**
   * -10011: The login timeout.
   */
  RTM_ERROR_LOGIN_TIMEOUT = -10011,
  /**
   * -10012: The login is rejected by server.
   */
  RTM_ERROR_LOGIN_REJECTED = -10012,
  /**
   * -10013: The login is aborted due to unrecoverable error.
   */
  RTM_ERROR_LOGIN_ABORTED = -10013,
  /**
   * -10014: The parameter is invalid.
   */
  RTM_ERROR_INVALID_PARAMETER = -10014,
  /**
   * -10015: The login is not authorized. Happens user login the RTM system without granted from console.
   */
  RTM_ERROR_LOGIN_NOT_AUTHORIZED = -10015,
  /**
   * -10016: Try to login or join with inconsistent app ID.
   */
  RTM_ERROR_INCONSISTENT_APPID = -10016,
  /**
   * -10017: Already call same request.
   */
  RTM_ERROR_DUPLICATE_OPERATION = -10017,
  /**
   * -10018: Already call destroy or release, this instance is forbidden to call any api, please create new instance.
   */
  RTM_ERROR_INSTANCE_ALREADY_RELEASED = -10018,
  /**
   * -10019: The channel type is invalid.
   */
  RTM_ERROR_INVALID_CHANNEL_TYPE = -10019,
  /**
   * -10020: The encryption parameter is invalid.
   */
  RTM_ERROR_INVALID_ENCRYPTION_PARAMETER = -10020,
  /**
   * -10021: The operation is too frequent.
   */
  RTM_ERROR_OPERATION_RATE_EXCEED_LIMITATION = -10021,
  /**
   * -10022: The service is not configured in private config mode.
   */
  RTM_ERROR_SERVICE_NOT_SUPPORTED = -10022,
  /**
   * -10023: This login operation stopped by a new login operation or logout operation.
   */
  RTM_ERROR_LOGIN_CANCELED = -10023,
  /**
   * -10024: The private config is invalid, set private config should both set serviceType and accessPointHosts.
   */
  RTM_ERROR_INVALID_PRIVATE_CONFIG = -10024,
  /**
   * -10025: Perform operation failed due to RTM service is not connected.
   */
  RTM_ERROR_NOT_CONNECTED = -10025,

  /**
   * -11001 ~ -12000 : reserved for channel error.
   * -11001: The user has not joined the channel.
   */
  RTM_ERROR_CHANNEL_NOT_JOINED = -11001,
  /**
   * -11002: The user has not subscribed the channel.
   */
  RTM_ERROR_CHANNEL_NOT_SUBSCRIBED = -11002,
  /**
   * -11003: The topic member count exceeds the limit.
   */
  RTM_ERROR_CHANNEL_EXCEED_TOPIC_USER_LIMITATION = -11003,
  /**
   * -11004: The channel is reused in RTC.
   */
  RTM_ERROR_CHANNEL_IN_REUSE = -11004,
  /**
   * -11005: The channel instance count exceeds the limit.
   */
  RTM_ERROR_CHANNEL_INSTANCE_EXCEED_LIMITATION = -11005,
  /**
   * -11006: The channel is in error state.
   */
  RTM_ERROR_CHANNEL_IN_ERROR_STATE = -11006,
  /**
   * -11007: The channel join failed.
   */
  RTM_ERROR_CHANNEL_JOIN_FAILED = -11007,
  /**
   * -11008: The topic name is invalid.
   */
  RTM_ERROR_CHANNEL_INVALID_TOPIC_NAME = -11008,
  /**
   * -11009: The message is invalid.
   */
  RTM_ERROR_CHANNEL_INVALID_MESSAGE = -11009,
  /**
   * -11010: The message length exceeds the limit.
   */
  RTM_ERROR_CHANNEL_MESSAGE_LENGTH_EXCEED_LIMITATION = -11010,
  /**
   * -11011: The user list is invalid.
   */
  RTM_ERROR_CHANNEL_INVALID_USER_LIST = -11011,
  /**
   * -11012: The stream channel is not available.
   */
  RTM_ERROR_CHANNEL_NOT_AVAILABLE = -11012,
  /**
   * -11013: The topic is not subscribed.
   */
  RTM_ERROR_CHANNEL_TOPIC_NOT_SUBSCRIBED = -11013,
  /**
   * -11014: The topic count exceeds the limit.
   */
  RTM_ERROR_CHANNEL_EXCEED_TOPIC_LIMITATION = -11014,
  /**
   * -11015: Join topic failed.
   */
  RTM_ERROR_CHANNEL_JOIN_TOPIC_FAILED = -11015,
  /**
   * -11016: The topic is not joined.
   */
  RTM_ERROR_CHANNEL_TOPIC_NOT_JOINED = -11016,
  /**
   * -11017: The topic does not exist.
   */
  RTM_ERROR_CHANNEL_TOPIC_NOT_EXIST = -11017,
  /**
   * -11018: The topic meta is invalid.
   */
  RTM_ERROR_CHANNEL_INVALID_TOPIC_META = -11018,
  /**
   * -11019: Subscribe channel timeout.
   */
  RTM_ERROR_CHANNEL_SUBSCRIBE_TIMEOUT = -11019,
  /**
   * -11020: Subscribe channel too frequent.
   */
  RTM_ERROR_CHANNEL_SUBSCRIBE_TOO_FREQUENT = -11020,
  /**
   * -11021: Subscribe channel failed.
   */
  RTM_ERROR_CHANNEL_SUBSCRIBE_FAILED = -11021,
  /**
   * -11022: Unsubscribe channel failed.
   */
  RTM_ERROR_CHANNEL_UNSUBSCRIBE_FAILED = -11022,
  /**
   * -11023: Encrypt message failed.
   */
  RTM_ERROR_CHANNEL_ENCRYPT_MESSAGE_FAILED = -11023,
  /**
   * -11024: Publish message failed.
   */
  RTM_ERROR_CHANNEL_PUBLISH_MESSAGE_FAILED = -11024,
  /**
   * -11025: Publish message too frequent.
   */
  RTM_ERROR_CHANNEL_PUBLISH_MESSAGE_TOO_FREQUENT = -11025,
  /**
   * -11026: Publish message timeout.
   */
  RTM_ERROR_CHANNEL_PUBLISH_MESSAGE_TIMEOUT = -11026,
  /**
   * -11027: The connection state is invalid.
   */
  RTM_ERROR_CHANNEL_NOT_CONNECTED = -11027,
  /**
   * -11028: Leave channel failed.
   */
  RTM_ERROR_CHANNEL_LEAVE_FAILED = -11028,
  /**
   * -11029: The custom type length exceeds the limit.
   */
  RTM_ERROR_CHANNEL_CUSTOM_TYPE_LENGTH_OVERFLOW = -11029,
  /**
   * -11030: The custom type is invalid.
   */
  RTM_ERROR_CHANNEL_INVALID_CUSTOM_TYPE = -11030,
  /**
   * -11031: unsupported message type (in MacOS/iOS platform，message only support NSString and NSData)
   */
  RTM_ERROR_CHANNEL_UNSUPPORTED_MESSAGE_TYPE = -11031,
  /**
   * -11032: The channel presence is not ready.
   */
  RTM_ERROR_CHANNEL_PRESENCE_NOT_READY = -11032,
  /**
   * -11033: The destination user of publish message is offline.
   */
  RTM_ERROR_CHANNEL_RECEIVER_OFFLINE = -11033,
  /**
   * -11034: The channel join operation is canceled.
   */
  RTM_ERROR_CHANNEL_JOIN_CANCELED = -11034,

  /**
   * -12001 ~ -13000 : reserved for storage error.
   * -12001: The storage operation failed.
   */
  RTM_ERROR_STORAGE_OPERATION_FAILED = -12001,
  /**
   * -12002: The metadata item count exceeds the limit.
   */
  RTM_ERROR_STORAGE_METADATA_ITEM_EXCEED_LIMITATION = -12002,
  /**
   * -12003: The metadata item is invalid.
   */
  RTM_ERROR_STORAGE_INVALID_METADATA_ITEM = -12003,
  /**
   * -12004: The argument in storage operation is invalid.
   */
  RTM_ERROR_STORAGE_INVALID_ARGUMENT = -12004,
  /**
   * -12005: The revision in storage operation is invalid.
   */
  RTM_ERROR_STORAGE_INVALID_REVISION = -12005,
  /**
   * -12006: The metadata length exceeds the limit.
   */
  RTM_ERROR_STORAGE_METADATA_LENGTH_OVERFLOW = -12006,
  /**
   * -12007: The lock name in storage operation is invalid.
   */
  RTM_ERROR_STORAGE_INVALID_LOCK_NAME = -12007,
  /**
   * -12008: The lock in storage operation is not acquired.
   */
  RTM_ERROR_STORAGE_LOCK_NOT_ACQUIRED = -12008,
  /**
   * -12009: The metadata key is invalid.
   */
  RTM_ERROR_STORAGE_INVALID_KEY = -12009,
  /**
   * -12010: The metadata value is invalid.
   */
  RTM_ERROR_STORAGE_INVALID_VALUE = -12010,
  /**
   * -12011: The metadata key length exceeds the limit.
   */
  RTM_ERROR_STORAGE_KEY_LENGTH_OVERFLOW = -12011,
  /**
   * -12012: The metadata value length exceeds the limit.
   */
  RTM_ERROR_STORAGE_VALUE_LENGTH_OVERFLOW = -12012,
  /**
   * -12013: The metadata key already exists.
   */
  RTM_ERROR_STORAGE_DUPLICATE_KEY = -12013,
  /**
   * -12014: The revision in storage operation is outdated.
   */
  RTM_ERROR_STORAGE_OUTDATED_REVISION = -12014,
  /**
   * -12015: The storage operation performed without subscribing.
   */
  RTM_ERROR_STORAGE_NOT_SUBSCRIBE = -12015,
  /**
   * -12016: The metadata item is invalid.
   */
  RTM_ERROR_STORAGE_INVALID_METADATA_INSTANCE = -12016,
  /**
   * -12017: The user count exceeds the limit when try to subscribe.
   */
  RTM_ERROR_STORAGE_SUBSCRIBE_USER_EXCEED_LIMITATION = -12017,
  /**
   * -12018: The storage operation timeout.
   */
  RTM_ERROR_STORAGE_OPERATION_TIMEOUT = -12018,
  /**
   * -12019: The storage service not available.
   */
  RTM_ERROR_STORAGE_NOT_AVAILABLE = -12019,

  /**
   * -13001 ~ -14000 : reserved for presence error.
   * -13001: The user is not connected.
   */
  RTM_ERROR_PRESENCE_NOT_CONNECTED = -13001,
  /**
   * -13002: The presence is not writable.
   */
  RTM_ERROR_PRESENCE_NOT_WRITABLE = -13002,
  /**
   * -13003: The argument in presence operation is invalid.
   */
  RTM_ERROR_PRESENCE_INVALID_ARGUMENT = -13003,
  /**
   * -13004: The cached presence state count exceeds the limit.
   */
  RTM_ERROR_PRESENCE_CACHED_TOO_MANY_STATES = -13004,
  /**
   * -13005: The state count exceeds the limit.
   */
  RTM_ERROR_PRESENCE_STATE_COUNT_OVERFLOW = -13005,
  /**
   * -13006: The state key is invalid.
   */
  RTM_ERROR_PRESENCE_INVALID_STATE_KEY = -13006,
  /**
   * -13007: The state value is invalid.
   */
  RTM_ERROR_PRESENCE_INVALID_STATE_VALUE = -13007,
  /**
   * -13008: The state key length exceeds the limit.
   */
  RTM_ERROR_PRESENCE_STATE_KEY_SIZE_OVERFLOW = -13008,
  /**
   * -13009: The state value length exceeds the limit.
   */
  RTM_ERROR_PRESENCE_STATE_VALUE_SIZE_OVERFLOW = -13009,
  /**
   * -13010: The state key already exists.
   */
  RTM_ERROR_PRESENCE_STATE_DUPLICATE_KEY = -13010,
  /**
   * -13011: The user is not exist.
   */
  RTM_ERROR_PRESENCE_USER_NOT_EXIST = -13011,
  /**
   * -13012: The presence operation timeout.
   */
  RTM_ERROR_PRESENCE_OPERATION_TIMEOUT = -13012,
  /**
   * -13013: The presence operation failed.
   */
  RTM_ERROR_PRESENCE_OPERATION_FAILED = -13013,

  /**
   * -14001 ~ -15000 : reserved for lock error.
   * -14001: The lock operation failed.
   */
  RTM_ERROR_LOCK_OPERATION_FAILED = -14001,
  /**
   * -14002: The lock operation timeout.
   */
  RTM_ERROR_LOCK_OPERATION_TIMEOUT = -14002,
  /**
   * -14003: The lock operation is performing.
   */
  RTM_ERROR_LOCK_OPERATION_PERFORMING = -14003,
  /**
   * -14004: The lock already exists.
   */
  RTM_ERROR_LOCK_ALREADY_EXIST = -14004,
  /**
   * -14005: The lock name is invalid.
   */
  RTM_ERROR_LOCK_INVALID_NAME = -14005,
  /**
   * -14006: The lock is not acquired.
   */
  RTM_ERROR_LOCK_NOT_ACQUIRED = -14006,
  /**
   * -14007: Acquire lock failed.
   */
  RTM_ERROR_LOCK_ACQUIRE_FAILED = -14007,
  /**
   * -14008: The lock is not exist.
   */
  RTM_ERROR_LOCK_NOT_EXIST = -14008,
  /**
   * -14009: The lock service is not available.
   */
  RTM_ERROR_LOCK_NOT_AVAILABLE = -14009,
};

/**
 * Connection states between rtm sdk and agora server.
 */
enum RTM_CONNECTION_STATE {
  /**
   * 1: The SDK is disconnected with server.
   */
  RTM_CONNECTION_STATE_DISCONNECTED = 1,
  /**
   * 2: The SDK is connecting to the server.
   */
  RTM_CONNECTION_STATE_CONNECTING = 2,
  /**
   * 3: The SDK is connected to the server and has joined a channel. You can now publish or subscribe to
   * a track in the channel.
   */
  RTM_CONNECTION_STATE_CONNECTED = 3,
  /**
   * 4: The SDK keeps rejoining the channel after being disconnected from the channel, probably because of
   * network issues.
   */
  RTM_CONNECTION_STATE_RECONNECTING = 4,
  /**
   * 5: The SDK fails to connect to the server or join the channel.
   */
  RTM_CONNECTION_STATE_FAILED = 5,
};

/**
 * Reasons for connection state change.
 */
enum RTM_CONNECTION_CHANGE_REASON {
  /**
   * 0: The SDK is connecting to the server.
   */
  RTM_CONNECTION_CHANGED_CONNECTING = 0,
  /**
   * 1: The SDK has joined the channel successfully.
   */
  RTM_CONNECTION_CHANGED_JOIN_SUCCESS = 1,
  /**
   * 2: The connection between the SDK and the server is interrupted.
   */
  RTM_CONNECTION_CHANGED_INTERRUPTED = 2,
  /**
   * 3: The connection between the SDK and the server is banned by the server.
   */
  RTM_CONNECTION_CHANGED_BANNED_BY_SERVER = 3,
  /**
   * 4: The SDK fails to join the channel for more than 20 minutes and stops reconnecting to the channel.
   */
  RTM_CONNECTION_CHANGED_JOIN_FAILED = 4,
  /**
   * 5: The SDK has left the channel.
   */
  RTM_CONNECTION_CHANGED_LEAVE_CHANNEL = 5,
  /**
   * 6: The connection fails because the App ID is not valid.
   */
  RTM_CONNECTION_CHANGED_INVALID_APP_ID = 6,
  /**
   * 7: The connection fails because the channel name is not valid.
   */
  RTM_CONNECTION_CHANGED_INVALID_CHANNEL_NAME = 7,
  /**
   * 8: The connection fails because the token is not valid.
   */
  RTM_CONNECTION_CHANGED_INVALID_TOKEN = 8,
  /**
   * 9: The connection fails because the token has expired.
   */
  RTM_CONNECTION_CHANGED_TOKEN_EXPIRED = 9,
  /**
   * 10: The connection is rejected by the server.
   */
  RTM_CONNECTION_CHANGED_REJECTED_BY_SERVER = 10,
  /**
   * 11: The connection changes to reconnecting because the SDK has set a proxy server.
   */
  RTM_CONNECTION_CHANGED_SETTING_PROXY_SERVER = 11,
  /**
   * 12: When the connection state changes because the app has renewed the token.
   */
  RTM_CONNECTION_CHANGED_RENEW_TOKEN = 12,
  /**
   * 13: The IP Address of the app has changed. A change in the network type or IP/Port changes the IP
   * address of the app.
   */
  RTM_CONNECTION_CHANGED_CLIENT_IP_ADDRESS_CHANGED = 13,
  /**
   * 14: A timeout occurs for the keep-alive of the connection between the SDK and the server.
   */
  RTM_CONNECTION_CHANGED_KEEP_ALIVE_TIMEOUT = 14,
  /**
   * 15: The SDK has rejoined the channel successfully.
   */
  RTM_CONNECTION_CHANGED_REJOIN_SUCCESS = 15,
  /**
   * 16: The connection between the SDK and the server is lost.
   */
  RTM_CONNECTION_CHANGED_LOST = 16,
  /**
   * 17: The change of connection state is caused by echo test.
   */
  RTM_CONNECTION_CHANGED_ECHO_TEST = 17,
  /**
   * 18: The local IP Address is changed by user.
   */
  RTM_CONNECTION_CHANGED_CLIENT_IP_ADDRESS_CHANGED_BY_USER = 18,
  /**
   * 19: The connection is failed due to join the same channel on another device with the same uid.
   */
  RTM_CONNECTION_CHANGED_SAME_UID_LOGIN = 19,
  /**
   * 20: The connection is failed due to too many broadcasters in the channel.
   */
  RTM_CONNECTION_CHANGED_TOO_MANY_BROADCASTERS = 20,
  /**
   * 21: The connection is failed due to license validation failure.
   */
  RTM_CONNECTION_CHANGED_LICENSE_VALIDATION_FAILURE = 21,
  /**
   * 22: The connection is failed due to certification verify failure.
   */
  RTM_CONNECTION_CHANGED_CERTIFICATION_VERIFY_FAILURE = 22,
  /**
   * 23: The connection is failed due to user vid not support stream channel.
   */
  RTM_CONNECTION_CHANGED_STREAM_CHANNEL_NOT_AVAILABLE = 23,
  /**
   * 24: The connection is failed due to token and appid inconsistent.
   */
  RTM_CONNECTION_CHANGED_INCONSISTENT_APPID = 24,
  /**
   * 10001: The connection of rtm edge service has been successfully established.
   */
  RTM_CONNECTION_CHANGED_LOGIN_SUCCESS = 10001,
  /**
   * 10002: User log out Agora RTM system.
   */
  RTM_CONNECTION_CHANGED_LOGOUT = 10002,
  /**
   * 10003: User log out Agora RTM system.
   */
  RTM_CONNECTION_CHANGED_PRESENCE_NOT_READY = 10003,
};

/**
 * RTM channel type.
 */
enum RTM_CHANNEL_TYPE {
  /**
   * 0: Unknown channel type.
   */
  RTM_CHANNEL_TYPE_NONE = 0,
  /**
   * 1: Message channel.
   */
  RTM_CHANNEL_TYPE_MESSAGE = 1,
  /**
   * 2: Stream channel.
   */
  RTM_CHANNEL_TYPE_STREAM = 2,
   /**
   * 3: User.
   */
  RTM_CHANNEL_TYPE_USER = 3,
};

/**
  @brief Message type when user publish message to channel or topic
  */
enum RTM_MESSAGE_TYPE {
  /**
    0: The binary message.
    */
  RTM_MESSAGE_TYPE_BINARY = 0,
  /**
    1: The ascii message.
    */
  RTM_MESSAGE_TYPE_STRING = 1,
};

/**
  @brief Storage type indicate the storage event was triggered by user or channel
  */
enum RTM_STORAGE_TYPE {
  /**
    0: Unknown type.
    */
  RTM_STORAGE_TYPE_NONE= 0,
  /**
    1: The user storage event.
    */
  RTM_STORAGE_TYPE_USER = 1,
  /**
    2: The channel storage event.
    */
  RTM_STORAGE_TYPE_CHANNEL = 2,
};

/**
  * The storage event type, indicate storage operation
  */
enum RTM_STORAGE_EVENT_TYPE {
  /**
    0: Unknown event type.
    */
  RTM_STORAGE_EVENT_TYPE_NONE= 0,
  /**
    1: Triggered when user subscribe user metadata state or join channel with options.withMetadata = true
    */
  RTM_STORAGE_EVENT_TYPE_SNAPSHOT = 1,
  /**
    2: Triggered when a remote user set metadata
    */
  RTM_STORAGE_EVENT_TYPE_SET = 2,
  /**
    3: Triggered when a remote user update metadata
    */
  RTM_STORAGE_EVENT_TYPE_UPDATE = 3,
  /**
    4: Triggered when a remote user remove metadata
    */
  RTM_STORAGE_EVENT_TYPE_REMOVE = 4,
};

/**
 * The lock event type, indicate lock operation
 */
enum RTM_LOCK_EVENT_TYPE {
  /**
   * 0: Unknown event type
   */
  RTM_LOCK_EVENT_TYPE_NONE = 0,
  /**
   * 1: Triggered when user subscribe lock state
   */
  RTM_LOCK_EVENT_TYPE_SNAPSHOT = 1,
  /**
   * 2: Triggered when a remote user set lock
   */
  RTM_LOCK_EVENT_TYPE_LOCK_SET = 2,
  /**
   * 3: Triggered when a remote user remove lock
   */
  RTM_LOCK_EVENT_TYPE_LOCK_REMOVED = 3,
  /**
   * 4: Triggered when a remote user acquired lock
   */
  RTM_LOCK_EVENT_TYPE_LOCK_ACQUIRED = 4,
  /**
   * 5: Triggered when a remote user released lock
   */
  RTM_LOCK_EVENT_TYPE_LOCK_RELEASED = 5,
  /**
   * 6: Triggered when user reconnect to rtm service,
   * detect the lock has been acquired and released by others.
   */
  RTM_LOCK_EVENT_TYPE_LOCK_EXPIRED = 6,
};

/**
 * The proxy type
 */
enum RTM_PROXY_TYPE {
  /**
   * 0: Link without proxy
   */
  RTM_PROXY_TYPE_NONE = 0,
  /**
   * 1: Link with http proxy
   */
  RTM_PROXY_TYPE_HTTP = 1,
};

/**
  @brief Topic event type
  */
enum RTM_TOPIC_EVENT_TYPE {
  /**
   * 0: Unknown event type
   */
  RTM_TOPIC_EVENT_TYPE_NONE = 0,
  /**
   * 1: The topic snapshot of this channel
   */
  RTM_TOPIC_EVENT_TYPE_SNAPSHOT = 1,
  /**
   * 2: Triggered when remote user join a topic
   */
  RTM_TOPIC_EVENT_TYPE_REMOTE_JOIN_TOPIC = 2,
  /**
   * 3: Triggered when remote user leave a topic
   */
  RTM_TOPIC_EVENT_TYPE_REMOTE_LEAVE_TOPIC = 3,
};

/**
  @brief Presence event type
  */
enum RTM_PRESENCE_EVENT_TYPE {
  /**
   * 0: Unknown event type
   */
  RTM_PRESENCE_EVENT_TYPE_NONE = 0,
  /**
   * 1: The presence snapshot of this channel
   */
  RTM_PRESENCE_EVENT_TYPE_SNAPSHOT = 1,
  /**
   * 2: The presence event triggered in interval mode
   */
  RTM_PRESENCE_EVENT_TYPE_INTERVAL = 2,
  /**
   * 3: Triggered when remote user join channel
   */
  RTM_PRESENCE_EVENT_TYPE_REMOTE_JOIN_CHANNEL = 3,
  /**
   * 4: Triggered when remote user leave channel
   */
  RTM_PRESENCE_EVENT_TYPE_REMOTE_LEAVE_CHANNEL = 4,
  /**
   * 5: Triggered when remote user's connection timeout
   */
  RTM_PRESENCE_EVENT_TYPE_REMOTE_TIMEOUT = 5,
  /**
   * 6: Triggered when user changed state
   */
  RTM_PRESENCE_EVENT_TYPE_REMOTE_STATE_CHANGED = 6,
  /**
   * 7: Triggered when user joined channel without presence service
   */
  RTM_PRESENCE_EVENT_TYPE_ERROR_OUT_OF_SERVICE = 7,
};

/** 
 * Definition of LogConfiguration
 */
struct RtmLogConfig {
  /**
   * The log file path, default is NULL for default log path
   */
  const char* filePath;
  /** 
   * The log file size, KB , set 1024KB to use default log size
   */
  uint32_t fileSizeInKB;
  /**
   *  The log level, set LOG_LEVEL_INFO to use default log level
   */
  RTM_LOG_LEVEL level;

  RtmLogConfig() : filePath(NULL), fileSizeInKB(DEFAULT_LOG_SIZE_IN_KB), level(RTM_LOG_LEVEL_INFO) {}
};

/**
 * User list.
 */
struct UserList {
  /**
   * The list of users.
   */
  const char** users;
  /**
   * The number of users.
   */
  size_t userCount;

  UserList() : users(NULL), userCount(0) {}
};

/**
  @brief Topic publisher information
  */
struct PublisherInfo {
  /**
   * The publisher user ID
   */
  const char* publisherUserId;
  /**
   * The metadata of the publisher
   */
  const char* publisherMeta;

  PublisherInfo() : publisherUserId(NULL),
                    publisherMeta(NULL) {}
};

/**
  @brief Topic information
  */
struct TopicInfo {
  /**
   * The name of the topic
   */
  const char* topic;
  /**
   * The publisher array
   */
  PublisherInfo* publishers;
  /**
   * The count of publisher in current topic
   */
  size_t publisherCount;

  TopicInfo() : topic(NULL),
                publishers(NULL),
                publisherCount(0) {}
};

/**
  @brief User state property
  */
struct StateItem {
  /**
   * The key of the state item.
   */
  const char* key;
  /**
   * The value of the state item.
   */
  const char* value;

  StateItem() : key(NULL), value(NULL) {}
};

/**
 *  The information of a Lock.
 */
struct LockDetail {
  /**
   * The name of the lock.
   */
  const char* lockName;
  /**
   * The owner of the lock. Only valid when user getLocks or receive LockEvent with RTM_LOCK_EVENT_TYPE_SNAPSHOT
   */
  const char* owner;
  /**
   * The ttl of the lock.
   */
  uint32_t ttl;

  LockDetail() : lockName(NULL),
                 owner(NULL),
                 ttl(0) {}
};

/**
 *  The states of user.
 */
struct UserState {
  /**
   * The user id.
   */
  const char* userId;
  /**
   * The user states.
   */
  const StateItem* states;
  /**
   * The count of user states.
   */
  size_t statesCount;

  UserState() : userId(NULL),
                states(NULL),
                statesCount(0) {}
};

/**
 *  The subscribe option.
 */
struct SubscribeOptions {
  /**
   * Whether to subscribe channel with message
   */
  bool withMessage;
  /**
   * Whether to subscribe channel with metadata
   */
  bool withMetadata;
  /**
   * Whether to subscribe channel with user presence
   */
  bool withPresence;
  /**
   * Whether to subscribe channel with lock
   */
  bool withLock;

  /**
   * Whether to subscribe channel in quiet mode
   * Quiet mode means remote user will not receive any notification when we subscribe or
   * unsubscribe or change our presence state
   */
  bool beQuiet;

  SubscribeOptions() : withMessage(true),
                       withMetadata(false),
                       withPresence(true),
                       withLock(false),
                       beQuiet(false) {}
};

/**
 *  The channel information.
 */
struct ChannelInfo {
  /**
   * The channel which the message was published
   */
  const char* channelName;
  /**
   * Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE
   */
  RTM_CHANNEL_TYPE channelType;
};

/**
 *  The option to query user presence.
 */
struct PresenceOptions {
  /**
   * Whether to display user id in query result
   */
  bool includeUserId;
  /**
   * Whether to display user state in query result
   */
  bool includeState;
  /**
   * The paging object used for pagination.
   */
  const char* page;

  PresenceOptions() : includeUserId(true),
                      includeState(false),
                      page(NULL) {}
};

/**
  @brief Publish message option
  */
struct PublishOptions {
  /*
   The channel type.
  */
  RTM_CHANNEL_TYPE channelType;  
  /**
    The message type.
    */
  RTM_MESSAGE_TYPE messageType;
  /**
    The custom type of the message, up to 32 bytes for customize
    */
  const char* customType;

  PublishOptions() : channelType(RTM_CHANNEL_TYPE_MESSAGE), messageType(RTM_MESSAGE_TYPE_BINARY),
                     customType(NULL) {}
};

/**
  @brief topic message option
  */
struct TopicMessageOptions {
  /**
    The message type.
    */
  RTM_MESSAGE_TYPE messageType;
  /**
    The time to calibrate data with media,
    only valid when user join topic with syncWithMedia in stream channel
    */
  uint64_t sendTs;
  /**
    The custom type of the message, up to 32 bytes for customize
    */
  const char* customType;

  TopicMessageOptions() : messageType(RTM_MESSAGE_TYPE_BINARY),
                     sendTs(0), customType(NULL) {}
};

/**
 *  The option to query user presence.
 */
struct GetOnlineUsersOptions {
  /**
   * Whether to display user id in query result
   */
  bool includeUserId;
  /**
   * Whether to display user state in query result
   */
  bool includeState;
  /**
   * The paging object used for pagination.
   */
  const char* page;

  GetOnlineUsersOptions() : includeUserId(true),
                      includeState(false),
                      page(NULL) {}
};

/**
  @brief Proxy configuration
  */
struct RtmProxyConfig {
  /**
    The Proxy type.
    */
  RTM_PROXY_TYPE proxyType;
  /**
    The Proxy server address.
    */
  const char* server;
  /**
    The Proxy server port.
    */
  uint16_t port;
  /**
    The Proxy user account.
    */
  const char* account;
  /**
    The Proxy password.
    */
  const char* password;

  RtmProxyConfig() : proxyType(RTM_PROXY_TYPE_NONE),
                     server(NULL),
                     port(0),
                     account(NULL),
                     password(NULL) {}
};

/**
  @brief encryption configuration
  */
struct RtmEncryptionConfig {
  /**
   * The encryption mode.
   */
  RTM_ENCRYPTION_MODE  encryptionMode;

  /**
   * The encryption key in the string format.
   */
  const char* encryptionKey;

  /**
   * The encryption salt.
   */
  uint8_t encryptionSalt[32];

  RtmEncryptionConfig() : encryptionMode(RTM_ENCRYPTION_MODE_NONE),
                       encryptionKey(NULL) {
    memset(encryptionSalt, 0, sizeof(encryptionSalt));
  }
};

struct RtmPrivateConfig {
  /**
   * Rtm service type.
   */
  RTM_SERVICE_TYPE serviceType;

  /**
   * Local access point hosts list.
   */
  const char** accessPointHosts;

  /**
   * The count of access point hosts list.
   */
  size_t accessPointHostsCount;

  RtmPrivateConfig() : serviceType(RTM_SERVICE_TYPE_NONE), accessPointHosts(NULL), accessPointHostsCount(0) {}
};

}  // namespace rtm
}  // namespace agora
