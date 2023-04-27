#import <Photos/Photos.h>

@interface PHObject (Private)
@property (readonly) NSString * uuid;
@property (readonly) PHPhotoLibrary *photoLibrary;
@end

@interface PHAsset (Private)
+(id)fetchAssetsWithUUIDs:(id)uuids options:(id)options;
@end

@interface PHAssetCollection (Private)
@property (readonly) NSString *cloudGUID;
@property (nonatomic,readonly) NSString * title;
@end

@interface TCCDService : NSObject
@property (retain, nonatomic) NSString *name;
@end

@interface PLManagedAsset : NSObject
@property (nonatomic, readonly, retain) id localID;
@property (nonatomic, readonly) NSString *pl_uuid;
-(id)pl_PHAssetFromPhotoLibrary:(id)photoLibrary;
@end