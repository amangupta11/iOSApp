//
//  ViewController.m
//  BeaconPoc
//
//  Created by Aman Gupta on 10/06/16.
//  Copyright © 2016 Aman Gupta. All rights reserved.
//

#import "BeaconDashboardViewController.h"
#import "BeaconDashboardTableViewCell.h"
#import "BeaconAdminDetailsViewController.h"
#import "BeaconRadarViewController.h"
#import "AIBBeaconRegionAny.h"
#import "UIViewController+BCLActivityIndicator.h"
#define  kCellIdentifier @"cellBeaconIdentifier"
@import CoreLocation;
@interface BeaconDashboardViewController ()<CLLocationManagerDelegate>
{
    BeaconAdminDetailsViewController *beaconAdminDetailsViewController;
}
@property(nonatomic, strong) NSDictionary*		beaconsDict;
@property(nonatomic, strong) CLLocationManager* locationManager;
@property(nonatomic, strong) NSArray*			listUUID;
@property(nonatomic)		 BOOL				sortByMajorMinor;
@property(nonatomic)		 BOOL				beaconRegistered;
@property(nonatomic, retain) CLBeacon*			selectedBeacon;
@property(nonatomic, retain) BCLBeacon*         bclBeacon;
@end

@implementation BeaconDashboardViewController
NSSet *observedBeacons;
UIBarButtonItem *rightButtonItem;
BeaconAdminDetailsViewController *vc;
BeaconRadarViewController *radarView;
- (void)viewDidLoad {
    [super viewDidLoad];
    [self showActivityIndicatorViewAnimated:YES];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.leftBarButtonItem = backButtonItem;
    backButtonItem.enabled = NO;
    rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"RadarView" style:UIBarButtonItemStylePlain target:self action:@selector(moveToRadarViewController)];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
    rightButtonItem.enabled = NO;
    // Do any additional setup after loading the view, typically from a nib.
    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(initializeLocationManager) userInfo:nil repeats:YES];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconListChanged:) name:@"sortedBeaconsList" object:nil];
}
-(void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    [self.navigationItem.leftBarButtonItem setEnabled:NO];
}
-(void)initializeLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.listUUID=[[NSArray alloc] init];
    self.beaconsDict=[[NSMutableDictionary alloc] init];
    self.sortByMajorMinor=NO;
    
    AIBBeaconRegionAny *beaconRegionAny = [[AIBBeaconRegionAny alloc] initWithIdentifier:@"Any"];
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startRangingBeaconsInRegion:beaconRegionAny];
    
}
- (void)beaconListChanged:(NSNotification *)notification
{
     observedBeacons = notification.object;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
     return [_listUUID count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(_listUUID.count>0)
    {
        NSString* key=[_listUUID objectAtIndex:section];
        return [[_beaconsDict objectForKey:key] count];
    }
    else
    {
        return 1;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BeaconDashboardTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"BeaconDetailsCell" forIndexPath:indexPath];
    if(_listUUID.count>0)
    {
        __weak typeof(self) weakSelf = self;
        [weakSelf hideActivityIndicatorViewAnimated:YES];
        rightButtonItem.enabled = YES;
        NSString* key=[_listUUID objectAtIndex:[indexPath indexAtPosition:0]];
        CLBeacon* beacon=[[_beaconsDict objectForKey:key] objectAtIndex:[indexPath indexAtPosition:1]];
        cell.beaconNameLabel.text = beacon.proximityUUID.UUIDString;
        cell.major.text =[NSString stringWithFormat:@"Major: %.2f", [[beacon.major stringValue] floatValue]];
        cell.minor.text =[NSString stringWithFormat:@"Minor: %.2f", [[beacon.minor stringValue] floatValue]];
        cell.beaconDistanceLabel.text=[[NSString alloc] initWithFormat:@"Distance: %.2fm", beacon.accuracy];
        cell.arrowImage.hidden = false;
        cell.noBeaconInRangeLabel.hidden = true;
         NSArray *listOfBeacons = [observedBeacons allObjects];
        for (int i = 0 ; i < listOfBeacons.count; i++) {
            self.bclBeacon = [listOfBeacons objectAtIndex:i];
            NSLog(@"%@ - %@", [beacon.major stringValue], [self.bclBeacon.major stringValue]);
            if ([[self.bclBeacon.major stringValue] isEqualToString:[beacon.major stringValue]] && [self.bclBeacon.proximityUUID.UUIDString isEqualToString:beacon.proximityUUID.UUIDString] && [[self.bclBeacon.minor stringValue] isEqualToString:[beacon.minor stringValue]] ) {
                cell.status.text = @"Registered";
                 self.beaconRegistered = true;
                break;
            }
            else{
                cell.status.text = @"Not Registered";
                self.beaconRegistered = false;

            }
            
        }
        
    }
    else{
        __weak typeof(self) weakSelf = self;
        rightButtonItem.enabled = NO;
        [weakSelf hideActivityIndicatorViewAnimated:YES];
        cell.noBeaconInRangeLabel.hidden = false;
        cell.noBeaconInRangeLabel.text =@"No beacon in range";
        cell.beaconNameLabel.text =nil;
        cell.beaconDistanceLabel.text =@"";
        cell.major.text =nil;
        cell.minor.text =nil;
        cell.status.text = nil;
        cell.vendor.text = nil;
        cell.arrowImage.hidden = true;
    }

    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if((_listUUID.count>0))
    {
        NSString * storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        vc = [storyboard instantiateViewControllerWithIdentifier:@"BeaconDetailsViewController"];
        NSString* key=[_listUUID objectAtIndex:[indexPath indexAtPosition:0]];
        CLBeacon* beacon=[[_beaconsDict objectForKey:key] objectAtIndex:[indexPath indexAtPosition:1]];
         vc.beaconDetails = beacon;
         vc.observedBclBeacons = observedBeacons;
         [self.navigationController pushViewController:vc animated:YES];
  
    }
    else
    {
        
    }
    
}

-(void)moveToRadarViewController
{
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    radarView = [storyboard instantiateViewControllerWithIdentifier:@"BeaconRadarViewController"];
    [self.navigationController pushViewController:radarView animated:YES];
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"locationManagerDidChangeAuthorizationStatus: %d", status);
    
    [UIAlertController alertControllerWithTitle:@"Authoritzation Status changed"
                                        message:[[NSString alloc] initWithFormat:@"Location Manager did change authorization status to: %d", status]
                                 preferredStyle:UIAlertControllerStyleAlert];
    
}
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"locationManager:%@ didRangeBeacons:%@ inRegion:%@",manager, beacons, region);
    
    NSMutableArray* listUuid=[[NSMutableArray alloc] init];
    NSMutableDictionary* beaconsDict=[[NSMutableDictionary alloc] init];
    for (CLBeacon* beacon in beacons) {
        NSString* uuid=[beacon.proximityUUID UUIDString];
        NSMutableArray* list=[beaconsDict objectForKey:uuid];
        if (list==nil){
            list=[[NSMutableArray alloc] init];
            [listUuid addObject:uuid];
            [beaconsDict setObject:list forKey:uuid];
        }
        [list addObject:beacon];
    }
    [listUuid sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString* string1=obj1;
        NSString* string2=obj2;
        return [string1 compare:string2];
    }];
    if (_sortByMajorMinor){
        for (NSString* uuid in listUuid){
            NSMutableArray* list=[beaconsDict objectForKey:uuid];
            [list sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                CLBeacon* b1=obj1;
                CLBeacon* b2=obj2;
                NSComparisonResult r=[b1.major compare:b2.major];
                if (r==NSOrderedSame){
                    r=[b1.minor compare:b2.minor];
                }
                return r;
            }];
        }
    }
    _listUUID=listUuid;
    _beaconsDict=beaconsDict;
    
    [self.tableView reloadData];
}
- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"locationManager:%@ rangingBeaconsDidFailForRegion:%@ withError:%@", manager, region, error);
    
    [UIAlertController alertControllerWithTitle:@"Ranging Beacons fail"
                                        message:[[NSString alloc] initWithFormat:@"Ranging beacons fail with error: %@", error]
                                 preferredStyle:UIAlertControllerStyleAlert];
}

@end
