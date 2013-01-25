//
//  ASAppDelegate.h
//  AppSendr
//
//  Created by Nolan Brown on 4/10/12.
//  Copyright (c) 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import <Cocoa/Cocoa.h>
#import "IPADropView.h"
#import "MAAttachedWindow.h"
#import <Sparkle/Sparkle.h>

@interface ASAppDelegate : NSObject <NSApplicationDelegate, IPADropViewDelegate, NSMenuDelegate> {
    
    
    @private
    NSUserDefaults *defaults_;
	NSStatusItem *statusItem_;
    IPADropView *dropView_;
    MAAttachedWindow *urlCopiedWindow_;
    NSMutableArray *menuItems_;
    
    NSArray *orderedApps_;
    BOOL reloadOpenApps_;
    
}
@property(assign) BOOL checkForUpdates;

@property IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *statusItemMenu;
@property (weak) IBOutlet NSToolbar *toolbar;
@property (weak) IBOutlet NSView *generalSettingsView;
@property (weak) IBOutlet NSView *advancedSettingsView;

@property (weak) IBOutlet NSView *copiedURLView;
@property (weak) IBOutlet NSTextField *copiedURLTextField;

@property (weak) IBOutlet NSTextField *numDropsTextField;
@property (weak) IBOutlet NSSlider *numDropsSlider;

@property (weak) IBOutlet NSTextField *popupDurationTextField;
@property (weak) IBOutlet NSSlider *popupDurationSlider;



- (IBAction)orderFrontSettingsWindow:(id)sender;
- (IBAction)selectAppToUpload:(id)sender;

- (IBAction)numDropsSliderChanged:(id)sender;
- (IBAction)popupDurationSliderChanged:(id)sender;

@end
