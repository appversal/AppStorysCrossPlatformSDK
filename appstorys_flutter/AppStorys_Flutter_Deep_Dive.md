# AppStorys Flutter SDK — Complete Technical Deep Dive
### Screen Capture, Widget Trees, Bridges, Streams, and Overlays

---

## TABLE OF CONTENTS

1. The Big Picture — What is happening and why
2. Flutter's Rendering Model — The three trees
3. RenderRepaintBoundary — The screenshot frame
4. Taking the Screenshot — `boundary.toImage()`
5. Uint8List — What bytes actually are
6. Walking the Widget Tree — Finding named elements
7. ValueKey — Giving widgets a name tag
8. localToGlobal — Converting coordinates
9. MethodChannel — The bridge between Dart and Kotlin
10. Why a Bridge Exists — Flutter vs Native
11. StateFlow — Kotlin's live data container
12. EventChannel — Native pushing to Dart
13. StateFlow → EventChannel → Dart Stream — The full reactive chain
14. Why Streams? — The alternative (polling) and why it's bad
15. Overlay and OverlayEntry — How tooltips float above everything
16. The Complete End-to-End Flow Diagram
17. Quick Reference Cheat Sheet

---

## 1. THE BIG PICTURE — WHAT IS HAPPENING AND WHY

Before any code — understand the goal.

AppStorys wants to let a dashboard user (a product manager at some company) 
visually say: "Show a tooltip pointing at the Login button when users land on 
the Home screen."

For that to work, the backend needs to know:
  - WHERE is the "Login button" on the actual phone screen? (pixels)
  - WHAT does the screen look like? (screenshot)
  - WHEN does a tooltip campaign exist for this screen? (campaign config)

And the Flutter app needs to:
  - Receive that config
  - Find the Login button widget at runtime
  - Draw a floating tooltip card pointing at it

This document explains every technical piece that makes this happen.

---

## 2. FLUTTER'S RENDERING MODEL — THE THREE TREES

Flutter doesn't draw widgets directly. It uses THREE parallel trees.

```
  WIDGET TREE           ELEMENT TREE          RENDER TREE
  (your code)         (Flutter's runtime)    (actual layout/paint)

  Widget               Element                RenderObject
  (blueprint)          (live instance)        (knows size/position)

  Text("Hello")   -->  StatelessElement  -->  RenderParagraph
  Container()     -->  StatelessElement  -->  RenderConstrainedBox
  Stack()         -->  MultiChildElement -->  RenderStack
```

ANALOGY:
  - Widget tree = Architectural blueprint (just a plan, immutable)
  - Element tree = The actual house being built (mutable, has state)
  - Render tree = The physical measurements of every wall (size, position)

WHY THIS MATTERS FOR US:
  - To take a screenshot → we need the Render tree
  - To find "which widget has key X" → we walk the Element tree
  - To get pixel positions → we ask RenderBox (a RenderObject subtype)

---

## 3. RENDERREPAINTBOUNDARY — THE SCREENSHOT FRAME

```dart
RenderRepaintBoundary? boundary =
    context.findAncestorRenderObjectOfType<RenderRepaintBoundary>();
```

Think of `RenderRepaintBoundary` as a PICTURE FRAME around part of your UI.

Flutter normally repaints widgets lazily — only what changed gets redrawn.
A RenderRepaintBoundary tells Flutter:
  "Everything inside me is an independent layer. Cache it separately."

WHY YOU NEED IT TO TAKE A SCREENSHOT:
Without a boundary, Flutter's render tree is spread across multiple GPU 
layers that don't have a single buffer you can read. The boundary forces 
Flutter to composite the entire subtree into ONE bitmap in memory.

```
Screen
┌──────────────────────────────────┐
│                                  │
│   ┌──────────────────────────┐   │
│   │  RenderRepaintBoundary   │   │
│   │  ┌────────────────────┐  │   │
│   │  │  Your Screen UI    │  │   │
│   │  │  (entire content)  │  │   │
│   │  └────────────────────┘  │   │
│   │                           │   │
│   │  <-- This whole box is    │   │
│   │      one PNG in memory    │   │
│   └──────────────────────────┘   │
│                                  │
└──────────────────────────────────┘
```

`findAncestorRenderObjectOfType<RenderRepaintBoundary>()` walks UP the render 
tree from the current widget until it finds the nearest one.

Fallback:
```dart
boundary ??= WidgetsBinding.instance.renderViewElement?.renderObject
    as RenderRepaintBoundary?;
```
If there is no ancestor boundary, grab the ROOT boundary — the entire screen.

---

## 4. TAKING THE SCREENSHOT — `boundary.toImage()`

```dart
// Step 1: Wait until the boundary is fully painted
for (int i = 0; i < 10 && boundary.debugNeedsPaint; i++) {
  await Future.delayed(const Duration(milliseconds: 50));
}

// Step 2: Render to image
final pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
final image = await boundary.toImage(pixelRatio: pixelRatio);

// Step 3: Convert to bytes
final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
final pngBytes = byteData!.buffer.asUint8List();
```

Let's break each line down:

### `debugNeedsPaint`
A flag on every RenderObject. If true, Flutter hasn't finished painting it yet.
We poll until it's false (max 10 tries × 50ms = 500ms wait).

### `devicePixelRatio`
On a phone with a 3x screen (like most modern iPhones/Android flagships),
1 logical pixel = 3 physical pixels.

  - Widget at x=100 (logical) → actually at x=300 physical pixels on screen
  - The PNG should use physical pixels to match the actual screen image

```
  LOGICAL PIXELS          PHYSICAL PIXELS
  (what Flutter uses)     (actual screen dots)

  ┌──┐                    ┌──┬──┬──┐
  │  │  x 3.0 ratio       │  │  │  │
  └──┘                    ├──┼──┼──┤
  1x1                     │  │  │  │
                          ├──┼──┼──┤
                          │  │  │  │
                          └──┴──┴──┘
                          3x3
```

### `boundary.toImage(pixelRatio: pixelRatio)`
This is a Flutter engine call. It tells the GPU to render the boundary's 
content into a `ui.Image` object (an in-memory bitmap).
This is `async` because the GPU renders on its own thread.

### `image.toByteData(format: ui.ImageByteFormat.png)`
Converts the GPU bitmap to a PNG-encoded byte buffer.
`ui.ImageByteFormat.png` = compress as PNG (lossless, good for UI screenshots).
Other option: `rawRgba` = raw uncompressed pixel data (bigger, faster to decode).

### `.buffer.asUint8List()`
`byteData` is a `ByteData` — a low-level buffer of bytes.
`.buffer` = the underlying memory block (`ByteBuffer`)
`.asUint8List()` = view it as a list of unsigned 8-bit integers (0–255)

This is your final `pngBytes` — a sequence of numbers representing your PNG file.

---

## 5. UINT8LIST — WHAT BYTES ACTUALLY ARE

`Uint8List` = **Unsigned Integer, 8-bit, List**

Every file on your computer is ultimately a sequence of bytes.
A byte = a number from 0 to 255 (8 bits = 2^8 = 256 possible values).

ANALOGY: Think of a byte as a single pixel in a black-and-white image where 
0 = black and 255 = white. Real images use multiple bytes per pixel (R, G, B, A).

```
A PNG file on disk:

[137, 80, 78, 71, 13, 10, 26, 10, ...]
  ^   ^   ^   ^
  |   P   N   G   ← These 4 bytes are literally the letters "PNG" in ASCII
  |                 (137 is the PNG magic number header)
  |
  This is what Uint8List holds — just raw numbers

In Dart:
  Uint8List pngBytes = [137, 80, 78, 71, 13, 10, 26, 10, ...]
  pngBytes.length    = (filesize in bytes, e.g. 45231)
```

WHY NOT JUST PASS A FILE PATH?
Because Flutter runs in a sandboxed Dart VM. There's no guaranteed file system 
location both Dart and Kotlin can access at the same time. Passing the raw bytes 
through the MethodChannel is simpler and more reliable.

WHY UINT8 AND NOT INT?
Regular `int` in Dart is 64-bit. You don't need 64-bit precision per byte — 
that would waste 8x memory. `Uint8List` is a typed, compact buffer using 
exactly 1 byte per element. For a 1MB screenshot: 1,000,000 elements.

---

## 6. WALKING THE WIDGET TREE — FINDING NAMED ELEMENTS

```dart
static String _collectLayout(BuildContext context, double pixelRatio) {
  final data = <Map<String, dynamic>>[];

  void visit(Element el) {
    final key = el.widget.key;
    final ro = el.renderObject;
    if (key is ValueKey<String> && ro is RenderBox && ro.hasSize) {
      final pos = ro.localToGlobal(Offset.zero);
      final sz = ro.size;
      data.add({
        'id': key.value,
        'frame': {
          'x': (pos.dx * pixelRatio).round(),
          'y': (pos.dy * pixelRatio).round(),
          'width': (sz.width * pixelRatio).round(),
          'height': (sz.height * pixelRatio).round(),
        },
      });
    }
    el.visitChildren(visit);  // <-- recursion
  }

  visit(context as Element);
  return jsonEncode(data);
}
```

### How does `visitChildren` work?

`Element.visitChildren(visitor)` calls `visitor(child)` for every direct child 
Element. By calling it recursively, you visit EVERY element in the entire tree.

ANALOGY: It's like a family tree walk. You start at grandpa (root context), 
visit all his children, then each child's children, all the way down.

```
Root Element
├── Scaffold Element
│   ├── AppBar Element
│   │   └── Text Element  ← has ValueKey("page_title")? → record it
│   └── Column Element
│       ├── Button Element ← has ValueKey("login_btn")? → record it
│       └── Text Element
```

### The `is` check
```dart
if (key is ValueKey<String> && ro is RenderBox && ro.hasSize)
```

`key is ValueKey<String>` — not every widget has a key. Most don't.
This filter says: only look at widgets that were explicitly tagged by the dev.

`ro is RenderBox` — some elements don't have a render object (e.g., invisible 
widgets). RenderBox is the subtype that knows about 2D size and position.

`ro.hasSize` — if the widget hasn't been laid out yet, its size is undefined.
We skip those to avoid crashes.

---

## 7. VALUEKEY — GIVING WIDGETS A NAME TAG

```dart
// Developer writes this in their Flutter screen:
ElevatedButton(
  key: const ValueKey('login_button'),
  onPressed: () {},
  child: Text('Login'),
)
```

Flutter has several Key types:
  - `Key` — abstract base
  - `ValueKey<T>` — identified by a value of type T (we use `String`)
  - `GlobalKey` — unique across the entire app, can access state
  - `UniqueKey` — random, used to force widget recreation

`ValueKey<String>` is the "name tag" for tooltip targeting.

The dev labels their widget:
```dart
  key: const ValueKey('login_button')
```

The AppStorys dashboard stores:
```json
  { "target": "login_button" }
```

`TooltipManager._findElement('login_button')` walks the tree until it finds 
the Element whose widget has `ValueKey('login_button')`.

```dart
if (key is ValueKey<String> && key.value == target) {
  found = el;
  return;
}
```

MATCH! Now we know exactly which widget to point the tooltip at.

---

## 8. LOCALTOGLOBAL — CONVERTING COORDINATES

```dart
final pos = ro.localToGlobal(Offset.zero);
```

Every RenderBox knows its position RELATIVE TO ITS PARENT.
But we need the position relative to the SCREEN (global coordinates).

ANALOGY: 
  Imagine you're in a building. Your room is on Floor 3, 10 meters from the 
  elevator. Your desk is 2 meters from the door. 
  
  Local position of desk = "2m from the door"
  Global position of desk = "Floor 3 + 10m from elevator + 2m from door"

`localToGlobal(Offset.zero)` means: 
  "Give me the global position of my top-left corner (0,0 in my local space)"
  
  Flutter walks UP the render tree, accumulating all the transforms 
  (translations, scales, rotations) until it reaches the screen root.

```
Screen (0,0)
  └── Scaffold (0,0 relative to screen = 0,0 global)
        └── Column (top: 80, left: 0 = 80,0 global)
              └── Button (top: 200, left: 50 relative to Column)
              
Button global position = 0+0+50, 0+80+200 = (50, 280)
```

---

## 9. METHODCHANNEL — THE BRIDGE BETWEEN DART AND KOTLIN

Flutter is written in Dart. Native Android is written in Kotlin/Java.
They run in SEPARATE EXECUTION ENVIRONMENTS.

```
┌─────────────────────────────────────────────────────┐
│                   Android Process                    │
│                                                      │
│  ┌──────────────────┐      ┌───────────────────────┐ │
│  │   Dart / Flutter │      │   Kotlin / Native     │ │
│  │   (Flutter VM)   │      │   (Android Runtime)   │ │
│  │                  │      │                        │ │
│  │  Your Dart code  │      │  AppstorysFlutterPlugin│ │
│  │  UI, logic, etc. │      │  AppStorysCore (KMP)   │ │
│  │                  │      │  Ktor HTTP, Storage    │ │
│  └────────┬─────────┘      └───────────┬────────────┘ │
│           │                            │              │
│           │◄──── MethodChannel ───────►│              │
│           │    "appstorys_flutter"     │              │
│                                        │              │
└─────────────────────────────────────────────────────┘
```

### How MethodChannel works:

DART SIDE (sends message):
```dart
final channel = MethodChannel('appstorys_flutter');
await channel.invokeMethod('identifyElements', {
  'screenName': 'HomeScreen',
  'screenshot': Uint8List,
  'children': '[ {"id":"btn",...} ]',
});
```

KOTLIN SIDE (receives message):
```kotlin
channel = MethodChannel(binding.binaryMessenger, "appstorys_flutter")
channel.setMethodCallHandler(this)

override fun onMethodCall(call: MethodCall, result: Result) {
  when (call.method) {
    "identifyElements" -> handleIdentifyElements(call, result)
    // ...
  }
}
```

The channel name `"appstorys_flutter"` is just a string — both sides must 
use the exact same string. It's like a radio frequency both must tune to.

ANALOGY: MethodChannel is like a TELEPHONE CALL.
  - Dart dials a number (method name)
  - Kotlin picks up and handles it
  - Kotlin says "ok done" (result.success) or "error" (result.error)
  - Dart gets the response (the Future completes)

### Data encoding across MethodChannel

Flutter automatically encodes/decodes these types:

```
Dart            ↔   Kotlin
────────────────────────────
null            ↔   null
bool            ↔   Boolean
int             ↔   Int / Long
double          ↔   Double
String          ↔   String
Uint8List       ↔   ByteArray       ← Your screenshot
List<?>         ↔   List<Any?>
Map<?, ?>       ↔   HashMap<Any?,Any?>
```

The PNG bytes (`Uint8List`) automatically become a `ByteArray` in Kotlin.
No manual serialization needed.

---

## 10. WHY A BRIDGE EXISTS — FLUTTER VS NATIVE

Flutter draws its own UI using its own rendering engine (Skia/Impeller).
It doesn't use Android Views at all.

But things like:
  - Network calls with complex auth
  - Accessing device storage (SharedPreferences)
  - Bluetooth, Camera, GPS
  - Complex business logic shared with other platforms (KMP)

...are better done in native code, or MUST be done in native code.

```
Things Flutter Dart CAN do:            Things needing Native:
─────────────────────────────          ──────────────────────
Draw UI (Canvas, Widgets)              SharedPreferences
HTTP (via dart:io)                     Background services
JSON parsing                           Platform-specific APIs
State management                       KMP shared logic
Taking screenshots                     Access token management
Walking widget tree                    JitPack library integration
```

The MethodChannel is the designed solution for this boundary.

---

## 11. STATEFLOW — KOTLIN'S LIVE DATA CONTAINER

Before understanding EventChannel, you need to understand StateFlow.

```kotlin
private val _campaigns = MutableStateFlow<List<Campaign>>(emptyList())
val campaigns: StateFlow<List<Campaign>> = _campaigns.asStateFlow()
```

ANALOGY: StateFlow is like a LIVE SCOREBOARD.
  - It always has a current value (starts as `emptyList()`)
  - Anyone can subscribe (collect) to get updates
  - Every new subscriber IMMEDIATELY receives the current value
  - When the value changes, ALL subscribers get the new value

Compare to a regular variable:
```kotlin
// Regular variable — you have to check it yourself, no notification
var campaigns: List<Campaign> = emptyList()

// StateFlow — it NOTIFIES you when it changes
val campaigns: StateFlow<List<Campaign>>
```

### How it flows in AppStorysCore:

```
getScreenCampaigns() runs
        │
        ▼
API call completes
        │
        ▼
_campaigns.emit(campaignsList)   ← writes new value
        │
        ├──► Collector 1 (Android UI) gets notified
        ├──► Collector 2 (Flutter EventChannel) gets notified
        └──► Collector 3 (React Native bridge) gets notified
```

One source of truth. Multiple listeners. No polling needed.

### MutableStateFlow vs StateFlow

```kotlin
private val _campaigns = MutableStateFlow(...)  // writable (private)
val campaigns: StateFlow<...> = _campaigns      // read-only (public)
```

This is the standard Kotlin pattern:
  - `_campaigns` = private, only AppStorysCore can write to it
  - `campaigns` = public, everyone can READ and SUBSCRIBE but not write
  - Protects state from being mutated externally

---

## 12. EVENTCHANNEL — NATIVE PUSHING TO DART

MethodChannel = REQUEST/RESPONSE (like HTTP — Dart asks, Kotlin answers once)
EventChannel  = STREAM (like a WebSocket — Kotlin pushes whenever it wants)

```dart
// Dart side — sets up the stream
static const EventChannel _campaignsEventChannel =
    EventChannel('appstorys_flutter/campaigns_stream');

Stream<String> get campaignsStream {
  return _campaignsEventChannel
      .receiveBroadcastStream()
      .map((event) => event as String);
}
```

```kotlin
// Kotlin side — pushes data into the stream
campaignsEventChannel = EventChannel(
    flutterPluginBinding.binaryMessenger,
    "appstorys_flutter/campaigns_stream"
)
campaignsEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        // Dart has subscribed — start sending
        campaignsCollectionJob = pluginScope.launch {
            core.campaigns.collect { _ ->
                val json = core.getCampaignsJson()
                withContext(Dispatchers.Main) {
                    sink.success(json)    // <-- PUSH to Dart
                }
            }
        }
    }
    override fun onCancel(arguments: Any?) {
        campaignsCollectionJob?.cancel()  // Dart unsubscribed — stop
    }
})
```

`sink.success(json)` pushes the JSON string into the Dart stream.
Dart receives it as an event in `receiveBroadcastStream()`.

ANALOGY: EventChannel is like a RADIO BROADCAST STATION.
  - Kotlin is the station (transmitter)
  - Dart is the radio (receiver)
  - `sink.success(data)` = the station transmits a signal
  - `stream.listen(...)` = the radio is tuned in and playing
  - `onCancel` = listener turns off the radio

---

## 13. STATEFLOW → EVENTCHANNEL → DART STREAM — THE FULL CHAIN

This is the most interesting part. Let's trace every step:

```
AppStorysCore                 AppstorysFlutterPlugin.kt        Flutter Dart
─────────────                 ──────────────────────────       ────────────

_campaigns                    pluginScope coroutine            campaignsStream
MutableStateFlow              collects campaigns SF            (EventChannel)
     │                              │                               │
     │  1. getScreenCampaigns()     │                               │
     │     completes, emits list    │                               │
     │──────────────────────────►  │                               │
     │                              │  2. .collect { _ ->           │
     │                              │       json = getCampaignsJson │
     │                              │       sink.success(json)      │
     │                              │     }                         │
     │                              │──────────────────────────────►│
     │                              │                               │ 3. stream.listen
     │                              │                               │    (json) => {
     │                              │                               │    decode campaigns
     │                              │                               │    processTooltips()
     │                              │                               │    }
```

### Step-by-step in code:

**Step 1 — Core emits:**
```kotlin
// AppStorysCore.kt line ~314
_campaigns.emit(campaignsList)
```

**Step 2 — Plugin collects and pushes:**
```kotlin
// AppstorysFlutterPlugin.kt line ~51
core.campaigns.collect { _ ->
    val json = core.getCampaignsJson()
    withContext(Dispatchers.Main) {
        sink.success(json)        // sends JSON string to Dart
    }
}
```
Note: `withContext(Dispatchers.Main)` — EventChannel's `sink.success()` MUST 
be called on the Android Main thread. The collect runs on `Dispatchers.Default` 
(background). `withContext` switches threads just for the `sink.success()` call.

**Step 3 — Dart receives:**
```dart
// appstorys_flutter_method_channel.dart line ~27
_campaignsEventChannel
    .receiveBroadcastStream()     // subscribe to native events
    .map((event) => event as String)  // type-cast each event
```

**Step 4 — App layer uses it:**
```dart
// appstorys_flutter.dart line ~47
Stream<List<Map<String, Object?>>> get campaignsUpdates {
  return campaignsStream.map((json) {
    final decoded = jsonDecode(json);
    return decoded.whereType<Map>()...toList();
  });
}
```

**Step 5 — Example app listens:**
```dart
// Your screen widget
subscribeToCampaigns(appstorys.campaignsStream, (json) {
  final campaigns = jsonDecode(json) as List;
  appstorys.processTooltips(context, campaigns);
});
```

The whole chain is REACTIVE — no polling, no manual refresh.
One `_campaigns.emit(...)` in Kotlin causes tooltips to appear in Flutter.

---

## 14. WHY STREAMS? — THE ALTERNATIVE AND WHY IT'S BAD

### The polling approach (BAD):
```dart
// Without streams — polling every 500ms
Timer.periodic(Duration(milliseconds: 500), (_) async {
  final json = await appstorys.getCampaignsJson();
  updateUI(json);
});
```

Problems:
  - Wakes up every 500ms even when nothing changed — wastes battery
  - Latency: up to 500ms delay before UI updates
  - Race conditions: multiple timers might run simultaneously
  - Hard to cancel cleanly
  - Scales badly: 10 widgets = 10 timers

### The stream approach (GOOD):
```dart
// With streams — push-based
appstorys.campaignsStream.listen((json) {
  updateUI(json);
});
```

Benefits:
  - Zero CPU when nothing changes
  - Instant update the moment campaigns change
  - One native listener shared across all subscribers (broadcast stream)
  - Clean cancel: `subscription.cancel()` stops everything
  - Composable: `.map()`, `.where()`, `.distinct()` etc.

### The broadcast stream cache trick:
```dart
// appstorys_flutter.dart
Stream<String>? _campaignsStreamCache;

Stream<String> get campaignsStream {
  _campaignsStreamCache ??=
      AppstorysFlutterPlatform.instance.campaignsStream.asBroadcastStream();
  return _campaignsStreamCache!;
}
```

`??=` = "assign if null" — lazy initialization.

Problem without this: every time a widget calls `.campaignsStream`, it would call 
`.receiveBroadcastStream()` again, creating a NEW native EventChannel listener.
10 widgets = 10 listeners = 10 copies of the same JSON sent to Dart.

Fix: Create the native stream ONCE, convert to broadcast stream (many 
subscribers, one source), and cache it. All widgets share the same stream.

```
Without cache:                       With cache:
─────────────                        ────────────
Widget A ──► .receiveBroadcastStream()  ┐
Widget B ──► .receiveBroadcastStream()  ├─► 3 separate native listeners
Widget C ──► .receiveBroadcastStream()  ┘   (wasteful)

Widget A ──┐
Widget B ──┼─► shared broadcast stream ──► 1 native listener ──► Kotlin
Widget C ──┘                                (efficient)
```

---

## 15. OVERLAY AND OVERLAYENTRY — HOW TOOLTIPS FLOAT ABOVE EVERYTHING

### What is the Overlay?

Flutter's `Overlay` is a special Stack that sits ABOVE all routes and widgets.
It's used for: tooltips, dropdowns, dialogs, snackbars, loading spinners.

```
Flutter render tree (simplified):

MaterialApp
└── Navigator
    └── Overlay              ← always on top
        ├── OverlayEntry 0   ← your screen (HomeScreen)
        ├── OverlayEntry 1   ← dialogs if any
        └── OverlayEntry 2   ← TooltipManager inserts here ← OUR TOOLTIP
```

### OverlayEntry

```dart
_overlay = OverlayEntry(
  builder: (_) => Material(
    color: Colors.transparent,
    child: Stack(
      children: [
        // Layer 1: Dark backdrop with cutout
        if (bdEnabled)
          GestureDetector(
            onTap: _advance,
            child: CustomPaint(
              size: screen,
              painter: _BackdropPainter(...),
            ),
          ),
        
        // Layer 2: Arrow pointing at target
        Positioned(
          left: arrowX, top: arrowY,
          child: CustomPaint(painter: _ArrowPainter(up: below, color: arrowColor)),
        ),
        
        // Layer 3: Tooltip card
        Positioned(
          left: tooltipX, top: tooltipY,
          child: Container(
            width: tw, height: th,
            child: isText ? _TextContent(...) : _ImageContent(...),
          ),
        ),
      ],
    ),
  ),
);

Overlay.of(_ctx!).insert(_overlay!);  // actually show it
```

### CustomPaint and CustomPainter

Flutter's standard widgets are great, but sometimes you need raw drawing.
`CustomPaint` gives you a `Canvas` — like an HTML Canvas or Android Canvas.

```dart
class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))  // full screen
      ..addRRect(RRect.fromRectAndRadius(highlightRect, ...))   // cutout
      ..fillType = PathFillType.evenOdd;                        // make cutout transparent
    
    canvas.drawPath(path, Paint()..color = darkColor);
  }
}
```

`PathFillType.evenOdd` is the trick:
  - Draw a full-screen rectangle
  - Draw the highlight rounded rectangle INSIDE it
  - EvenOdd rule: where paths OVERLAP, cancel each other out → transparent hole
  - Result: dark everywhere EXCEPT the target widget area

```
Before evenOdd:         After evenOdd:
───────────────         ──────────────
█████████████           ████████████
█████████████           ███ HOLE ███
█████████████           ████████████
(all dark)              (dark with hole over target)
```

### Positioning the tooltip (above or below):

```dart
final spaceBelow = screen.height - (position.dy + size.height);
final spaceAbove = position.dy;
final below = spaceBelow >= estimatedTh + arrowH + elementArrowGap
              || spaceBelow > spaceAbove;

final tooltipY = below
    ? position.dy + size.height + elementArrowGap + arrowH
    : position.dy - elementArrowGap - arrowH - estimatedTh;
```

```
          tooltipY (above)
          ┌───────────────┐
          │  Tooltip Card  │
          └───────┬───────┘
                  ▼ (arrow pointing down)
         ┌────────────────┐
         │  Target Widget  │  ← position.dy, size.height
         └────────────────┘
                  ▼ (arrow pointing up)
          ┌───────────────┐
          │  Tooltip Card  │
          └───────────────┘
          tooltipY (below)
```

---

## 16. THE COMPLETE END-TO-END FLOW DIAGRAM

```
══════════════════════════════════════════════════════════════════════════
PART A: SCREEN CAPTURE (Dev/Test Tool — tells backend about element layout)
══════════════════════════════════════════════════════════════════════════

  DEV TAPs PURPLE CAMERA BUTTON
           │
           ▼
  CaptureManager._capture()
  ┌─────────────────────────────────────────────────────────────┐
  │  1. Find RenderRepaintBoundary                               │
  │  2. Wait for debugNeedsPaint == false                        │
  │  3. boundary.toImage(pixelRatio: x)  → ui.Image             │
  │  4. image.toByteData(png)            → ByteData             │
  │  5. byteData.buffer.asUint8List()    → Uint8List (PNG bytes) │
  └─────────────────────────────────────────────────────────────┘
           │                    │
           │                    ▼
           │         _collectLayout(context, pixelRatio)
           │         ┌─────────────────────────────────┐
           │         │  Walk Element tree               │
           │         │  For each ValueKey<String>:      │
           │         │    id = key.value                │
           │         │    pos = renderBox.localToGlobal │
           │         │    sz  = renderBox.size          │
           │         │    × pixelRatio for physical px  │
           │         └──────────────┬──────────────────┘
           │                        │
           │           JSON: [{id, frame:{x,y,w,h}}, ...]
           │                        │
           ▼                        ▼
  identifyElements(screenName, pngBytes, childrenJson)
           │
           ▼
  MethodChannel.invokeMethod('identifyElements', {
      'screenName': String,
      'screenshot': Uint8List  → ByteArray in Kotlin,
      'children':   String
  })
           │
           │  [Dart ←→ Native boundary]
           │
           ▼
  AppstorysFlutterPlugin.kt → handleIdentifyElements()
  ┌────────────────────────────────────────┐
  │  Extract screenName, screenshot, children│
  │  pluginScope.launch {                   │
  │    core.tooltipIdentify(...)            │ (fire-and-forget)
  │  }                                      │
  │  result.success(null)  ← returns to Dart│
  └──────────────────┬─────────────────────┘
                     │
                     ▼
  AppStorysCore.tooltipIdentify()
  (KMP shared-core — same code for Android + iOS)
                     │
                     ▼
  ApiClient.tooltipIdentify()   [Ktor HTTP — KMP]
  ┌─────────────────────────────────────────────────────────┐
  │  POST https://backend.appstorys.co/api/v1/appinfo/      │
  │       identify-elements/                                │
  │                                                         │
  │  Headers: Authorization: Bearer <token>                 │
  │  Body (multipart/form-data):                            │
  │    screenName  = "HomeScreen"                           │
  │    user_id     = "user123"                              │
  │    children    = '[{"id":"login_btn","frame":{...}}]'  │
  │    screenshot  = <PNG bytes>                            │
  └─────────────────────────────────────────────────────────┘
                     │
                     ▼
           BACKEND (AppStorys server)
  ┌────────────────────────────────────────┐
  │  Stores: screenshot + element map for  │
  │  this screenName + accountId           │
  │  Dashboard shows it visually to PM     │
  └────────────────────────────────────────┘


══════════════════════════════════════════════════════════════════════════
PART B: TOOLTIP DISPLAY (Production flow — shows tooltips to users)
══════════════════════════════════════════════════════════════════════════

  USER OPENS SCREEN
           │
           ▼
  getScreenCampaigns("HomeScreen")
           │
           ▼
  AppStorysCore (KMP):
  ┌─────────────────────────────────────────────────────┐
  │  1. POST track-user-res → eligible campaign IDs     │
  │  2. GET campaigns.json from S3 CDN (ETag cached)    │
  │  3. Filter: screen="HomeScreen" && id in eligible   │
  │  4. _campaigns.emit(filteredList)  ← StateFlow      │
  └──────────────────────────┬──────────────────────────┘
                             │
                             │  StateFlow emits new value
                             ▼
  AppstorysFlutterPlugin.kt coroutine:
  ┌─────────────────────────────────────────────────────┐
  │  core.campaigns.collect { _ ->                      │
  │      val json = core.getCampaignsJson()             │
  │      withContext(Dispatchers.Main) {                │
  │          sink.success(json)  ← EventChannel push    │
  │      }                                              │
  │  }                                                  │
  └──────────────────────────┬──────────────────────────┘
                             │
                             │  [Native → Dart via EventChannel]
                             ▼
  Dart Stream<String> emits JSON string
           │
           ▼
  CampaignsStreamMixin / listener in screen widget:
  ┌────────────────────────────────────────────┐
  │  subscribeToCampaigns(stream, (json) {     │
  │      final campaigns = jsonDecode(json);   │
  │      appstorys.processTooltips(ctx, camp); │
  │  });                                       │
  └───────────────────┬────────────────────────┘
                      │
                      ▼
  TooltipManager.processTooltips()
  ┌─────────────────────────────────────────────────────┐
  │  Filter: campaign_type == 'TTP'                     │
  │  Extract tooltips list, sort by 'order'             │
  │  For each tooltip:                                  │
  │    _findElement(target)                             │
  │      → walk Element tree for ValueKey(target)       │
  │    If found → add to _queue                         │
  │  await Future.delayed(1 second)                     │
  │  _showNext()                                        │
  └──────────────────────────┬──────────────────────────┘
                             │
                             ▼
  _insert() — build OverlayEntry
  ┌─────────────────────────────────────────────────────┐
  │  Get target position:                               │
  │    renderBox.localToGlobal(Offset.zero)             │
  │    renderBox.size                                   │
  │                                                     │
  │  Calculate above/below:                             │
  │    spaceBelow vs spaceAbove                         │
  │                                                     │
  │  Build Stack:                                       │
  │    1. _BackdropPainter (dark + highlight cutout)    │
  │    2. _ArrowPainter (triangle)                      │
  │    3. Tooltip card (text or image)                  │
  │                                                     │
  │  Overlay.of(ctx).insert(overlayEntry)               │
  └──────────────────────────┬──────────────────────────┘
                             │
                             ▼
                    TOOLTIP VISIBLE ON SCREEN

                      User taps → _advance()
                             │
                             ▼
                    Next tooltip in queue
                             │
                             ▼
                    When all done → reset()
```

---

## 17. QUICK REFERENCE CHEAT SHEET

```
CONCEPT                  WHAT IT IS                     WHERE IN CODE
─────────────────────────────────────────────────────────────────────────
RenderRepaintBoundary    Screenshot frame                capture_manager.dart:77
boundary.toImage()       Flutter built-in screenshot     capture_manager.dart:97
Uint8List                Raw bytes (0-255 per element)   capture_manager.dart:101
devicePixelRatio         Logical → physical px scale     capture_manager.dart:96
visitChildren()          Recursive element tree walk     capture_manager.dart:128
ValueKey<String>         Named widget for targeting      your screen widgets
localToGlobal()          Widget position on screen       capture_manager.dart:121
MethodChannel            Dart → Kotlin one-shot call     appstorys_flutter_method_channel.dart
EventChannel             Kotlin → Dart continuous push   appstorys_flutter_method_channel.dart:23
StateFlow                Kotlin reactive state holder    AppStorysCore.kt:82
.emit()                  Write new value to StateFlow    AppStorysCore.kt:314
.collect()               Subscribe to StateFlow changes  AppstorysFlutterPlugin.kt:51
sink.success()           Push event to Dart stream       AppstorysFlutterPlugin.kt:54
receiveBroadcastStream() Start listening on EventChannel method_channel.dart:29
asBroadcastStream()      Share one stream among many     appstorys_flutter.dart:41
OverlayEntry             Floating widget above all UI    tooltip_manager.dart:200
Overlay.of(ctx).insert() Show the floating widget        tooltip_manager.dart:262
CustomPaint/Painter      Raw canvas drawing              tooltip_manager.dart:493
PathFillType.evenOdd     Create hole/cutout in shape     tooltip_manager.dart:519
Positioned               Absolute position in a Stack    tooltip_manager.dart:219
withContext(Main)        Switch to UI thread in Kotlin   AppstorysFlutterPlugin.kt:53
pluginScope.launch       Background coroutine            AppstorysFlutterPlugin.kt:288
multipart/form-data      HTTP with mixed text+bytes      ApiClient.kt:409
formData { append() }    Build multipart body in Ktor    ApiClient.kt:411
```

---

## KEY ANALOGIES SUMMARY

```
CONCEPT             ANALOGY
──────────────────────────────────────────────────────────────
Widget tree         Architectural blueprint (static plan)
Element tree        House under construction (live, mutable)
Render tree         Physical measurement tape on every wall
RenderRepaintBoundary  Picture frame → everything inside = one bitmap
devicePixelRatio    Zoom multiplier on a retina screen
Uint8List           A file as a list of numbers (0-255 each)
MethodChannel       Phone call (Dart dials, Kotlin picks up, answers once)
EventChannel        Radio broadcast (Kotlin transmits, Dart listens)
StateFlow           Live scoreboard (always has current value, notifies all)
.collect()          Subscribing to the scoreboard updates
Stream              A river — data flows continuously when available
Polling             Repeatedly checking your mailbox every 5 min
Stream (vs polling) The mailbox calls YOU when a letter arrives
Overlay             A transparent sheet of glass floating above everything
OverlayEntry        Something drawn on that glass sheet
CustomPaint         A blank canvas with a paintbrush (draw anything)
PathFillType.evenOdd  Hole-punch: where two shapes overlap → transparent
ValueKey("btn")     A name tag stuck to a widget
localToGlobal()     Converting "3rd floor, room 5" → GPS coordinates
```

---

*Document covers: capture_manager.dart, tooltip_manager.dart,*
*appstorys_flutter_method_channel.dart, AppstorysFlutterPlugin.kt,*
*AppStorysCore.kt, ApiClient.kt*
