#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "FormController.h"

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSApplication *app = [ETApplication sharedApplication];
	id controller = [[FormController alloc] init];
	
	[app setDelegate: controller];
	[app run];
	
	[controller release];
	[pool release];
	
	return 0;
}
