#import <Foundation/Foundation.h>
#import "SipInvite.h"
#import "VSLCall.h"

static NSString *const REMOTE_PARTY_ID_KEY = @"Remote-Party-ID";

@interface SipInvite()
@property (readwrite, nonatomic) NSDictionary *remotePartyId;
@end

@implementation SipInvite

/**
 Create this SipInvite object using the full INVITE packet.

 @param packet The full SIP INVITE packet.
 @return An instance of SipInvite
 */
- (instancetype _Nullable)initWithInvitePacket:(char*)packet {
    [self extractRemotePartyIdFromPacket:packet];

    return self;
}

/**
 Check if this INVITE contained a REMOTE-PARTY-ID SIP header.

 @return TRUE if the INVITE contained the header, otherwise FALSE.
 */
- (bool) hasRemotePartyId {
    return [self.remotePartyId objectForKey:@"caller_number"] != nil;
}

/**
 Get the caller id from the REMOTE-PARTY-ID SIP header.
 
 @return The caller id from the REMOTE-PARTY-ID SIP header.
 */
- (NSString *) getRemotePartyIdNumber {
    return self.remotePartyId[@"caller_number"];
}

/**
 Get the name from the REMOTE-PARTY-ID SIP header.

 @return The name from the REMOTE-PARTY-ID SIP header.
 */
- (NSString *) getRemotePartyIdName {
    return self.remotePartyId[@"caller_name"];
}

/**
 Finds the REMOTE-PARTY-ID header in the invite and extracts the relevant data from it.

 @param packet The full INVITE packet.
 */
- (void) extractRemotePartyIdFromPacket:(char *)packet {
    NSArray *remotePartyId = [self extractValueForKey:REMOTE_PARTY_ID_KEY fromPacket:packet];
    
    if ([remotePartyId count] <= 0) {
        return;
    }
    
    NSString *remotePartyIdAddress = remotePartyId[0];

    self.remotePartyId = [VSLCall getCallerInfoFromRemoteUri:remotePartyIdAddress];
}

/**
 Extract the specific key given, terminated by a semi-colon.
 
 @param key The key to search for, this should appear at the start of the line.
 @param packet The entire packet to search.
 @return return The value of the key, up to the semi-colon.
 */
- (NSArray *) extractValueForKey:(NSString *)key fromPacket:(char*)packet {
    NSString *line = [self findLineContaining:key inPacket:packet];
    
    if (line == nil) {
        return nil;
    }
    
    
    return [line componentsSeparatedByString:@";"];
}

/**
 Searches the SIP INVITE for the line with a given key.
 
 @param key The key to search for, this should appear at the start of the line.
 @param packet The entire packet to search.
 @return return The entire line relevant to the given key, nil if this line is not found.
 */
- (NSString *) findLineContaining:(NSString *)key inPacket:(char*) packet {
    NSString *packetAsString = [NSString stringWithUTF8String:packet];
    NSArray *lines = [packetAsString componentsSeparatedByString:@"\n"];
    
    for (id line in lines) {
        if ([line hasPrefix:key]) {
            NSString *formattedKey = [NSString stringWithFormat:@"%@: ", key];
            NSLog(@"TEST123: >>>>%@<<<<", formattedKey);
            return [line stringByReplacingOccurrencesOfString:formattedKey withString:@""];
        }
    }
    
    return nil;
}

@end
