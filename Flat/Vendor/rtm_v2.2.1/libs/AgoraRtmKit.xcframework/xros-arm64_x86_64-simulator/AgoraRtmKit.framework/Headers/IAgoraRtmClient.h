
// Copyright (c) 2022 Agora.io. All rights reserved

// This program is confidential and proprietary to Agora.io.
// And may not be copied, reproduced, modified, disclosed to others, published
// or used, in whole or in part, without the express prior written permission
// of Agora.io.

#pragma once  // NOLINT(build/header_guard)

#include "IAgoraStreamChannel.h"
#include "IAgoraRtmStorage.h"
#include "IAgoraRtmPresence.h"
#include "IAgoraRtmLock.h"
#include "AgoraRtmBase.h"

#ifndef OPTIONAL_ENUM_CLASS
#if __cplusplus >= 201103L || (defined(_MSC_VER) && _MSC_VER >= 1800)
#define OPTIONAL_ENUM_CLASS enum class
#else
#define OPTIONAL_ENUM_CLASS enum
#endif
#endif

namespace agora {
namespace rtm {

class IRtmEventHandler;

/**
 *  Configurations for RTM Client.
 */
struct RtmConfig {
  /**
   * The App ID of your project.
   */
  const char* appId;

  /**
   * The ID of the user.
   */
  const char* userId;

  /**
   * The region for connection. This advanced feature applies to scenarios that
   * have regional restrictions.
   *
   * For the regions that Agora supports, see #AREA_CODE.
   *
   * After specifying the region, the SDK connects to the Agora servers within
   * that region.
   */
  RTM_AREA_CODE areaCode;

  /**
   * The protocol used for connecting to the Agora RTM service.
   */
  RTM_PROTOCOL_TYPE protocolType;

  /**
   * Presence timeout in seconds, specify the timeout value when you lost connection between sdk
   * and rtm service.
   */
  uint32_t presenceTimeout;

  /**
   * Heartbeat interval in seconds, specify the interval value of sending heartbeat between sdk
   * and rtm service.
   */
  uint32_t heartbeatInterval;

  /**
   * - For Android, it is the context of Activity or Application.
   * - For Windows, it is the window handle of app. Once set, this parameter enables you to plug
   * or unplug the video devices while they are powered.
   */
  void* context;

  /**
   * Whether to use String user IDs, if you are using RTC products with Int user IDs,
   * set this value as 'false'. Otherwise errors might occur.
   */
  bool useStringUserId;

  /**
   * Whether to enable multipath, introduced from 2.2.0, for now , only effect on stream channel.
   */
  bool multipath;

  /**
   * The callbacks handler
   */
  IRtmEventHandler* eventHandler;

  /**
   * The config for customer set log path, log size and log level.
   */
  RtmLogConfig logConfig;

  /**
   * The config for proxy setting
   */
  RtmProxyConfig proxyConfig;

  /**
   * The config for encryption setting
   */
  RtmEncryptionConfig  encryptionConfig;

  /**
   * The config for private setting
   */
  RtmPrivateConfig privateConfig;

  RtmConfig() : appId(NULL),
                userId(NULL),
                areaCode(RTM_AREA_CODE_GLOB),
                protocolType(RTM_PROTOCOL_TYPE_TCP_UDP),
                presenceTimeout(300),
                heartbeatInterval(5),
                context(NULL),
                useStringUserId(true),
                multipath(false),
                eventHandler(NULL) {}
};

/**
 * The IRtmEventHandler class.
 *
 * The SDK uses this class to send callback event notifications to the app, and the app inherits
 * the methods in this class to retrieve these event notifications.
 *
 * All methods in this class have their default (empty)  implementations, and the app can inherit
 * only some of the required events instead of all. In the callback methods, the app should avoid
 * time-consuming tasks or calling blocking APIs, otherwise the SDK may not work properly.
 */
class IRtmEventHandler {
 public:
  virtual ~IRtmEventHandler() {}

  struct LinkStateEvent {
    /**
     * The current link state
     */
    RTM_LINK_STATE currentState;
    /**
     * The previous link state
     */
    RTM_LINK_STATE previousState;
    /**
     * The service type
     */
    RTM_SERVICE_TYPE serviceType;
    /**
     * The operation which trigger this event
     */
    RTM_LINK_OPERATION operation;
    /**
     * The reason of this state change event
     */
    const char* reason;
    /**
     * The affected channels
     */
    const char** affectedChannels;
    /**
     * The affected channel count
     */
  size_t affectedChannelCount;
    /**
     * The unrestored channels
     */
    const char** unrestoredChannels;
    /**
     * The unrestored channel count
     */
    size_t unrestoredChannelCount;
    /**
     * Is resumed from disconnected state
     */
    bool isResumed;
    /**
     * RTM server UTC time
     */
    uint64_t timestamp;

    LinkStateEvent() : currentState(RTM_LINK_STATE_IDLE),
                       previousState(RTM_LINK_STATE_IDLE),
                       serviceType(RTM_SERVICE_TYPE_MESSAGE),
                       operation(RTM_LINK_OPERATION_LOGIN),
                       reason(NULL),
                       affectedChannels(NULL),
                       affectedChannelCount(0),
                       unrestoredChannels(NULL),
                       unrestoredChannelCount(0),
                       isResumed(false),
                       timestamp(0) {}
  };

  struct MessageEvent {
    /**
     * Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE
     */
    RTM_CHANNEL_TYPE channelType;
    /**
     * Message type
     */
    RTM_MESSAGE_TYPE messageType;
    /**
     * The channel which the message was published
     */
    const char* channelName;
    /**
     * If the channelType is RTM_CHANNEL_TYPE_STREAM, which topic the message came from. only for RTM_CHANNEL_TYPE_STREAM
     */
    const char* channelTopic;
    /**
     * The payload
     */
    const char* message;
    /**
     * The payload length
     */
    size_t messageLength;
    /**
     * The publisher
     */
    const char* publisher;
    /**
     * The custom type of the message
     */
    const char* customType;
    /**
     * RTM server UTC time
     */
    uint64_t timestamp;

    MessageEvent() : channelType(RTM_CHANNEL_TYPE_NONE),
                     messageType(RTM_MESSAGE_TYPE_BINARY),
                     channelName(NULL),
                     channelTopic(NULL),
                     message(NULL),
                     messageLength(0),
                     publisher(NULL),
                     customType(NULL),
                     timestamp(0) {}
  };

  struct PresenceEvent {

    struct IntervalInfo {
      /**
       * Joined users during this interval
       */
      UserList joinUserList;
      /**
       * Left users during this interval
       */
      UserList leaveUserList;
      /**
       * Timeout users during this interval
       */
      UserList timeoutUserList;
      /**
       * The user state changed during this interval
       */
      UserState* userStateList;
      /**
       * The user count
       */
      size_t userStateCount;

      IntervalInfo() : userStateList(NULL),
                       userStateCount(0) {}
    };

    struct SnapshotInfo {
      /**
       * The user state in this snapshot event
       */
      UserState* userStateList;
      /**
       * The user count
       */
      size_t userCount;

      SnapshotInfo() : userStateList(NULL),
                       userCount(0) {}
    };

    /**
     * Indicate presence event type
     */
    RTM_PRESENCE_EVENT_TYPE type;
    /**
     * Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE
     */
    RTM_CHANNEL_TYPE channelType;
    /**
     * The channel which the presence event was triggered
     */
    const char* channelName;
    /**
     * The user who triggered this event.
     */
    const char* publisher;
    /**
     * The user states
     */
    const StateItem* stateItems;
    /**
     * The states count
     */
    size_t stateItemCount;
    /**
     * Only valid when in interval mode
     */
    IntervalInfo interval;
    /**
     * Only valid when receive snapshot event
     */
    SnapshotInfo snapshot;
    /**
     * RTM server UTC time 
     */
    uint64_t timestamp;

    PresenceEvent() : type(RTM_PRESENCE_EVENT_TYPE_NONE),
                      channelType(RTM_CHANNEL_TYPE_NONE),
                      channelName(NULL),
                      publisher(NULL),
                      stateItems(NULL),
                      stateItemCount(0),
                      timestamp(0) {}
  };

  struct TopicEvent {
    /**
     * Indicate topic event type
     */
    RTM_TOPIC_EVENT_TYPE type;
    /**
     * The channel which the topic event was triggered
     */
    const char* channelName;
    /**
     * The user who triggered this event.
     */
    const char* publisher;
    /**
     * Topic information array.
     */
    const TopicInfo* topicInfos;
    /**
     * The count of topicInfos.
     */
    size_t topicInfoCount;
    /**
     * RTM server UTC time 
     */
    uint64_t timestamp;

    TopicEvent() : type(RTM_TOPIC_EVENT_TYPE_NONE),
                   channelName(NULL),
                   publisher(NULL),
                   topicInfos(NULL),
                   topicInfoCount(0),
                   timestamp(0) {}
  };

  struct LockEvent {
    /**
     * Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE
     */
    RTM_CHANNEL_TYPE channelType;
    /**
     * Lock event type, indicate lock states
     */
    RTM_LOCK_EVENT_TYPE eventType;
    /**
     * The channel which the lock event was triggered
     */
    const char* channelName;
    /**
     * The detail information of locks
     */
    const LockDetail* lockDetailList;
    /**
     * The count of locks
     */
    size_t count;
    /**
     * RTM server UTC time 
     */
    uint64_t timestamp;

    LockEvent() : channelType(RTM_CHANNEL_TYPE_NONE),
                  eventType(RTM_LOCK_EVENT_TYPE_NONE),
                  channelName(NULL),
                  lockDetailList(NULL),
                  count(0),
                  timestamp(0) {}
  };

  struct StorageEvent {
    /**
     * Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE
     */
    RTM_CHANNEL_TYPE channelType;
    /**
     * Storage type, RTM_STORAGE_TYPE_USER or RTM_STORAGE_TYPE_CHANNEL
     */
    RTM_STORAGE_TYPE storageType;
    /**
     * Indicate storage event type
     */
    RTM_STORAGE_EVENT_TYPE eventType;
    /**
     * The target name of user or channel, depends on the RTM_STORAGE_TYPE
     */
    const char* target;
    /**
     * The metadata information
     */
    Metadata data;
    /**
     * RTM server UTC time 
     */
    uint64_t timestamp;

    StorageEvent() : channelType(RTM_CHANNEL_TYPE_NONE),
                     storageType(RTM_STORAGE_TYPE_NONE),
                     eventType(RTM_STORAGE_EVENT_TYPE_NONE),
                     target(NULL),
                     timestamp(0) {}
  };


  /**
   * Occurs when link state change
   *
   * @param event details of link state event
   */
  virtual void onLinkStateEvent(const LinkStateEvent& event) {
    (void)event;
  }

  /**
   * Occurs when receive a message.
   *
   * @param event details of message event.
   */
  virtual void onMessageEvent(const MessageEvent& event) {
    (void)event;
  }

  /**
   * Occurs when remote user presence changed
   *
   * @param event details of presence event.
   */
  virtual void onPresenceEvent(const PresenceEvent& event) {
    (void)event;
  }

  /**
   * Occurs when remote user join/leave topic or when user first join this channel,
   * got snapshot of topics in this channel
   *
   * @param event details of topic event.
   */
  virtual void onTopicEvent(const TopicEvent& event) {
    (void)event;
  }

  /**
   * Occurs when lock state changed
   *
   * @param event details of lock event.
   */
  virtual void onLockEvent(const LockEvent& event) {
    (void)event;
  }

  /**
   * Occurs when receive storage event
   *
   * @param event details of storage event.
   */
  virtual void onStorageEvent(const StorageEvent& event) {
    (void)event;
  }

  /**
   * Occurs when user join a stream channel.
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param userId The id of the user.
   * @param errorCode The error code.
   */
  virtual void onJoinResult(const uint64_t requestId, const char* channelName, const char* userId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)userId;
    (void)errorCode;
  }

  /**
   * Occurs when user leave a stream channel.
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param userId The id of the user.
   * @param errorCode The error code.
   */
  virtual void onLeaveResult(const uint64_t requestId, const char* channelName, const char* userId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)userId;
    (void)errorCode;
  }

  /**
   * Occurs when user publish topic message.
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param topic The name of the topic.
   * @param errorCode The error code.
   */
  virtual void onPublishTopicMessageResult(const uint64_t requestId, const char* channelName, const char* topic, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)topic;
    (void)errorCode;
  }

  /**
   * Occurs when user join topic.
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param userId The id of the user.
   * @param topic The name of the topic.
   * @param meta The meta of the topic.
   * @param errorCode The error code.
   */
  virtual void onJoinTopicResult(const uint64_t requestId, const char* channelName, const char* userId, const char* topic, const char* meta, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)userId;
    (void)topic;
    (void)meta;
    (void)errorCode;
  }

  /**
   * Occurs when user leave topic.
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param userId The id of the user.
   * @param topic The name of the topic.
   * @param meta The meta of the topic.
   * @param errorCode The error code.
   */
  virtual void onLeaveTopicResult(const uint64_t requestId, const char* channelName, const char* userId, const char* topic, const char* meta, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)userId;
    (void)topic;
    (void)meta;
    (void)errorCode;
  }

  /**
   * Occurs when user subscribe topic.
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param userId The id of the user.
   * @param topic The name of the topic.
   * @param succeedUsers The subscribed users.
   * @param failedUser The failed to subscribe users.
   * @param errorCode The error code.
   */
  virtual void onSubscribeTopicResult(const uint64_t requestId, const char* channelName, const char* userId, const char* topic, UserList succeedUsers, UserList failedUsers, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)userId;
    (void)topic;
    (void)succeedUsers;
    (void)failedUsers;
    (void)errorCode;
  }

  /**
   * Occurs when user call unsubscribe topic.
   * 
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param topic The name of the topic.
   * @param errorCode The error code.
   */
  virtual void onUnsubscribeTopicResult(const uint64_t requestId, const char* channelName, const char* topic, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)topic;
    (void)errorCode;
  }

  /**
   * Occurs when user call get subscribe user list.
   * 
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param topic The name of the topic.
   * @param users The subscribed user list.
   * @param errorCode The error code.
   */
  virtual void onGetSubscribedUserListResult(const uint64_t requestId, const char* channelName, const char* topic, UserList users, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)topic;
    (void)users;
    (void)errorCode;
  }

  /**
   * @deprecated This callback is deprecated. Use LinkStateEvent instead.
   * Occurs when the connection state changes between rtm sdk and agora service.
   *
   * @param channelName The name of the channel.
   * @param state The new connection state.
   * @param reason The reason for the connection state change.
   */
  virtual void onConnectionStateChanged(const char* channelName, RTM_CONNECTION_STATE state, RTM_CONNECTION_CHANGE_REASON reason) {
    (void)channelName;
    (void)state;
    (void)reason;
  }

  /**
   * Occurs when token will expire in 30 seconds.
   *
   * @param channelName The name of the channel.
   */
  virtual void onTokenPrivilegeWillExpire(const char* channelName) {
    (void)channelName;
  }

  /**
   * Occurs when subscribe a channel
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param errorCode The error code.
   */
  virtual void onSubscribeResult(const uint64_t requestId, const char* channelName, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)errorCode;
  }

  /**
   * Occurs when unsubscribe a channel
   *
   * @param requestId The related request id when user unsubscribe.
   * @param channelName The name of the channel.
   * @param errorCode The error code.
   */
  virtual void onUnsubscribeResult(const uint64_t requestId, const char* channelName, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)errorCode;
  }

  /**
   * Occurs when user publish message.
   *
   * @param requestId The related request id when user publish message
   * @param errorCode The error code.
   */
  virtual void onPublishResult(const uint64_t requestId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)errorCode;
  }

  /**
   * Occurs when user login.
   *
   * @param requestId The related request id when user perform this operation
   * @param errorCode The error code.
   */
  virtual void onLoginResult(const uint64_t requestId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)errorCode;
  }

  /**
   * Occurs when user logout.
   *
   * @param requestId The related request id when user perform this operation.
   * @param errorCode The error code.
   */
  virtual void onLogoutResult(const uint64_t requestId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)errorCode;
  }

  /**
   * Occurs when user renew token.
   *
   * @param requestId The related request id when user renew token.
   * @param serverType The type of server.
   * @param channelName The name of the channel.
   * @param errorCode The error code.
   */
  virtual void onRenewTokenResult(const uint64_t requestId, RTM_SERVICE_TYPE serverType, const char* channelName, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)serverType;
    (void)channelName;
    (void)errorCode;
  }

  /**
   * Occurs when user setting the channel metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param errorCode The error code.
   */
  virtual void onSetChannelMetadataResult(
      const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)errorCode;
  }

  /**
   * Occurs when user updating the channel metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param errorCode The error code.
   */
  virtual void onUpdateChannelMetadataResult(
      const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)errorCode;
  }

  /**
   * Occurs when user removing the channel metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param errorCode The error code.
   */
  virtual void onRemoveChannelMetadataResult(
      const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)errorCode;
  }

  /**
   * Occurs when user try to get the channel metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param data The result metadata of getting operation.
   * @param errorCode The error code.
   */
  virtual void onGetChannelMetadataResult(
      const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, const Metadata& data, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)data;
    (void)errorCode;
  }

  /**
   * Occurs when user setting the user metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param userId The id of the user.
   * @param errorCode The error code.
   */
  virtual void onSetUserMetadataResult(
      const uint64_t requestId, const char* userId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)userId;
    (void)errorCode;
  }

  /**
   * Occurs when user updating the user metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param userId The id of the user.
   * @param errorCode The error code.
   */
  virtual void onUpdateUserMetadataResult(
      const uint64_t requestId, const char* userId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)userId;
    (void)errorCode;
  }

  /**
   * Occurs when user removing the user metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param userId The id of the user.
   * @param errorCode The error code.
   */
  virtual void onRemoveUserMetadataResult(
      const uint64_t requestId, const char* userId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)userId;
    (void)errorCode;
  }

  /**
   * Occurs when user try to get the user metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param userId The id of the user.
   * @param data The result metadata of getting operation.
   * @param errorCode The error code.
   */
  virtual void onGetUserMetadataResult(
      const uint64_t requestId, const char* userId, const Metadata& data, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)userId;
    (void)data;
    (void)errorCode;
  }

  /**
   * Occurs when user subscribe a user metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param userId The id of the user.
   * @param errorCode The error code.
   */
  virtual void onSubscribeUserMetadataResult(const uint64_t requestId, const char* userId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)userId;
    (void)errorCode;
  }

  /**
   * Occurs when user unsubscribe a user metadata
   *
   * @param requestId The related request id when user perform this operation
   * @param userId The id of the user.
   * @param errorCode The error code.
   */
  virtual void onUnsubscribeUserMetadataResult(const uint64_t requestId, const char* userId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)userId;
    (void)errorCode;
  }
  
  /**
   * Occurs when user set a lock
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param errorCode The error code.
   */
  virtual void onSetLockResult(const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)lockName;
    (void)errorCode;
  }

  /**
   * Occurs when user delete a lock
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param errorCode The error code.
   */
  virtual void onRemoveLockResult(const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)lockName;
    (void)errorCode;
  }

  /**
   * Occurs when user release a lock
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param errorCode The error code.
   */
  virtual void onReleaseLockResult(const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)lockName;
    (void)errorCode;
  }

  /**
   * Occurs when user acquire a lock
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param errorCode The error code.
   * @param errorDetails The details of error.
   */
  virtual void onAcquireLockResult(const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, RTM_ERROR_CODE errorCode, const char* errorDetails) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)lockName;
    (void)errorCode;
    (void)errorDetails;
  }

  /**
   * Occurs when user revoke a lock
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param errorCode The error code.
   */
  virtual void onRevokeLockResult(const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)lockName;
    (void)errorCode;
  }

  /**
   * Occurs when user try to get locks from the channel
   *
   * @param requestId The related request id when user perform this operation
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockDetailList The details of the locks.
   * @param count The count of the locks.
   * @param errorCode The error code.
   */
  virtual void onGetLocksResult(const uint64_t requestId, const char* channelName, RTM_CHANNEL_TYPE channelType, const LockDetail* lockDetailList, const size_t count, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channelName;
    (void)channelType;
    (void)lockDetailList;
    (void)count;
    (void)errorCode;
  }

  /**
   * Occurs when query who joined this channel
   *
   * @param requestId The related request id when user perform this operation
   * @param userStatesList The states the users.
   * @param count The user count.
   * @param nextPage The next page.
   * @param errorCode The error code.
   */
  virtual void onWhoNowResult(const uint64_t requestId, const UserState* userStateList, const size_t count, const char* nextPage, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)userStateList;
    (void)count;
    (void)nextPage;
    (void)errorCode;
  }

  /**
   * Occurs when query who joined this channel
   *
   * @param requestId The related request id when user perform this operation
   * @param userStatesList The states the users.
   * @param count The user count.
   * @param nextPage The next page.
   * @param errorCode The error code.
   */
  virtual void onGetOnlineUsersResult(const uint64_t requestId, const UserState* userStateList, const size_t count, const char* nextPage, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)userStateList;
    (void)count;
    (void)nextPage;
    (void)errorCode;
  }

  /**
   * Occurs when query which channels the user joined
   *
   * @param requestId The related request id when user perform this operation
   * @param channels The channel informations.
   * @param count The channel count.
   * @param errorCode The error code.
   */
  virtual void onWhereNowResult(const uint64_t requestId, const ChannelInfo* channels, const size_t count, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channels;
    (void)count;
    (void)errorCode;
  }

  /**
   * Occurs when query which channels the user joined
   *
   * @param requestId The related request id when user perform this operation
   * @param channels The channel informations.
   * @param count The channel count.
   * @param errorCode The error code.
   */
  virtual void onGetUserChannelsResult(const uint64_t requestId, const ChannelInfo* channels, const size_t count, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)channels;
    (void)count;
    (void)errorCode;
  }

  /**
   * Occurs when set user presence
   *
   * @param requestId The related request id when user perform this operation
   * @param errorCode The error code.
   */
  virtual void onPresenceSetStateResult(const uint64_t requestId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)errorCode;
  }

  /**
   * Occurs when delete user presence
   *
   * @param requestId The related request id when user perform this operation
   * @param errorCode The error code.
   */
  virtual void onPresenceRemoveStateResult(const uint64_t requestId, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)errorCode;
  }

  /**
   * Occurs when get user presence
   *
   * @param requestId The related request id when user perform this operation
   * @param states The user states
   * @param errorCode The error code.
   */
  virtual void onPresenceGetStateResult(const uint64_t requestId, const UserState& state, RTM_ERROR_CODE errorCode) {
    (void)requestId;
    (void)state;
    (void)errorCode;
  }
};

/**
 * The IRtmClient class.
 *
 * This class provides the main methods that can be invoked by your app.
 *
 * IRtmClient is the basic interface class of the Agora RTM SDK.
 * Creating an IRtmClient object and then calling the methods of
 * this object enables you to use Agora RTM SDK's functionality.
 */
class IRtmClient {
 public:
  /**
   * Release the rtm client instance.
   *
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual int release() = 0;

  /**
   * Login the Agora RTM service. The operation result will be notified by \ref agora::rtm::IRtmEventHandler::onLoginResult callback.
   *
   * @param [in] token Token used to login RTM service.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void login(const char* token, uint64_t& requestId) = 0;

  /**
   * Logout the Agora RTM service. Be noticed that this method will break the rtm service including storage/lock/presence.
   *
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void logout(uint64_t& requestId) = 0;

  /**
   * Get the storage instance.
   *
   * @return
   * - return NULL if error occurred
   */
  virtual IRtmStorage* getStorage() = 0;

  /**
   * Get the lock instance.
   *
   * @return
   * - return NULL if error occurred
   */
  virtual IRtmLock* getLock() = 0;

  /**
   * Get the presence instance.
   *
   * @return
   * - return NULL if error occurred
   */
  virtual IRtmPresence* getPresence() = 0;

  /**
   * Renews the token. Once a token is enabled and used, it expires after a certain period of time.
   * You should generate a new token on your server, call this method to renew it.
   *
   * @param [in] token Token used renew.
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void renewToken(const char* token, uint64_t& requestId) = 0;

  /**
   * Publish a message in the channel.
   *
   * @param [in] channelName The name of the channel.
   * @param [in] message The content of the message.
   * @param [in] length The length of the message.
   * @param [in] option The option of the message.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void publish(const char* channelName, const char* message, const size_t length, const PublishOptions& option, uint64_t& requestId) = 0;

  /**
   * Subscribe a channel.
   *
   * @param [in] channelName The name of the channel.
   * @param [in] options The options of subscribe the channel.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void subscribe(const char* channelName, const SubscribeOptions& options, uint64_t& requestId) = 0;

  /**
   * Unsubscribe a channel.
   *
   * @param [in] channelName The name of the channel.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void unsubscribe(const char* channelName, uint64_t& requestId) = 0;

  /**
   * Create a stream channel instance.
   *
   * @param [in] channelName The Name of the channel.
   * @param [out] errorCode The error code.
   * @return
   * - return NULL if error occurred
   */
  virtual IStreamChannel* createStreamChannel(const char* channelName, int& errorCode) = 0;

  /**
   * Set parameters of the sdk or engine
   *
   * @param [in] parameters The parameters in json format
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual int setParameters(const char* parameters) = 0;

 protected:
  virtual ~IRtmClient() {}
};

/**
 * Creates the rtm client object and returns the pointer.
 * 
 * @param [in] config The configuration of the rtm client.
 * @param [out] errorCode The error code.
 * @return Pointer of the rtm client object.
 */
AGORA_API IRtmClient* AGORA_CALL createAgoraRtmClient(const RtmConfig& config, int& errorCode);

/**
 * Convert error code to error string
 *
 * @param [in] errorCode Received error code
 * @return The error reason
 */
AGORA_API const char* AGORA_CALL getErrorReason(int errorCode);

/**
 * Get the version info of the Agora RTM SDK.
 *
 * @return The version info of the Agora RTM SDK.
 */
AGORA_API const char* AGORA_CALL getVersion();
}  // namespace rtm
}  // namespace agora
