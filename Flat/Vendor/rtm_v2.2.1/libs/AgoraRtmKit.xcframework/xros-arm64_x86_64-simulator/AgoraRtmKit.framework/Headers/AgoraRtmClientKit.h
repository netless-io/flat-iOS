//
//  AgoraRtmClientKit.h
//  AgoraRtcKit
//
//  Copyright (c) 2022 Agora. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "AgoraRtmObjects.h"
@protocol AgoraRtmClientDelegate <NSObject>
@optional

/**
   * Occurs when link state change
   * @param rtmKit the AgoraRtmClientKit Object.  
   * @param event details of link state event.
   */
- (void)rtmKit:(AgoraRtmClientKit * _Nonnull)rtmKit
    didReceiveLinkStateEvent:(AgoraRtmLinkStateEvent * _Nonnull)event NS_SWIFT_NAME(rtmKit(_:didReceiveLinkStateEvent:));

/**
   * Occurs when receive a message.
   * @param rtmKit the AgoraRtmClientKit Object.  
   * @param event details of message event.
   */
- (void)rtmKit:(AgoraRtmClientKit * _Nonnull)rtmKit
    didReceiveMessageEvent:(AgoraRtmMessageEvent * _Nonnull)event NS_SWIFT_NAME(rtmKit(_:didReceiveMessageEvent:));

  /**
   * Occurs when remote user presence changed
   * 
   * @param rtmKit the AgoraRtmClientKit Object.
   * @param event details of presence event.
   */
- (void)rtmKit:(AgoraRtmClientKit * _Nonnull)rtmKit
    didReceivePresenceEvent:(AgoraRtmPresenceEvent * _Nonnull)event NS_SWIFT_NAME(rtmKit(_:didReceivePresenceEvent:));

  /**
   * Occurs when lock state changed
   * @param rtmKit the AgoraRtmClientKit Object.
   * @param event details of lock event.
   */
- (void)rtmKit:(AgoraRtmClientKit * _Nonnull)rtmKit
    didReceiveLockEvent:(AgoraRtmLockEvent * _Nonnull)event NS_SWIFT_NAME(rtmKit(_:didReceiveLockEvent:));

  /**
   * Occurs when receive storage event
   * 
   * @param rtmKit the AgoraRtmClientKit Object
   * @param event details of storage event.
   */
- (void)rtmKit:(AgoraRtmClientKit * _Nonnull)rtmKit
    didReceiveStorageEvent:(AgoraRtmStorageEvent * _Nonnull)event NS_SWIFT_NAME(rtmKit(_:didReceiveStorageEvent:));

  /**
   * Occurs when remote user join/leave topic or when user first join this channel,
   * got snapshot of topics in this channel
   *
   * @param rtmKit the AgoraRtmClientKit Object.
   * @param event details of topic event.
   */
- (void)rtmKit:(AgoraRtmClientKit * _Nonnull)rtmKit
    didReceiveTopicEvent:(AgoraRtmTopicEvent * _Nonnull)event NS_SWIFT_NAME(rtmKit(_:didReceiveTopicEvent:));

  /**
   * Occurs when token will expire in 30 seconds.
   *
   * @param rtmKit the AgoraRtmClientKit Object.
   * @param channelName The name of the channel.
   */
- (void)rtmKit:(AgoraRtmClientKit * _Nonnull)rtmKit
      tokenPrivilegeWillExpire:(NSString * _Nullable)channel NS_SWIFT_NAME(rtmKit(_:tokenPrivilegeWillExpire:));

/**
   * Occurs when the connection state changes between rtm sdk and agora service.
   *
   * @param rtmKit the AgoraRtmClientKit Object.
   * @param channelName The Name of the channel.
   * @param state The new connection state.
   * @param reason The reason for the connection state change.
   */
- (void)rtmKit:(AgoraRtmClientKit * _Nonnull)kit
    channel:(NSString * _Nonnull)channelName
    connectionChangedToState:(AgoraRtmClientConnectionState)state
    reason:(AgoraRtmClientConnectionChangeReason)reason NS_SWIFT_NAME(rtmKit(_:channel:connectionChangedToState:reason:));
@end

NS_ASSUME_NONNULL_BEGIN
/**
 * The AgoraRtmClientKit class.
 *
 * This class provides the main methods that can be invoked by your app.
 *
 * AgoraRtmClientKit is the basic interface class of the Agora RTM SDK.
 * Creating an AgoraRtmClientKit object and then calling the methods of
 * this object enables you to use Agora RTM SDK's functional
 * 
 */
__attribute__((visibility("default"))) @interface AgoraRtmClientKit : NSObject

- (instancetype _Nullable)init NS_UNAVAILABLE;

/**
 * Initializes the rtm client instance.
 *
 * @param config The configurations for RTM Client.
 * @param delegate  The callbacks handler.
 * @param error  When get nil instance, get error info from error.
 * 
 * @return 
 * - nil: initialize rtm client failed, and the error information can be retrievd via the `error` parameter.
 * - not nil: initialize rtm client success.
 */
- (instancetype _Nullable)initWithConfig:(AgoraRtmClientConfig * _Nonnull)config
                                 delegate:(id <AgoraRtmClientDelegate> _Nullable)delegate
                                    error:(NSError**)error NS_SWIFT_NAME(init(_:delegate:));
 
/**
   * Login the Agora RTM service. The operation result will be notified by \ref agora::rtm::IRtmEventHandler::onLoginResult callback.
   *
   * @param token Token used to login RTM service.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) loginByToken:(NSString* _Nullable)token
           completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(login(_:completion:));

/**
   * Logout the Agora RTM service. Be noticed that this method will break the rtm service includeing storage/lock/presence.
   *
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) logout:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(logout(_:));
   
/**
   * Get the storage instance.
   *
   * @return
   * - return nil if error occured
   */
- (AgoraRtmStorage* _Nullable)getStorage NS_SWIFT_NAME(getStorage());

/**
   * Get the lock instance.
   *
   * @return
   * - return nil if error occured
   */
- (AgoraRtmLock* _Nullable)getLock NS_SWIFT_NAME(getLock());

/**
   * Get the presence instance.
   *
   * @return
   * - return nil if error occured
   */    
- (AgoraRtmPresence* _Nullable)getPresence NS_SWIFT_NAME(getPresence());

/**
   * Renews the token. Once a token is enabled and used, it expires after a certain period of time.
   * You should generate a new token on your server, call this method to renew it.
   *
   * @param token Token used renew.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) renewToken:(NSString* _Nonnull)token
         completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(renewToken(_:completion:));

  /**
   * Subscribe a channel.
   *
   * @param channelName The name of the channel.
   * @param subscribeOption The options of subscribe the channel.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) subscribeWithChannel:(NSString* _Nonnull)channelName
                       option:(AgoraRtmSubscribeOptions* _Nullable)subscribeOption
                   completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(subscribe(channelName:option:completion:));

  /**
   * Unsubscribe a channel.
   *
   * @param channelName The name of the channel.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) unsubscribeWithChannel:(NSString* _Nonnull)channelName
                     completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(unsubscribe(_:completion:));
  /**
   * Publish a message in the channel.
   *
   * @param channelName The name of the channel.
   * @param message The content of the string message.
   * @param publishOption The option of the message.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) publish:(NSString* _Nonnull)channelName
         message:(NSString* _Nonnull)message
          option:(AgoraRtmPublishOptions* _Nullable)publishOption
      completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(publish(channelName:message:option:completion:));

  /**
   * Publish a message in the channel.
   *
   * @param channelName The name of the channel.
   * @param data The content of the raw message.
   * @param publishOption The option of the message.  
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) publish:(NSString* _Nonnull)channelName
            data:(NSData* _Nonnull)data
          option:(AgoraRtmPublishOptions* _Nullable)publishOption
      completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(publish(channelName:data:option:completion:));

/**
   * add more delegate instance.
   *
   * @param delegate The name of the channel.
   * 
   */
- (void) addDelegate:(id <AgoraRtmClientDelegate> _Nonnull)delegate NS_SWIFT_NAME(addDelegate(_:));

/**
   * remove delegate instance.
   *
   * @param delegate The name of the channel.
   * 
   */
- (void) removeDelegate:(id <AgoraRtmClientDelegate> _Nonnull)delegate NS_SWIFT_NAME(removeDelegate(_:));  
 /**
   * Set parameters of the sdk or engine
   *
   * @param parameters The parameters in json format
   * @return
   * - AgoraRtmErrorOk: Success.
   * - other: Failure.
   */ 
- (AgoraRtmErrorCode)setParameters:(NSString* _Nonnull)parameter NS_SWIFT_NAME(setParameters(_:));

/**
   * Convert error code to error string.
   *
   * @param errorCode Received error code
   * @return The error reason
   */ 
+ (NSString* _Nullable)getErrorReason:(AgoraRtmErrorCode)errorCode NS_SWIFT_NAME(getErrorReason(_:));
/**
 * Get the version info of the AgoraRtmKit.
 *
 * @return The version info of the AgoraRtmKit.
 */
+ (NSString * _Nonnull)getVersion NS_SWIFT_NAME(getVersion());
        

/**
 * create a stream channel instance.
 *
 * @param channelName The Name of the channel.
 * @param error  When get nil instance, get error info from error.
 * @return
 * - nil: create stream channel failed，and the error information can be retrievd via the `error` parameter.
 * - not nil: create stream channel success.
 */
- (AgoraRtmStreamChannel * _Nullable)createStreamChannel:(NSString * _Nonnull)channelName 
                                                   error:(NSError**)error NS_SWIFT_NAME(createStreamChannel(_:));


/**
 * destroy the rtm client instance.
 *
 * @return
 * - AgoraRtmErrorOk: Success.
 * - other: Failure.
 */
- (AgoraRtmErrorCode)destroy NS_SWIFT_NAME(destroy());
@end

NS_ASSUME_NONNULL_END

__attribute__((visibility("default"))) @interface AgoraRtmStreamChannel : NSObject

- (instancetype _Nullable)init NS_UNAVAILABLE;
/**
   * Join the channel.
   *
   * @param option join channel options.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void)joinWithOption:(AgoraRtmJoinChannelOption * _Nonnull)option
            completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(join(_:completion:));

/**
   * Leave the channel.
   *
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void)leave:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(leave(_:));

/**
   * Renews the token. Once a token is enabled and used, it expires after a certain period of time.
   * You should generate a new token on your server, call this method to renew it.
   *
   * @param token token Token used renew.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void)renewToken:(NSString* _Nonnull)token
        completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(renewToken(_:completion:));

/**
   * Join a topic.
   *
   * @param topic The name of the topic.
   * @param option The options of the topic.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) joinTopic:(NSString * _Nonnull)topic 
            option:(AgoraRtmJoinTopicOption * _Nullable)option
        completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(joinTopic(_:option:completion:));

/**
   * Leave the topic.
   *
   * @param topic The name of the topic.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) leaveTopic:(NSString * _Nonnull)topic
         completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(leaveTopic(_:completion:));

/**
   * Subscribe a topic.
   *
   * @param topic The name of the topic.
   * @param option The options of subscribe the topic.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) subscribeTopic:(NSString * _Nonnull)topic 
                 option:(AgoraRtmTopicOption * _Nullable)option
             completion:(AgoraRtmTopicSubscriptionBlock _Nullable)completionBlock NS_SWIFT_NAME(subscribeTopic(_:option:completion:));

             
/**
   * UnsubscribeTopic a topic.
   *
   * @param topic The name of the topic.
   * @param option The options of subscribe the topic.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) unsubscribeTopic:(NSString * _Nonnull)topic 
                   option:(AgoraRtmTopicOption * _Nullable)option
               completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(unsubscribeTopic(_:option:completion:));

/**   
   * publish a message in the topic.
   *
   * @param topic The name of the topic. 
   * @param message The content of string message.
   * @param options The option of the message.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) publishTopicMessage:(NSString * _Nonnull)topic
                     message:(NSString * _Nonnull)message
                      option:(AgoraRtmTopicMessageOptions * _Nullable)options
                  completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(publishTopicMessage(topic:message:option:completion:));


/**
   * publish a message in the topic.
   *
   * @param topic The name of the topic.
   * @param message The content of raw message. 
   * @param options The option of the message.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) publishTopicMessage:(NSString * _Nonnull)topic
                        data:(NSData * _Nonnull)data
                      option:(AgoraRtmTopicMessageOptions * _Nullable)options
                  completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(publishTopicMessage(topic:data:option:completion:));
  /**
   * Get subscribed user list
   *
   * @param topic The name of the topic.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) getSubscribedUserList:(NSString* _Nonnull)topic
                    completion:(AgoraRtmGetTopicSubscribedUsersBlock _Nullable)completionBlock NS_SWIFT_NAME(getSubscribedUserList(_:completion:));

/**
  * return the channel name of this stream channel.
  *
  * @return The channel name.
  */
- (NSString * _Nonnull)getChannelName NS_SWIFT_NAME(getChannelName());

/**
 * release the stream channel instance.
 *
 * @return
* - AgoraRtmErrorOk: Success.
 * - other: Failure.
 */
- (AgoraRtmErrorCode)destroy;
              
@end

__attribute__((visibility("default"))) @interface AgoraRtmStorage : NSObject

- (instancetype _Nullable)init NS_UNAVAILABLE;
  /**
   * Set the metadata of a specified channel.
   *
   * @param channelName The name of the channel.
   * @param channelType Which channel type, AgoraRtmChannelTypeStream or AgoraRtmChannelTypeMessage.
   * @param data Metadata data.
   * @param options The options of operate metadata.
   * @param lock lock for operate channel metadata.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) setChannelMetadata:(NSString * _Nonnull)channelName
                channelType:(AgoraRtmChannelType)channelType
                       data:(AgoraRtmMetadata* _Nonnull)data
                    options:(AgoraRtmMetadataOptions* _Nullable)options
                       lock:(NSString * _Nullable)lock
                 completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(setChannelMetadata(channelName:channelType:data:options:lock:completion:));

  /**
   * Update the metadata of a specified channel.
   *
   * @param channelName The channel Name of the specified channel.
   * @param channelType Which channel type, AgoraRtmChannelTypeStream or AgoraRtmChannelTypeMessage.
   * @param data Metadata data.
   * @param options The options of operate metadata.
   * @param lock lock for operate channel metadata.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo. 
   * 
   */
- (void) updateChannelMetadata:(NSString * _Nonnull)channelName
                   channelType:(AgoraRtmChannelType)channelType
                          data:(AgoraRtmMetadata* _Nonnull)data
                       options:(AgoraRtmMetadataOptions* _Nullable)options
                          lock:(NSString * _Nullable)lock
                    completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(updateChannelMetadata(channelName:channelType:data:options:lock:completion:));

  /**
   * Remove the metadata of a specified channel.
   *
   * @param channelName The channel Name of the specified channel.
   * @param channelType Which channel type, AgoraRtmChannelTypeStream or AgoraRtmChannelTypeMessage.
   * @param data Metadata data.
   * @param options The options of operate metadata.
   * @param lock lock for operate channel metadata.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) removeChannelMetadata:(NSString * _Nonnull)channelName
                   channelType:(AgoraRtmChannelType)channelType
                          data:(AgoraRtmMetadata* _Nonnull)data
                       options:(AgoraRtmMetadataOptions* _Nullable)options
                          lock:(NSString * _Nullable)lock
                    completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(removeChannelMetadata(channelName:channelType:data:options:lock:completion:));

  /**
   * Get the metadata of a specified channel.
   *
   * @param channelName The channel Name of the specified channel.
   * @param channelType Which channel type, AgoraRtmChannelTypeStream or AgoraRtmChannelTypeMessage.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) getChannelMetadata:(NSString * _Nonnull)channelName
                channelType:(AgoraRtmChannelType)channelType
                 completion:(AgoraRtmGetMetadataBlock _Nullable)completionBlock NS_SWIFT_NAME(getChannelMetadata(channelName:channelType:completion:));

/**
   * Set the metadata of a specified user.   
   *
   * @param userId The user ID of the specified user.
   * @param data Metadata data.
   * @param options The options of operate metadata.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   * 
   */
- (void) setUserMetadata:(NSString * _Nonnull)userId
                    data:(AgoraRtmMetadata* _Nonnull)data
                 options:(AgoraRtmMetadataOptions* _Nullable)options
              completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(setUserMetadata(userId:data:options:completion:));

/**
   * Update the metadata of a specified user.
   *
   * @param userId The user ID of the specified user.
   * @param data Metadata data.
   * @param options The options of operate metadata.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) updateUserMetadata:(NSString * _Nonnull)userId
                       data:(AgoraRtmMetadata* _Nonnull)data
                    options:(AgoraRtmMetadataOptions* _Nullable)options
                 completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(updateUserMetadata(userId:data:options:completion:));

  /**
   * Remove the metadata of a specified user.
   *
   * @param userId The user ID of the specified user.
   * @param data Metadata data.
   * @param options The options of operate metadata.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) removeUserMetadata:(NSString * _Nonnull)userId
                       data:(AgoraRtmMetadata* _Nonnull)data
                    options:(AgoraRtmMetadataOptions* _Nullable)options
                 completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(removeUserMetadata(userId:data:options:completion:));

  /**
   * Get the metadata of a specified user.
   *
   * @param userId The user ID of the specified user.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) getUserMetadata:(NSString * _Nonnull)userId
              completion:(AgoraRtmGetMetadataBlock _Nullable)completionBlock NS_SWIFT_NAME(getUserMetadata(userId:completion:));

  /**
   * Subscribe the metadata update event of a specified user.
   *
   * @param userId The user ID of the specified user.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) subscribeUserMetadata:(NSString * _Nonnull)userId
                    completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(subscribeUserMetadata(userId:completion:));

  /**
   * unsubscribe the metadata update event of a specified user.
   *
   * @param userId The user ID of the specified user.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
- (void) unsubscribeUserMetadata:(NSString * _Nonnull)userId
                      completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(unsubscribeUserMetadata(userId:completion:));
@end

__attribute__((visibility("default"))) @interface AgoraRtmLock : NSObject

- (instancetype _Nullable)init NS_UNAVAILABLE;
/**
   * sets a lock
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param ttl The lock ttl.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) setLock:(NSString * _Nonnull)channelName
    channelType:(AgoraRtmChannelType)channelType
       lockName:(NSString * _Nonnull)lockName
            ttl:(int) ttl
     completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(setLock(channelName:channelType:lockName:ttl:completion:));

  /**
   * removes a lock
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) removeLock:(NSString * _Nonnull)channelName
       channelType:(AgoraRtmChannelType)channelType
          lockName:(NSString * _Nonnull)lockName
        completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(removeLock(channelName:channelType:lockName:completion:));

  /**
   * acquires a lock
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param retry Whether to automatic retry when acquires lock failed
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) acquireLock:(NSString * _Nonnull)channelName
        channelType:(AgoraRtmChannelType)channelType
           lockName:(NSString * _Nonnull)lockName
              retry:(BOOL)retry
         completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(acquireLock(channelName:channelType:lockName:retry:completion:));


  /**
   * releases a lock
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   *
   */
-(void) releaseLock:(NSString * _Nonnull)channelName
        channelType:(AgoraRtmChannelType)channelType
           lockName:(NSString * _Nonnull)lockName
         completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(releaseLock(channelName:channelType:lockName:completion:));

  /**
   * disables a lock
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param lockName The name of the lock.
   * @param owner The lock owner.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) revokeLock:(NSString * _Nonnull)channelName
       channelType:(AgoraRtmChannelType)channelType
          lockName:(NSString * _Nonnull)lockName
            userId:(NSString * _Nonnull)userId
        completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(revokeLock(channelName:channelType:lockName:userId:completion:));


  /**
   * gets locks in the channel
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) getLocks:(NSString * _Nonnull)channelName
     channelType:(AgoraRtmChannelType)channelType
      completion:(AgoraRtmGetLocksBlock _Nullable)completionBlock NS_SWIFT_NAME(getLocks(channelName:channelType:completion:));
@end


/**
 * The IRtmPresence class.
 *
 * This class provides the rtm presence methods that can be invoked by your app.
 */
__attribute__((visibility("default"))) @interface AgoraRtmPresence : NSObject

- (instancetype _Nullable)init NS_UNAVAILABLE;

  /**
   * To query who joined this channel
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param options The query option.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) whoNow:(NSString * _Nonnull)channelName
   channelType:(AgoraRtmChannelType)channelType
       options:(AgoraRtmPresenceOptions* _Nullable)options
    completion:(AgoraRtmWhoNowBlock _Nullable)completionBlock NS_SWIFT_NAME(whoNow(channelName:channelType:options:completion:));

  /**
   * To query who joined this channel
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param options The query option.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) getOnlineUsers:(NSString * _Nonnull)channelName
           channelType:(AgoraRtmChannelType)channelType
               options:(AgoraRtmGetOnlineUsersOptions* _Nullable)options
            completion:(AgoraRtmGetOnlineUsersBlock _Nullable)completionBlock NS_SWIFT_NAME(getOnlineUser(channelName:channelType:options:completion:));

  /**
   * To query which channels the user joined
   *
   * @param userId The id of the user.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) whereNow:(NSString * _Nonnull)userId
      completion:(AgoraRtmWhereNowBlock _Nullable)completionBlock NS_SWIFT_NAME(whereNow(userId:completion:));

  /**
   * To query which channels the user joined
   *
   * @param userId The id of the user.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) getUserChannels:(NSString * _Nonnull)userId
             completion:(AgoraRtmGetUserChannelsBlock _Nullable)completionBlock NS_SWIFT_NAME(getUserChannels(userId:completion:));

  /**
   * Set user state
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param items The states item of user.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) setState:(NSString * _Nonnull)channelName
     channelType:(AgoraRtmChannelType)channelType
           items:(NSDictionary<NSString *, NSString *> *_Nonnull)items
      completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(setState(channelName:channelType:items:completion:));

  /**
   * Delete user state
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param keys The keys of state item.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) removeState:(NSString * _Nonnull)channelName
        channelType:(AgoraRtmChannelType)channelType
               keys:(NSArray<NSString *> * _Nonnull)keys
         completion:(AgoraRtmOperationBlock _Nullable)completionBlock NS_SWIFT_NAME(removeState(channelName:channelType:keys:completion:));

  /**
   * Get user state
   *
   * @param channelName The name of the channel.
   * @param channelType The type of the channel.
   * @param userId The id of the user.
   * @param completionBlock The operation result will be notified by completionBlock, if operation success，will given a not nil response and nil errorInfo，if operation failed，will given a nil response and not nil errorInfo.
   * 
   */
-(void) getState:(NSString * _Nonnull)channelName
     channelType:(AgoraRtmChannelType)channelType
          userId:(NSString * _Nonnull)userId
      completion:(AgoraRtmPresenceGetStateBlock _Nullable)completionBlock NS_SWIFT_NAME(getState(channelName:channelType:userId:completion:));
@end
