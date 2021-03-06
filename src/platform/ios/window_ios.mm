#include "macro.h"
#ifdef VI3D_PLATFORM_IOS
#include "pthread.h"
#include "window.h"
#include "system.h"

#import <UIKit/UIKit.h>
#import <QuartzCore/CAEAGLLayer.h>
#import <OpenGLES/ES2/gl.h>

using namespace vi3d;

int vi_main(int argc, char *argv[]);
void* vi_main_thread(void* args) 
{ 
    vi_main(0, NULL); 
    return 0; 
} 



@interface AppDelegate : UIResponder <UIApplicationDelegate> { } @end
@implementation AppDelegate

- (void)applicationWillResignActive:(UIApplication *)application    { Event ev(Event::APP_PAUSE);     System::inst()->putEvent(ev); }
- (void)applicationDidBecomeActive:(UIApplication *)application     { Event ev(Event::APP_RESUME);    System::inst()->putEvent(ev); }
- (void)applicationDidEnterBackground:(UIApplication *)application  { Event ev(Event::APP_STOP);      System::inst()->putEvent(ev); }
- (void)applicationWillEnterForeground:(UIApplication *)application { Event ev(Event::APP_RESTART);   System::inst()->putEvent(ev); }
- (void)applicationWillTerminate:(UIApplication *)application       { Event ev(Event::WM_CLOSE);      System::inst()->putEvent(ev); }

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    pthread_t tid;
    pthread_create(&tid, NULL, &vi_main_thread, NULL);
    return YES;
}
@end


int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}


@interface GLWindow : UIWindow { } @end

@implementation GLWindow { }
+(Class)layerClass                          { return [CAEAGLLayer class]; }


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    int i = 0;
    for(UITouch* touch in touches)
    {
        CGPoint point = [touch locationInView:nil];
        
        Event ev(Event::IO_TOUCH_DOWN);
        ev.data.touch.type = 1;
        ev.data.touch.idx = i++;
        ev.data.touch.x = point.x;
        ev.data.touch.x = point.y;
        System::inst()->putEvent(ev);
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    int i = 0;
    for(UITouch* touch in touches)
    {
        CGPoint point = [touch locationInView:nil];
        
        Event ev(Event::IO_TOUCH_MOVE);
        ev.data.touch.type = 1;
        ev.data.touch.idx = i++;
        ev.data.touch.x = point.x;
        ev.data.touch.x = point.y;
        System::inst()->putEvent(ev);
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    int i = 0;
    for(UITouch* touch in touches)
    {
        CGPoint point = [touch locationInView:nil];
        
        Event ev(Event::IO_TOUCH_UP);
        ev.data.touch.type = 1;
        ev.data.touch.idx = i++;
        ev.data.touch.x = point.x;
        ev.data.touch.x = point.y;
        System::inst()->putEvent(ev);
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}
@end


@interface GLController : UIViewController { } @end

@implementation GLController { }

-(BOOL)shouldAutorotate
{
    return YES;
}
@end

namespace vi3d 
{

class WindowIOS:public Window
{
public:
    WindowIOS();
    ~WindowIOS();
    
    void show(const char* title, int w, int h);
    void swap();
    void getSize(int w, int h);
    bool getEvent(Event &ev);
private:
    void exec(NSObject* obj, SEL sel);
private:
    GLController*   m_controller;
    GLWindow*       m_window;
    EAGLContext*    m_context;

    GLuint frameBuffer;
    GLuint colorBuffer;
    GLuint depthBuffer;
};


WindowIOS::WindowIOS()
{
    m_controller = NULL;
    m_window = NULL;
    m_context = NULL;
}

WindowIOS::~WindowIOS()
{
    glDeleteRenderbuffers(1, &colorBuffer);
    glDeleteRenderbuffers(1, &depthBuffer);
    glDeleteFramebuffers(1, &frameBuffer);

}

void WindowIOS::show(const char* title, int w, int h)
{
    m_controller = [GLController alloc];
    m_window = [[GLWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [m_window setRootViewController:m_controller];
    [m_window performSelectorOnMainThread:@selector(setScreen:) withObject:[UIScreen mainScreen] waitUntilDone:YES];
    exec(m_window, @selector(makeKeyAndVisible));

    m_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:m_context];

    glGenFramebuffers(1, &frameBuffer);
    glGenRenderbuffers(1, &colorBuffer);
    glGenRenderbuffers(1, &depthBuffer);

    CAEAGLLayer* layer = (CAEAGLLayer*)[m_window layer];
    

    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorBuffer);
    [m_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorBuffer);

    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);

    glBindRenderbuffer(GL_RENDERBUFFER, depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, w, h);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthBuffer);

    [m_window performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
}

void WindowIOS::swap()
{
    glBindRenderbuffer(GL_RENDERBUFFER, colorBuffer);
    [m_context presentRenderbuffer:colorBuffer];

}

void WindowIOS::exec(NSObject* obj, SEL sel)
{ 
    [obj performSelectorOnMainThread:sel withObject:nil waitUntilDone:YES]; 
}

void WindowIOS::getSize(int width, int height)
{
    if(m_window)
    {
        width = m_window.bounds.size.width;
        height = m_window.bounds.size.height;    
    }
}

 
bool WindowIOS::getEvent(Event &ev)
{
    return false;
}


Window* Window::inst()
{
    if(gptr)
    {
        return gptr;
    }
    else
    {
        gptr = new WindowIOS();
        return gptr;
    }

}




}
#endif
