#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h> // for key codes

#import <OpenGL/OpenGL.h>
#import <GameController/GameController.h>

#import <mach/mach_time.h>

#import <cyril.h>
#import <glext.h>


@class View;
    @interface View : NSOpenGLView <NSWindowDelegate> {
        CVDisplayLinkRef displayLink; //display link for managing rendering thread
        uint64_t init_time;

        CyOnDisplay on_display;
        CyOnEvent on_event;
    }

    - (void) animate;
    - (id) initWithFrame: (NSRect)frame onDisplay: (CyOnDisplay) on_display onEvent: (CyOnEvent) on_event;
@end

static CVReturn display_link_callback(CVDisplayLinkRef dl, const CVTimeStamp* now, const CVTimeStamp* outTime, CVOptionFlags fIn, CVOptionFlags* fOut, void* ctx) {
    @autoreleasepool {
        [(__bridge View*)ctx animate];
    }
    return kCVReturnSuccess;
}

@implementation View

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void) windowWillClose: (NSNotification *) note {
    [[NSApplication sharedApplication] terminate: self];
}

- (id) initWithFrame: (NSRect) frame onDisplay: (CyOnDisplay) display_cb onEvent: (CyOnEvent) event_cb {
    NSOpenGLPixelFormatAttribute attribs[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFAColorSize, 32,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0
    };

    NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
    self = [super initWithFrame:frame pixelFormat:fmt];
    [self setWantsBestResolutionOpenGLSurface:YES];
    [fmt release];

    init_time = mach_absolute_time();
    on_event = event_cb;
    on_display = display_cb;

    // Initialize glext
    int res = glext_init();
    if(res != 0) {
        fprintf(stderr, "glext: failed to initialize: %d\n", res);
        exit(EXIT_FAILURE);
    }

    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];

    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    CVDisplayLinkSetOutputCallback(displayLink, &display_link_callback, (__bridge void*)self);

    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);

    // Activate the display link
    CVDisplayLinkStart(displayLink);

    return self;
}

- (void) drawRect:(NSRect) theRect {
    NSRect rect = [self convertRectToBacking:[self bounds]];
    on_display((GLsizei) rect.size.width, (GLsizei) rect.size.height);
    [[self openGLContext] flushBuffer];
}

- (void) mouseMoved: (NSEvent*) theEvent {

}

- (void) mouseUp: (NSEvent*) theEvent {
    NSPoint curPoint = [theEvent locationInWindow];
    CyEvent ev = (CyEvent){ CY_LEFT_MOUSE_UP, {.mouse={.x=curPoint.x, .y=curPoint.y}} };
    on_event(&ev);
}

- (void) mouseDown: (NSEvent*) theEvent {
    NSPoint curPoint = [theEvent locationInWindow];
    CyEvent ev = (CyEvent){ CY_LEFT_MOUSE_DOWN, {.mouse={.x=curPoint.x, .y=curPoint.y}} };
    on_event(&ev);
}

- (void) rightMouseUp: (NSEvent*) theEvent {
    NSPoint curPoint = [theEvent locationInWindow];
    CyEvent ev = (CyEvent){ CY_RIGHT_MOUSE_UP, {.mouse={.x=curPoint.x, .y=curPoint.y}} };
    on_event(&ev);
}

- (void) rightMouseDown: (NSEvent*) theEvent {
    NSPoint curPoint = [theEvent locationInWindow];
    CyEvent ev = (CyEvent){ CY_RIGHT_MOUSE_DOWN, {.mouse={.x=curPoint.x, .y=curPoint.y}} };
    on_event(&ev);
}

- (void) animate {
    // uint64_t currentTime = mach_absolute_time();
    // uint64_t elapsedTime = currentTime - m_previousTime;
    // m_previousTime = currentTime;

    // mach_timebase_info_data_t info;
    // mach_timebase_info(&info);

    // elapsedTime *= info.numer;
    // elapsedTime /= info.denom;

    // float timeStep = elapsedTime / 1000000.0f;

    [self display];
}

- (void) keyDown:(NSEvent *)theEvent {
    if([theEvent isARepeat]) return; // ignore key repeat

    CyEvent ev; //  = (CyEvent){ CY_KEY_DOWN, {.key={.code=}} };
    switch([theEvent keyCode]) {
        case kVK_Escape:
            ev = (CyEvent){ CY_KEY_DOWN, {.key={.code=CY_KEY_ESCAPE}} };
            on_event(&ev);
            break;
        default:
            ev = (CyEvent){ CY_KEY_DOWN, {.key={.code=CY_KEY_UNKNOWN}} };
            on_event(&ev);
    }
}

- (void) keyUp:(NSEvent *)theEvent {
    CyEvent ev;
    switch([theEvent keyCode]) {
        case kVK_Escape:
            ev = (CyEvent){ CY_KEY_UP, {.key={.code=CY_KEY_ESCAPE}} };
            on_event(&ev);
            break;
        default:
            ev = (CyEvent){ CY_KEY_UP, {.key={.code=CY_KEY_UNKNOWN}} };
            on_event(&ev);
    }
}

- (void)dealloc {
    // Release the display link
    CVDisplayLinkRelease(displayLink);
    [super dealloc];
}

@end


//
// Cy
//
int cy_init() {
    // TODO: install key translation table
    return 0;
}

CyGeom cy_window(char* title, int x, int y, int w, int h, CyOnDisplay display_cb, CyOnEvent event_cb) {
    NSRect screenBounds = [[NSScreen mainScreen] frame];
    NSRect viewBounds = NSMakeRect(x, y, w, h);

    View* view = [[View alloc] initWithFrame:viewBounds onDisplay:display_cb onEvent:event_cb];

    NSRect centered = NSMakeRect(NSMidX(screenBounds) - NSMidX(viewBounds),
                                 NSMidY(screenBounds) - NSMidY(viewBounds),
                                 viewBounds.size.width, viewBounds.size.height);

    NSWindow* window = [[NSWindow alloc]
        initWithContentRect:centered
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
        backing:NSBackingStoreBuffered
        defer:NO];

    [window setTitle: [NSString stringWithUTF8String: title]];
    [window setContentView:view];
    [window setDelegate:view];
    [window setLevel: NSFloatingWindowLevel];
    [window makeKeyAndOrderFront: view];
    [window setBackgroundColor:[NSColor clearColor]];
#if 0
        [window  setAcceptsMouseMovedEvents: YES];
#endif
    [view release];

    NSRect rect = [view convertRectToBacking:[view bounds]];
    return (CyGeom){rect.size.width, rect.size.height};
}

int cy_main() {
    [[NSApplication sharedApplication] run];
    return 0;  // not reached
}

void cy_terminate() {
    NSApplication *app = [NSApplication sharedApplication];
    [app terminate: app];
}
