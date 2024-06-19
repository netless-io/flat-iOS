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
 * Metadata options.
 */
struct MetadataOptions {
  /**
  * Indicates whether or not to notify server update the modify timestamp of metadata
  */
  bool recordTs;
  /**
  * Indicates whether or not to notify server update the modify user id of metadata
  */
  bool recordUserId;

  MetadataOptions()
        : recordTs(false),
          recordUserId(false) {}
};

struct MetadataItem {
 public:
  /**
  * The key of the metadata item.
  */
  const char* key;
  /**
  * The value of the metadata item.
  */
  const char* value;
  /**
  * The User ID of the user who makes the latest update to the metadata item.
  */
  const char* authorUserId;
  /**
  * The revision of the metadata item.
  */
  int64_t revision;
  /**
  * The Timestamp when the metadata item was last updated.
  */
  int64_t updateTs;

  MetadataItem()
        : key(NULL),
          value(NULL),
          authorUserId(NULL),
          revision(-1),
          updateTs(0) {}

  MetadataItem(const char* key, const char* value, int64_t revision = -1)
        : key(key),
          value(value),
          authorUserId(NULL),
          revision(revision),
          updateTs(0) {}
};

struct Metadata {
  /**
   * the major revision of metadata.
  */
  int64_t majorRevision;

  /**
   * The metadata item array.
   */
  MetadataItem* items;
  /**
   * The items count.
   */
  size_t itemCount;

  Metadata()
        : majorRevision(-1),
          items(NULL),
          itemCount(0) {}
};

class IRtmStorage {
 public:
  /**
   * Set the metadata of a specified channel.
   *
   * @param [in] channelName The name of the channel.
   * @param [in] channelType Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE.
   * @param [in] data Metadata data.
   * @param [in] options The options of operate metadata.
   * @param [in] lock lock for operate channel metadata.
   * @param [out] requestId The unique ID of this request.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void setChannelMetadata(
      const char* channelName, RTM_CHANNEL_TYPE channelType, const Metadata& data, const MetadataOptions& options, const char* lockName, uint64_t& requestId) = 0;
  /**
   * Update the metadata of a specified channel.
   *
   * @param [in] channelName The channel Name of the specified channel.
   * @param [in] channelType Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE.
   * @param [in] data Metadata data.
   * @param [in] options The options of operate metadata.
   * @param [in] lock lock for operate channel metadata.
   * @param [out] requestId The unique ID of this request.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void updateChannelMetadata(
      const char* channelName, RTM_CHANNEL_TYPE channelType, const Metadata& data, const MetadataOptions& options, const char* lockName, uint64_t& requestId) = 0;
  /**
   * Remove the metadata of a specified channel.
   *
   * @param [in] channelName The channel Name of the specified channel.
   * @param [in] channelType Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE.
   * @param [in] data Metadata data.
   * @param [in] options The options of operate metadata.
   * @param [in] lock lock for operate channel metadata.
   * @param [out] requestId The unique ID of this request.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void removeChannelMetadata(
      const char* channelName, RTM_CHANNEL_TYPE channelType, const Metadata& data, const MetadataOptions& options, const char* lockName, uint64_t& requestId) = 0;
  /**
   * Get the metadata of a specified channel.
   *
   * @param [in] channelName The channel Name of the specified channel.
   * @param [in] channelType Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE.
   * @param requestId The unique ID of this request.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void getChannelMetadata(
      const char* channelName, RTM_CHANNEL_TYPE channelType, uint64_t& requestId) = 0;

  /**
   * Set the metadata of a specified user.
   *
   * @param [in] userId The user ID of the specified user.
   * @param [in] data Metadata data.
   * @param [in] options The options of operate metadata.
   * @param [out] requestId The unique ID of this request.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void setUserMetadata(
      const char* userId, const Metadata& data, const MetadataOptions& options, uint64_t& requestId) = 0;
  /**
   * Update the metadata of a specified user.
   *
   * @param [in] userId The user ID of the specified user.
   * @param [in] data Metadata data.
   * @param [in] options The options of operate metadata.
   * @param [out] requestId The unique ID of this request.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void updateUserMetadata(
      const char* userId, const Metadata& data, const MetadataOptions& options, uint64_t& requestId) = 0;
  /**
   * Remove the metadata of a specified user.
   *
   * @param [in] userId The user ID of the specified user.
   * @param [in] data Metadata data.
   * @param [in] options The options of operate metadata.
   * @param [out] requestId The unique ID of this request.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void removeUserMetadata(
      const char* userId, const Metadata& data, const MetadataOptions& options, uint64_t& requestId) = 0;
  /**
   * Get the metadata of a specified user.
   *
   * @param [in] userId The user ID of the specified user.
   * @param [out] requestId The unique ID of this request.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void getUserMetadata(const char* userId, uint64_t& requestId) = 0;

  /**
   * Subscribe the metadata update event of a specified user.
   *
   * @param [in] userId The user ID of the specified user.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void subscribeUserMetadata(const char* userId, uint64_t& requestId) = 0;
  /**
   * unsubscribe the metadata update event of a specified user.
   *
   * @param [in] userId The user ID of the specified user.
   * 
   * @return
   * - 0: Success.
   * - < 0: Failure.
   */
  virtual void unsubscribeUserMetadata(const char* userId, uint64_t& requestId) = 0;

 protected:
  virtual ~IRtmStorage() {}
};

}  // namespace rtm
}  // namespace agora
