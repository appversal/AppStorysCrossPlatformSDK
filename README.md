This is the most updated code which includes:

- WebSockets
- Scratch Cards

Platform initialization
-----------------------

The shared core requires an Android Application context for some platform-level operations (storage, device info, etc.).

Recommended: call PlatformStorage.initialize(application) from your Application.onCreate() before using the SDK. This avoids reflection-based lookups that can fail in content providers, instrumentation tests, or non-standard process startups.

Note: `PlatformStorage.initialize` accepts a nullable `Context?`. Pass a non-null `Application` instance from your `Application.onCreate()` (recommended). Passing `null` will clear any previously-initialized context. If you intentionally clear the context, the SDK will attempt the reflection fallback and may throw an error if that also fails.

If you cannot call the initializer, the Android implementation will attempt a best-effort reflection fallback (ActivityThread.currentApplication()). If that also fails the SDK will throw a clear IllegalStateException explaining the required action.

