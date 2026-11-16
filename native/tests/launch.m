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
static void click(NSWindow *window, double x, double y, NSInteger count)
{
	NSView *view = window.contentView;
	double scale = fmin(view.bounds.size.width/1280, view.bounds.size.height/800);
	NSPoint point = NSMakePoint((view.bounds.size.width-1280*scale)/2+x*scale,
		(view.bounds.size.height-800*scale)/2+y*scale);
	point = [view convertPoint:point toView:nil];
	[view mouseDown:[NSEvent mouseEventWithType:NSEventTypeLeftMouseDown location:point
		modifierFlags:0 timestamp:0 windowNumber:window.windowNumber context:nil
		eventNumber:1 clickCount:count pressure:1]];
}
__attribute__((constructor)) static void checkLaunch(void)
{
	signal(SIGALRM, timeout); alarm(30);
	@autoreleasepool {
		__block int stage = 0;
		__block NSArray *lastFrame = nil;
		BOOL travel = strcmp(getenv("CAPTIVE_TEST_CLOSE"), "travel") == 0;
		NSTimer *timer = [NSTimer timerWithTimeInterval:0.3 repeats:YES block:^(NSTimer *timer) {
			assert(!NSApp.modalWindow && "Normal play must not open OS dialogs");
			NSWindow *window = NSApp.windows.firstObject;
			assert(window && NSApp.mainMenu);
			// Advance only after the game has processed the previous inputs and
			// submitted another frame; rendering may outlast the timer interval.
			NSArray *frame = [[window.contentView valueForKey:@"controller"] valueForKey:@"frame"];
			if (!frame || frame == lastFrame) return;
			lastFrame = frame;
			if (travel) {
				if (stage == 0) key(window,@"",101,0); // F9 restores the legitimately completed first base.
				else if (stage == 1) key(window,@"\r",36,0);
				else if (stage == 2) key(window,@"",96,0);
				else if (stage == 3) { key(window,@"q",12,0); key(window,@"w",13,0); }
				else if (stage == 4) { key(window,@"",96,0); click(window,1100,42,1); }
				else if (stage == 5) {
					NSString *directory = [NSProcessInfo.processInfo.arguments.firstObject.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"saves"];
					NSError *error = nil;
					assert([NSFileManager.defaultManager copyItemAtPath:[directory stringByAppendingPathComponent:@"quick.captive"]
						toPath:[directory stringByAppendingPathComponent:@"before-checkpoint.captive"] error:&error]);
					key(window,@"",96,0);
				} else { [timer invalidate]; key(window,@"q",12,NSEventModifierFlagCommand); }
			} else if (stage == 0) {
				click(window,100,620,2);
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
