#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>

@interface AlbumManager : NSObject
@property (nonatomic, retain) NSDictionary *settings;
+ (instancetype)sharedInstance;
- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (NSString *)uuidForCollection:(PHAssetCollection *)collection;
- (void)authenticateWithBiometricsWithCompletion:(void (^)(BOOL success))completion;
- (void)authenticateWithPasswordForHash:(NSString *)hash WithCompletion:(void (^)(BOOL success))completion;
- (NSString*)sha256HashForText:(NSString*)text;
@end

#define PREFERENCES_PATH           ROOT_PATH_NS_VAR(@"/var/mobile/Library/Preferences/")
#define PLIST_PATH                 ROOT_PATH_NS_VAR(@"/var/mobile/Library/Preferences/com.noisyflake.albummanager.plist")