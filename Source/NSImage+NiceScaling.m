/* =============================================================================
    PROJECT:    Filie
    FILE:       NSImage+NiceScaling.h
    
    COPYRIGHT:  (c) 2003 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL, Modified BSD
    
    REVISIONS:
        2003-12-19  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "NSImage+NiceScaling.h"


@implementation NSImage (NiceScaling)

-(NSImage*) scaledImageToFitSize: (NSSize)fitIn
{
	return [self scaledImageToFitSize: fitIn withInterpolation: NSImageInterpolationHigh];
}


-(NSImage*) scaledImageToFitSize: (NSSize)fitIn withInterpolation: (NSImageInterpolation)inter
{
	return [self scaledImageToFitSize: fitIn withInterpolation: inter andBox: NO];
}

-(NSImage*) scaledImageToFitSize: (NSSize)fitIn withInterpolation: (NSImageInterpolation)inter andBox: (BOOL)doBox
{
	NSSize		size = [self scaledSizeToFitSize: fitIn];
	NSImage*	img = [[NSImage alloc] initWithSize: fitIn];
	NSRect		srcBox = { { 0, 0 }, { 0, 0 } },
				dstBox = { { 0, 0 }, { 0, 0 } };
	
	dstBox.size = size;
	srcBox.size = [self size];
	dstBox.origin.x += (fitIn.width -size.width) /2;
	dstBox.origin.y += (fitIn.height -size.height) /2;
	
	NS_DURING
		[img lockFocus];
			if( doBox )
			{
				[[NSColor whiteColor] set];
				[NSBezierPath fillRect: dstBox];
				[[NSColor blackColor] set];
			}
			[[NSGraphicsContext currentContext] setImageInterpolation: inter];
			[self drawInRect: dstBox fromRect: srcBox operation:NSCompositeSourceOver fraction:1.0];
			if( doBox )
				[NSBezierPath strokeRect: dstBox];
		[img unlockFocus];
		
		NS_VALUERETURN( img, NSImage* );
	NS_HANDLER
		NSLog(@"Couldn't scale image %@",localException);
	NS_ENDHANDLER
	
	return nil;
}


-(NSImage*) scaledImageToCoverSize: (NSSize)fitIn
{
	return [self scaledImageToCoverSize: fitIn withInterpolation: NSImageInterpolationHigh];
}


-(NSImage*) scaledImageToCoverSize: (NSSize)fitIn withInterpolation: (NSImageInterpolation)inter
{
	return [self scaledImageToCoverSize: fitIn withInterpolation: inter andBox: NO];
}

-(NSImage*) scaledImageToCoverSize: (NSSize)fitIn withInterpolation: (NSImageInterpolation)inter andBox: (BOOL)doBox
{
	return [self scaledImageToCoverSize: fitIn withInterpolation: inter andBox: doBox align: NSImageAlignCenter];
}

-(NSImage*) scaledImageToCoverSize: (NSSize)fitIn withInterpolation: (NSImageInterpolation)inter
						andBox: (BOOL)doBox align: (NSImageAlignment)align
{
	NSSize		size = [self scaledSizeToCoverSize: fitIn];
	NSImage*	img = [[NSImage alloc] initWithSize: fitIn];
	NSRect		srcBox = { { 0, 0 }, { 0, 0 } },
				dstBox = { { 0, 0 }, { 0, 0 } },
				clipBox = { { 0, 0 }, { 0, 0 } };
	
	dstBox.size = size;
	srcBox.size = [self size];
	clipBox.size = fitIn;
	
	// Center it:
	switch( align )
	{
		case NSImageAlignCenter:		// Center h and v.
			dstBox.origin.x -= (dstBox.size.width - clipBox.size.width) /2;
			dstBox.origin.y -= (dstBox.size.height - clipBox.size.height) /2;
			break;
		
		case NSImageAlignTop:			// Center h, v at top.
			dstBox.origin.x -= (dstBox.size.width - clipBox.size.width) /2;
			dstBox.origin.y -= dstBox.size.height - clipBox.size.height;
			break;
		
		case NSImageAlignTopLeft:		// h at left, v at top.
			dstBox.origin.y -= dstBox.size.height - clipBox.size.height;
			break;
		
		case NSImageAlignLeft:			// h at left, center v.
			dstBox.origin.y -= (dstBox.size.height - clipBox.size.height) /2;
			break;
		
		case NSImageAlignBottomLeft:	// h at left, v at bottom
		default:
			break;
		
		case NSImageAlignBottom:		// center h, v at bottom.
			dstBox.origin.x -= (dstBox.size.width - clipBox.size.width) /2;
			break;
		
		case NSImageAlignBottomRight:   // h at right, v at bottom.
			dstBox.origin.x -= dstBox.size.width - clipBox.size.width;
			break;
		
		case NSImageAlignRight:			// h at right, center v.
			dstBox.origin.x -= dstBox.size.width - clipBox.size.width;
			dstBox.origin.y -= (dstBox.size.height - clipBox.size.height) /2;
			break;
		
		case NSImageAlignTopRight:		// h at right, v at top.
			dstBox.origin.y -= dstBox.size.height - clipBox.size.height;
			dstBox.origin.x -= dstBox.size.width - clipBox.size.width;
			break;
		
	}
	
	NS_DURING
		[img lockFocus];
			[NSBezierPath clipRect: clipBox];
			[[NSGraphicsContext currentContext] setImageInterpolation: inter];
			[self drawInRect: dstBox fromRect: srcBox operation:NSCompositeSourceOver fraction:1.0];
			if( doBox )
			{
				[[NSColor blackColor] set];
				[NSBezierPath strokeRect: clipBox];
			}
		[img unlockFocus];
		
		NS_VALUERETURN( img, NSImage* );
	NS_HANDLER
		NSLog(@"Couldn't scale image %@",localException);
	NS_ENDHANDLER
	
	return nil;
}


-(NSSize)   scaledSizeToFitSize: (NSSize)size
{
	return [[self class] scaledSize: [self size] toFitSize: size];
}


+(NSSize)   scaledSize: (NSSize)imgSize toFitSize: (NSSize)size
{ 
	NSSize  finalSize = imgSize;
	CGFloat   ratio = size.width / imgSize.width;

	//if( imgSize.width > size.width || imgSize.height > size.height )
	{
		finalSize.width = size.width;
        if( imgSize.height == imgSize.width )
            finalSize.height = finalSize.width;
        else
            finalSize.height = imgSize.height * ratio;
		
		if( finalSize.height > size.height )
		{
			ratio = size.height / imgSize.height;
			finalSize.height = size.height;
            if( imgSize.height == imgSize.width )
                finalSize.width = finalSize.height;
            else
                finalSize.width = imgSize.width * ratio;
		}
	}
	
	return( finalSize ); 
}


-(NSSize)   scaledSizeToCoverSize: (NSSize)size 
{
	return [[self class] scaledSize: [self size] toCoverSize: size];
}


+(NSSize)   scaledSize: (NSSize)imgSize toCoverSize: (NSSize)size
{ 
	NSSize  finalSize = imgSize;
	CGFloat   ratio = imgSize.height / imgSize.width;
	
	/*if( imgSize.width == size.width
		&& imgSize.height == size.height )
		return imgSize;*/
	
	finalSize.width = size.width;
	finalSize.height = finalSize.width * ratio;
	
	if( finalSize.height < size.height )
	{
		ratio = imgSize.width / imgSize.height;
		finalSize.height = size.height;
		finalSize.width = finalSize.height * ratio;
	}
	
	return( finalSize ); 
} 


@end
