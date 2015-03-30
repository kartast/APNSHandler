//
//  APNSHandler.m
//
//  Created by Kien on 5/2/15.
//  Copyright (c) 2015 Thkeen. All rights reserved.
//

#import "APNSHandler.h"

@interface APNSHandler ()
{
  struct {
    int didAsk;
    int settingsUpdated;
    int didRegisterForRemote;
    int didFailToRegisterForRemote;
  } _delegateFlags;
  
  // measure the duration when start registering for user notification settings. If > 0.26 means the iOS prompt was shown.
  NSDate *_startRegisterTimestamp;
}

@end

@implementation APNSHandler
@synthesize deviceToken = _deviceToken;
+ (instancetype)sharedInstance
{
  static APNSHandler * _sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[APNSHandler alloc] init];
  });
  return _sharedInstance;
}
- (instancetype)init
{
  self = [super init];
  if (self)
  {
    self.shouldAutoRegisterRemoteNotification = YES;
    _startRegisterTimestamp = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
  }
  return self;
}
- (void)dealloc
{
  _startRegisterTimestamp = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)setup
{
  if (self.canDisplayNotification && self.shouldAutoRegisterRemoteNotification)
  {
    [self registerForRemoteNotifications]; // silently, since we already asked!
  }
}

#pragma mark - Properties
- (void)setDelegate:(id<APNSHandlerDelegate>)delegate
{
  _delegate = delegate;
  _delegateFlags.didAsk = _delegate && [(id)_delegate respondsToSelector:@selector(APNSHandler:didAskForNotificationSettingsWithPrompt:canDisplayNotification:)];
  _delegateFlags.didRegisterForRemote = _delegate && [(id)_delegate respondsToSelector:@selector(APNSHandler:didRegisterForRemoteNotificationsWithDeviceToken:)];
  _delegateFlags.didFailToRegisterForRemote = _delegate && [(id)_delegate respondsToSelector:@selector(APNSHandler:didFailToRegisterForRemoteNotificationsWithError:)];
  _delegateFlags.settingsUpdated = _delegate && [(id)_delegate respondsToSelector:@selector(APNSHandler:notificationSettingsUpdated:canDisplayNotification:)];
}
- (BOOL)canDisplayNotification
{
  return ([UIApplication sharedApplication].currentUserNotificationSettings.types != UIUserNotificationTypeNone);
}
- (NSString *)deviceToken
{
  if (!_deviceToken)
  {
    _deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"APNSHandler_deviceToken"];
  }
  return _deviceToken;
}
- (void)setDeviceToken:(NSString *)deviceToken
{
  _deviceToken = deviceToken;
  [[NSUserDefaults standardUserDefaults] setObject:_deviceToken forKey:@"APNSHandler_deviceToken"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Methods

- (void)registerUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
  _startRegisterTimestamp = [NSDate date];
  [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
}
- (void)registerForRemoteNotifications
{
  [[UIApplication sharedApplication] registerForRemoteNotifications];
}
- (void)registerForRemoteNotificationsIfNecessary
{
  if (self.canDisplayNotification && self.shouldAutoRegisterRemoteNotification && (![UIApplication sharedApplication].isRegisteredForRemoteNotifications || self.deviceToken.length == 0))
  {
    [self registerForRemoteNotifications];
  }
}

#pragma mark - UIApplicationDelegate Handler

- (void)handleApplication:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
  if (self.canDisplayNotification && self.shouldAutoRegisterRemoteNotification)
  {
    [self registerForRemoteNotifications];
  }
  if (_delegateFlags.didAsk)
  {
    [_delegate APNSHandler:self didAskForNotificationSettingsWithPrompt:(
                                                                         _startRegisterTimestamp == nil
                                                                         || (-[_startRegisterTimestamp timeIntervalSinceNow] > 0.26)
                                                                         )
    canDisplayNotification:self.canDisplayNotification];
  }
  _startRegisterTimestamp = nil;
}
- (void)handleApplication:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  NSString *token = [deviceToken description];
  token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
  token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
  token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
  self.deviceToken = token;
  if (_delegateFlags.didRegisterForRemote)
  {
    [_delegate APNSHandler:self didRegisterForRemoteNotificationsWithDeviceToken:self.deviceToken];
  }
}
- (void)handleApplication:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  if (_delegateFlags.didFailToRegisterForRemote)
  {
    [_delegate APNSHandler:self didFailToRegisterForRemoteNotificationsWithError:error];
  }
}

#pragma mark - UIApplicationDelegate

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
  if (_delegateFlags.settingsUpdated)
  {
    [_delegate APNSHandler:self notificationSettingsUpdated:[UIApplication sharedApplication].currentUserNotificationSettings canDisplayNotification:self.canDisplayNotification];
  }
  [self registerForRemoteNotificationsIfNecessary];
}

@end
