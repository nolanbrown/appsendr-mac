//
//  IPADropView.h
//
//  Created by Nolan Brown on 5/12/11.
//  Copyright 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import <Cocoa/Cocoa.h>

@protocol IPADropViewDelegate;

@interface IPADropView : NSView <NSMenuDelegate> {
	BOOL isDragged_;
    BOOL highlight_;
	NSImageView *imageView_;
    id <IPADropViewDelegate>__unsafe_unretained delegate_;
    BOOL success_;
    BOOL error_;

}
@property (nonatomic, unsafe_unretained) IBOutlet id <IPADropViewDelegate>delegate;
@property (weak) NSStatusItem *statusItem;
@property (assign) CGFloat progress;

- (CGPoint) pointForAttachedWindow;
- (void) updateViewForProgress: (CGFloat) progress;
- (void) flashViewForSuccess: (BOOL) success;
@end

@protocol IPADropViewDelegate <NSObject>
- (void) viewRecievedFileAtPath: (NSString *) path;

@end
