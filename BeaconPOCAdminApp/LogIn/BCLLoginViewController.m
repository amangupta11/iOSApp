//
//  BCLLoginViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLLoginViewController.h"
#import "BeaconAdminCtrlManager.h"
#import "AlertControllerManager.h"
#import "AppDelegate.h"
#import "UIViewController+BCLActivityIndicator.h"
#import <BeaconCtrl/BCLBeacon.h>
#import <BeaconCtrl/BCLZone.h>
#import <BeaconCtrl/BCLLocation.h>
#import "BeaconDashboardViewController.h"

@interface BCLLoginViewController () <UIScrollViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIView *emailTextFieldContainer;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@property (weak, nonatomic) IBOutlet UIView *passwordTextFieldContainer;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoVerticalCenterConstraint;

@end

@implementation BCLLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardDidShow:) name: UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.emailTextField.text = @"";
    self.passwordTextField.text = @"";
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)beaconCtrlManagerDidLogoutNotification:(NSNotification *)notification
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.shouldVerifySystemSettings = NO;
}

- (IBAction)loginButtonAction:(id)sender
{
    NSLog(@"login!!");
    
    [self showActivityIndicatorViewAnimated:YES];
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

    __weak typeof(self) weakSelf = self;
    
    [[BeaconAdminCtrlManager sharedManager] setupForExistingAdminUserWithEmail:self.emailTextField.text password:self.passwordTextField.text completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            [weakSelf hideActivityIndicatorViewAnimated:YES];
            if (!success) {
                [[AlertControllerManager sharedManager] presentLogInErrorWithTitle:@"Error" message:@"Invalid email or password" inViewController:self completion:nil];
                return;
            }
            NSString * storyboardName = @"Main";
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
            BeaconDashboardViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"BeaconDashboradViewController"];
            [self.navigationController pushViewController:vc animated:YES];
        });
    }];
}





#pragma mark - BCLRegisterViewControllerDelegate


#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Keyboard

- (void) keyboardDidShow:(NSNotification *)notification
{
    
}

- (void) keyboardWillHide:(NSNotification *)notification
{
   
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
       //self.logoVerticalCenterConstraint.constant = constant;
    [self.view layoutIfNeeded];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    //[self performSegueWithIdentifier:@"BeaconDetailsViewController" sender:nil];
}



@end
