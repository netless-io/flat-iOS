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
 * The IRtmLock class.
 *
 * This class provides the rtm lock methods that can be invoked by your app.
 */
class IRtmLock {
 public:
  /**
   * sets a lock
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] lockName The name of the lock.
   * @param [in] ttl The lock ttl.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void setLock(const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, uint32_t ttl, uint64_t& requestId) = 0;

  /**
   * gets locks in the channel
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void getLocks(const char* channelName, RTM_CHANNEL_TYPE channelType, uint64_t& requestId) = 0;

  /**
   * removes a lock
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] lockName The name of the lock.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void removeLock(const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, uint64_t& requestId) = 0;

  /**
   * acquires a lock
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] lockName The name of the lock.
   * @param [in] retry Whether to automatically retry when acquires lock failed
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void acquireLock(const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, bool retry, uint64_t& requestId) = 0;

  /**
   * releases a lock
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] lockName The name of the lock.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void releaseLock(const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, uint64_t& requestId) = 0;

  /**
   * disables a lock
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType The type of the channel.
   * @param [in] lockName The name of the lock.
   * @param [in] owner The lock owner.
   * @param [out] requestId The related request id of this operation.
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void revokeLock(const char* channelName, RTM_CHANNEL_TYPE channelType, const char* lockName, const char* owner, uint64_t& requestId) = 0;

 protected:
  virtual ~IRtmLock() {}
};

}  // namespace rtm
}  // namespace agora
