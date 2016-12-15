//
//  BeaconAdminDetailsViewController.m
//  BeaconPOCAdminApp
//
//  Created by Aman Gupta on 22/06/16.
//  Copyright © 2016 Aman Gupta. All rights reserved.
//

#import "BeaconAdminDetailsViewController.h"
#import <BeaconCtrl/BCLBeacon.h>
#import "BeaconAdminCtrlManager.h"
#import "AlertControllerManager.h"
#import "UIViewController+BCLActivityIndicator.h"
@interface BeaconAdminDetailsViewController ()
@property (strong, nonatomic) IBOutlet UITextField *beaconNameTextField;

@property (strong, nonatomic) IBOutlet UITextField *majorTextField;
@property (strong, nonatomic) IBOutlet UITextField *minorTextField;
@property (strong, nonatomic) IBOutlet UITextField *distanceTextField;
@property (strong, nonatomic) IBOutlet UITextField *vendorTextField;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (nonatomic) BCLEventType selectedTrigger;
@property (strong, nonatomic) IBOutlet UITextField *uuidTextField;
@property(nonatomic, retain) BCLBeacon*  bclBeacon;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) IBOutlet UIButton *editButton;
@property (nonatomic) NSString *notificationMessage;
@end

@implementation BeaconAdminDetailsViewController
NSMutableDictionary *beaconDict;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.saveButton.hidden = true;
    self.deleteButton.hidden = true;
    self.editButton.hidden = false;
    [self setNavigationBar];
    [self showBeaconDetails];
    [self disableTextFieldEditing];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    // Do any additional setup after loading the view.
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)setNavigationBar
{
    UIImage *backBtnImage = [UIImage imageNamed:@"back.png"] ;
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithImage:backBtnImage style:UIBarButtonItemStylePlain target:self action:@selector(backButtonAction) ];
    self.navigationItem.leftBarButtonItem = backButtonItem;
}

-(void)showBeaconDetails
{
    NSArray *listOfBeacons = [self.observedBclBeacons allObjects];
    for (int i = 0 ; i < listOfBeacons.count; i++) {
        self.bclBeacon = [listOfBeacons objectAtIndex:i];
        if ([[self.bclBeacon.major stringValue] isEqualToString:[_beaconDetails.major stringValue]]) {
            self.deleteButton.hidden = false;
            self.beaconNameTextField.text = self.bclBeacon .name;
            self.uuidTextField.text = self.bclBeacon .proximityUUID.UUIDString;
            self.distanceTextField.text = [[NSString alloc] initWithFormat:@"%.2fm", self.bclBeacon .accuracy];
            self.majorTextField.text =[NSString stringWithFormat:@"%.2f", [[self.bclBeacon .major stringValue] floatValue]];
            self.minorTextField.text =[NSString stringWithFormat:@"%.2f", [[self.bclBeacon .minor stringValue] floatValue]];
            self.vendorTextField.text = self.bclBeacon.vendor;
            break;
        }
        else{
            self.deleteButton.hidden = true;
            self.beaconNameTextField.text = @"NA";
            self.uuidTextField.text = _beaconDetails.proximityUUID.UUIDString;
            self.distanceTextField.text = [[NSString alloc] initWithFormat:@"%.2fm", _beaconDetails.accuracy];
            self.majorTextField.text =[NSString stringWithFormat:@"%.2f", [[_beaconDetails.major stringValue] floatValue]];
            self.minorTextField.text =[NSString stringWithFormat:@"%.2f", [[_beaconDetails.minor stringValue] floatValue]];
            self.vendorTextField.text = @"NA";
        }
    }
    
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}
-(void)backButtonAction
{
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)disableTextFieldEditing
{
    self.beaconNameTextField.enabled = false;
    self.uuidTextField.enabled = false;
    self.majorTextField.enabled = false;
    self.minorTextField.enabled = false;
    self.distanceTextField.enabled = false;
    self.vendorTextField.enabled = false;
    
}
- (IBAction)editFields:(id)sender {
    self.beaconNameTextField.enabled = true;
    self.saveButton.hidden = false;
    self.editButton.hidden = true;
    self.uuidTextField.enabled = true;
    self.majorTextField.enabled = true;
    self.minorTextField.enabled = true;
    self.distanceTextField.enabled = true;
    self.vendorTextField.enabled = true;
    
}
- (IBAction)saveBeacon:(id)sender {
    NSString *testActionName;
    NSArray *testActionAttributes;
    
    if (self.notificationMessage) {
        testActionName = @"Test action";
        testActionAttributes = @[@{@"name" : @"text", @"value" : self.notificationMessage}];
    }
    float  majorValue = [self.majorTextField.text floatValue];
    float  minorValue = [self.minorTextField.text floatValue];
    NSNumber * majorNumber =[NSNumber numberWithFloat:majorValue];
    NSNumber * minorNumber =[NSNumber numberWithFloat:minorValue];
    beaconDict = [[NSMutableDictionary alloc] init];
    [beaconDict setValue:self.beaconNameTextField.text forKey:@"name"];
    [beaconDict setValue:self.uuidTextField.text forKey:@"uuid"];
    [beaconDict setValue:majorNumber forKey:@"major"];
    [beaconDict setValue:minorNumber forKey:@"minor"];

    [self.bclManager createBeacon:beaconDict testActionName:testActionName testActionTrigger:self.selectedTrigger testActionAttributes:testActionAttributes completion:^(BCLBeacon *newBeacon, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
        
                    NSLog(@"success");
                [[AlertControllerManager sharedManager] presentErrorWithTitle:@"Success" message:@"Beacon Added Successfully" inViewController:self completion:nil];
               
            } else {
                [[AlertControllerManager sharedManager] presentError:error inViewController:self completion:nil];
            }
            
            self.navigationItem.rightBarButtonItem.enabled = YES;
            self.navigationItem.leftBarButtonItem.enabled = YES;
            [self hideActivityIndicatorViewAnimated:YES];
        });
    }];

}



- (BeaconAdminCtrlManager *)bclManager
{
    return [BeaconAdminCtrlManager sharedManager];
}
- (IBAction)deleteBeacon:(id)sender {
   
    
        [self showActivityIndicatorViewAnimated:YES];
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.leftBarButtonItem.enabled = NO;
        [self.bclManager deleteBeacon:self.bclBeacon completion:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [[AlertControllerManager sharedManager] presentErrorWithTitle:@"Success" message:@"Beacon removed Successfully" inViewController:self completion:nil];
                } else {
                    [[AlertControllerManager sharedManager] presentError:error inViewController:self completion:nil];
                }
                [self hideActivityIndicatorViewAnimated:YES];
                self.navigationItem.rightBarButtonItem.enabled = YES;
                self.navigationItem.leftBarButtonItem.enabled = YES;
            });
        }];
    
}
@end
