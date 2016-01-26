//
//  VSLCallViewController.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <VialerSIPLib-iOS/VialerSIPLib.h>

@protocol VSLCallViewControllerDelegate <NSObject>
@property (strong, nonatomic) VSLCall *call;
@end

@interface VSLCallViewController : UIViewController

/**
 *  Delegate that conforms to VSLCallViewControllerDelegate protocol.
 *
 *  Set this property to get the call instance after the view is dismissed.
 */
@property (strong, nonatomic) id<VSLCallViewControllerDelegate> delegate;

/**
 *  Account that should be used for making the outgoing call.
 */
@property (strong, nonatomic) VSLAccount *account;

/**
 *  Number that should be called.
 */
@property (strong, nonatomic) NSString *numberToCall;

/**
 *  Call instance. 
 *
 *  This could be set if the call is incoming.
 */
@property (strong, nonatomic) VSLCall *call;

@end
