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
 * The IRtmPresence class.
 *
 * This class provides the rtm presence methods that can be invoked by your app.
 */
class IRtmPresence {
 public:
  /**
   * To query who joined this channel
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] options The query option.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void whoNow(const char* channelName, RTM_CHANNEL_TYPE channelType, const PresenceOptions& options, uint64_t& requestId) = 0;

  /**
   * To query which channels the user joined
   *
   * @param [in] userId The id of the user.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void whereNow(const char* userId, uint64_t& requestId) = 0;

  /**
   * Set user state
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] items The states item of user.
   * @param [in] count The count of states item.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void setState(const char* channelName, RTM_CHANNEL_TYPE channelType, const StateItem* items, size_t count, uint64_t& requestId) = 0;

  /**
   * Delete user state
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] keys The keys of state item.
   * @param [in] count The count of keys.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void removeState(const char* channelName, RTM_CHANNEL_TYPE channelType, const char** keys, size_t count, uint64_t& requestId) = 0;

  /**
   * Get user state
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] userId The id of the user.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void getState(const char* channelName, RTM_CHANNEL_TYPE channelType, const char* userId, uint64_t& requestId) = 0;

  /**
   * To query who joined this channel
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] options The query option.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void getOnlineUsers(const char* channelName, RTM_CHANNEL_TYPE channelType, const GetOnlineUsersOptions& options, uint64_t& requestId) = 0;

  /**
   * To query which channels the user joined
   *
   * @param [in] userId The id of the user.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void getUserChannels(const char* userId, uint64_t& requestId) = 0;

 protected:
  virtual ~IRtmPresence() {}
};

}  // namespace rtm
}  // namespace agora
