#import <AppKit/AppKit.h>

static BOOL RunOpen(NSArray<NSString *> *arguments) {
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/open"];
    task.arguments = arguments;
    NSError *error = nil;
    if (![task launchAndReturnError:&error]) return NO;
    [task waitUntilExit];
    return task.terminationStatus == 0;
}

int main(void) {
    @autoreleasepool {
        NSString *webApp = [NSHomeDirectory() stringByAppendingPathComponent:@"Applications/Chrome Apps.localized/Sonos.app"];
        NSURL *helper = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Helpers/Sonos Controller.app" isDirectory:YES];
        BOOL controllerRunning = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"local.ops.sonos-controller"].count > 0;
        BOOL controllerStarted = controllerRunning || RunOpen(@[@"-g", @"-a", helper.path]);
        if (![[NSFileManager defaultManager] fileExistsAtPath:webApp]) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Sonos web app is missing";
            alert.informativeText = @"Reinstall the Sonos web app in its dedicated Chrome profile.";
            [alert runModal];
            return 1;
        }
        BOOL webAppStarted = RunOpen(@[@"-a", webApp]);
        return controllerStarted && webAppStarted ? 0 : 1;
    }
}
