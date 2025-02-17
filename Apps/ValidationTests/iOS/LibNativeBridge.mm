#include "LibNativeBridge.h"

#import <Babylon/AppRuntime.h>
#import <Babylon/Graphics.h>
#import <Babylon/ScriptLoader.h>
#import <Babylon/Plugins/NativeEngine.h>
#import <Babylon/Plugins/NativeOptimizations.h>
#import <Babylon/Plugins/NativeXr.h>
#import <Babylon/Polyfills/Canvas.h>
#import <Babylon/Polyfills/Window.h>
#import <Babylon/Polyfills/XMLHttpRequest.h>
#import <UIKit/UIKit.h>

std::unique_ptr<Babylon::Graphics> graphics{};
std::unique_ptr<Babylon::AppRuntime> runtime{};

#import <Shared/TestUtils.h>

@implementation LibNativeBridge

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
}

- (void)init:(MTKView*)view width:(int)inWidth height:(int)inHeight
{
    runtime.reset();
    graphics.reset();

    float width = inWidth;
    float height = inHeight;

    Babylon::WindowConfiguration graphicsConfig{};
    graphicsConfig.WindowPtr = view;
    graphicsConfig.Width = static_cast<size_t>(width);
    graphicsConfig.Height = static_cast<size_t>(height);
    graphics = Babylon::Graphics::CreateGraphics(graphicsConfig);
    graphics->StartRenderingCurrentFrame();
    graphics->SetDiagnosticOutput([](const char* outputString) { printf("%s", outputString); fflush(stdout); });

    runtime = std::make_unique<Babylon::AppRuntime>();

    runtime->Dispatch([](Napi::Env env)
    {
        Babylon::Polyfills::Window::Initialize(env);
        Babylon::Polyfills::XMLHttpRequest::Initialize(env);
        Babylon::Polyfills::Canvas::Initialize(env);

        graphics->AddToJavaScript(env);
        Babylon::Plugins::NativeEngine::Initialize(env);

        Babylon::Plugins::NativeOptimizations::Initialize(env);

        // Initialize NativeXr plugin.
        Babylon::Plugins::NativeXr::Initialize(env);

        Babylon::TestUtils::CreateInstance(env, nullptr);
    });

    Babylon::ScriptLoader loader{ *runtime };
    loader.LoadScript("app:///Scripts/babylon.max.js");
    loader.LoadScript("app:///Scripts/babylonjs.loaders.js");
    loader.LoadScript("app:///Scripts/babylonjs.materials.js");
    loader.LoadScript("app:///Scripts/babylon.gui.js");
    loader.LoadScript("app:///Scripts/validation_native.js");
}

- (void)resize:(int)inWidth height:(int)inHeight
{
    if (graphics)
    {
        graphics->UpdateSize(static_cast<size_t>(inWidth), static_cast<size_t>(inHeight));
    }
}

- (void)render
{
    if (graphics)
    {
        graphics->FinishRenderingCurrentFrame();
        graphics->StartRenderingCurrentFrame();
    }
}

@end
