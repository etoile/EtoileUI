/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import "ETStyle+CoreObject.h"


@implementation ETStyleGroup (CoreObject)
@end

@implementation ETShape (CoreObject)

- (NSData *) serializedPath
{
	return (_path != nil ? [NSKeyedArchiver archivedDataWithRootObject: _path] : nil);
}

- (void) setSerializedPath: (NSData *)aBezierPathData
{
	ASSIGN(_path, [NSKeyedUnarchiver unarchiveObjectWithData: aBezierPathData]);
}

- (NSString *) serializedPathResizeSelector
{
	return NSStringFromSelector(_resizeSelector);
}

- (void) setSerializedPathResizeSelector: (NSString *)aSelString
{
	_resizeSelector = NSSelectorFromString(aSelString);
}

- (NSData *) serializedFillColor
{
	return (_fillColor != nil ? [NSKeyedArchiver archivedDataWithRootObject: _fillColor] : nil);;
}

- (void) setSerializedFillColor: (NSData *)aColorData
{
	ASSIGN(_fillColor, [NSKeyedUnarchiver unarchiveObjectWithData: aColorData]);
}

- (NSData *) serializedStrokeColor
{
	return (_strokeColor != nil ? [NSKeyedArchiver archivedDataWithRootObject: _strokeColor] : nil);;
}

- (void) setSerializedStrokeColor: (NSData *)aColorData
{
	ASSIGN(_strokeColor, [NSKeyedUnarchiver unarchiveObjectWithData: aColorData]);
}

@end
