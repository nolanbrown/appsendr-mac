//
//  Icon.m
//  AppSendr
//
//  Created by Nolan Brown on 1/31/12.
//  Copyright (c) 2012 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "Icon.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#import "NSFileManager+DirectoryLocations.h"
#import "iOSApp.h"
#import "AndroidApp.h"
#import <QuartzCore/QuartzCore.h>
#import "NSImage+AppSendr.h"
@interface Icon (Private)

- (NSString *) _findFile: (NSString *) file inPath: (NSString *) path;
- (NSImage *) _convertCrushedPNGToNormalPNGAtPath: (NSString *) path;
- (NSString *) _pathForPngcrush;

@end

@implementation Icon
@synthesize app = app_, processedIconPath = processedIconPath_, smallImage = smallImage_,largeImage = largeImage_;


- (id) initWithApp: (ASApp* ) app imageProcessingFinished:(void (^)(Icon *icon)) callback {
    self = [super init];
    if (self) {
        self.app = app;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if([app isKindOfClass:[iOSApp class]]) {
                self.path =  [self _pathForLargestIconIniOSApp:(iOSApp *)app];
                ASLog(@"self.path: %@",self.path);
                if(self.path)
                    self.image = [self _convertCrushedPNGToNormalPNGAtPath:self.path brute:NO];
                
                if(self.image) {
                    CGFloat multiplier = self.image.size.width / 57.0;
                    NSImage *rounded = [self roundImageCorners:self.image withRaidus:multiplier * 9];
                    self.largeImage = rounded;
                    self.smallImage = [NSImage scaleImage:rounded toSize:CGSizeMake(15, 15) proportionally:YES];
                    
                    NSData *data = [self dataFromImage:rounded];
                    NSString *iconPNGPath = [self.app.cachePath stringByAppendingPathComponent:@"icon.png"];
                    
                    if([data writeToFile:iconPNGPath atomically: NO]) {
                        self.processedIconPath = iconPNGPath;
                    }
                    
                }
            }
            else if([app isKindOfClass:[AndroidApp class]]) {
                NSString *appPath = self.app.cachePath;
                
                NSString *res = [appPath stringByAppendingPathComponent:@"res"];
                NSString *iconPath = nil;
                
                NSString *xhdpi = [self _findFile:@"ic_launcher.png" inPath:[res stringByAppendingPathComponent:@"drawable-xhdpi"]];
                iconPath = xhdpi ? xhdpi : nil;
                
                NSString *hdpi = [self _findFile:@"ic_launcher.png" inPath:[res stringByAppendingPathComponent:@"drawable-hdpi"]];
                iconPath = iconPath ? iconPath : hdpi;
                
                NSString *mdpi = [self _findFile:@"ic_launcher.png" inPath:[res stringByAppendingPathComponent:@"drawable-mdpi"]];
                iconPath = iconPath ? iconPath : mdpi;
                
                NSString *ldpi = [self _findFile:@"ic_launcher.png" inPath:[res stringByAppendingPathComponent:@"drawable-ldpi"]];
                iconPath = iconPath ? iconPath : ldpi;
                
                self.path = iconPath;
                
                if(self.path) {
                    self.largeImage = [[NSImage alloc] initWithContentsOfFile:self.path];
                    
                    self.smallImage = [NSImage scaleImage:self.largeImage toSize:CGSizeMake(15, 15) proportionally:YES];
                    
                    NSString *iconPNGPath = [self.app.cachePath stringByAppendingPathComponent:@"icon.png"];
                    NSData *data = [self dataFromImage:self.largeImage];

                    if([data writeToFile:iconPNGPath atomically: NO]) {
                        self.processedIconPath = iconPNGPath;
                    }   
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^() {
                callback(self);
            });
        });
        

        
    }
    return self;
}
- (NSData *) dataFromImage: (NSImage *) image  {
    ASLog(@"[image representations]  %@",[image representations] );
//    NSBitmapImageRep *imgRep = [[image representations] objectAtIndex: 0];
//    NSData *data = [imgRep representationUsingType: NSPNGFileType properties: nil];

    NSData *data = [NSBitmapImageRep representationOfImageRepsInArray:[image representations] usingType:NSPNGFileType properties:nil];

    return data;
}

- (NSData *) imageData {
    if(!self.image) {
        return nil;
    }
    
    return [self dataFromImage:self.image];
}

- (void)dealloc {

    processedIconPath_ = nil;
    smallImage_ = nil;
    largeImage_ = nil;

    app_ = nil;
}


//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.processedIconPath forKey:@"processedIconPath"];
    [encoder encodeObject:self.smallImage forKey:@"smallImage"];
    [encoder encodeObject:self.largeImage forKey:@"largeImage"];

}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if ((self = [super initWithCoder:decoder])) {
        self.processedIconPath = [decoder decodeObjectForKey:@"processedIconPath"];
        self.smallImage = [decoder decodeObjectForKey:@"smallImage"];
        self.largeImage = [decoder decodeObjectForKey:@"largeImage"];

    }
    return self;
}


- (NSImage *) roundImageCorners: (NSImage *) img withRaidus: (CGFloat) radius {
    
    NSImage* anImage = img; //[NSImage imageNamed:@"Lenna.tiff"]; //or some other source
    
    //create a bitmap at a specific size
    NSRect offscreenRect = NSMakeRect(0.0, 0.0, img.size.width, img.size.height);
    ASLog(@"offscreenRect %@",NSStringFromRect(offscreenRect));
    
    NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                                       pixelsWide:offscreenRect.size.width
                                                                       pixelsHigh:offscreenRect.size.height
                                                                    bitsPerSample:8
                                                                  samplesPerPixel:4
                                                                         hasAlpha:YES
                                                                         isPlanar:NO
                                                                   colorSpaceName:NSCalibratedRGBColorSpace
                                                                     bitmapFormat:0
                                                                      bytesPerRow:(4 * offscreenRect.size.width)
                                                                     bitsPerPixel:32];
    
    //save the current graphics context and lock focus on the bitmap
    NSGraphicsContext* originalContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext
                                          graphicsContextWithBitmapImageRep:bitmap]];
    [NSGraphicsContext saveGraphicsState];
    
    //clear the image rep. This is faster than filling with [NSColor clearColor].
    unsigned char *bitmapData = [bitmap bitmapData];
    if (bitmapData)
        bzero(bitmapData, [bitmap bytesPerRow] * [bitmap pixelsHigh]);
    
    //create the border path
    CGFloat borderWidth = 0.0;
    CGFloat cornerRadius = radius;
    NSRect borderRect = NSInsetRect(offscreenRect, borderWidth/2.0, borderWidth/2.0);
    NSBezierPath* border = [NSBezierPath bezierPathWithRoundedRect:borderRect xRadius:cornerRadius yRadius:cornerRadius];
    [border setLineWidth:borderWidth];
    
    //set the border as a clipping path
    [NSGraphicsContext saveGraphicsState];
    [border addClip];
    
    //scale and draw the image
    [anImage setSize:offscreenRect.size];
    [anImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    //set the border color
//    [[NSColor clearColor] set];
//    
//    //draw the border
//    [border stroke];
    
    //restore the original graphics context
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext setCurrentContext:originalContext];
    
    //get PNG data from the image rep
    NSData* pngData = [bitmap representationUsingType:NSPNGFileType properties:nil];

    return [[NSImage alloc] initWithData:pngData];
    return img;
}

#pragma mark -


- (NSString *) _findFile: (NSString *) file inPath: (NSString *) path
{
    if(!file) {
        return nil;
    }
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
    
    for (NSString *filename in fileEnumerator) {
        if([filename isEqualToString:file]) {
            return [path stringByAppendingPathComponent:filename]; 
        }
        
    }    
    return nil;
    
}

/* Not currently being used */
- (NSString *) _pathForPngcrush {
        
    BOOL xcodebuild_exists = [[NSFileManager defaultManager] isExecutableFileAtPath:@"/usr/bin/xcodebuild"];
    if(!xcodebuild_exists)
        return nil;
    
    BOOL xcrun_esists = [[NSFileManager defaultManager] isExecutableFileAtPath:@"/usr/bin/xcrun"];
    if(!xcrun_esists)
        return nil;
    
    // get ios sdk version
    NSTask *task = [[NSTask alloc] init];

    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardOutput:outputPipe];
    [task setLaunchPath: @"/usr/bin/xcodebuild"];
    [task setArguments: @[@"-showsdks"]];
    [task launch];
    [task waitUntilExit];
    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding]; // Autorelease optional, depending on usage.
    ASLog(@"XCODEBUILD Output: %@",outputString);
        
    NSError* error = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"iphoneos([2-9]+.*[0-9]*)" options:0 error:&error];
    
    NSArray* matches = [regex matchesInString:outputString options:0 range:NSMakeRange(0, [outputString length])];
    ASLog(@"SDK Matches: %@",matches);
    
    NSString *iosSDKVersion = nil;
    
    if([matches count] > 0) {
        NSTextCheckingResult *match = matches[0];
        iosSDKVersion = [outputString substringWithRange:[match range]];
    }
    
    if(!iosSDKVersion) {
        return nil;
    }

    
    task = [[NSTask alloc] init];
    
    outputPipe = [NSPipe pipe];
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardOutput:outputPipe];
    [task setLaunchPath: @"/usr/bin/xcrun"];
    [task setArguments: @[@"-sdk",iosSDKVersion, @"-find", @"pngcrush"]];
    [task launch];
    [task waitUntilExit];
    
    outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    ASLog(@"PNGCRUSH: %@",outputString);

    return outputString;
    
}


- (NSImage *) _convertCrushedPNGToNormalPNGAtPath: (NSString *) path brute:(BOOL)brute {
    ASLog(@"Converting image at path %@",path);
    if(!path)
    {
        return nil;
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
    if(image){
        return image;
    }
    
    return nil;
    
    
    NSString *outputPath = nil;
	
    ASLog(@"Writing image at path %@",outputPath);

    if([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:outputPath];
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];

        return image;
    }
    
	return nil;
}


- (NSString *) _pathForLargestIconIniOSApp: (iOSApp *) iOSApp {
    NSString *appPath = iOSApp.appPath;
    NSDictionary *bundleInfo = iOSApp.bundleInfo;
    
    ASLog(@"Bundle Info: %@",bundleInfo);
    NSString *path = nil;
    if(bundleInfo) {
        NSArray *icons = bundleInfo[@"CFBundleIconFiles"];
        if(!icons){
            NSDictionary *iconDictionary = bundleInfo[@"CFBundleIcons"];
            icons = iconDictionary[@"CFBundleIconFiles"];
            if(!icons){
                NSDictionary *primaryIconDictionary = iconDictionary[@"CFBundlePrimaryIcon"];
                icons = primaryIconDictionary[@"CFBundleIconFiles"];
            }
        }
        
        ASLog(@"Icons: %@",icons);
        if(icons != nil) {
            NSInteger iconWidth = 0;
            for(NSString *possibleIcon in icons) {
                ASLog(@"filePath %@", possibleIcon);

                NSString *filePath = [self _findFile:possibleIcon inPath:appPath];
                NSImage *image = [self _convertCrushedPNGToNormalPNGAtPath:filePath brute:NO];
                
                if(image) {
                    NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
                    
                    
                    if(iconWidth<[bitmap pixelsWide]) {
                        iconWidth=[bitmap pixelsWide];
                        ASLog(@"Icon Width: %ld",iconWidth);
                        path = filePath;
                        ASLog(@" *Icon path %@",path);

                    }
                }
            }
        }
        
        if(!path && bundleInfo[@"CFBundleIconFile"]){
            NSString *iconName = bundleInfo[@"CFBundleIconFile"];
            path = [self _findFile:iconName inPath:appPath];
            
        }        
    }
    
    if(!path) {
        NSString *filePath = [self _findFile:@"Icon@2x.png" inPath:appPath];   
        if(filePath) {
            path = filePath;
        }
        else {
            filePath = [self _findFile:@"Icon.png" inPath:appPath];   
            if(filePath) {
                path = filePath;
            }
            else {
                path = [[NSBundle mainBundle] pathForResource:@"app_default" ofType:@"png"]; 
                
            }
        }   
    }
    
    return path;
}

@end
