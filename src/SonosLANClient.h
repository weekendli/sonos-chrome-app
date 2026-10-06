#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface SonosLANClient : NSObject
- (void)fetchState:(void (^)(NSDictionary *state))completion;
- (void)performAction:(NSString *)action value:(nullable NSNumber *)value completion:(void (^)(NSString * _Nullable error))completion;
+ (BOOL)isLocalURL:(NSURL *)url;
@end
NS_ASSUME_NONNULL_END
