//
//  BeaconDashboardTableViewCell.h
//  BeaconPoc
//
//  Created by Aman Gupta on 17/06/16.
//  Copyright © 2016 Aman Gupta. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BeaconDashboardTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *beaconNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *beaconDistanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *major;
@property (strong, nonatomic) IBOutlet UILabel *minor;
@property (strong, nonatomic) IBOutlet UILabel *status;

@property (strong, nonatomic) IBOutlet UILabel *vendor;
@property (strong, nonatomic) IBOutlet UIImageView *arrowImage;
@property (strong, nonatomic) IBOutlet UILabel *noBeaconInRangeLabel;

@end
