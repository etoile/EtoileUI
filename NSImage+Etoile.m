/*
	NSImage+Etoile.m
	
	NSImage additions.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <EtoileUI/NSImage+Etoile.h>
#import <EtoileUI/ETCompatibility.h>


@implementation NSImage (Etoile)

/** Initializes and returns an NSImage instance which is snapshot of the view
	parameter. The snapshot is taken at the time this method is called. */
- (NSImage *) initWithView: (NSView *)view
{
	self = [super init];
	
	if (self != nil)
	{
		NSRect viewRect = [view frame];
		
		viewRect.origin = NSZeroPoint;
		#ifdef GNUSTEP
		self = [self initWithData: [view dataWithEPSInsideRect: viewRect]];
		#else
		// NOTE: -dataWithEPSInsideRect: doesn't work on Mac OS X and PDF isn't
		// supported on GNUstep
		self = [self initWithData: [view dataWithPDFInsideRect: viewRect]];
		#endif
	}
	
	ETLog(@"Generated new image with reps %@ based on view %@", [self representations], view);
	
	return self;
}

@end
