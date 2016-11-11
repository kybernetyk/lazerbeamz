//
//  SLColorArt.m
//  ColorArt
//
//  Created by Aaron Brethorst on 12/11/12.
//
// Copyright (C) 2012 Panic Inc. Code by Wade Cosgrove. All rights reserved.
//
// Redistribution and use, with or without modification, are permitted provided that the following conditions are met:
//
// - Redistributions must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//
// - Neither the name of Panic Inc nor the names of its contributors may be used to endorse or promote works derived from this software without specific prior written permission from Panic Inc.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL PANIC INC BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "SLColorArt.h"
#include <sqlite3.h>

#define kColorThresholdMinimumPercentage 0.01

@interface NSColor (SLDarkAddition)

- (BOOL)sl_isDarkColor;
- (BOOL)sl_isDistinct:(NSColor*)compareColor;
- (NSColor*)sl_colorWithMinimumSaturation:(CGFloat)saturation;
- (BOOL)sl_isBlackOrWhite;
- (BOOL)sl_isContrastingColor:(NSColor*)color;

@end


@interface SLCountedColor : NSObject

@property (assign) NSUInteger count;
@property (strong) NSColor *color;

- (id)initWithColor:(NSColor*)color count:(NSUInteger)count;

@end


@interface SLColorArt ()

@property(retain,readwrite) NSColor *backgroundColor;
@property(retain,readwrite) NSColor *primaryColor;
@property(retain,readwrite) NSColor *secondaryColor;
@property(retain,readwrite) NSColor *detailColor;
@end


@implementation SLColorArt

+ (SLColorArt*)colorArtWithImage:(NSImage*)image scaledSize:(NSSize)size {
    return [[SLColorArt alloc] initWithImage:image scaledSize:size];
}

+ (SLColorArt*) colorArtForImageAtPath: (NSString *) imagePath {
    NSImage *img = [[NSImage alloc] initWithContentsOfFile: imagePath];
    if (!img) {
        return nil;
    }
    
    NSSize sze = [NSScreen mainScreen].frame.size;
    sze.width = sze.width / 4;
    sze.height = sze.height / 4;
    //
    //    sze.width = 256;
    //    sze.height = 256;
    
    CGImageRef img2 = CGImageCreateCopyWithColorSpace([img CGImageForProposedRect: nil
                                                                          context: nil
                                                                            hints:nil],
                                                      CGColorSpaceCreateDeviceRGB());
    NSImage *resultingImage = [[NSImage alloc] initWithCGImage: img2 size: sze];
    
    CGImageRelease(img2);
    
    
    
    return [[SLColorArt alloc] initWithImage: resultingImage
                                  scaledSize: sze];
}

//This is needed when the user has random desktop wallpapers activated. In that case NSWorkspace will only return
//the base image folder and not the whole filename. So we will have to get the wallpaper filename ourselves.
+ (NSString *) currentDesktopWallpaperPath {
    NSMutableArray *sqliteData = [[NSMutableArray alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ([paths count] == 0) {
        NSLog(@"failed to retrieve paths...");
        return nil;
    }
    
    NSString *appSup = [paths firstObject];
    NSString *dbPath = [appSup stringByAppendingPathComponent:@"Dock/desktoppicture.db"];
    
    sqlite3 *database;
    if (sqlite3_open([dbPath UTF8String], &database) == SQLITE_OK) {
        const char *sql = "SELECT * FROM data";
        sqlite3_stmt *sel;
        if(sqlite3_prepare_v2(database, sql, -1, &sel, NULL) == SQLITE_OK) {
            while(sqlite3_step(sel) == SQLITE_ROW) {
                NSString *data = [NSString stringWithUTF8String:(char *)sqlite3_column_text(sel, 0)];
                [sqliteData addObject:data];
            }
            sqlite3_finalize(sel);
        } else {
            NSLog(@"prepare failed ... %s", sqlite3_errmsg(database));
            sqlite3_close(database);
            return nil;
        }
        sqlite3_close(database);
    } else {
        NSLog(@"opening db failed ... %s", sqlite3_errmsg(database));
        sqlite3_close(database);
        return nil;
    }
    if ([sqliteData count] == 0) {
        NSLog(@"sqliteData.count == 0");
        sqlite3_close(database);
        return nil;
    }

    NSInteger pic_idx = [sqliteData count] - 1;
    if (pic_idx < 0) {
        pic_idx = 0;
    }
    NSString *fn = sqliteData[pic_idx];
    if ([fn containsString: @"/"]) {
        return fn.stringByExpandingTildeInPath;
    }
    
    NSString *base = [[[NSWorkspace sharedWorkspace] desktopImageURLForScreen: [NSScreen mainScreen]] path];
    NSString *ext = [base pathExtension].lowercaseString;
    BOOL base_is_a_file = ([ext containsString: @"jpg"] || [ext containsString: @"png"] || [ext containsString: @"jpeg"]);
    if (base_is_a_file > 0) {
        return base;
    }
    
    return [base stringByAppendingPathComponent: fn].stringByExpandingTildeInPath;
}

+ (NSImage *)mainScreenShot {
    NSRect screenRect = [[NSScreen mainScreen] frame];
    CGImageRef cgImage = CGWindowListCreateImage(screenRect, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
    
    NSSize sze = NSMakeSize(screenRect.size.width/8, screenRect.size.height/8);
    
    //    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    //    CGImageRelease(cgImage);
    //    NSImage *image = [[NSImage alloc] init];
    //    [image addRepresentation:rep];
    NSImage *img = [[NSImage alloc] initWithCGImage: cgImage size: sze];
    CGImageRelease(cgImage);
    return img;
    //    return image;
}

+ (SLColorArt*) colorArtForMainScreen {
    NSImage *img = [SLColorArt mainScreenShot];
    if (!img) {
        return nil;
    }
    
    //    NSSize sze = [NSScreen mainScreen].frame.size;
    //    sze.width = sze.width / 4;
    //    sze.height = sze.height / 4;
    return [[SLColorArt alloc] initWithImageUnscale: img
                                         scaledSize: [img size]];
}

+ (NSImage *)imageWithRect:(NSRect)rect ofImage:(NSImage *)original;
{
    NSPoint zero = { 0.0, 0.0 };
    NSImage *result = [[NSImage alloc] initWithSize: rect.size];
    
    [result lockFocus];
    [original compositeToPoint:zero fromRect:rect
                     operation:NSCompositeCopy];
    [result unlockFocus];
    return result;
}

+ (NSArray<SLColorArt*>*) colorArtsForMainScreen {
    NSImage *img = [SLColorArt mainScreenShot];
    if (!img) {
        return nil;
    }
    
    NSSize sze = [img size];

    NSMutableArray *ma = @[].mutableCopy;

    {
        NSSize s = NSMakeSize(sze.width/3.0, sze.height);
        NSRect r = NSMakeRect(0, 0, s.width, s.height);
        
        NSImage *sub = [self imageWithRect: r ofImage: img];
        SLColorArt *coli = [[SLColorArt alloc] initWithImageUnscale: sub
                                                         scaledSize: [sub size]];
        [ma addObject: coli];
    }

    {
        NSSize s = NSMakeSize(sze.width/3.0, sze.height);
        NSRect r = NSMakeRect(s.width, 0, s.width, s.height);
        
        NSImage *sub = [self imageWithRect: r ofImage: img];
        SLColorArt *coli = [[SLColorArt alloc] initWithImageUnscale: sub
                                                         scaledSize: [sub size]];
        [ma addObject: coli];
    }

    {
        NSSize s = NSMakeSize(sze.width/3.0, sze.height);
        NSRect r = NSMakeRect(s.width*2, 0, s.width, s.height);
        
        NSImage *sub = [self imageWithRect: r ofImage: img];
        SLColorArt *coli = [[SLColorArt alloc] initWithImageUnscale: sub
                                                         scaledSize: [sub size]];
        [ma addObject: coli];
    }

    {
        NSSize s = NSMakeSize(sze.width, sze.height/3);
        NSRect r = NSMakeRect(0, 0, s.width, s.height);
        
        NSImage *sub = [self imageWithRect: r ofImage: img];
        SLColorArt *coli = [[SLColorArt alloc] initWithImageUnscale: sub
                                                         scaledSize: [sub size]];
        [ma addObject: coli];
    }

    
    return ma;
}


- (id)initWithImageUnscale:(NSImage*)image scaledSize:(NSSize)size {
    self = [super init];
    
    if (self)
    {
        //        NSImage *finalImage = [self scaleImage:image size:size];
        //        self.scaledImage = finalImage;
        self.scaledImage = image;
        
        [self analyzeImage:image];
    }
    
    return self;
}

- (id)initWithImage:(NSImage*)image scaledSize:(NSSize)size {
    self = [super init];
    
    if (self)
    {
        NSImage *finalImage = [self scaleImage:image size:size];
        self.scaledImage = finalImage;
        
        [self analyzeImage:image];
    }
    
    return self;
}


- (NSImage*)scaleImage:(NSImage*)image size:(NSSize)scaledSize
{
    NSSize imageSize = [image size];
    NSImage *squareImage = [[NSImage alloc] initWithSize:NSMakeSize(imageSize.width, imageSize.width)];
    NSImage *scaledImage = nil;
    NSRect drawRect;
    
    // make the image square
    if ( imageSize.height > imageSize.width )
    {
        drawRect = NSMakeRect(0, imageSize.height - imageSize.width, imageSize.width, imageSize.width);
    }
    else
    {
        drawRect = NSMakeRect(0, 0, imageSize.height, imageSize.height);
    }
    
    // use native square size if passed zero size
    if ( NSEqualSizes(scaledSize, NSZeroSize) )
    {
        scaledSize = drawRect.size;
    }
    
    scaledImage = [[NSImage alloc] initWithSize:scaledSize];
    
    [squareImage lockFocus];
    [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.width) fromRect:drawRect operation:NSCompositeSourceOver fraction:1.0];
    [squareImage unlockFocus];
    
    // scale the image to the desired size
    
    [scaledImage lockFocus];
    [squareImage drawInRect:NSMakeRect(0, 0, scaledSize.width, scaledSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [scaledImage unlockFocus];
    
    // convert back to readable bitmap data
    
    CGImageRef cgImage = [scaledImage CGImageForProposedRect:NULL context:nil hints:nil];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    NSImage *finalImage = [[NSImage alloc] initWithSize:scaledImage.size];
    [finalImage addRepresentation:bitmapRep];
//    CGImageRelease(cgImage);
    return finalImage;
}

- (void)analyzeImage:(NSImage*)anImage
{
    NSCountedSet *imageColors = nil;
    NSColor *backgroundColor = [self findEdgeColor:anImage imageColors:&imageColors];
    NSColor *primaryColor = nil;
    NSColor *secondaryColor = nil;
    NSColor *detailColor = nil;
    BOOL darkBackground = [backgroundColor sl_isDarkColor];
    
    [self findTextColors:imageColors primaryColor:&primaryColor secondaryColor:&secondaryColor detailColor:&detailColor backgroundColor:backgroundColor];
    
    if ( primaryColor == nil )
    {
#if DEBUG
        NSLog(@"SLColorArt::missed primary");
#endif
        if ( darkBackground )
            primaryColor = [[NSColor whiteColor] colorUsingColorSpace: [NSColorSpace deviceRGBColorSpace]];
        else
            primaryColor = [[NSColor blackColor] colorUsingColorSpace: [NSColorSpace deviceRGBColorSpace]];
    }
    
    if ( secondaryColor == nil )
    {
#if DEBUG
        NSLog(@"SLColorArt::missed secondary");
#endif
        if ( darkBackground )
            secondaryColor = [[NSColor whiteColor] colorUsingColorSpace: [NSColorSpace deviceRGBColorSpace]];
        else
            secondaryColor = [[NSColor blackColor] colorUsingColorSpace: [NSColorSpace deviceRGBColorSpace]];
    }
    
    if ( detailColor == nil )
    {
#if DEBUG
        NSLog(@"SLColorArt::missed detail");
#endif
        if ( darkBackground )
            detailColor = [[NSColor whiteColor] colorUsingColorSpace: [NSColorSpace deviceRGBColorSpace]];
        else
            detailColor = [[NSColor blackColor] colorUsingColorSpace: [NSColorSpace deviceRGBColorSpace]];
    }
    
    self.backgroundColor = backgroundColor;
    self.primaryColor = primaryColor;
    self.secondaryColor = secondaryColor;
    self.detailColor = detailColor;
    
    imageColors = nil;
}

#define fequalzero(a) (fabs(a) < FLT_EPSILON)

- (NSColor*)findEdgeColor:(NSImage*)image imageColors:(NSCountedSet**)colors
{
    NSImageRep *imageRep = [[image representations] lastObject];
    
    if ( ![imageRep isKindOfClass:[NSBitmapImageRep class]] )
    {
        [image lockFocus];
        imageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, image.size.width, image.size.height)];
        [image unlockFocus];
    }
    
    //colorAtX:y: and imageRep need to be in the same color space
    imageRep = [(NSBitmapImageRep*)imageRep bitmapImageRepByConvertingToColorSpace:[NSColorSpace genericRGBColorSpace] renderingIntent:NSColorRenderingIntentDefault];
    
    NSInteger pixelsWide = [imageRep pixelsWide];
    NSInteger pixelsHigh = [imageRep pixelsHigh];
    
    NSCountedSet *imageColors = [[NSCountedSet alloc] initWithCapacity:pixelsWide * pixelsHigh];
    NSCountedSet *leftEdgeColors = [[NSCountedSet alloc] initWithCapacity:pixelsHigh];
    NSUInteger	searchColumnX = 0;
    
    for ( NSUInteger x = 0; x < pixelsWide; x++ )
    {
        for ( NSUInteger y = 0; y < pixelsHigh; y++ )
        {
            NSColor *color = [(NSBitmapImageRep*)imageRep colorAtX:x y:y];
            
            if ( x == searchColumnX )
            {
                //make sure it's a meaningful color
                if ( color.alphaComponent > .5 )
                    [leftEdgeColors addObject:color];
            }
            
            if ( !fequalzero(color.alphaComponent) )
                [imageColors addObject:color];
        }
        
        // background is clear, keep looking in next column for background color
        if ( leftEdgeColors.count == 0 )
            searchColumnX += 1;
    }
    
    *colors = imageColors;
    
    
    NSEnumerator *enumerator = [leftEdgeColors objectEnumerator];
    NSColor *curColor = nil;
    NSMutableArray *sortedColors = [NSMutableArray arrayWithCapacity:[leftEdgeColors count]];
    
    while ( (curColor = [enumerator nextObject]) != nil )
    {
        NSUInteger colorCount = [leftEdgeColors countForObject:curColor];
        
        NSInteger randomColorsThreshold = (NSInteger)(pixelsHigh * kColorThresholdMinimumPercentage);
        
        if ( colorCount <= randomColorsThreshold ) // prevent using random colors, threshold based on input image height
            continue;
        
        SLCountedColor *container = [[SLCountedColor alloc] initWithColor:curColor count:colorCount];
        
        [sortedColors addObject:container];
    }
    
    [sortedColors sortUsingSelector:@selector(compare:)];
    
    SLCountedColor *proposedEdgeColor = nil;
    
    if ( [sortedColors count] > 0 )
    {
        proposedEdgeColor = [sortedColors objectAtIndex:0];
        
        if ( [proposedEdgeColor.color sl_isBlackOrWhite] ) // want to choose color over black/white so we keep looking
        {
            for ( NSInteger i = 1; i < [sortedColors count]; i++ )
            {
                SLCountedColor *nextProposedColor = [sortedColors objectAtIndex:i];
                
                if (((double)nextProposedColor.count / (double)proposedEdgeColor.count) > .3 ) // make sure the second choice color is 30% as common as the first choice
                {
                    if ( ![nextProposedColor.color sl_isBlackOrWhite] )
                    {
                        proposedEdgeColor = nextProposedColor;
                        break;
                    }
                }
                else
                {
                    // reached color threshold less than 40% of the original proposed edge color so bail
                    break;
                }
            }
        }
    }
    
    return proposedEdgeColor.color;
}


- (void)findTextColors:(NSCountedSet*)colors primaryColor:(NSColor**)primaryColor secondaryColor:(NSColor**)secondaryColor detailColor:(NSColor**)detailColor backgroundColor:(NSColor*)backgroundColor
{
    NSEnumerator *enumerator = [colors objectEnumerator];
    NSColor *curColor = nil;
    NSMutableArray *sortedColors = [NSMutableArray arrayWithCapacity:[colors count]];
    BOOL findDarkTextColor = ![backgroundColor sl_isDarkColor];
    
    while ( (curColor = [enumerator nextObject]) != nil )
    {
        curColor = [curColor sl_colorWithMinimumSaturation:.15];
        
        if ( [curColor sl_isDarkColor] == findDarkTextColor )
        {
            NSUInteger colorCount = [colors countForObject:curColor];
            
            //if ( colorCount <= 2 ) // prevent using random colors, threshold should be based on input image size
            //	continue;
            
            SLCountedColor *container = [[SLCountedColor alloc] initWithColor:curColor count:colorCount];
            
            [sortedColors addObject:container];
        }
    }
    
    [sortedColors sortUsingSelector:@selector(compare:)];
    
    for ( SLCountedColor *curContainer in sortedColors )
    {
        curColor = curContainer.color;
        
        if ( *primaryColor == nil )
        {
            if ( [curColor sl_isContrastingColor:backgroundColor] )
                *primaryColor = curColor;
        }
        else if ( *secondaryColor == nil )
        {
            if ( ![*primaryColor sl_isDistinct:curColor] || ![curColor sl_isContrastingColor:backgroundColor] )
                continue;
            
            *secondaryColor = curColor;
        }
        else if ( *detailColor == nil )
        {
            if ( ![*secondaryColor sl_isDistinct:curColor] || ![*primaryColor sl_isDistinct:curColor] || ![curColor sl_isContrastingColor:backgroundColor] )
                continue;
            
            *detailColor = curColor;
            break;
        }
    }
}

@end


@implementation NSColor (SLDarkAddition)

- (BOOL)sl_isDarkColor
{
    NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat r, g, b, a;
    
    [convertedColor getRed:&r green:&g blue:&b alpha:&a];
    
    CGFloat lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    
    if ( lum < .5 )
    {
        return YES;
    }
    
    return NO;
}


- (BOOL)sl_isDistinct:(NSColor*)compareColor
{
    NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor *convertedCompareColor = [compareColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat r, g, b, a;
    CGFloat r1, g1, b1, a1;
    
    [convertedColor getRed:&r green:&g blue:&b alpha:&a];
    [convertedCompareColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    
    CGFloat threshold = .25; //.15
    
    if ( fabs(r - r1) > threshold ||
        fabs(g - g1) > threshold ||
        fabs(b - b1) > threshold ||
        fabs(a - a1) > threshold )
    {
        // check for grays, prevent multiple gray colors
        
        if ( fabs(r - g) < .03 && fabs(r - b) < .03 )
        {
            if ( fabs(r1 - g1) < .03 && fabs(r1 - b1) < .03 )
                return NO;
        }
        
        return YES;
    }
    
    return NO;
}


- (NSColor*)sl_colorWithMinimumSaturation:(CGFloat)minSaturation
{
    NSColor *tempColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    if ( tempColor != nil )
    {
        CGFloat hue = 0.0;
        CGFloat saturation = 0.0;
        CGFloat brightness = 0.0;
        CGFloat alpha = 0.0;
        
        [tempColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
        
        if ( saturation < minSaturation )
        {
            return [NSColor colorWithCalibratedHue:hue saturation:minSaturation brightness:brightness alpha:alpha];
        }
    }
    
    return self;
}


- (BOOL)sl_isBlackOrWhite
{
    NSColor *tempColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    if ( tempColor != nil )
    {
        CGFloat r, g, b, a;
        
        [tempColor getRed:&r green:&g blue:&b alpha:&a];
        
        if ( r > .91 && g > .91 && b > .91 )
            return YES; // white
        
        if ( r < .09 && g < .09 && b < .09 )
            return YES; // black
    }
    
    return NO;
}


- (BOOL)sl_isContrastingColor:(NSColor*)color
{
    NSColor *backgroundColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor *foregroundColor = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    if ( backgroundColor != nil && foregroundColor != nil )
    {
        CGFloat br, bg, bb, ba;
        CGFloat fr, fg, fb, fa;
        
        [backgroundColor getRed:&br green:&bg blue:&bb alpha:&ba];
        [foregroundColor getRed:&fr green:&fg blue:&fb alpha:&fa];
        
        CGFloat bLum = 0.2126 * br + 0.7152 * bg + 0.0722 * bb;
        CGFloat fLum = 0.2126 * fr + 0.7152 * fg + 0.0722 * fb;
        
        CGFloat contrast = 0.;
        
        if ( bLum > fLum )
            contrast = (bLum + 0.05) / (fLum + 0.05);
        else
            contrast = (fLum + 0.05) / (bLum + 0.05);
        
        //return contrast > 3.0; //3-4.5 W3C recommends 3:1 ratio, but that filters too many colors
        return contrast > 1.6;
    }
    
    return YES;
}


@end


@implementation SLCountedColor

- (id)initWithColor:(NSColor*)color count:(NSUInteger)count
{
    self = [super init];
    
    if ( self )
    {
        self.color = color;
        self.count = count;
    }
    
    return self;
}

- (NSComparisonResult)compare:(SLCountedColor*)object
{
    if ( [object isKindOfClass:[SLCountedColor class]] )
    {
        if ( self.count < object.count )
        {
            return NSOrderedDescending;
        }
        else if ( self.count == object.count )
        {
            return NSOrderedSame;
        }
    }
    
    return NSOrderedAscending;
}


@end
