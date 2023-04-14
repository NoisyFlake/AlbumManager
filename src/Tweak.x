#import "Tweak.h"

AlbumManager *albumManager;


/*****************************************************
**													**
**	Stock albums front page controller:				**
**	Handle taps										**
**													**
*****************************************************/


%hook PXNavigationListGadget 
-(id)_navigateTolistItem:(PXNavigationListAssetCollectionItem *)item animated:(BOOL)animated {
	PHAssetCollection *collection = (PHAssetCollection *)item.collection;
	NSString *uuid = [albumManager uuidForCollection:collection];

	id __block orig = nil;

	[albumManager tryAccessingAlbumWithUUID:uuid WithCompletion:^(BOOL success) {
		if (success) orig = %orig;
	}];
	
	return orig;
}
%end


/*****************************************************
**													**
**	User albums front page controller:				**
**	Handle taps and trigger the PUStackView update	**
**													**
*****************************************************/


%hook PUHorizontalAlbumListGadget
-(void)_navigateToCollection:(PHAssetCollection *)collection animated:(BOOL)animated interactive:(BOOL)interactive completion:(id)completion {
	NSString *uuid = [albumManager uuidForCollection:collection];

	[albumManager tryAccessingAlbumWithUUID:uuid WithCompletion:^(BOOL success) {
		if (success) %orig;
	}];
}

-(id)targetPreviewViewForLocation:(CGPoint)location inCoordinateSpace:(id)space {
	PHAssetCollection *collection = (PHAssetCollection *)[self gadgetAtLocation:location inCoordinateSpace:space].collection;
	NSString *uuid = [albumManager uuidForCollection:collection];

	// Block the long-press menu on protected albums
	return [albumManager objectForKey:uuid] ? nil : %orig;
}

-(void)collectionView:(id)collectionView willDisplayCell:(PXGadgetUICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
	%orig;

	// Update the lockView whenever a cell is rendered
	PUAlbumGadget *gadget = [self _gadgetAtIndexPath:indexPath];
	PUStackView *stackView = gadget.albumListCellContentView.stackView;
	PHAssetCollection *collection = (PHAssetCollection *)gadget.collection;
	
	[stackView updateLockViewForCollection:collection];
}

-(void)viewWillAppear:(BOOL)animated {
	%orig;
	
	// Update the gadgets whenever the view appears (e.g. after using the back button)
	UICollectionView *collectionView = self.view.subviews[0];
	[collectionView reloadData];

	// Make sure all albums are locked when the app enters the background
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAlbumLocks:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

%new
-(void)resetAlbumLocks:(NSNotification *)notification {
	[albumManager resetUnlocks];

	UICollectionView *collectionView = self.view.subviews[0];
	[collectionView reloadData];
}
%end


/*****************************************************
**													**
**	User albums "see all" list controller:			**
**	Handle taps and trigger the PUStackView update	**
**													**
*****************************************************/


%hook PUAlbumListViewController
-(void)navigateToCollection:(PHAssetCollection *)collection animated:(BOOL)animated completion:(id)completion {
	NSString *uuid = [albumManager uuidForCollection:collection];
	
	[albumManager tryAccessingAlbumWithUUID:uuid WithCompletion:^(BOOL success) {
		if (success) %orig;
	}];
}

-(id)collectionView:(id)collectionView contextMenuConfigurationForItemAtIndexPath:(id)indexPath point:(CGPoint)point {
	PHAssetCollection *collection = [self collectionAtIndexPath:indexPath];
	NSString *uuid = [albumManager uuidForCollection:collection];

	// Block the long-press menu on protected albums
	return [albumManager objectForKey:uuid] ? nil : %orig;
}

-(PUAlbumListCell *)collectionView:(id)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	PUAlbumListCell *cell = %orig;

	// Update the lock view whenever a cell is rendered
	PUAlbumListCellContentView *contentView = cell.albumListCellContentView;
	PUStackView *stackView = contentView.stackView;
	PHAssetCollection *collection = [self collectionAtIndexPath:indexPath];

	[stackView updateLockViewForCollection:collection];

	return cell;
}

-(void)viewWillAppear:(BOOL)animated {
	%orig;
	
	// Update the gadgets whenever the view appears (e.g. after using the back button)
	UICollectionView *collectionView = self.view.subviews[0];
	[collectionView reloadData];

	// Make sure all albums are locked when the app enters the background
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAlbumLocks:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

%new
-(void)resetAlbumLocks:(NSNotification *)notification {
	[albumManager resetUnlocks];

	UICollectionView *collectionView = self.view.subviews[0];
	[collectionView reloadData];
}
%end


/*****************************************************
**													**
**	Add actions for (un)locking to the album menu	**
**													**
*****************************************************/


%hook PXPhotosGridActionMenuController
-(NSArray *)actions {
	NSMutableArray *actions = [%orig mutableCopy];

	PHAssetCollection *collection = nil;

	for (id manager in self.actionManagers) {
		if ([manager isKindOfClass:NSClassFromString(@"PXPhotoKitAssetCollectionActionManager")]) {
			PXPhotoKitAssetCollectionActionManager *collectionManager = (PXPhotoKitAssetCollectionActionManager *)manager;
			collection = collectionManager.assetCollectionReference.assetCollection;
		}
	}

	NSString *uuid = [albumManager uuidForCollection:collection];

	if (uuid) {
		NSString *locked = [albumManager objectForKey:uuid];
		
		if (locked) {
			UIAction *unlockAction = [UIAction actionWithTitle:@"Unlock Album" image:[UIImage systemImageNamed:@"lock.open"] identifier:@"AlbumManagerUnlockAlbum" handler:^(__kindof UIAction* _Nonnull action) {
				[albumManager removeObjectForKey:uuid];
			}];
			[actions addObject:unlockAction];
		} else {
			UIAction *lockAction = [UIAction actionWithTitle:@"Lock Album" image:[UIImage systemImageNamed:@"lock"] identifier:@"AlbumManagerLockAlbum" handler:^(__kindof UIAction* _Nonnull action) {

				UIViewController *rootVC = [[[[UIApplication sharedApplication] windows] firstObject] rootViewController];

				LAContext *context = [[LAContext alloc] init];
				BOOL isBiometryAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
				NSString *biometryType = context.biometryType == LABiometryTypeFaceID ? @"Face ID" : @"Touch ID";

				UIAlertController *authTypeVC = [UIAlertController alertControllerWithTitle:@"Authentication Method" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

				UIAlertAction *biometrics = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"  Lock with %@", biometryType] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
					[albumManager setObject:@"biometrics" forKey:uuid];
				}];
				[biometrics setValue:[[UIImage systemImageNamed:context.biometryType == LABiometryTypeFaceID ? @"faceid" : @"touchid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
				[biometrics setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
				biometrics.enabled = isBiometryAvailable;

				UIAlertAction *password = [UIAlertAction actionWithTitle:@"Lock with Password" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
					UIAlertController *passwordVC = [UIAlertController alertControllerWithTitle:@"Set Password" message:nil preferredStyle:UIAlertControllerStyleAlert];
					[passwordVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
						textField.autocorrectionType = UITextAutocorrectionTypeNo;
						textField.spellCheckingType = UITextSpellCheckingTypeNo;
					}];

					UIAlertAction *acceptPassword = [UIAlertAction actionWithTitle:@"Lock Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
						NSString *passwordCleartext = [passwordVC.textFields[0] text];
						if (passwordCleartext.length <= 0) return;

						NSString *passwordHash = [albumManager sha256HashForText:passwordCleartext];
						[albumManager setObject:[NSString stringWithFormat:@"p%@", passwordHash] forKey:uuid];
					}];
					UIAlertAction *cancelPassword = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}];
					[passwordVC addAction:acceptPassword];
					[passwordVC addAction:cancelPassword];

					[rootVC presentViewController:passwordVC animated:YES completion:nil];

					
				}];
				[password setValue:[[UIImage systemImageNamed:@"textformat.abc"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
				[password setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];

				UIAlertAction *passcode = [UIAlertAction actionWithTitle:@"Lock with Passcode" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
					UIAlertController *passwordVC = [UIAlertController alertControllerWithTitle:@"Set Passcode" message:nil preferredStyle:UIAlertControllerStyleAlert];
					[passwordVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
						textField.autocorrectionType = UITextAutocorrectionTypeNo;
						textField.spellCheckingType = UITextSpellCheckingTypeNo;
						textField.keyboardType = UIKeyboardTypeNumberPad;
					}];

					UIAlertAction *acceptPassword = [UIAlertAction actionWithTitle:@"Lock Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
						NSString *passwordCleartext = [passwordVC.textFields[0] text];
						if (passwordCleartext.length <= 0) return;

						NSString *passwordHash = [albumManager sha256HashForText:passwordCleartext];
						[albumManager setObject:[NSString stringWithFormat:@"c%@", passwordHash] forKey:uuid];
					}];
					UIAlertAction *cancelPassword = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}];
					[passwordVC addAction:acceptPassword];
					[passwordVC addAction:cancelPassword];

					[rootVC presentViewController:passwordVC animated:YES completion:nil];

					
				}];
				[passcode setValue:[[UIImage systemImageNamed:@"textformat.123"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
				[passcode setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];

				UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}];
				
				[authTypeVC addAction:biometrics];
				[authTypeVC addAction:password];
				[authTypeVC addAction:passcode];
				[authTypeVC addAction:cancel];

				[rootVC presentViewController:authTypeVC animated:YES completion:nil];
			}];

			[actions addObject:lockAction];
		}
	}

	return actions;
}
%end


/*****************************************************
**													**
**	Add blur and lock icon to the album preview		**
**													**
*****************************************************/


%hook PUStackView
%property (nonatomic, retain) UIView *lockView;

%new
-(void)updateLockViewForCollection:(PHAssetCollection *)collection {
	NSString *uuid = [albumManager uuidForCollection:collection];
	NSString *protection = [albumManager objectForKey:uuid];

	if ([albumManager objectForKey:uuid] == nil ||
		([[albumManager objectForKey:@"rememberUnlock"] boolValue] && [albumManager.unlockedAlbums containsObject:uuid]) ||
        ([[albumManager objectForKey:@"unlockSameAuth"] boolValue] && [albumManager.unlockedProtections containsObject:protection])
	) {
        if (self.lockView) {
            [self.lockView removeFromSuperview];
            self.lockView = nil;
        }

        return;
    }

	if (!self.lockView) {
        UIView *lockView = [[UIView alloc] initWithFrame:self.bounds];
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

		[self addSubview:lockView];
        self.lockView = lockView;
	}
}
%end


/*****************************************************
**													**
**	Go to the root controller when leaving          **
**  the app and a locked album is open              **
**													**
*****************************************************/


%hook PXPhotosUIViewController
-(void)viewWillAppear:(BOOL)animated {
	%orig;

	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goToRootIfLocked:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

%new
-(void)goToRootIfLocked:(NSNotification *)notification {
	PHAssetCollection *collection = (PHAssetCollection *)self.assetReferenceForCurrentScrollPosition.assetCollection;
	NSString *uuid = [albumManager uuidForCollection:collection];
	NSString *protection = [albumManager objectForKey:uuid];

	if (protection != nil) {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}
%end


/*****************************************************
**													**
**	                Tweak Constructor      	        **
**													**
*****************************************************/


%ctor {
    albumManager = [NSClassFromString(@"AlbumManager") sharedInstance];

	if ([[albumManager objectForKey:@"enabled"] boolValue]) {
		%init;
	}
}