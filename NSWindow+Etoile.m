/*  <title>NSWindow+Etoile</title>

	NSWindow+Etoile.m
	
	<abstract>NSWindow additions.</abstract>
 
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

#import <EtoileUI/NSWindow+Etoile.h>
#import <EtoileUI/ETObjectBrowserLayout.h>
#import <EtoileUI/ETCompatibility.h>

#define WINDOW_CONTENT_RECT NSMakeRect(200, 200, 600, 300)

@implementation NSWindow (Etoile)

+ (unsigned int) defaultStyleMask
{
	return (NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask 
		| NSMiniaturizableWindowMask);
}

- (id) init
{
	return [self initWithContentRect: WINDOW_CONTENT_RECT
					       styleMask: [NSWindow defaultStyleMask]
							 backing: NSBackingStoreBuffered
							   defer: YES];
}

- (id) initWithFrame: (NSRect)frame styleMask: (unsigned int)windowStyle
{
	NSRect contentRect = [NSWindow contentRectForFrameRect: frame 
	                                             styleMask: windowStyle];
	return [self initWithContentRect: contentRect
					       styleMask: windowStyle
							 backing: NSBackingStoreBuffered
							   defer: YES];
}

- (id) initWithContentRect: (NSRect)rect styleMask: (unsigned int)windowStyle
{
	return [self initWithContentRect: rect
					       styleMask: windowStyle
							 backing: NSBackingStoreBuffered
							   defer: YES];
}

- (BOOL) isSystemPrivateWindow
{
#ifdef GNUSTEP
	BOOL isAppIconWindow = [self isKindOfClass: NSClassFromString(@"NSIconWindow")];
	BOOL isMenuWindow = [self isKindOfClass: NSClassFromString(@"NSMenuPanel")];
#else
	BOOL isAppIconWindow = NO;
	BOOL isMenuWindow = NO;
#endif
	return ([self isCacheWindow] || isAppIconWindow || isMenuWindow);
}

- (BOOL) isCacheWindow
{
#ifdef GNUSTEP
	return ([self isKindOfClass: NSClassFromString(@"GSCacheW")]);
#else
	return NO;
#endif
}

- (IBAction) browse: (id)sender
{
	ETObjectBrowser *browser = [[ETObjectBrowser alloc] init];

	ETLog(@"browse %@", self);
	[browser setBrowsedObject: [self contentView]];
	[[browser panel] makeKeyAndOrderFront: self];
}

@end
