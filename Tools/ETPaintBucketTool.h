/**
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETTool.h>

typedef NS_ENUM(NSUInteger, ETPaintMode)
{
	ETPaintModeFill,
	ETPaintModeStroke
};

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

@property (nonatomic, copy) NSColor *fillColor;
@property (nonatomic, copy) NSColor *strokeColor;
// NOTE: May be better named paintAction with ETStrokePaintAction...
@property (nonatomic) ETPaintMode paintMode;

/** @taskunit Settings related Actions */

- (void) changePaintMode: (id)sender;
- (void) changeColor: (id)sender;

@end
