#import <AppKit/AppKit.h>
#import "../captive_native.h"
#include <assert.h>
#include <signal.h>
#include <unistd.h>

static NSEvent *keyEvent(NSWindow *window, NSString *text, unsigned short code, NSEventModifierFlags flags)
{
	return [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:flags
		timestamp:0 windowNumber:window.windowNumber context:nil characters:text
		charactersIgnoringModifiers:text isARepeat:NO keyCode:code];
}
static void timeout(int signalNumber)
{
	(void)signalNumber;
	write(STDERR_FILENO, "Native lifecycle test timed out\n", 32);
	_exit(124);
}
static void awaitFullscreen(CaptiveHost *host, NSMenuItem *item, BOOL expected)
{
	for (int i = 0; i < 600; ++i) {
		assert(captive_host_pump(host));
		BOOL enabled = [(id<NSMenuItemValidation>)item.target validateMenuItem:item];
		if (enabled && captive_host_is_fullscreen(host) == expected) return;
		usleep(10000);
	}
	assert(!"Fullscreen transition did not complete");
}
int main(int argc, const char **argv)
{
	assert(argc == 2);
	signal(SIGALRM, timeout); alarm(20);
	@autoreleasepool {
		assert(strlen(captive_executable_directory()) > 0);
		CaptiveHost *host = captive_host_create("Captive — lifecycle check");
		assert(host && captive_host_pump(host));
		NSWindow *window = NSApp.windows.firstObject;
		assert(window);
		NSMenuItem *fullscreen = [NSApp.mainMenu.itemArray[2].submenu itemAtIndex:0];
		NSString *mode = [NSString stringWithUTF8String:argv[1]];
		if ([mode isEqualToString:@"fullscreen"]) {
			NSRect frame = window.frame;
			assert([NSApp.mainMenu performKeyEquivalent:keyEvent(window, @"f", 3,
				NSEventModifierFlagControl | NSEventModifierFlagCommand)]);
			captive_host_fullscreen(host); // Repeated clicks during transition are ignored.
			awaitFullscreen(host, fullscreen, YES);
			assert([fullscreen.title isEqualToString:@"Exit Full Screen"]);
			[window.contentView keyDown:keyEvent(window, @"\033", 53, 0)];
			awaitFullscreen(host, fullscreen, NO);
			assert([fullscreen.title isEqualToString:@"Enter Full Screen"]);
			assert(fabs(window.frame.size.width-frame.size.width)<2 && fabs(window.frame.size.height-frame.size.height)<2);
			CaptiveEvent event;
			while (captive_host_event(host, &event)) assert(!(event.kind == 1 && event.code == CAPTIVE_KEY_ESCAPE));
			captive_host_fullscreen(host);
			awaitFullscreen(host, fullscreen, YES);
			assert([NSApp.mainMenu performKeyEquivalent:keyEvent(window, @"f", 3,
				NSEventModifierFlagControl | NSEventModifierFlagCommand)]);
			awaitFullscreen(host, fullscreen, NO);
			[window performClose:nil];
		} else if ([mode isEqualToString:@"close"]) {
			[window performClose:nil];
		} else if ([mode isEqualToString:@"quit"]) {
			assert([NSApp.mainMenu performKeyEquivalent:keyEvent(window, @"q", 12, NSEventModifierFlagCommand)]);
		} else { assert(!"Unknown lifecycle test"); }
		assert(!captive_host_pump(host));
		captive_host_destroy(host);
	}
	return 0;
}
