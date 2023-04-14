#import <Photos/Photos.h>

@interface PHObject (Private)
@property (readonly) NSString * uuid;
@end

@interface PHAssetCollection (Private)
@property (readonly) NSString *cloudGUID;
@end