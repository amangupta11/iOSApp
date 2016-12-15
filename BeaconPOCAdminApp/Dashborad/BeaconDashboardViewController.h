//
//  BeaconDashboardViewController.h
//  BeaconPoc
//
//  Created by Aman Gupta on 10/06/16.
//  Copyright © 2016 Aman Gupta. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BeaconDashboardViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

