//
//  BeaconAdminCtrlManager.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BeaconAdminCtrlManager.h"
#import "AppDelegate.h"
#import <BeaconCtrl/BCLBeaconCtrl.h>
#import <BeaconCtrl/BCLBeacon.h>
#import <BeaconCtrl/BCLTrigger.h>
#import <SSKeychain/SSKeychain.h>
#import "BeaconDashboardViewController.h"
NSString * const BeaconManagerReadyForSetupNotification = @"BeaconManagerReadyForSetupNotification";
NSString * const BeaconManagerDidLogoutNotification = @"BeaconManagerDidLogoutpNotification";
NSString * const BeaconManagerDidFetchBeaconCtrlConfigurationNotification = @"BeaconManagerDidFetchBeaconCtrlConfigurationNotification";
NSString * const BeaconManagerClosestBeaconDidChangeNotification = @"BeaconManagerClosestBeaconDidChangeNotification";
NSString * const BeaconManagerCurrentZoneDidChangeNotification = @"BeaconManagerCurrentZoneDidChangeNotification";
NSString * const BeaconManagerPropertiesUpdateDidStartNotification = @"BeaconManagerPropertiesUpdateDidStartNotification";
NSString * const BeaconManagerPropertiesUpdateDidFinishNotification = @"BeaconManagerPropertiesUpdateDidFinishNotification";
NSString * const BeaconManagerFirmwareUpdateDidStartNotification = @"BeaconManagerFirmwareUpdateDidStartNotification";
NSString * const BeaconManagerFirmwareUpdateDidProgressNotification = @"BeaconManagerFirmwareUpdateDidProgresstNotification";
NSString * const BeaconManagerFirmwareUpdateDidFinishNotification = @"BeaconManagerFirmwareUpdateDidFinishNotification";

@interface BeaconAdminCtrlManager () <BCLBeaconCtrlDelegate>

@property (nonatomic, copy) NSString *pushNotificationDeviceToken;
@property (nonatomic) BCLBeaconCtrlPushEnvironment pushEnvironment;

@property (nonatomic, readwrite) BOOL isReadyForSetup;
@property (nonatomic, readwrite) BOOL isAutomaticBeaconCtrlRefreshMuted;

@property (nonatomic, strong) NSTimer *refetchConfigurationTimer;

@end

@implementation BeaconAdminCtrlManager
BeaconDashboardViewController *beaconAction;
- (instancetype)init
{
    if (self = [super init]) {
        NSUserDefaults *stantardUserDefaults = [NSUserDefaults standardUserDefaults];
        beaconAction = [[BeaconDashboardViewController alloc]init];
        [stantardUserDefaults setInteger:10 forKey:@"BCLRemoteAppMaxFloorNumber"];
        [stantardUserDefaults synchronize];
        
    }
    
    return self;
}

+ (instancetype)sharedManager
{
    static BeaconAdminCtrlManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[BeaconAdminCtrlManager alloc] init];
    });
    return sharedManager;
}

- (void)setupForExistingUserWithAutologin:(void (^)(BOOL, NSError *))completion
{
    [self setupForExistingAdminUserWithEmail:[self emailFromKeyChain] password:[self passwordFromKeychain] completion:completion];
}

- (void)setupForExistingAdminUserWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(BOOL, NSError *))completion
{
    self.beaconCtrlAdmin = [BCLBeaconCtrlAdmin beaconCtrlAdminWithCliendId:@"76b8780413c3902d76ae7a05b9a17dcb04ed0696147696d3b4ff3302269efc32" clientSecret:@"55f560c85ce5e645c928eb72537a1183b87b947d9d4129a8786c10f6bff3613b"];
    
    __weak typeof(self) weakSelf = self;
    
    [self.beaconCtrlAdmin loginAdminUserWithEmail:email password:password completion:^(BOOL success, NSError *error) {
        if (!success) {
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        [weakSelf finishSetupForAdminUserWithEmail:email password:password completion:completion];
    }];
}

- (void)refetchBeaconCtrlConfiguration:(void (^)(NSError *error))completion
{
    __weak typeof(self) weakSelf = self;
    
    [self.beaconCtrl fetchConfiguration:^(NSError *error) {
        if (!error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerDidFetchBeaconCtrlConfigurationNotification object:weakSelf];
        }
        
        [weakSelf.beaconCtrl updateMonitoredBeacons];
        
        if (completion) {
            completion(error);
        }
    }];
}

- (void)muteAutomaticBeaconCtrlConfigurationRefresh
{
    self.isAutomaticBeaconCtrlRefreshMuted = YES;
}

- (void)unmuteAutomaticBeaconCtrlConfigurationRefresh
{
    self.isAutomaticBeaconCtrlRefreshMuted = NO;
}

- (void)setIsReadyForSetup:(BOOL)isReadyForSetup
{
    if (_isReadyForSetup == NO && isReadyForSetup == YES) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerReadyForSetupNotification object:self];
    }
    
    _isReadyForSetup = isReadyForSetup;
}
- (void)createBeacon:(NSMutableDictionary *)beacon testActionName:(NSString *)testActionName testActionTrigger:(BCLEventType)trigger testActionAttributes:(NSArray *)testActionAttributes completion:(void (^)(BCLBeacon *, NSError *))completion
{
    __weak typeof(self) weakSelf = self;
    
    void (^finalCompletion)(BCLBeacon *newBeacon, NSError *error) = ^void (BCLBeacon *newBeacon, NSError *error){
        if (completion) {
            if (error) {
                completion(newBeacon, error);
                return;
            }
            
            [weakSelf.beaconCtrl stopMonitoringBeacons];
            
            [weakSelf refetchBeaconCtrlConfiguration:^(NSError *error) {
                [weakSelf.beaconCtrl startMonitoringBeacons];
                
                __block BCLBeacon *updatedNewBeacon;
                
                [weakSelf.beaconCtrl.configuration.beacons enumerateObjectsUsingBlock:^(BCLBeacon *enumeratedBeacon, BOOL *beaconStop) {
                    if ([enumeratedBeacon.beaconIdentifier isEqualToString:newBeacon.beaconIdentifier]) {
                        updatedNewBeacon = enumeratedBeacon;
                        *beaconStop = YES;
                    }
                }];
                
                completion(updatedNewBeacon, error);
            }];
        }
    };
    
    [self.beaconCtrlAdmin createBeacon:beacon testActionName:testActionName testActionTrigger:trigger testActionAttributes:testActionAttributes completion:finalCompletion];
}
- (void)deleteBeacon:(BCLBeacon *)beacon completion:(void (^)(BOOL success, NSError *error))completion
{
    __weak typeof(self) weakSelf = self;
    
    void (^finalCompletion)(BOOL success, NSError *error) = ^void (BOOL success, NSError *error){
        if (completion) {
            if (error) {
                completion(success, error);
                return;
            }
            
            [weakSelf.beaconCtrl stopMonitoringBeacons];
            
            [weakSelf refetchBeaconCtrlConfiguration:^(NSError *error) {
                [weakSelf.beaconCtrl startMonitoringBeacons];
                
                completion(success, error);
            }];
        }
    };
    
    [self.beaconCtrlAdmin deleteBeacon:beacon completion:finalCompletion];
}


#pragma mark - BCLBeaconCtrlDelegate

- (void)closestObservedBeaconDidChange:(BCLBeacon *)closestBeacon
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerClosestBeaconDidChangeNotification object:self userInfo:@{@"closestBeacon": closestBeacon ? : [NSNull null]}];
}

- (void)currentZoneDidChange:(BCLZone *)currentZone
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerCurrentZoneDidChangeNotification object:self userInfo:@{@"currentZone": currentZone ? : [NSNull null]}];
}

- (void)didChangeObservedBeacons:(NSSet *)newObservedBeacons
{
}

- (BOOL)shouldAutomaticallyPerformAction:(BCLAction *)action
{
    return YES;
}


- (void)willPerformAction:(BCLAction *)action
{
    
}

- (void) didPerformAction:(BCLAction *)action
{
}

- (void)beaconsPropertiesUpdateDidStart:(BCLBeacon *)beacon
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerPropertiesUpdateDidStartNotification object:self userInfo:@{@"beacon": beacon}];
}

- (void)beaconsPropertiesUpdateDidFinish:(BCLBeacon *)beacon success:(BOOL)success
{
    [self.beaconCtrlAdmin syncBeacon:beacon completion:^(NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerPropertiesUpdateDidFinishNotification object:self userInfo:@{@"beacon": beacon, @"success": @(NO)}];
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerPropertiesUpdateDidFinishNotification object:self userInfo:@{@"beacon": beacon, @"success": @(YES)}];
        });
    }];
}

- (void)beaconsFirmwareUpdateDidStart:(BCLBeacon *)beacon
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerFirmwareUpdateDidStartNotification object:self userInfo:@{@"beacon": beacon}];
}

- (void)beaconsFirmwareUpdateDidProgress:(BCLBeacon *)beacon progress:(NSUInteger)progress
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerFirmwareUpdateDidProgressNotification object:self userInfo:@{@"beacon": beacon, @"progress": @(progress)}];
}

- (void)beaconsFirmwareUpdateDidFinish:(BCLBeacon *)beacon success:(BOOL)success
{
    [self.beaconCtrlAdmin syncBeacon:beacon completion:^(NSError *error) {
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerFirmwareUpdateDidFinishNotification object:self userInfo:@{@"beacon": beacon, @"success": @(NO)}];
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerFirmwareUpdateDidFinishNotification object:self userInfo:@{@"beacon": beacon, @"success": @(YES)}];
    }];
}

#pragma mark - Private



- (NSString *)keychainServiceName
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (NSDictionary *)keychainAccountDictionary
{
    return [[SSKeychain accountsForService:[self keychainServiceName]] lastObject];
}

- (NSString *)emailFromKeyChain
{
    NSDictionary *keychainAccountDict = [self keychainAccountDictionary];
    
    if (keychainAccountDict) {
        return keychainAccountDict[kSSKeychainAccountKey];
    }
    
    return nil;
}

- (NSString *)passwordFromKeychain
{
    return [SSKeychain passwordForService:[self keychainServiceName] account:[self emailFromKeyChain]];;
}





- (void)finishSetupForAdminUserWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(BOOL, NSError *))completion
{
    __weak typeof(self) weakSelf = self;
    
    [self.beaconCtrlAdmin fetchTestApplicationCredentials:^(NSString *applicationClientId, NSString *applicationClientSecret, NSError *error) {
        if (!applicationClientId || !applicationClientSecret) {
            if (completion) {
                completion(NO, error);
                return;
            }
        }
        
        [weakSelf.beaconCtrlAdmin fetchZoneColors:^(NSError *error) {
            if (error) {
                if (completion) {
                    completion(NO, error);
                }
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [BCLBeaconCtrl setupBeaconCtrlWithClientId:applicationClientId clientSecret:applicationClientSecret userId:email pushEnvironment:self.pushEnvironment pushToken:self.pushNotificationDeviceToken completion:^(BCLBeaconCtrl *beaconCtrl, BOOL isRestoredFromCache, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        if (!beaconCtrl) {
                            if (completion) {
                                completion(NO, error);
                                return;
                            }
                        }
                        
                        weakSelf.beaconCtrl = beaconCtrl;
                        beaconCtrl.delegate = self;
                        [beaconCtrl startMonitoringBeacons];
                        [SSKeychain setPassword:password forService:[self keychainServiceName] account:email];
                        
                        weakSelf.refetchConfigurationTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:weakSelf selector:@selector(refetchBeaconCtrlConfigurationTimerHandler:) userInfo:nil repeats:YES];
                        
                        NSError *beaconMonitoringError;
                        if (![beaconCtrl isBeaconCtrlReadyToProcessBeaconActions:&beaconMonitoringError]) {
                            NSLog(@"");
                        }
                        
                        if (completion) {
                            completion(YES, nil);
                        }
                    });
                }];
            });
        }];
    }];
}

-(NSSet*)listOfBeacons {
    return 0;
}

- (void)refetchBeaconCtrlConfigurationTimerHandler:(NSTimer *)timer
{
    if (self.isAutomaticBeaconCtrlRefreshMuted) {
        return;
    }
    
    [self refetchBeaconCtrlConfiguration:^(NSError *error) {
        if (error) {
            // TODO: Handle error!
            return;
        }
    }];
}
- (void)logout
{
    [self.beaconCtrl stopMonitoringBeacons];
    
    [self.beaconCtrl logout];
    [self.beaconCtrlAdmin logout];
    
    [self.refetchConfigurationTimer invalidate];
    self.refetchConfigurationTimer = nil;
    
    self.beaconCtrl.delegate = nil;
    
    self.beaconCtrl = nil;
    self.beaconCtrlAdmin = nil;
    
    if ([self emailFromKeyChain]) {
        [SSKeychain deletePasswordForService:[self keychainServiceName] account:[self emailFromKeyChain]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BeaconManagerDidLogoutNotification object:self];
}


@end
