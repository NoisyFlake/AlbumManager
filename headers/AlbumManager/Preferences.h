#import <Preferences/Preferences.h>
#import <FrontBoardServices/FBSSystemService.h>
#import <SpringBoardServices/SBSRelaunchAction.h>

#import "AlbumManager.h"

@interface NSTask : NSObject
@property (copy) NSArray * arguments;
@property (retain) id standardOutput; 
- (void)setLaunchPath:(NSString *)path;
- (void)launch;
- (void)waitUntilExit;
@end

@interface AlbumManagerRootListController : PSListController
-(void)setupHeader;
-(void)setupFooterVersion;
-(void)resetSettings;
-(void)twitter;
-(void)paypal;
-(void)setTweakEnabled:(id)value specifier:(PSSpecifier *)specifier;
-(void)respring;
@end

@interface AlbumManagerButton : PSTableCell
@end

@interface PSSubtitleSwitchTableCell : PSSwitchTableCell
@end

@interface AlbumManagerSwitch : PSSubtitleSwitchTableCell
@end

@interface UINavigationItem (BetterAlarm)
@property (assign,nonatomic) UINavigationBar * navigationBar;
@end

#define kAlbumManagerColor [UIColor colorWithRed: 0.65 green: 0.89 blue: 0.63 alpha: 1.00]
