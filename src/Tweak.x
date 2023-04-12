#import "Tweak.h"

AlbumManager *albumManager;

// Stock albums like Burst, Hidden, etc.
%hook PXNavigationListGadget 
-(id)_navigateTolistItem:(PXNavigationListAssetCollectionItem *)item animated:(BOOL)animated {
	PHAssetCollection *collection = (PHAssetCollection *)item.collection;
	NSLog(@"UUID: %@", collection.cloudGUID);
	return nil;
}
%end






// User albums
%hook PUHorizontalAlbumListGadget
-(void)_navigateToCollection:(PHAssetCollection *)collection animated:(BOOL)animated interactive:(BOOL)interactive completion:(id)completion {
	NSString *uuid = [albumManager uuidForCollection:collection];

	if ([albumManager objectForKey:uuid]) {
		LAContext *context = [[LAContext alloc] init];
		NSError *authError = nil;

		if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&authError]) {
			[context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"Unlock album" reply:^(BOOL success, NSError *error) {
				dispatch_async(dispatch_get_main_queue(), ^{
					if (success) {
						%orig;
					}
				});
			}];
		} else {
			NSLog(@"No auth method found");
			%orig;
		}

		return;
	}

	%orig;
}

-(id)targetPreviewViewForLocation:(CGPoint)location inCoordinateSpace:(id)space {
	PHAssetCollection *collection = (PHAssetCollection *)[self gadgetAtLocation:location inCoordinateSpace:space].collection;
	NSString *uuid = [albumManager uuidForCollection:collection];
	if ([albumManager objectForKey:uuid]) {

		return nil;
	}

	return %orig;
}

-(void)collectionView:(id)collectionView willDisplayCell:(PXGadgetUICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
	%orig;

	// Update the lockView whenever a cell is rendered
	PUAlbumGadget *gadget = [self _gadgetAtIndexPath:indexPath];
	PUStackView *stackView = gadget.albumListCellContentView.stackView;
	PHAssetCollection *collection = (PHAssetCollection *)gadget.collection;
	
	[albumManager updateLockViewInStackView:stackView forCollection:collection];
}

-(void)viewWillAppear:(BOOL)animated {
	%orig;
	
	// Update the gadgets whenever the view appears (e.g. after using the back button)
	UICollectionView *collectionView = self.view.subviews[0];
	[collectionView reloadData];
}
%end






// User albums ("See All")
%hook PUAlbumListViewController
-(void)navigateToCollection:(PHAssetCollection *)collection animated:(BOOL)animated completion:(id)completion {
	NSString *uuid = [albumManager uuidForCollection:collection];
	if ([albumManager objectForKey:uuid]) {


		// return;
	}

	%orig;
}

-(id)collectionView:(id)collectionView contextMenuConfigurationForItemAtIndexPath:(id)indexPath point:(CGPoint)point {
	PHAssetCollection *collection = [self collectionAtIndexPath:indexPath];
	NSString *uuid = [albumManager uuidForCollection:collection];
	if ([albumManager objectForKey:uuid]) {

		return nil;
	}

	return %orig;
}

-(PUAlbumListCell *)collectionView:(id)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	PUAlbumListCell *cell = %orig;

	// Update the lock view whenever a cell is rendered
	PUAlbumListCellContentView *contentView = cell.albumListCellContentView;
	PUStackView *stackView = contentView.stackView;
	PHAssetCollection *collection = [self collectionAtIndexPath:indexPath];

	[albumManager updateLockViewInStackView:stackView forCollection:collection];

	return cell;
}

-(void)viewWillAppear:(BOOL)animated {
	%orig;
	
	// Update the gadgets whenever the view appears (e.g. after using the back button)
	UICollectionView *collectionView = self.view.subviews[0];
	[collectionView reloadData];
}
%end


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
				[albumManager setObject:@"biometrics" forKey:uuid];
			}];
			[actions addObject:lockAction];
		}
	}

	return actions;
}
%end

%hook PUStackView
%property (nonatomic, retain) UIView *lockView;
%end

%ctor {
    albumManager = [NSClassFromString(@"AlbumManager") sharedInstance];

    %init;
}