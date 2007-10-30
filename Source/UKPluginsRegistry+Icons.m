#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>

#ifdef GNUSTEP
#define APPLICATION_SUPPORT @"ApplicationSupport"
#else /* Cocoa */
#define APPLICATION_SUPPORT @"Application Support"
#endif

@implementation UKPluginsRegistry (Icons)

- (id) loadIconForPath:(NSString*) iconPath
{
	if (iconPath == nil)
	{
		return [NSImage imageNamed: @"NSApplicationIcon"];
	}
	return [[[NSImage alloc] initWithContentsOfFile: iconPath] autorelease];
}
@end
