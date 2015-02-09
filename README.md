APNSHandler
===========
## Apple Push Notification Handler for iOS 8 - a wrapper class that helps dealing with iOS Remote or Local Notification Settings

#### How to use
```objective-c
[[APNSHandler sharedInstance] setup];
[APNSHandler sharedInstance].delegate = self;
[APNSHandler sharedInstance].shouldAutoRegisterRemoteNotification = YES;
```
#### Override these delegates and let APNSHandler handle them for you
```objective-c
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
  [[APNSHandler sharedInstance] handleApplication:application didRegisterUserNotificationSettings:notificationSettings];
}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  [[APNSHandler sharedInstance] handleApplication:application didFailToRegisterForRemoteNotificationsWithError:error];
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  [[APNSHandler sharedInstance] handleApplication:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}
```
#### Delegate methods
```objective-c
@protocol APNSHandlerDelegate <NSObject>
@optional
/**
 *  Will be called only once in an app install
 *
 *  @param canDisplayNotification   If YES: user already tap on either Don't Allow or Allow button. If NO: user never sees the system Alert View before, it's a good time to display your own custom UI first then call registerNotificationSettings
 *  @param didPrompt   If YES: user never see the prompt from system before. If NO: user used to make a decision, so no UI was displayed. Good time to display a custom popup to guide user to enable in SETTINGS > NOTIFICATIONS > Your_App_name > ENABLED > TURN ON!
 *  @param types   UIUserNotificationType
 */
- (void)APNSHandlerDidAskForNotificationSettingsWithPrompt:(BOOL)didPrompt
                                    canDisplayNotification:(BOOL)canDisplayNotification;
/**
 *  Received device token from Apple
 *
 *  @param deviceToken NSString
 */
- (void)APNSHandlerDidRegisterForRemoteNotificationsWithDeviceToken:(NSString*)deviceToken;

/**
 *  Probably changed manually by user. Called when app becomes active if there's any change.
 *
 *  @param notificationTypes UIUserNotificationType
 */
- (void)APNSHandlerNotificationTypesDidChange:(UIUserNotificationType)notificationTypes
                       canDisplayNotification:(BOOL)canDisplayNotification;

/**
 *  Fail to register remote notification because of internet connectivity or denial
 *
 *  @param error NSError
 */
- (void)APNSHandlerDidFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
@end

/**
 *  APNSHandler is only iOS 8 compatible.
 */
@interface APNSHandler : NSObject

+ (instancetype)sharedInstance;
/**
 *  If YES: it either means you can fire a LOCAL notification; can register REMOTE notification; and can receive and display PUSH notification from server
 *  If NO: UIUserNotificationTypeNone
 */
@property (nonatomic) BOOL canDisplayNotification;
/**
 *  Return the last deviceToken, can be new or cached since the last app launch
 */
@property (nonatomic, strong) NSString *deviceToken;
/**
 *  UIUserNotificationType. If None, please use other flags to display proper behaviour
 */
@property UIUserNotificationType notificationTypes;
/**
 *  Default: YES. If your app doesn't have Push Notification or you want to control when to call, set this flag to NO.
 */
@property (nonatomic) BOOL shouldAutoRegisterRemoteNotification;
/**
 *  APNSHandlerDelegate
 */
@property (nonatomic, weak) id<APNSHandlerDelegate>delegate;
/**
 *  Start listening to significant events
 */
- (void)setup;
/**
 *  Call to UIApplication registerUserNotificationSettings but start a timer (as a trick) to measure whether a system alert was shown
 *
 *  @param notificationSettings UIUserNotificationSettings
 */
- (void)registerUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
/**
 *  Call to UIApplication registerForRemoteNotifications
 */
- (void)registerForRemoteNotifications;
/**
 *  Call to UIApplication registerForRemoteNotifications if did not register before
 */
- (void)registerForRemoteNotificationsIfNecessary;
/**
 *  Handler. Please put in didRegisterUserNotificationSettings
 *
 *  @param application          UIApplication
 *  @param notificationSettings UIUserNotificationSettings
 */
- (void)handleApplication:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
/**
 *  Handler. Please put in didRegisterForRemoteNotificationsWithDeviceToken
 *
 *  @param application UIApplication
 *  @param deviceToken NSData
 */
- (void)handleApplication:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
/**
 *  Handler. Please put in didFailToRegisterForRemoteNotificationsWithError
 *
 *  @param application UIApplication
 *  @param error       NSError
 */
- (void)handleApplication:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

```
