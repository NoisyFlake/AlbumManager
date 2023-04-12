#import <UIKit/UIKit.h>

@interface AlbumManager : NSObject
@property (nonatomic, retain) NSDictionary *settings;
+ (instancetype)sharedInstance;
- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (NSString *)uuidForCollection:(PHAssetCollection *)collection;
- (void)updateLockViewInStackView:(PUStackView *)stackView forCollection:(PHAssetCollection *)collection;
// - (void)updateLockViewInStackView:(PUStackView *)stackView;
@end

#define PREFERENCES_PATH           ROOT_PATH_NS_VAR(@"/var/mobile/Library/Preferences/")
#define PLIST_PATH                 ROOT_PATH_NS_VAR(@"/var/mobile/Library/Preferences/com.noisyflake.albummanager.plist")