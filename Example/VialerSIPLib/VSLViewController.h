//
//  VSLViewController.h
//  Copyright © 2015 Devhouse Spindle. All rights reserved.
//

@import UIKit;

#import <VialerSIPLib-iOS/VialerSIPLib.h>
#import "VSLCallViewController.h"

@interface VSLViewController : UIViewController <VSLCallViewControllerDelegate>
@property (strong, nonatomic) VSLCall *call;
@end
