//
//  ASAppDelegate.m
//  AppSendr
//
//  Created by Nolan Brown on 4/10/12.
//  Copyright (c) 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "ASAppDelegate.h"
#import "ASApp.h"
#import "ASAPIClient.h"
#import "NSFileManager+DirectoryLocations.h"
#import "NSImage+AppSendr.h"
#import "NSWindow+DPAdditions.h"

NSString *ASToolbarGeneralSettingsItemIdentifier = @"ASToolbarGeneralSettingsItem";
NSString *ASToolbarAdvancedSettingsItemIdentifier = @"ASToolbarAdvancedSettingsItem";

typedef enum StatusItemState {
    StatusItemOK = 1,
    StatusItemDisabled = 2,
    StatusItemUploading = 3
} ASStatusItemState;


@implementation ASAppDelegate

@synthesize window = _window;

@synthesize statusItemMenu = statusItemMenu_;
@synthesize toolbar = toolbar_;
@synthesize generalSettingsView = generalSettingsView_;
@synthesize advancedSettingsView = advancedSettingsView_;
@synthesize copiedURLView = copiedURLView_;
@synthesize copiedURLTextField = copiedURLTextField_;

@synthesize numDropsTextField = numDropsTextField_;
@synthesize numDropsSlider = numDropsSlider_;
@synthesize popupDurationTextField = popupDurationTextField_;
@synthesize popupDurationSlider = popupDurationSlider_;

@synthesize openAtLogin = openAtLogin_, showInDock, showInMenuBar, enablePngcrush;

- (void)dealloc
{
    menuItems_ = nil;

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"numDrops"]) {
        [[NSUserDefaults standardUserDefaults] setInteger:7 forKey:@"numDrops"];
    }
    
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"popupDuration"]) {
        [[NSUserDefaults standardUserDefaults] setInteger:3 forKey:@"popupDuration"];
    }
    
    defaults_ = [NSUserDefaults standardUserDefaults];
    menuItems_ = [[NSMutableArray alloc] init];
    
    if(![defaults_ objectForKey:@"openAtLoginIsSet"]) {
        self.openAtLogin = YES;
    }
    
    // Insert code here to initialize your application
    [self _setStatusItemState:StatusItemOK];
    NSArray *apps = [self _recentlyOpenedApps];
    for(ASApp *app in apps) {
        [self _addAppToStatusMenu:app];
    }
    
}



- (IBAction)numDropsSliderChanged:(id)sender {
    NSInteger numDrops = [[NSUserDefaults standardUserDefaults] integerForKey:@"numDrops"];
    NSSlider *slider = (NSSlider *) sender;
    NSInteger value = slider.integerValue;
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:@"numDrops"];

    if(numDrops < value) { // added 1 more drop
        [self _resetMenuItems];
    }
    else if(numDrops > value) {
        [self _resetMenuItems];

    }
    
    
    NSString *str = [NSString stringWithFormat:@"%ld", value];
    self.numDropsTextField.stringValue = str;
    

}

- (IBAction)popupDurationSliderChanged:(id)sender {
    NSSlider *slider = (NSSlider *) sender;
    NSInteger value = slider.integerValue;
    
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:@"popupDuration"];
    
    NSString *str = [NSString stringWithFormat:@"%ld secs", value];
    self.popupDurationTextField.stringValue = str;
}


- (IBAction)displayViewForGeneralSettings:(id)sender {
	if (self.generalSettingsView && [self.window contentView] != self.generalSettingsView)
		[self.window setContentView:self.generalSettingsView display:YES animate:YES];
}


- (IBAction)displayViewForAdvancedSettings:(id)sender {
	if (self.advancedSettingsView && [self.window contentView] != self.advancedSettingsView)
		[self.window setContentView:self.advancedSettingsView display:YES animate:YES];
}


- (IBAction)orderFrontSettingsWindow:(id)sender {
	if (![NSApp isActive])
		[NSApp activateIgnoringOtherApps:YES];
	[self.window makeKeyAndOrderFront:sender];
    
    
    
    NSInteger numDrops = [[NSUserDefaults standardUserDefaults] integerForKey:@"numDrops"];
    [self.numDropsSlider setFloatValue: numDrops];
    self.numDropsTextField.stringValue = [NSString stringWithFormat:@"%ld", numDrops];
    
    
    NSInteger popupDuration = [[NSUserDefaults standardUserDefaults] integerForKey:@"popupDuration"];
    [self.popupDurationSlider setFloatValue: popupDuration];
    self.popupDurationTextField.stringValue = [NSString stringWithFormat:@"%ld secs", popupDuration];
    
}

- (IBAction)selectAppToUpload:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setTitle:@"Choose an .app, .ipa, or .apk"];
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
    [panel setAllowedFileTypes:@[@"ipa",@"app",@"apk"]];
    
    NSString *startDir = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPathSelected"];
    if(startDir == nil)
        startDir = NSHomeDirectory();
    
    [panel setDirectoryURL:[NSURL URLWithString:startDir]];
    
    // This method displays the panel and returns immediately.
    // The completion handler is called when the user selects an
    // item or cancels the panel.
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL*  theDoc = [panel URLs][0];
            if([theDoc isFileURL]) {
                NSString *path = [theDoc path];
                [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"lastPathSelected"];
                [self processFileAtPath:path];
            }
        }
        
        // Balance the earlier retain call.
    }];
}

#pragma mark - Drop View Delegate

- (void) viewRecievedFileAtPath: (NSString *) path {
    [self processFileAtPath:path];
}



- (void) processFileAtPath: (NSString *) path {
    [ASApp appWithSourcePath:path proccessingFinished:^(ASApp *app, BOOL success) {
        [self _uploadApp:app];

    }];
}


- (void) _uploadApp: (ASApp *) app {
    [[ASAPIClient sharedClient] uploadApp:app 
                     withProgressCallback:^(CGFloat progress) {
                         if((progress * 100) < 80)
                             [dropView_ updateViewForProgress:(progress * 100)];
                     }
                                 finished:^(BOOL successful, id response) {
                                     if(successful) {
                                         NSDictionary *jsonResponse = (NSDictionary *) response;
                                         if(!jsonResponse[@"error"]) {
                                             
                                             NSString *otaURLStr = jsonResponse[@"url"];
                                             NSString *otaId = jsonResponse[@"id"];
                                             NSString *deleteToken = jsonResponse[@"token"];

                                             app.otaURL = [NSURL URLWithString:otaURLStr];
                                             app.otaId = otaId;
                                             app.deleteToken = deleteToken;
                                             ASLog(@"app.otaURL %@",app.otaURL);
                                             app.addedAt = [NSDate date];
                                             [app copyURLToClipboard];
                                             [self _showCopiedURL:otaURLStr];
                                         }
                                         
                                         [dropView_ flashViewForSuccess:YES];
                                         [dropView_ updateViewForProgress:100];
                                         
                                         [self _addAppToStatusMenu:app];
                                         
                                         [app save];
                                         
                                         reloadOpenApps_ = YES;
                                         [self _recentlyOpenedApps];
                                     }   
                                     else {
                                         [app destroy];
                                         [dropView_ flashViewForSuccess:NO];
                                         [dropView_ updateViewForProgress:100];
                                     }
                                 }];
}

- (void) _addAppToStatusMenu: (ASApp *) app {
    NSString *name = [NSString stringWithFormat:@"%@ (%@)",app.name,app.version];
    
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""]; //@selector(openInBrowser:)
    
    [item setRepresentedObject:app.guid];
    
    if(app.icon.smallImage) {
        [item setImage:app.icon.smallImage];

    }
    else if(app.icon.image) {
        NSImage *image = [NSImage scaleImage:app.icon.image toSize:CGSizeMake(20, 20) proportionally:YES];
        [item setImage:image];
    }
    NSMenu *submenu = [[NSMenu alloc] initWithTitle:name];

    [submenu addItemWithTitle:[NSString stringWithFormat:@"Dropped on %@",[app formattedAddedAt]] action:nil keyEquivalent:@""];
    
    
    if(app.otaURL) {
        [submenu addItemWithTitle:@"Copy link to Clipboard" action:@selector(copyLinkToClipboard:) keyEquivalent:@""];        
    }
    [submenu addItemWithTitle:@"View in Browser" action:@selector(openInBrowser:) keyEquivalent:@""];
    [submenu addItemWithTitle:@"Open in Finder" action:@selector(openInFinder:) keyEquivalent:@""];        

    [submenu addItemWithTitle:@"Delete" action:@selector(deleteFromCache:) keyEquivalent:@""];        

    [menuItems_ insertObject:item atIndex:0];
    
    [self.statusItemMenu insertItem:item atIndex:3];
    [self.statusItemMenu setSubmenu:submenu forItem:item];
    
}

- (void) openInBrowser: (id) sender {
    
    NSMenuItem *item = (NSMenuItem *) sender;
    NSMenuItem *parent = [item parentItem];
    NSString *guid = (NSString *)[parent representedObject];
    ASApp *app = [ASApp appWithGUID:guid];
    if(app) {
        if(app.otaURL) {
            [[NSWorkspace sharedWorkspace] openURL:app.otaURL];
        }
    }

}
- (void) copyLinkToClipboard: (id) sender {
    NSMenuItem *item = (NSMenuItem *) sender;
    NSMenuItem *parent = [item parentItem];
    NSString *guid = (NSString *)[parent representedObject];
    ASApp *app = [ASApp appWithGUID:guid];
    if(app) {
        [app copyURLToClipboard];
        [self _showCopiedURL:[app.otaURL absoluteString]];

    }
}

- (void) openInFinder: (id) sender {
    NSMenuItem *item = (NSMenuItem *) sender;
    NSMenuItem *parent = [item parentItem];
    NSString *guid = (NSString *)[parent representedObject];
    ASApp *app = [ASApp appWithGUID:guid];
    if(app) {
        [[NSWorkspace sharedWorkspace] openFile:app.cachePath];
    }
    
}

- (void) deleteFromCache: (id) sender {
    NSMenuItem *item = (NSMenuItem *) sender;
    NSMenuItem *parent = [item parentItem];
    NSString *guid = (NSString *)[parent representedObject];
    ASApp *app = [ASApp appWithGUID:guid];
    
    [[ASAPIClient sharedClient] destroyApp:app finished:^(BOOL successful) {
        ASLog(@"Deleted: %d",successful);
    }];

    [app destroy];
    
    [self.statusItemMenu removeItem:parent];
    
    [menuItems_ removeObject:item];
    
    reloadOpenApps_ = YES;
    [self _recentlyOpenedApps];
}


#pragma mark -
#pragma mark NSToolbar delegate methods


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)_toolbar {
	return @[ASToolbarGeneralSettingsItemIdentifier,
            ASToolbarAdvancedSettingsItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            NSToolbarSpaceItemIdentifier,
            NSToolbarSeparatorItemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)_toolbar {
	return @[ASToolbarGeneralSettingsItemIdentifier,
            ASToolbarAdvancedSettingsItemIdentifier];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)_toolbar {
	return [self toolbarDefaultItemIdentifiers:_toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)_toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = nil;
	if (itemIdentifier == ASToolbarGeneralSettingsItemIdentifier) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setImage:[NSImage imageNamed:@"NSPreferencesGeneral"]];
		[item setLabel:@"General"];
		[item setToolTip:@"General settings"];
		[item setTarget:self];
		[item setAction:@selector(displayViewForGeneralSettings:)];
        if(!_toolbar.selectedItemIdentifier) {
            _toolbar.selectedItemIdentifier = ASToolbarGeneralSettingsItemIdentifier;
        }
	}
	else if (itemIdentifier == ASToolbarAdvancedSettingsItemIdentifier) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[item setImage:[NSImage imageNamed:@"NSAdvanced"]];
		[item setLabel:@"Advanced"];
		[item setToolTip:@"You probably don't need to change these things in here"];
		[item setTarget:self];
		[item setAction:@selector(displayViewForAdvancedSettings:)];
	}
    
	return item;
}

#pragma mark - Private Methods

- (void) _setStatusItemState: (ASStatusItemState) state {
    
	if (!statusItem_) {
        
        statusItem_ = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        [statusItem_ setHighlightMode:YES];
        [statusItem_ setEnabled:YES];
        [statusItem_ setMenu:self.statusItemMenu];
        
        if(!dropView_) {
            dropView_ = [[IPADropView alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
            [dropView_ setMenu:self.statusItemMenu];
            [dropView_ setStatusItem:statusItem_];
            dropView_.delegate = self;
        }
        [statusItem_ setView:dropView_];
	}    
    
    switch (state) {
        case StatusItemOK:
            break;
            
        default:
            break;
    }
}

- (void) _showCopiedURL: (NSString *) url {
    
    [self _closeCopiedURLPopup];
    
    CGPoint p = CGPointMake([dropView_ pointForAttachedWindow].x - 32, [dropView_ pointForAttachedWindow].y);
    // Attach/detach window.
    urlCopiedWindow_ = [[MAAttachedWindow alloc] initWithView:self.copiedURLView 
                                            attachedToPoint:p 
                                                   inWindow:nil 
                                                     onSide:MAPositionBottom 
                                                 atDistance:5.0];
    //[self.copiedURLTextField setTextColor:[urlCopiedWindow_ borderColor]];
    [self.copiedURLTextField setStringValue:[NSString stringWithFormat:@"%@ copied!",url]];
    [urlCopiedWindow_ makeKeyAndOrderFront:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:nil];
    
    CGFloat duration = [[NSUserDefaults standardUserDefaults] floatForKey:@"popupDuration"];

    [self performSelector:@selector(_closeCopiedURLPopup) withObject:nil afterDelay:duration];
}

- (void) _closeCopiedURLPopup {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSWindowDidResignKeyNotification 
                                                  object:nil];
    
    if(urlCopiedWindow_) {
        [urlCopiedWindow_ orderOut:self];
        urlCopiedWindow_ = nil;
    }
}
- (void) windowDidResignKey: (NSNotification *) note {
    [self _closeCopiedURLPopup];
}

- (void) _removeLastMenuItem {
    
    [self.statusItemMenu removeItem:[menuItems_ lastObject]];
    [menuItems_ removeLastObject];
}

- (void) _addNextMenuItem {
    NSInteger size = [menuItems_ count];
    if(size < [orderedApps_ count]) {
        ASApp *app = orderedApps_[size+1];
        [self _addAppToStatusMenu:app];
    }
}


- (void) _resetMenuItems {    
    for(NSMenuItem *item in menuItems_) {
        if([self.statusItemMenu indexOfItem:item] >= 0)
        [self.statusItemMenu removeItem:item];
    }
    
    [menuItems_ removeAllObjects];
    
    NSArray *apps = [self _recentlyOpenedApps];
    for(ASApp *app in apps) {
        [self _addAppToStatusMenu:app];
    }
}

- (NSArray *) _recentlyOpenedApps {
    if(orderedApps_ && !reloadOpenApps_) {
        NSInteger numDrops = [[NSUserDefaults standardUserDefaults] integerForKey:@"numDrops"];
        if([orderedApps_ count] > numDrops+1) {
            NSInteger len = [orderedApps_ count];
            return [orderedApps_ objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(len-numDrops, numDrops)]];
        }
        return orderedApps_;
    }
    
    NSMutableArray *apps = [NSMutableArray array];
    
    NSString *caches = [[NSFileManager defaultManager] cachesDirectory];
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:caches];
    
    for (NSString *filename in fileEnumerator) {
        NSString *dir = [caches stringByAppendingPathComponent:filename];
        BOOL isDir = NO;
        if([[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir]) {
            if(isDir) {
                NSString *appFile = [dir stringByAppendingPathComponent:kASFileName];
                ASApp *app = [ASApp loadFromDisk:appFile];
                if(app) {
                    [apps addObject:app];
                }
            }
        }
    }    
    
    NSArray *sortedApps;
    sortedApps = [apps sortedArrayUsingComparator:^(id a, id b) {
        NSDate *first = [(ASApp*)a addedAt];
        NSDate *second = [(ASApp*)b addedAt];
                
        return [first compare:second];
    }];
    if(orderedApps_) {
        orderedApps_ = nil;
    }
    reloadOpenApps_ = NO;
    orderedApps_ = sortedApps ;
    
    
    return [self _recentlyOpenedApps];
}

@end
