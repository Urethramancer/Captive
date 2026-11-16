#import <AppKit/AppKit.h>
#include <assert.h>
#include <signal.h>
#include <unistd.h>

// Injected only by test-launch.sh: exercise the unmodified game's zero-argument path.
static void timeout(int number)
{
	(void)number;
	write(STDERR_FILENO, "Game launch check timed out\n", 27);
	_exit(124);
}
static void key(NSWindow *window, NSString *text, unsigned short code, NSEventModifierFlags flags)
{
	NSEvent *event = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
		modifierFlags:flags timestamp:0 windowNumber:window.windowNumber context:nil
		characters:text charactersIgnoringModifiers:text isARepeat:NO keyCode:code];
	if (flags & NSEventModifierFlagCommand) assert([NSApp.mainMenu performKeyEquivalent:event]);
	else [window.contentView keyDown:event];
}
__attribute__((constructor)) static void checkLaunch(void)
{
	signal(SIGALRM, timeout); alarm(15);
	@autoreleasepool {
		__block int stage = 0;
		NSTimer *timer = [NSTimer timerWithTimeInterval:0.3 repeats:YES block:^(NSTimer *timer) {
			assert(!NSApp.modalWindow && "Normal play must not open OS dialogs");
			NSWindow *window = NSApp.windows.firstObject;
			assert(window && NSApp.mainMenu);
			if (stage == 0) {
				NSView *view = window.contentView;
				double scale = fmin(view.bounds.size.width/1280, view.bounds.size.height/800);
				NSPoint point = NSMakePoint((view.bounds.size.width-1280*scale)/2+100*scale,
					(view.bounds.size.height-800*scale)/2+620*scale);
				point = [view convertPoint:point toView:nil];
				[view mouseDown:[NSEvent mouseEventWithType:NSEventTypeLeftMouseDown location:point
					modifierFlags:0 timestamp:0 windowNumber:window.windowNumber context:nil
					eventNumber:1 clickCount:2 pressure:1]];
			} else if (stage == 1) {
				key(window,@"Z",6,0); key(window,@"e",14,0); key(window,@"d",2,0);
				key(window,@"\r",36,0);
			} else if (stage == 2) {
				key(window,@"",96,0); // F5 saves the renamed party.
			} else {
				[timer invalidate];
				if (strcmp(getenv("CAPTIVE_TEST_CLOSE"), "window") == 0) [window performClose:nil];
				else key(window,@"q",12,NSEventModifierFlagCommand);
			}
			++stage;
		}];
		[NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
	}
}
