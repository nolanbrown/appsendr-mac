//
//  IPADropView.m
//
//  Created by Nolan Brown on 5/12/11.
//  Copyright 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "IPADropView.h"
#import <QuartzCore/QuartzCore.h>


@implementation IPADropView
@synthesize delegate = delegate_;
@synthesize statusItem = statusItem_;
@synthesize progress = progress_;

- (id)initWithFrame:(NSRect)frame {
    if (! (self = [super initWithFrame:frame] ) ) {
        return self;
    }
	
    self.progress = 100;

	[self registerForDraggedTypes:@[@"com.apple.iTunes.ipa", 
								   NSFilenamesPboardType]];
    return self;
}

- (void) awakeFromNib {
	
    self.progress = 100;
	[self registerForDraggedTypes:@[@"com.apple.iTunes.ipa", 
								   NSFilenamesPboardType]];	
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{

	isDragged_ = YES;
	[self setNeedsDisplay:YES];
    if ((NSDragOperationCopy & [sender draggingSourceOperationMask]) 
		== NSDragOperationCopy) {
		
        return NSDragOperationCopy;
		
    } 	
    // not a drag we can use
	return NSDragOperationNone;	
	
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
} 




- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *zPasteboard = [sender draggingPasteboard];
	// define the images  types we accept
	// NSPasteboardTypeTIFF: (used to be NSTIFFPboardType).
	// NSFilenamesPboardType:An array of NSString filenames
    NSArray *zImageTypesAry = @[@"com.apple.iTunes.ipa", 
							   NSFilenamesPboardType];
	
    NSString *zDesiredType = [zPasteboard availableTypeFromArray:zImageTypesAry];
	if ([zDesiredType isEqualToString:@"com.apple.iTunes.ipa"]) { 
		NSData *zPasteboardData   = [zPasteboard dataForType:zDesiredType];
		if (zPasteboardData == nil) {
			ASLog(@"Error: MyNSView performDragOperation zPasteboardData == nil");
			return NO;
		}
		
		[self setNeedsDisplay:YES];
		return YES;
		
	}
	

	if ([zDesiredType isEqualToString:NSFilenamesPboardType]) {
		// the pasteboard contains a list of file names
		//Take the first one
		NSArray *zFileNamesAry = [zPasteboard propertyListForType:@"NSFilenamesPboardType"];
		NSString *zPath = zFileNamesAry[0];
        NSString *ext = [zPath pathExtension];
        ASLog(@"extentions: %@",ext);
        if([ext isEqualToString:@"ipa"] || [ext isEqualToString:@"app"] || [ext isEqualToString:@"apk"]) {
            [self.delegate viewRecievedFileAtPath:zPath];
        }
        else {
            [[NSAlert alertWithMessageText:@"AppSendr Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You must select a .ipa, .app or .apk."] runModal];
            

        }
		
		[self setNeedsDisplay:YES];
		return YES;
		
    }

	return NO;
	
} // end performDragOperation


- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	isDragged_ = NO;
    [self setNeedsDisplay:YES];

} // end concludeDragOperation


- (void)draggingExited:(id <NSDraggingInfo>)sender {
	isDragged_ = NO;
	[self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)dirtyRect {

    
    [self.statusItem drawStatusBarBackgroundInRect:[self bounds] withHighlight:highlight_];

    NSImage *anImage = nil;
    
    if(success_) {
        anImage = [NSImage imageNamed:@"bb_upload_sucess.png"];
    }
    else if(error_) {
        anImage = [NSImage imageNamed:@"bb_error.png"];
    }
    else {
        if(self.progress < 100) {
            anImage = [NSImage imageNamed:[NSString stringWithFormat:@"bb%d.png",(int)self.progress]];
            
        }
        else {
            anImage = [NSImage imageNamed:@"appsendr.png"];
        }    
    }
    
	

	// Find the point at which to draw it.
	NSPoint backgroundCenter;
	backgroundCenter.x = [self bounds].size.width / 2;
	backgroundCenter.y = [self bounds].size.height / 2;
	
	NSPoint drawPoint = backgroundCenter;
	drawPoint.x -= [anImage size].width / 2;
	drawPoint.y -= [anImage size].height / 2;
	
	// Draw it.
	[anImage drawAtPoint:drawPoint
				fromRect:NSZeroRect
			   operation:NSCompositeSourceOver
				fraction:1.0];
	
	//NSRect zOurBounds = [self bounds];
    [super drawRect:dirtyRect];

} // end drawRect


- (void)setMenu:(NSMenu *)menu {
    [menu setDelegate:self];
    [super setMenu:menu];
}

- (void)mouseDown:(NSEvent *)event {
    [self.statusItem popUpStatusItemMenu:[self menu]]; // or another method that returns a menu
}

- (void)menuWillOpen:(NSMenu *)menu {
    highlight_ = YES;
    [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    highlight_ = NO;
    [self setNeedsDisplay:YES];
}


- (CGPoint) pointForAttachedWindow {
    NSRect frame = [[self window] frame];
    NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
    return pt;
}

- (void) updateViewForProgress: (CGFloat) progress {
    self.progress = round(progress / 5)*5;
    [self setNeedsDisplay:YES];

}


- (void) flashViewForSuccess: (BOOL) success {
    
    CGFloat duration = [[NSUserDefaults standardUserDefaults] floatForKey:@"popupDuration"];

    if(success) {
        success_ = YES;
        error_= NO;
        [self setNeedsDisplay:YES];
        [self performSelector:@selector(hideSuccessView) withObject:nil afterDelay:duration];
    }
    else {
        success_ = NO;
        error_= YES;
        [self setNeedsDisplay:YES];
        [self performSelector:@selector(hideSuccessView) withObject:nil afterDelay:duration];
    }
    
}

- (void) hideSuccessView {
    success_ = NO;
    error_ = NO;
    [self setNeedsDisplay:YES];
}
@end
