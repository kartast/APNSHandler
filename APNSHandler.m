//
//  APNSHandler.m
//
//  Created by Kien on 5/2/15.
//  Copyright (c) 2015 Thkeen. All rights reserved.
//

#import "APNSHandler.h"

@interface APNSHandler ()
{
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
  self.notificationTypes = [UIApplication sharedApplication].currentUserNotificationSettings.types;
  if (self.canDisplayNotification && self.shouldAutoRegisterRemoteNotification)
  {
    [self registerForRemoteNotifications]; // silently, since we already asked!
  }
}

#pragma mark - Properties

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

#pragma mark - UIApplicationDelegate Handler

- (void)handleApplication:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
  if (notificationSettings.types != UIUserNotificationTypeNone && self.shouldAutoRegisterRemoteNotification)
  {
    [self registerForRemoteNotifications];
  }
  if (self.delegate && [self.delegate respondsToSelector:@selector(APNSHandlerDidAskForNotificationSettingsWithPrompt:canDisplayNotification:)])
  {
    [self.delegate APNSHandlerDidAskForNotificationSettingsWithPrompt:(_startRegisterTimestamp == nil || (-[_startRegisterTimestamp timeIntervalSinceNow] > 0.26))
                                               canDisplayNotification:(notificationSettings.types != UIUserNotificationTypeNone)];
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
  if (self.delegate && [self.delegate respondsToSelector:@selector(APNSHandlerDidRegisterForRemoteNotificationsWithDeviceToken:)])
  {
    [self.delegate APNSHandlerDidRegisterForRemoteNotificationsWithDeviceToken:self.deviceToken];
  }
}
- (void)handleApplication:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(APNSHandlerDidFailToRegisterForRemoteNotificationsWithError:)])
  {
    [self.delegate APNSHandlerDidFailToRegisterForRemoteNotificationsWithError:error];
  }
}

#pragma mark - UIApplicationDelegate

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
  if (self.notificationTypes != [UIApplication sharedApplication].currentUserNotificationSettings.types)
  {
    self.notificationTypes = [UIApplication sharedApplication].currentUserNotificationSettings.types;
    if (self.delegate && [self.delegate respondsToSelector:@selector(APNSHandlerNotificationTypesDidChange:canDisplayNotification:)])
    {
      [self.delegate APNSHandlerNotificationTypesDidChange:self.notificationTypes canDisplayNotification:self.canDisplayNotification];
    }
  }
  if (self.canDisplayNotification && self.shouldAutoRegisterRemoteNotification && (![UIApplication sharedApplication].isRegisteredForRemoteNotifications || self.deviceToken.length == 0))
  {
    [self registerForRemoteNotifications];
  }
}

@end
