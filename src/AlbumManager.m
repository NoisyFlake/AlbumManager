#import "Tweak.h"

@implementation AlbumManager

+ (instancetype)sharedInstance {
    static AlbumManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        NSFileManager *manager = [NSFileManager defaultManager];
        if(![manager fileExistsAtPath:PREFERENCES_PATH isDirectory:nil]) {
            if(![manager createDirectoryAtPath:PREFERENCES_PATH withIntermediateDirectories:YES attributes:nil error:nil]) {
                NSLog(@"ERROR: Unable to create preferences folder");
                return nil;
            }
        }

        if(![manager fileExistsAtPath:PLIST_PATH isDirectory:nil]) {
            if (![manager createFileAtPath:PLIST_PATH contents:nil attributes:nil]) {
                NSLog(@"ERROR: Unable to create preferences file");
                return nil;
            }

            [[NSDictionary new] writeToURL:[NSURL fileURLWithPath:PLIST_PATH] error:nil];
        }

        _settings = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:PLIST_PATH] error:nil];
    }

    return self;
}

- (id)objectForKey:(NSString *)key {
    return [_settings objectForKey:key];
}

- (void)setObject:(id)object forKey:(NSString *)key {
    NSMutableDictionary *settings = [_settings mutableCopy];

    [settings setObject:object forKey:key];
    NSError *error;
    [settings writeToURL:[NSURL fileURLWithPath:PLIST_PATH] error:&error];

    _settings = [settings copy];
}

-(void)removeObjectForKey:(NSString *)key {
    NSMutableDictionary *settings = [_settings mutableCopy];

    [settings removeObjectForKey:key];
    [settings writeToURL:[NSURL fileURLWithPath:PLIST_PATH] error:nil];

    _settings = [settings copy];
}

- (NSString *)uuidForCollection:(PHAssetCollection *)collection {
    return collection.cloudGUID ? collection.cloudGUID : collection.uuid;
}

// - (void)updateLockViewInStackView:(PUStackView *)stackView {
- (void)updateLockViewInStackView:(PUStackView *)stackView forCollection:(PHAssetCollection *)collection {
    NSString *uuid = [self uuidForCollection:collection];
    // NSString *uuid = stackView.collectionUUID;

	if ([self objectForKey:uuid] == nil) {
        if (stackView.lockView) {
            [stackView.lockView removeFromSuperview];
            stackView.lockView = nil;
        }

        return;
    }

	if (!stackView.lockView) {
        NSLog(@"Size: %f", stackView.bounds.size.width);
        UIView *lockView = [[UIView alloc] initWithFrame:stackView.bounds];
        lockView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		blurEffectView.frame = lockView.bounds;
		blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [lockView addSubview:blurEffectView];

        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightMedium scale:UIImageSymbolScaleLarge];
        UIImage *lockIcon = [UIImage systemImageNamed:@"lock" withConfiguration:configuration];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:lockIcon];
        imageView.tintColor = UIColor.whiteColor;
        imageView.frame = lockView.bounds;
        imageView.contentMode = UIViewContentModeCenter;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [lockView addSubview:imageView];

		[stackView addSubview:lockView];
        stackView.lockView = lockView;
	}
}
@end