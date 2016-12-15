/*
 
 The MIT License (MIT)
 
 Copyright (c) 2015 ABM Adnan
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "BeaconRadarViewController.h"
#import "BeaconArcs.h"
#import "BeaconRadar.h"
#import "BeaconDot.h"
#import "AIBBeaconRegionAny.h"
#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiandsToDegrees(x) (x * 180.0 / M_PI)

@interface BeaconRadarViewController ()<CLLocationManagerDelegate>{
    __weak IBOutlet UIView *radarViewHolder;
    __weak IBOutlet UIView *radarLine;
    BeaconArcs *arcsView;
    BeaconRadar *radarView;
    float currentDeviceBearing;
    NSMutableArray *dots;
    NSArray *nearbyUsers;
    NSTimer *detectCollisionTimer;
    int beaconCount;
}
@property(nonatomic, strong) NSDictionary*		beaconsDict;
@property(nonatomic, strong) CLLocationManager* locationManager;
@property(nonatomic, strong) NSArray*			listUUID;
@property(nonatomic)		 BOOL				sortByMajorMinor;
@property(nonatomic, retain) CLBeacon*			selectedBeacon;
@end

@implementation BeaconRadarViewController
float distance;
BeaconDot *dot;

- (void)viewDidLoad {
    [super viewDidLoad];
    beaconCount = 0;
    [self initializeRadarView];
    [self initializeLocationManager];
}
-(void)initializeRadarView
{
    
    // Do any additional setup after loading the view, typically from a nib.
    dots = [[NSMutableArray alloc] init];
    nearbyUsers = [[NSArray alloc] init];
    
    arcsView = [[BeaconArcs alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
    
    // NOTE: Since our gradient layer is built as an image,
    // we need to scale it to match the display of the device.
    arcsView.layer.contentsScale = [UIScreen mainScreen].scale; // Retina
    
    radarViewHolder.layer.contentsScale = [UIScreen mainScreen].scale; // Retina
    
    [radarViewHolder addSubview:arcsView];
    
    // add tap gesture recognizer to arcs view to capture tap on dots (user profiles) and enlarge the selected dots with a white border
    arcsView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDotTapped:)];
    [arcsView addGestureRecognizer:tapGestureRecognizer];
    
    radarView = [[BeaconRadar alloc] initWithFrame:CGRectMake(3, 3, radarViewHolder.frame.size.width-6, radarViewHolder.frame.size.height-6)];
    
    radarView.layer.contentsScale = [UIScreen mainScreen].scale; // Retina
    
    radarView.alpha = 0.68;
    
    [radarViewHolder addSubview:radarView];
    [self spinRadar];
    currentDeviceBearing = 0;

}
-(void)initializeLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.headingFilter = kCLHeadingFilterNone;
    self.listUUID=[[NSArray alloc] init];
    self.beaconsDict=[[NSMutableDictionary alloc] init];
    self.sortByMajorMinor=NO;
    
    AIBBeaconRegionAny *beaconRegionAny = [[AIBBeaconRegionAny alloc] initWithIdentifier:@"Any"];
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startRangingBeaconsInRegion:beaconRegionAny];
}

-(void) removePreviousDots {
    for (BeaconDot *dot in dots) {
        [dot removeFromSuperview];
    }
    //dots = [NSMutableArray array];
}
#pragma mark - Reload Radar

-(void)renderUsersOnRadar{
    [self removePreviousDots];
    
    for (int i = 0 ; i < _listUUID.count; i++){
        NSString* key=[_listUUID objectAtIndex:i];
        CLBeacon* beacon=[[_beaconsDict objectForKey:key] objectAtIndex:0];
        distance = beacon.accuracy;
        dot = [[BeaconDot alloc] initWithFrame:CGRectMake(0, 0, 32.0, 32.0)];
        dot.layer.contentsScale = [UIScreen mainScreen].scale; // Retina
        dot.userDistance = [NSNumber numberWithFloat:distance];
        // dot.userProfile = user;
        dot.zoomEnabled = NO;
        dot.userInteractionEnabled = NO;
        [arcsView addSubview:dot];
        [dots addObject:dot];
        [self filterNearByUsersByDistance:distance];

    }
            // start timer to detect collision with radar line and blink
    detectCollisionTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                            target:self
                                                          selector:@selector(detectCollisions:)
                                                          userInfo:nil
                                                           repeats:YES];
}



#pragma mark - Spin the radar view continuously
-(void)spinRadar{
    /**** spin animation object ***/
    CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spin.duration = 1;
    spin.toValue = [NSNumber numberWithFloat:-M_PI];
    spin.cumulative = YES;
    spin.removedOnCompletion = NO; // this is to keep on animating after application pause-resume
    spin.repeatCount = MAXFLOAT;
    radarLine.layer.anchorPoint = CGPointMake(-0.18, 0.5);
    
    [radarLine.layer addAnimation:spin forKey:@"spinRadarLine"];
    [radarView.layer addAnimation:spin forKey:@"spinRadarView"];
}

- (void)rotateArcsToHeading:(CGFloat)angle {
    // rotate the circle to heading degree
    arcsView.transform = CGAffineTransformMakeRotation(angle);
    // rotate all dots to opposite angle to keep the profile image straight up
    /*for (Dot *dot in dots) {
     dot.transform = CGAffineTransformMakeRotation(-angle);
     }*/
}

- (float)getHeadingForDirectionFromCoordinate:(CLLocationCoordinate2D)fromLoc toCoordinate:(CLLocationCoordinate2D)toLoc
{
    float fLat = degreesToRadians(fromLoc.latitude);
    float fLng = degreesToRadians(fromLoc.longitude);
    float tLat = degreesToRadians(toLoc.latitude);
    float tLng = degreesToRadians(toLoc.longitude);
    
    float degree = radiandsToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)));
    
    if (degree >= 0) {
        return -degree;
    } else {
        return -(360+degree);
    }
}

#pragma mark - Rotate/Trsnslate Dot

- (void)rotateDot:(BeaconDot*)dot fromBearing:(CGFloat)fromDegrees toBearing:(CGFloat)degrees atDistance:(CGFloat)distance {
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathAddArc(path,nil, 140, 140, distance, degreesToRadians(fromDegrees), degreesToRadians(degrees), YES);
    
    CAKeyframeAnimation *theAnimation;
    
    // animation object for the key path
    theAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    theAnimation.path=path;
    CGPathRelease(path);
    
    // set the animation properties
    theAnimation.duration=3;
    theAnimation.removedOnCompletion = NO;
    theAnimation.repeatCount = 0;
    theAnimation.autoreverses = NO;
    theAnimation.fillMode = kCAFillModeForwards;
    theAnimation.cumulative = YES;
    
    
    CGPoint newPosition = CGPointMake(distance*cos(degreesToRadians(degrees))+138, distance*sin(degreesToRadians(degrees))+138);
    dot.layer.position = newPosition;
    
    
    [dot.layer addAnimation:theAnimation forKey:@"rotateDot"];
    
}

- (void)translateDot:(BeaconDot*)dot toBearing:(CGFloat)degrees atDistance:(CGFloat)distance {
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    
    [animation setFromValue:[NSValue valueWithCGPoint:[[dot.layer.presentationLayer valueForKey:@"position"] CGPointValue] ]];
    
    CGPoint newPosition = CGPointMake(distance*cos(degreesToRadians(degrees))+138, distance*sin(degreesToRadians(degrees))+138);
    [animation setToValue:[NSValue valueWithCGPoint: newPosition]];
    
    [animation setDuration:0.3f];
    animation.fillMode = kCAFillModeForwards;
    animation.autoreverses = NO;
    animation.repeatCount = 0;
    animation.removedOnCompletion = NO;
    animation.cumulative = YES;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [alphaAnimation setDuration:0.5f];
    alphaAnimation.fillMode = kCAFillModeForwards;
    alphaAnimation.autoreverses = NO;
    alphaAnimation.repeatCount = 0;
    alphaAnimation.removedOnCompletion = NO;
    alphaAnimation.cumulative = YES;
    alphaAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    if (distance > 132) {
        [alphaAnimation setToValue:[NSNumber numberWithFloat:0.0f]];
        
    }else{
        [alphaAnimation setToValue:[NSNumber numberWithFloat:1.0f]];
        
    }
    
    [dot.layer addAnimation:alphaAnimation forKey:@"alphaDot"];
    
    [dot.layer addAnimation:animation forKey:@"translateDot"];
    
}

#pragma mark - Tap Evaent on Dot
- (void)onDotTapped:(UITapGestureRecognizer *)recognizer {
    
    UIView *circleView = recognizer.view;
    
    CGPoint point = [recognizer locationInView:circleView];
    
    // The for loop is to find out multiple dots in vicinity
    // you may define a NSMutableArray before the for loop and
    // get the group of dots together
    NSMutableArray *tappedUsers = [NSMutableArray array];
                                   
    for (BeaconDot *d in dots) {
        if (d.zoomEnabled) {
            // remove selection from previously selected dot(s)
            d.zoomEnabled = NO;
            d.layer.borderColor = [UIColor clearColor].CGColor;
            [d setNeedsDisplay];
        }
        if([d.layer.presentationLayer hitTest:point] != nil){
            
            // you can get the list of tapped user(s if more than one users are close enough)
            [tappedUsers addObject:d]; // use this variable outside of for loop to get list of users

            // Show white border for selected dot(s) and zoom out a little bit
            d.layer.borderColor = [UIColor whiteColor].CGColor;
            d.layer.borderWidth = 1;
            d.layer.cornerRadius = 16;
            [d setNeedsDisplay];
            
            [self pulse:d];
            
            d.zoomEnabled = YES; // it'll keep a trace of selected dot(s)
        }
    }
    // use tappedUsers variable according to your app logic
}
#pragma mark - Detect Collisions

- (void)detectCollisions:(NSTimer*)theTimer
{
    float radarLineRotation = radiandsToDegrees( [[radarLine.layer.presentationLayer valueForKeyPath:@"transform.rotation.z"] floatValue] );
    
    if (radarLineRotation >= 0) {
        radarLineRotation -= 360;
    }
    
    
    for (int i = 0; i < [dots count]; i++) {
        BeaconDot *dot = [dots objectAtIndex:i];
        
        float dotBearing = [dot.bearing floatValue] - currentDeviceBearing;
        
        if (dotBearing < -360) {
            dotBearing += 360;
        }
        
        // collision detection
        if( ABS(dotBearing - radarLineRotation) <=  20)
        {
            [self pulse:dot];
            
        }
    }
}
-(void)pulse:(BeaconDot*)dot{
    if([dot.layer.animationKeys containsObject:@"pulse"] || dot.zoomEnabled){ // view is already animating. so return
        return;
    }
    
    CABasicAnimation * pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.duration = 0.15;
    pulse.toValue = [NSNumber numberWithFloat:1.4];
    pulse.autoreverses = YES;
    dot.layer.contentsScale = [UIScreen mainScreen].scale; // Retina
    [dot.layer addAnimation:pulse forKey:@"pulse"];
}

#pragma mark - Slider

// for this function to work, sorting of users data by distance in ASC order (nearest to farthest) is a must
-(void) filterNearByUsersByDistance: (float)maxDistance{
    for (id d in dots) {
        BeaconDot *dot = (BeaconDot *)d;
        float distance = MAX(35,[dot.userDistance floatValue] * 132.0 / maxDistance);
        [self translateDot:dot toBearing:[dot.bearing floatValue] atDistance: distance];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    float heading = newHeading.magneticHeading; //in degrees
    float headingAngle = -(heading*M_PI/180); //assuming needle points to top of iphone. convert to radians
    currentDeviceBearing = heading;
    //    circle.transform = CGAffineTransformMakeRotation(headingAngle);
    [self rotateArcsToHeading:headingAngle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
   
    if(_listUUID.count!=beaconCount)
    {
        beaconCount = (int)_listUUID.count;
        [self renderUsersOnRadar];
       //NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(renderUsersOnRadar) userInfo:nil repeats:YES];
    }
}
@end
