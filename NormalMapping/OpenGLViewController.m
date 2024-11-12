//
//  ViewController.m
//  ModelIOTextures
//
//  Created by mark lim pak mun on 09/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

#import "OpenGLViewController.h"
#import "OpenGLRenderer.h"

@implementation OpenGLViewController
{
    NSOpenGLView *_glView;
    CVDisplayLinkRef _displayLink;

    NSOpenGLContext *_glContext;
    GLuint _defaultFBOName;

    OpenGLRenderer *_renderer;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _glView = (NSOpenGLView *)self.view;

    [self prepareView];
    // OpenGL coordinate system is expressed in pixels.
    // macOS/iOS coordinate system is expressed in points.
    CGSize viewSizePoints = _glView.bounds.size;
    CGSize viewSizePixels = [_glView convertSizeToBacking:viewSizePoints];
    _renderer = [[OpenGLRenderer alloc] initWithSize:viewSizePixels
                                      defaultFBOName:_defaultFBOName];
}


- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)dealloc
{
    CVDisplayLinkStop(_displayLink);
}

- (void)viewDidLayout
{
    CGLLockContext(_glContext.CGLContextObj);

    CGSize viewSizePoints = _glView.bounds.size;
    CGSize viewSizePixels = [_glView convertSizeToBacking:viewSizePoints];

    [self makeCurrentContext];
    
    [_renderer resize:viewSizePixels];

    CGLUnlockContext(_glContext.CGLContextObj);

    if (!CVDisplayLinkIsRunning(_displayLink)) {
        CVDisplayLinkStart(_displayLink);
    }
}

- (void)viewDidAppear
{
    [_glView.window makeFirstResponder:self];
}

- (void)viewWillDisappear
{
    CVDisplayLinkStop(_displayLink);
}


- (void)prepareView
{
    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFAColorSize, 32,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };

    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

    NSAssert(pixelFormat, @"No OpenGL pixel format.");

    _glContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat
                                            shareContext:nil];

    CGLLockContext(_glContext.CGLContextObj);

    [_glContext makeCurrentContext];

    CGLUnlockContext(_glContext.CGLContextObj);

    //glEnable(GL_FRAMEBUFFER_SRGB);
    _glView.pixelFormat = pixelFormat;
    _glView.openGLContext = _glContext;
    _glView.wantsBestResolutionOpenGLSurface = YES;

    // The default framebuffer object (FBO) is 0 on macOS, because it uses
    // a traditional OpenGL pixel format model. Might be different on other OSes.
    _defaultFBOName = 0;

    CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);

    // Set the renderer output callback function.
    CVDisplayLinkSetOutputCallback(_displayLink,
                                   &OpenGLDisplayLinkCallback,
                                   (__bridge void *)self);

    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink,
                                                      _glContext.CGLContextObj,
                                                      pixelFormat.CGLPixelFormatObj);
    CVDisplayLinkStart(_displayLink);
}

static CVReturn OpenGLDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                          const CVTimeStamp* now,
                                          const CVTimeStamp* outputTime,
                                          CVOptionFlags flagsIn,
                                          CVOptionFlags* flagsOut,
                                          void* displayLinkContext)
{
    double fps = outputTime->rateScalar * outputTime->videoTimeScale / outputTime->videoRefreshPeriod;
    OpenGLViewController *viewController = (__bridge OpenGLViewController*)displayLinkContext;

    [viewController draw:fps];
    return kCVReturnSuccess;
    
}

- (void)makeCurrentContext
{
    [_glContext makeCurrentContext];
}

- (void)draw:(double)fps
{
    CGLLockContext(_glContext.CGLContextObj);

    [self makeCurrentContext];
    // The method might be called before the renderer object is instantiated.
    [_renderer draw:fps];

    CGLFlushDrawable(_glContext.CGLContextObj);
    CGLUnlockContext(_glContext.CGLContextObj);

}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint mousePoint = [self.view convertPoint:event.locationInWindow
                                        fromView:nil];

    [_renderer.camera startDraggingFromPoint: mousePoint];
}

- (void)mouseDragged:(NSEvent *)event
{
    NSPoint mousePoint = [self.view convertPoint:event.locationInWindow
                                        fromView:nil];
    if (_renderer.camera.isDragging) {
        [_renderer.camera dragToPoint: mousePoint];
    }
}

- (void)mouseUp:(NSEvent *)event
{
    NSPoint mousePoint = [self.view convertPoint:event.locationInWindow
                                        fromView:nil];
    [_renderer.camera endDrag];
}

 - (void)scrollWheel:(NSEvent *)event
{
    [_renderer.camera zoomInOrOut:event.scrollingDeltaY];
}

@end
