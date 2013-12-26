/**
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETTool.h>

typedef enum _ETPaintMode
{
	ETPaintModeFill,
	ETPaintModeStroke
} ETPaintMode;

/** @group Tools

@abstract An tool class which implements the well-known paint bucket tool 
present in many graphics-oriented applications.

TODO: Implement tolerance option. */
@interface ETPaintBucketTool : ETTool
{
	@private
	NSColor *_fillColor;
	NSColor *_strokeColor;
	ETPaintMode _paintMode;
}

/** @taskunit Interaction Settings */

- (NSColor *) fillColor;
- (void) setFillColor: (NSColor *)color;
- (NSColor *) strokeColor;
- (void) setStrokeColor: (NSColor *)color;
// NOTE: May be better named paintAction with ETStrokePaintAction...
- (ETPaintMode) paintMode;
- (void) setPaintMode: (ETPaintMode)aMode;

/** @taskunit Settings related Actions */

- (void) changePaintMode: (id)sender;
- (void) changeColor: (id)sender;

@end
