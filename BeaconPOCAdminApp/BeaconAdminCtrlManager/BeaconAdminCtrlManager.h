//
//  BeaconAdminCtrlManager.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <BeaconCtrl/BCLBeaconCtrl.h>
#import <BeaconCtrl/BCLBeaconCtrlAdmin.h>

extern NSString * const BeaconManagerReadyForSetupNotification;
extern NSString * const BeaconManagerDidLogoutNotification;
extern NSString * const BeaconManagerDidFetchBeaconCtrlConfigurationNotification;
extern NSString * const BeaconManagerClosestBeaconDidChangeNotification;
extern NSString * const BeaconManagerCurrentZoneDidChangeNotification;
extern NSString * const BeaconManagerPropertiesUpdateDidStartNotification;
extern NSString * const BeaconManagerPropertiesUpdateDidFinishNotification;
extern NSString * const BeaconManagerFirmwareUpdateDidStartNotification;
extern NSString * const BeaconManagerFirmwareUpdateDidProgressNotification;
extern NSString * const BeaconManagerFirmwareUpdateDidFinishNotification;


@interface BeaconAdminCtrlManager : NSObject

@property (nonatomic, strong) BCLBeaconCtrlAdmin *beaconCtrlAdmin;
@property (nonatomic, strong) BCLBeaconCtrl *beaconCtrl;

@property (nonatomic, readonly) BOOL isReadyForSetup;
@property (nonatomic, readonly) BOOL canTryAutoLogin;

+ (instancetype)sharedManager;

- (void)setupForExistingUserWithAutologin:(void (^)(BOOL success, NSError *error))completion;
- (void)setupForExistingAdminUserWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(BOOL success, NSError *error))completion;
- (void)setupForNewAdminUserWithEmail:(NSString *)email password:(NSString *)password passwordConfirmation:(NSString *)passwordConfirmation completion:(void (^)(BOOL success, NSError *error))completion;
- (void)createBeacon:(NSMutableDictionary *)beacon testActionName:(NSString *)testActionName testActionTrigger:(BCLEventType)trigger testActionAttributes:(NSArray *)testActionAttributes completion:(void (^)(BCLBeacon *, NSError *))completion;
- (void)refetchBeaconCtrlConfiguration:(void (^)(NSError *error))completion;
- (void)deleteBeacon:(BCLBeacon *)beacon completion:(void (^)(BOOL success, NSError *error))completion;
- (void)muteAutomaticBeaconCtrlConfigurationRefresh;

- (void)unmuteAutomaticBeaconCtrlConfigurationRefresh;
-(NSSet*)listOfBeacons;
-(void)logout;

@end
