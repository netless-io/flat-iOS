#import <Foundation/Foundation.h>
#import "AgoraRtmEnumerates.h"

@class AgoraRtmPublisherInfo;
@class AgoraRtmClientKit;
@class AgoraRtmMessageEvent;
@class AgoraRtmTopicOption;
@class AgoraRtmJoinTopicOption;
@class AgoraRtmJoinChannelOption;
@class AgoraRtmClientConfig;
@class AgoraRtmStreamChannel;
@class AgoraRtmTopicInfo;
@class AgoraRtmSubscribeOptions;
@class AgoraRtmPublishOptions;
@class AgoraRtmTopicMessageOptions;
@class AgoraRtmLock;
@class AgoraRtmStorage;
@class AgoraRtmPresence;
@class AgoraRtmMetadataOptions;
@class AgoraRtmMetadataItem;
@class AgoraRtmMetadata;
@class AgoraRtmLockDetail;
@class AgoraRtmPresenceOptions;
@class AgoraRtmGetOnlineUsersOptions;
@class AgoraRtmUserState;
@class AgoraRtmChannelInfo;
@class AgoraRtmTopicEvent;
@class AgoraRtmLockEvent;
@class AgoraRtmStorageEvent;
@class AgoraRtmPresenceEvent;
@class AgoraRtmLogConfig;
@class AgoraRtmProxyConfig;
@class AgoraRtmEncryptionConfig;
@class AgoraRtmPresenceIntervalInfo;
@class AgoraRtmErrorInfo;
@class AgoraRtmTopicSubscriptionResponse;
@class AgoraRtmLoginErrorInfo;
@class AgoraRtmGetMetadataResponse;
@class AgoraRtmGetLocksResponse;
@class AgoraRtmWhoNowResponse;
@class AgoraRtmGetOnlineUsersResponse;
@class AgoraRtmWhereNowResponse;
@class AgoraRtmGetUserChannelsResponse;
@class AgoraRtmPresenceGetStateResponse;
@class AgoraRtmGetTopicSubscribedUsersResponse;
@class AgoraRtmMessage;
@class AgoraRtmPrivateConfig;
@class AgoraRtmLinkStateEvent;

__attribute__((visibility("default"))) @interface AgoraRtmPublishOptions: NSObject
/**
   * Which channel type, RTM_CHANNEL_TYPE_USER or RTM_CHANNEL_TYPE_MESSAGE
   */
@property (nonatomic, assign) AgoraRtmChannelType channelType;

/**
 * The custom type of the message, up to 32 bytes for customize.
 */
@property (nonatomic, copy, nonnull) NSString* customType;
@end


__attribute__((visibility("default"))) @interface AgoraRtmTopicMessageOptions: NSObject
/**
 * The custom type of the message, up to 32 bytes for customize.
 */
@property (nonatomic, copy, nonnull) NSString* customType;

/**
 * The time to calibrate data with media,
 *only valid when user join topic with syncWithMedia in stream channel
*/
@property (nonatomic, assign) unsigned long long sendTs;
@end

__attribute__((visibility("default"))) @interface AgoraRtmMetadataOptions: NSObject

 /**
  * Indicates whether or not to notify server update the modify timestamp of metadata
  */
@property (nonatomic, assign) BOOL recordTs;

 /**
  * Indicates whether or not to notify server update the modify user id of metadata
  */
@property (nonatomic, assign) BOOL recordUserId;
@end

__attribute__((visibility("default"))) @interface AgoraRtmMetadataItem: NSObject

/**
  * The key of the metadata item.
  */
@property (nonatomic, copy, nonnull) NSString* key;

  /**
  * The value of the metadata item.
  */
@property (nonatomic, copy, nonnull) NSString* value;

  /**
  * The User ID of the user who makes the latest update to the metadata item.
  */
@property (nonatomic, copy, nonnull) NSString* authorUserId;

  /**
  * The revision of the metadata item.
  */
@property (nonatomic, assign) long long revision;

  /**
  * The timestamp when the metadata item was last updated.
  */
@property (nonatomic, assign) unsigned long long updateTs;
@end

__attribute__((visibility("default"))) @interface AgoraRtmMetadata: NSObject

- (instancetype _Nullable)init;
  /**
   * The major revision of the metadata.
   */
@property (nonatomic, assign) long long majorRevision;

/**
 * The metadata item array.
*/
@property (nonatomic, copy, nullable) NSArray<AgoraRtmMetadataItem *> *items;
@end

__attribute__((visibility("default"))) @interface AgoraRtmLockDetail: NSObject
/**
 * The name of the lock.
 */
@property (nonatomic, copy, nonnull) NSString* lockName;

/**
 * The owner of the lock. Only valid when user getLocks or receive LockEvent with RTM_LOCK_EVENT_TYPE_SNAPSHOT
 */
@property (nonatomic, copy, nonnull) NSString* owner;

/**
 * The ttl of the lock.
 */
@property (nonatomic, assign) int ttl;

/**
 * RTM server UTC time
*/
@property (nonatomic, assign) unsigned long long timestamp;
@end

__attribute__((visibility("default"))) @interface AgoraRtmGetOnlineUsersOptions: NSObject
 /**
   * Whether to display user id in query result
   */
@property (nonatomic, assign) BOOL includeUserId;

 /**
   * Whether to display user state in query result
   */
@property (nonatomic, assign) BOOL includeState;

/**
   * The paging object used for pagination.
   */
@property (nonatomic, copy, nonnull) NSString* page;
@end

__attribute__((visibility("default"))) @interface AgoraRtmPresenceOptions: NSObject
 /**
   * Whether to display user id in query result
   */
@property (nonatomic, assign) BOOL includeUserId;

 /**
   * Whether to display user state in query result
   */
@property (nonatomic, assign) BOOL includeState;

/**
   * The paging object used for pagination.
   */
@property (nonatomic, copy, nonnull) NSString* page;
@end

__attribute__((visibility("default"))) @interface AgoraRtmUserState: NSObject

 /**
   * The user id.
   */
@property (nonatomic, copy, nonnull) NSString* userId;

/**
   * The user states.
   */
@property (nonatomic, copy, nonnull)  NSDictionary<NSString *, NSString *> * states;
@end

__attribute__((visibility("default"))) @interface AgoraRtmChannelInfo: NSObject

/**
   * The channel which the message was published
   */
@property (nonatomic, copy, nonnull) NSString* channelName;

 /**
   * Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE
   */
@property (nonatomic, assign) AgoraRtmChannelType channelType;
@end


__attribute__((visibility("default"))) @interface AgoraRtmTopicEvent: NSObject

/**
 * Indicate topic event type
*/
@property (nonatomic, assign) AgoraRtmTopicEventType type;

/**
 * The channel which the topic event was triggered
 */
@property (nonatomic, copy, nonnull) NSString* channelName;

/**
 * The userId which the topic event was triggered  
 */
@property (nonatomic, copy, nonnull) NSString* publisher;

/**
 * Topic information array.
 */
@property (nonatomic, copy, nonnull) NSArray<AgoraRtmTopicInfo *> *topicInfos;

/**
 * RTM server UTC time
*/
@property (nonatomic, assign) unsigned long long timestamp;
@end

__attribute__((visibility("default"))) @interface AgoraRtmPublisherInfo: NSObject
/**
 * The publisher user ID
 */
@property (nonatomic, copy, nonnull) NSString* publisherUserId;

/**
 * The metadata of the publisher
 */
@property (nonatomic, copy, nullable) NSString* publisherMeta;
@end

__attribute__((visibility("default"))) @interface AgoraRtmLockEvent: NSObject
/**
 * Which channel type.
*/
@property (nonatomic, assign) AgoraRtmChannelType channelType;

/**
 * Lock event type, indicate lock states
*/
@property (nonatomic, assign) AgoraRtmLockEventType eventType;

/**
 * The channel which the lock event was triggered
*/
@property (nonatomic, copy, nonnull) NSString* channelName;
/**
 * The detail information of locks
*/
@property (nonatomic, copy, nonnull)  NSArray<AgoraRtmLockDetail *> * lockDetailList;

/**
 * RTM server UTC time
*/
@property (nonatomic, assign) unsigned long long timestamp;
@end

__attribute__((visibility("default"))) @interface AgoraRtmStorageEvent: NSObject

/**
 * Which channel type
 */ 
@property (nonatomic, assign) AgoraRtmChannelType channelType;

/**
 * Storage type, RTM_STORAGE_TYPE_USER or RTM_STORAGE_TYPE_CHANNEL
 */ 
@property (nonatomic, assign) AgoraRtmStorageType storageType;   

/**
 * Indicate storage event type
 */ 
@property (nonatomic, assign) AgoraRtmStorageEventType eventType;   

/**
 * The target name of user or channel depends on AgoraRtmStorageType
 */ 
@property (nonatomic, copy, nonnull) NSString* target;

/**
 * The metadata infomation
 */ 
@property (nonatomic, strong, nonnull) AgoraRtmMetadata* data;

/**
 * RTM server UTC time
*/
@property (nonatomic, assign) unsigned long long timestamp;
@end

__attribute__((visibility("default"))) @interface AgoraRtmLogConfig: NSObject <NSCopying>
/**
 * Set log path. 
*/
@property (nonatomic, copy, nullable) NSString* filePath;
/**
 * Set log max size.
*/
@property (nonatomic, assign) int fileSizeInKB;
/**
 * Set log output level.
*/
@property (nonatomic, assign) AgoraRtmLogLevel level;
@end

__attribute__((visibility("default"))) @interface AgoraRtmProxyConfig: NSObject <NSCopying>

- (instancetype _Nullable)init NS_UNAVAILABLE;

- (instancetype _Nonnull) initWithServer:(NSString * _Nonnull)server
                                    port:(unsigned short)port
                               proxyType:(AgoraRtmProxyType)proxyType; 
/**
    The Proxy type.
    */
@property (nonatomic, assign) AgoraRtmProxyType proxyType;

 /**
    The Proxy server address.
    */
@property (nonatomic, copy, nonnull) NSString* server;

/**
    The Proxy server port.
    */
@property (nonatomic, assign) unsigned short port;

 /**
    The Proxy user account.
    */
@property (nonatomic, copy, nullable) NSString* account;

/**
    The Proxy password.
    */
@property (nonatomic, copy, nullable) NSString* password;
@end

__attribute__((visibility("default"))) @interface AgoraRtmEncryptionConfig: NSObject <NSCopying>

/**
   * The encryption mode.
   */
@property (nonatomic, assign) AgoraRtmEncryptionMode encryptionMode;

/**
   * The encryption key in the string format.
   */
@property (copy, nonatomic ,nullable) NSString * encryptionKey;

/**                                     
   * The encryption salt.
   */
@property (strong, nonatomic, nullable) NSData * encryptionSalt;
@end

/**
 * Create topic options.
 */
__attribute__((visibility("default"))) @interface AgoraRtmJoinTopicOption: NSObject
/**
   * The qos of rtm message.
   */
@property (nonatomic, assign) AgoraRtmMessageQos qos;

  /**
   * The metaData of topic.
   */
@property (nonatomic, nullable) NSString* meta;

  /**
   * The priority of rtm message.
   */
@property (nonatomic, assign) AgoraRtmMessagePriority priority;

  /**
  * The rtm data will sync with media
  */
 @property (nonatomic, assign) BOOL syncWithMedia;

@end

/**
 * Topic options.
 */
__attribute__((visibility("default"))) @interface AgoraRtmTopicOption: NSObject
/**
 * The list of users to subscribe.
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> *users;
@end

/**
 * Join channel options.
 */
__attribute__((visibility("default"))) @interface AgoraRtmJoinChannelOption: NSObject
/**
* Token used to join channel.
*/
@property (nonatomic, copy, nullable) NSString *token;

/**
 * join channel with more event notification, see AgoraRtmJoinChannelFeature.
*/
@property (nonatomic, assign) AgoraRtmJoinChannelFeature features;

@end

__attribute__((visibility("default"))) @interface AgoraRtmMessageEvent: NSObject

    /**
     * Which channel type
     */
@property (nonatomic, assign) AgoraRtmChannelType channelType;
  /**
   * The channel to which the message was published
   */
@property (nonatomic, copy, nonnull) NSString *channelName;
  /**
   * If the channelType is stChannel, which topic the message come from. only for stChannel type
   */
@property (nonatomic, copy, nonnull) NSString *channelTopic;
  /**
   * The payload
   */
@property (nonatomic, copy, nonnull) AgoraRtmMessage *message;
  /**
   * The publisher
   */
@property (nonatomic, copy, nonnull) NSString *publisher;
/**
 * The publisher
*/
@property (nonatomic, copy, nullable) NSString *customType;
/**
 * RTM server UTC time
*/
@property (nonatomic, assign) unsigned long long timestamp;
@end

__attribute__((visibility("default"))) @interface AgoraRtmTopicInfo: NSObject
  /**
   * The name of the topic.
   */
@property (nonatomic, copy, nonnull) NSString *topic;

 /**
   * The publisher array
  */
@property (nonatomic, copy, nonnull) NSArray<AgoraRtmPublisherInfo *> *publishers;

@end

__attribute__((visibility("default"))) @interface AgoraRtmSubscribeOptions: NSObject

/**
 * subscribe channel with more event notification, see AgoraRtmSubscribeChannelFeature.
*/
@property (nonatomic, assign) AgoraRtmSubscribeChannelFeature features;

@end

__attribute__((visibility("default"))) @interface AgoraRtmPresenceIntervalInfo: NSObject

/**
 * Joined users during this interval
 */
@property (nonatomic, copy, nonnull) NSArray<NSString *> *joinUserList;

/**
 * Left users during this interval
 */
@property (nonatomic, copy, nonnull) NSArray<NSString *> *leaveUserList;

/**
 * Timeout users during this interval
 */
@property (nonatomic, copy, nonnull) NSArray<NSString *> *timeoutUserList;

/**
 * The user state changed during this interval
 */
@property (nonatomic, copy, nonnull) NSArray<AgoraRtmUserState *> *userStateList;
@end


__attribute__((visibility("default"))) @interface AgoraRtmPresenceEvent: NSObject
/**
 * Indicate presence event type
*/
@property (nonatomic, assign) AgoraRtmPresenceEventType type;
/**
 * Which channel type, RTM_CHANNEL_TYPE_STREAM or RTM_CHANNEL_TYPE_MESSAGE
*/
@property (nonatomic, assign) AgoraRtmChannelType channelType;

/**
 * The channel which the presence event was triggered
*/
@property (nonatomic, copy, nonnull) NSString * channelName;

/**
 * The user who triggered this event.
*/
@property (nonatomic, copy, nullable) NSString * publisher;

/**
 * The user states
*/
@property (nonatomic, copy, nonnull) NSDictionary<NSString *, NSString *> * states;
 
/**
 * Only valid when in interval mode
*/
@property (nonatomic, copy, nullable) AgoraRtmPresenceIntervalInfo* interval;

/**
 * Only valid when receive snapshot event
*/
@property (nonatomic, copy, nonnull) NSArray<AgoraRtmUserState *> * snapshot;

/**
 * RTM server UTC time
*/
@property (nonatomic, assign) unsigned long long timestamp;
@end

/**
 *  Configurations for RTM Client.
 */
__attribute__((visibility("default"))) @interface AgoraRtmClientConfig: NSObject

- (instancetype _Nullable)init NS_UNAVAILABLE;
/**
 * init with appid adn userid
*/
- (instancetype _Nonnull) initWithAppId:(NSString * _Nonnull)appId
                        userId:(NSString * _Nonnull)userId;
/**
   * The region for connection. This advanced feature applies to scenarios that
   * have regional restrictions.
   *
   * For the regions that Agora supports, see #AREA_CODE.
   *
   * After specifying the region, the SDK connects to the Agora servers within
   * that region.
   */
@property (nonatomic, assign) AgoraRtmAreaCode areaCode;

/**
 * The protocol used for connecting to the Agora RTM service.
 */
@property (nonatomic, assign)  AgoraRtmProtocolType protocolType;

/**
 * Presence timeout in seconds, specify the timeout value when you lost connection between sdk
 * and rtm service.
 */
@property (nonatomic, assign) unsigned int presenceTimeout;

/**
 * Heartbeat interval in seconds, specify the interval value of sending heartbeat between sdk
 * and rtm service.
 */
@property (nonatomic, assign) unsigned int heartbeatInterval;

/**
 * The App ID of your project.
 */
@property (nonatomic, copy, nonnull) NSString *appId;

/**
 * The ID of the user.
 */
@property (nonatomic, copy, nonnull) NSString *userId;

/**
 * Whether to use String user IDs, if you are using RTC products with Int user IDs,
 * set this value as 'false'. Otherwise errors might occur.
 */
@property (nonatomic, assign) BOOL useStringUserId;

/**
 * Whether to enable multipath, introduced from 2.2.0, for now , only effect on stream channel.
 */
@property (nonatomic, assign) BOOL multipath;

  /**
   * The config for customer set log path, log size and log level.
   */
@property (nonatomic, copy, nullable) AgoraRtmLogConfig * logConfig;

  /**
   * The config for proxy setting
   */
@property (nonatomic, copy, nullable) AgoraRtmProxyConfig * proxyConfig;

  /**
   * The config for encryption setting
   */
@property (nonatomic, copy, nullable) AgoraRtmEncryptionConfig * encryptionConfig;

/**
 * The config for private setting
 */
@property (nonatomic, copy, nullable) AgoraRtmPrivateConfig * privateConfig;
@end

__attribute__((visibility("default"))) @interface AgoraRtmErrorInfo: NSError

/*
*Error code of operation. see enum class  AgoraRtmOperationErrorCode for detail
*/
@property (nonatomic, assign) AgoraRtmErrorCode errorCode;

/**
 * Which api user called.
*/
@property (nonatomic, copy, nonnull) NSString *operation;

/**
 * brief description of login error.
*/
@property (nonatomic, copy, nonnull) NSString *reason;
@end


__attribute__((visibility("default"))) @interface AgoraRtmTopicSubscriptionResponse: NSObject
/**
 * The subscribed users.
*/
@property (nonatomic, copy, nonnull) NSArray<NSString *> *succeedUsers;

/**
 * The failed to subscribe users.
*/
@property (nonatomic, copy, nonnull) NSArray<NSString *> *failedUsers;
@end

__attribute__((visibility("default"))) @interface AgoraRtmGetMetadataResponse: NSObject

/**
 * The result metadata of getting operation.
*/
@property (nonatomic, strong, nullable) AgoraRtmMetadata* data;
@end

__attribute__((visibility("default"))) @interface AgoraRtmGetLocksResponse: NSObject
/**
 * The result metadata of getting operation.
*/
@property (nonatomic, copy, nonnull)  NSArray<AgoraRtmLockDetail *> * lockDetailList;
@end


__attribute__((visibility("default"))) @interface AgoraRtmGetOnlineUsersResponse: NSObject
/**
 *  count of members in channel
*/
@property (nonatomic, assign) int totalOccupancy;
/**
 * The states the users.
*/
@property (nonatomic, copy, nonnull)  NSArray<AgoraRtmUserState *> *userStateList;

/**
 * start point of next page
*/
@property (nonatomic, copy, nullable) NSString *nextPage;
@end


__attribute__((visibility("default"))) @interface AgoraRtmWhoNowResponse: NSObject
/**
 *  count of members in channel
*/
@property (nonatomic, assign) int totalOccupancy;
/**
 * The states the users.
*/
@property (nonatomic, copy, nonnull)  NSArray<AgoraRtmUserState *> *userStateList;

/**
 * start point of next page
*/
@property (nonatomic, copy, nullable) NSString *nextPage;
@end

__attribute__((visibility("default"))) @interface AgoraRtmWhereNowResponse: NSObject

/**
 *  count of channels already joined.
*/
@property (nonatomic, assign) int totalChannel;

/**
 * The channel informations.
*/
@property (nonatomic, copy, nonnull)  NSArray<AgoraRtmChannelInfo *> * channels;
@end

__attribute__((visibility("default"))) @interface AgoraRtmGetUserChannelsResponse: NSObject

/**
 *  count of channels already joined.
*/
@property (nonatomic, assign) int totalChannel;

/**
 * The channel informations.
*/
@property (nonatomic, copy, nonnull)  NSArray<AgoraRtmChannelInfo *> * channels;
@end

__attribute__((visibility("default"))) @interface AgoraRtmPresenceGetStateResponse: NSObject

/**
 * The user states
*/
@property (nonatomic, strong, nonnull)  AgoraRtmUserState * state;
@end

__attribute__((visibility("default"))) @interface AgoraRtmCommonResponse: NSObject
@end


__attribute__((visibility("default"))) @interface AgoraRtmMessage: NSObject <NSCopying>

/**
 * if rawData is nil read data from stringData
*/
@property (nonatomic, copy, nullable) NSData* rawData;

/**
 * if stringData is nil read data from rawData
*/
@property (nonatomic, copy, nullable) NSString* stringData;

@end

__attribute__((visibility("default"))) @interface AgoraRtmGetTopicSubscribedUsersResponse: NSObject
/**
 * The subscribed users.
*/
@property (nonatomic, copy, nonnull) NSArray<NSString *> *users;
@end

__attribute__((visibility("default"))) @interface AgoraRtmPrivateConfig: NSObject
/**
 * Rtm service type.
*/
@property (nonatomic, assign) AgoraRtmServiceType serviceType;

/**
 * Local access point server list.
*/
@property (nonatomic, copy, nonnull) NSArray<NSString *> *accessPointHosts;
@end

__attribute__((visibility("default"))) @interface AgoraRtmLinkStateEvent: NSObject
/**
 * The current link state
*/
@property (nonatomic, assign) AgoraRtmLinkState currentState;

/**
 * The previous link state
*/
@property (nonatomic, assign) AgoraRtmLinkState previousState;

/**
 * The service type
*/
@property (nonatomic, assign) AgoraRtmServiceType serviceType;

/**
 * The operation which trigger this event
*/
@property (nonatomic, assign) AgoraRtmLinkOperation operation;

/**
 * The reason of this state change event
*/
@property (nonatomic, copy, nullable) NSString* reason;

/**
 * The affected channels
*/
@property (nonatomic, copy, nonnull) NSArray<NSString *> * affectedChannels;

/**
 * The unrestored channels
*/
@property (nonatomic, copy, nonnull) NSArray<NSString *> * unrestoredChannels;

/**
 * Is resumed from disconnected state
*/
@property (nonatomic, assign) BOOL isResumed;

/**
 * RTM server UTC time
*/
@property (nonatomic, assign) unsigned long long timestamp;
@end




typedef void (^AgoraRtmTopicSubscriptionBlock)(AgoraRtmTopicSubscriptionResponse* _Nullable response, AgoraRtmErrorInfo* _Nullable errorInfo);

typedef void (^AgoraRtmOperationBlock)(AgoraRtmCommonResponse* _Nullable response, AgoraRtmErrorInfo* _Nullable errorInfo);

typedef void (^AgoraRtmGetMetadataBlock)(AgoraRtmGetMetadataResponse* _Nullable response, AgoraRtmErrorInfo* _Nullable errorInfo);

typedef void (^AgoraRtmGetLocksBlock)(AgoraRtmGetLocksResponse * _Nullable response, AgoraRtmErrorInfo* _Nullable errorInfo);

typedef void (^AgoraRtmWhoNowBlock)(AgoraRtmWhoNowResponse* _Nullable response, AgoraRtmErrorInfo* _Nullable errorInfo);

typedef void (^AgoraRtmWhereNowBlock)(AgoraRtmWhereNowResponse* _Nullable response, AgoraRtmErrorInfo* _Nullable errorInfo);

typedef void (^AgoraRtmGetOnlineUsersBlock)(AgoraRtmGetOnlineUsersResponse* _Nullable response, AgoraRtmErrorInfo* _Nullable errorInfo);

typedef void (^AgoraRtmGetUserChannelsBlock)(AgoraRtmGetUserChannelsResponse* _Nullable response, AgoraRtmErrorInfo* _Nullable errorInfo);

typedef void (^AgoraRtmPresenceGetStateBlock)(AgoraRtmPresenceGetStateResponse* _Nullable response, AgoraRtmErrorInfo* _Nullable errorInfo);

typedef void (^AgoraRtmGetTopicSubscribedUsersBlock)(AgoraRtmGetTopicSubscribedUsersResponse* _Nullable response, AgoraRtmErrorInfo* _Nonnull errorInfo);