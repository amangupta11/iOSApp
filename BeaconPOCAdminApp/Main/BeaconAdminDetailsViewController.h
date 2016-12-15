//
//  BeaconAdminDetailsViewController.h
//  BeaconPOCAdminApp
//
//  Created by Aman Gupta on 22/06/16.
//  Copyright © 2016 Aman Gupta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BeaconCtrl/BCLBeacon.h>

@interface BeaconAdminDetailsViewController : UIViewController
@property (nonatomic, strong)NSSet *observedBclBeacons;
@property (nonatomic, strong)CLBeacon *beaconDetails;
@end
