#import <AppKit/AppKit.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 3) {
            fprintf(stderr, "Usage: set-icon <application.app> <icon.icns|--clear>\n");
            return 2;
        }
        NSString *app = [NSString stringWithUTF8String:argv[1]];
        NSImage *image = nil;
        if (strcmp(argv[2], "--clear") != 0) {
            image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithUTF8String:argv[2]]];
            if (!image) { fprintf(stderr, "Could not load the icon.\n"); return 1; }
        }
        if (![[NSWorkspace sharedWorkspace] setIcon:image forFile:app options:0]) {
            fprintf(stderr, "Could not update the custom application icon.\n");
            return 1;
        }
        return 0;
    }
}
