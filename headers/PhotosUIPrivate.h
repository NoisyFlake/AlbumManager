@interface PUStackView : UIView
@property (nonatomic, retain) UIView *lockView;
-(void)updateLockViewForCollection:(PHAssetCollection *)collection;
@end

@interface PUAlbumListCellContentView : UIView
@property (setter=_setStackView:,nonatomic,retain) PUStackView* stackView;
@end

@interface PUAlbumGadget : NSObject
@property(retain, nonatomic) PHCollection *collection;
@property(retain, nonatomic) PUAlbumListCellContentView *albumListCellContentView;
@end

@interface PXGadgetUIViewController : UICollectionViewController
@end

@interface PXHorizontalCollectionGadget : PXGadgetUIViewController
@end

@interface PUHorizontalAlbumListGadget : PXHorizontalCollectionGadget
-(PUAlbumGadget *)gadgetAtLocation:(CGPoint)location inCoordinateSpace:(id)space;
-(PUAlbumGadget *)_gadgetAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface PUAlbumListViewController : UIViewController
-(PHAssetCollection *)collectionAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface PUAlbumListCell : UICollectionViewCell
@property (nonatomic, strong, readwrite) PUAlbumListCellContentView *albumListCellContentView;
@end