// Copyright (c) 2022 Agora.io. All rights reserved

// This program is confidential and proprietary to Agora.io.
// And may not be copied, reproduced, modified, disclosed to others, published
// or used, in whole or in part, without the express prior written permission
// of Agora.io.

#pragma once  // NOLINT(build/header_guard)

#include "AgoraRtmBase.h"

namespace agora {
namespace rtm {
/**
 * The qos of rtm message.
 */
enum RTM_MESSAGE_QOS {
  /**
   * Will not ensure that messages arrive in order.
   */
  RTM_MESSAGE_QOS_UNORDERED = 0,
  /**
   * Will ensure that messages arrive in order.
   */
  RTM_MESSAGE_QOS_ORDERED = 1,
};

/**
 * The priority of rtm message.
 */
enum RTM_MESSAGE_PRIORITY {
  /**
   * The highest priority
   */
  RTM_MESSAGE_PRIORITY_HIGHEST = 0,
  /**
   * The high priority
   */
  RTM_MESSAGE_PRIORITY_HIGH = 1,
  /**
   * The normal priority (Default)
   */
  RTM_MESSAGE_PRIORITY_NORMAL = 4,
  /**
   * The low priority
   */
  RTM_MESSAGE_PRIORITY_LOW = 8,
};

/**
 * Join channel options.
 */
struct JoinChannelOptions {
  /**
  * Token used to join channel.
  */
  const char* token;
  /**
  * Whether to subscribe channel metadata information
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
   * Whether to join channel in quiet mode
   * Quiet mode means remote user will not receive any notification when we join  or
   * leave or change our presence state
   */
  bool beQuiet;

  JoinChannelOptions() : token(NULL), withMetadata(false), withPresence(true), withLock(false), beQuiet(false) {}
};

/**
 * Join topic options.
 */
struct JoinTopicOptions {
  /**
   * The qos of rtm message.
   */
  RTM_MESSAGE_QOS qos;

  /**
   * The priority of rtm message.
   */
  RTM_MESSAGE_PRIORITY priority;

  /**
   * The metaData of topic.
   */
  const char* meta;

  /**
  * The rtm data will sync with media
  */
  bool syncWithMedia;

  JoinTopicOptions() : qos(RTM_MESSAGE_QOS_UNORDERED),
                       priority(RTM_MESSAGE_PRIORITY_NORMAL),
                       meta(NULL) {}
};

/**
 * Topic options.
 */
struct TopicOptions {
  /**
   * The list of users to subscribe.
   */
  const char** users;
  /**
   * The number of users.
   */
  size_t userCount;

  TopicOptions() : users(NULL), userCount(0) {}
};

/**
 * The IStreamChannel class.
 *
 * This class provides the stream channel methods that can be invoked by your app.
 */
class IStreamChannel {
 public:
  /**
   * Join the channel.
   *
   * @param [in] options join channel options.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void join(const JoinChannelOptions& options, uint64_t& requestId) = 0;

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
   * Leave the channel.
   *
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void leave(uint64_t& requestId) = 0;

  /**
   * Return the channel name of this stream channel.
   *
   * @return The channel name.
   */
  virtual const char* getChannelName() = 0;

  /**
   * Join a topic.
   *
   * @param [in] topic The name of the topic.
   * @param [in] options The options of the topic.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void joinTopic(const char* topic, const JoinTopicOptions& options, uint64_t& requestId) = 0;

  /**
   * Publish a message in the topic.
   *
   * @param [in] topic The name of the topic.
   * @param [in] message The content of the message.
   * @param [in] length The length of the message.
   * @param [in] option The option of the message.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void publishTopicMessage(const char* topic, const char* message, size_t length, const TopicMessageOptions& option, uint64_t& requestId) = 0;

  /**
   * Leave the topic.
   *
   * @param [in] topic The name of the topic.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void leaveTopic(const char* topic, uint64_t& requestId) = 0;

  /**
   * Subscribe a topic.
   *
   * @param [in] topic The name of the topic.
   * @param [in] options The options of subscribe the topic.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void subscribeTopic(const char* topic, const TopicOptions& options, uint64_t& requestId) = 0;

  /**
   * Unsubscribe a topic.
   *
   * @param [in] topic The name of the topic.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void unsubscribeTopic(const char* topic, const TopicOptions& options, uint64_t& requestId) = 0;

  /**
   * Get subscribed user list
   *
   * @param [in] topic The name of the topic.
   * @param [out] users The list of subscribed users.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void getSubscribedUserList(const char* topic, uint64_t& requestId) = 0;

  /**
   * Release the stream channel instance.
   *
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual int release() = 0;

 protected:
  virtual ~IStreamChannel() {}
};

}  // namespace rtm
}  // namespace agora
