#import <Foundation/Foundation.h>

@interface SipInvite : NSObject
- (instancetype _Nullable)initWithInvitePacket:(char*_Nonnull)packet;
- (bool) hasRemotePartyId;
- (NSString *_Nullable) getRemotePartyIdNumber;
- (NSString *_Nullable) getRemotePartyIdName;
@end
