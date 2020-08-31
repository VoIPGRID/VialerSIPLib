#import <Foundation/Foundation.h>
#import "SipInvite.h"
#import "VSLCall.h"

static NSString *const REMOTE_PARTY_ID_KEY = @"Remote-Party-ID";
static NSString *const P_ASSERTED_IDENTITY_KEY = @"P-Asserted-Identity";

@interface SipInvite()
@property (readwrite, nonatomic) NSDictionary *remotePartyId;
@property (readwrite, nonatomic) NSDictionary *pAssertedIdentity;
@end

@implementation SipInvite

- (instancetype _Nullable)initWithInvitePacket:(char*)packet {
    self.remotePartyId = [self extractFromLikeHeader:REMOTE_PARTY_ID_KEY FromPacket:packet];
    self.pAssertedIdentity = [self extractFromLikeHeader:P_ASSERTED_IDENTITY_KEY FromPacket:packet];
    
    return self;
}

- (bool) hasRemotePartyId {
    return [self.remotePartyId objectForKey:@"caller_number"] != nil;
}

- (NSString *) getRemotePartyIdNumber {
    return self.remotePartyId[@"caller_number"];
}

- (NSString *) getRemotePartyIdName {
    return self.remotePartyId[@"caller_name"];
}

- (bool) hasPAssertedIdentity {
    return [self.pAssertedIdentity objectForKey:@"caller_number"] != nil;
}

- (NSString *_Nullable) getPAssertedIdentityNumber {
    return self.pAssertedIdentity[@"caller_number"];
}

- (NSString *_Nullable) getPAssertedIdentityName {
    return self.pAssertedIdentity[@"caller_name"];
}

/**
 Finds the FROM-like header (i.e. a header that contains information similar to the FROM field) in the invite and extracts the relevant data from it.

 @param packet The full INVITE packet.
 */
- (NSDictionary *) extractFromLikeHeader:(NSString *)header FromPacket:(char *)packet {
    NSArray *remotePartyId = [self extractValueForKey:header fromPacket:packet];
    
    if ([remotePartyId count] <= 0) {
        return nil;
    }
    
    NSString *remotePartyIdAddress = remotePartyId[0];

    return [VSLCall getCallerInfoFromRemoteUri:remotePartyIdAddress];
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
    NSString *lineSeparator = [packetAsString rangeOfString:@"\r\n"].location != NSNotFound ? @"\r\n" : @"\n";
    NSArray *lines = [packetAsString componentsSeparatedByString:lineSeparator];

    for (id line in lines) {
        if ([line hasPrefix:key]) {
            return [line stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@: ", key] withString:@""];
        }
    }
    
    return nil;
}

@end
