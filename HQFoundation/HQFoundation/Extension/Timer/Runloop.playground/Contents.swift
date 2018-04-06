
import CoreFoundation

/*:
 # Runloop
 > 消息循环对象：在OSX/iOS 系统中，提供了两个这样的对象：NSRunLoop 和 CFRunLoopRef
 > * CFRunLoopRef 是在 CoreFoundation 框架内的，提供了纯 C 函数的 API，所有 API 都是线程安全的
 > * NSRunLoop 是基于 CFRunLoopRef 的封装，提供了面向对象的 API，这些 API 不是线程安全的
 */

/*:
 ## Runloop 与线程
 > CFRunLoop 是基于 pthread 来管理的；线程和 RunLoop 之间是一一对应的，它们保存在一个全局的 Dictionary 里。
 > 线程刚创建时并没有创建 RunLoop，Runloop 是懒加载的，如果不主动获取，那它一直都不会有。
 > RunLoop 的创建是发生在第一次获取时，RunLoop 的销毁是发生在线程结束时；只能在一个线程的内部获取其 RunLoop（主线程除外）。
 > 苹果不允许直接创建 RunLoop，它只提供了两个自动获取的函数：`CFRunLoopGetMain()` 和 `CFRunLoopGetCurrent()`
 */
let main = CFRunLoopGetMain() // main runloop
let current = CFRunLoopGetCurrent() // current thread runloop

// in main thread, main equal to current
main == current     // true


/*:
 ## CFRunloop
 > CoreFoundation 里面关于 RunLoop 有5个类
 > * CFRunloopRef
 > * CFRunLoopModeRef       // 没有对外暴露
 > * CFRunLoopSourceRef
 > * CFRunLoopTimerRef
 > * CFRunLoopObserverRef
 
 ![Runloop object relation ship](RunLoopRelationShip.png)
 
 * > CFRunLoopModeRef 没有对外暴露接口，只是通过 CFRunLoopRef 进行了封装；其中一个 RunLoop 包含若干个 Mode，每个 Mode 又包含若干个 Source/Timer/Observer。
 * > Source/Timer/Observer 被统称为 mode item，一个 item 可以被同时加入多个 mode。但一个 item 被重复加入同一个 mode 时是不会有效果的。如果一个 mode 中一个 item 都没有，则 RunLoop 会直接退出，不进入循环
 * > 每次调用 RunLoop 的主函数时，只能指定其中一个 Mode，这个Mode被称作 CurrentMode。如果需要切换 Mode，只能退出 Loop，再重新指定一个 Mode 进入。这样做主要是为了分隔开不同组的 Source/Timer/Observer，让其互不影响。
 
 CFRunloopMode:
 ```objc
 struct __CFRunLoopMode {
    CFStringRef _name;            // Mode Name, 例如 @"kCFRunLoopDefaultMode"
    CFMutableSetRef _sources0;    // Set
    CFMutableSetRef _sources1;    // Set
    CFMutableArrayRef _observers; // Array
    CFMutableArrayRef _timers;    // Array
    ...
 }
 ```
 
 CFRunloop:
 ```objc
 struct __CFRunLoop {
     CFMutableSetRef _commonModes;     // Set
     CFMutableSetRef _commonModeItems; // Set<Source/Observer/Timer>
     CFRunLoopModeRef _currentMode;    // Current Runloop Mode
     CFMutableSetRef _modes;           // Set
     ...
 };
 ```
 
 #### CommonModes
 > 有个概念叫 “CommonModes”：一个 Mode 可以将自己标记为”Common”属性（通过将其 ModeName 添加到 RunLoop 的 “commonModes” 中）。每当 RunLoop 的内容发生变化时，RunLoop 都会自动将 _commonModeItems 里的 Source/Observer/Timer 同步到具有 “Common” 标记的所有Mode里
 > * 应用场景举例：主线程的 RunLoop 里有两个预置的 Mode：kCFRunLoopDefaultMode 和 UITrackingRunLoopMode。这两个 Mode 都已经被标记为”Common”属性。DefaultMode 是 App 平时所处的状态，TrackingRunLoopMode 是追踪 ScrollView 滑动时的状态。当你创建一个 Timer 并加到 DefaultMode 时，Timer 会得到重复回调，但此时滑动一个TableView时，RunLoop 会将 mode 切换为 TrackingRunLoopMode，这时 Timer 就不会被回调，并且也不会影响到滑动操作。
 > * 有时需要一个 Timer，在两个 Mode 中都能得到回调，一种办法就是将这个 Timer 分别加入这两个 Mode。还有一种方式，就是将 Timer 加入到顶层的 RunLoop 的 “commonModeItems” 中。”commonModeItems” 被 RunLoop 自动更新到所有具有”Common”属性的 Mode 里去。
 
 #### CFRunLoop对外暴露的管理 Mode 接口
 * `CFRunLoopAddCommonMode(CFRunLoopRef runloop, CFStringRef modeName);` // 添加到commonMode
 * `CFRunLoopRunInMode(CFStringRef modeName, ...);`
 
 #### Mode 暴露的管理 mode item 的接口
 * `CFRunLoopAddSource(CFRunLoopRef rl, CFRunLoopSourceRef source, CFStringRef modeName);`
 * `CFRunLoopAddObserver(CFRunLoopRef rl, CFRunLoopObserverRef observer, CFStringRef modeName);`
 * `CFRunLoopAddTimer(CFRunLoopRef rl, CFRunLoopTimerRef timer, CFStringRef mode);`
 * `CFRunLoopRemoveSource(CFRunLoopRef rl, CFRunLoopSourceRef source, CFStringRef modeName);`
 * `CFRunLoopRemoveObserver(CFRunLoopRef rl, CFRunLoopObserverRef observer, CFStringRef modeName);`
 * `CFRunLoopRemoveTimer(CFRunLoopRef rl, CFRunLoopTimerRef timer, CFStringRef mode);`
 
 > 只能通过 mode name 来操作内部的 mode，当你传入一个新的 mode name 但 RunLoop 内部没有对应 mode 时，RunLoop会自动帮你创建对应的 CFRunLoopModeRef。对于一个 RunLoop 来说，其内部的 mode 只能增加不能删除
 > * 苹果公开提供的 Mode 有两个：kCFRunLoopDefaultMode (NSDefaultRunLoopMode) 和 UITrackingRunLoopMode
 > * 苹果还提供了一个操作 Common 标记的字符串：kCFRunLoopCommonModes (NSRunLoopCommonModes)，你可以用这个字符串来操作 Common Items，或标记一个 Mode 为 “Common”。
 */

/*:
 ### CFRunLoopSourceRef
 > 是事件的根源；Source分为 Source0 和 Source1
 
 #### Source0
 > Source0 只包含了一个回调（函数指针），它并不能主动触发事件。使用时，你需要先调用 CFRunLoopSourceSignal(source)，将这个 Source 标记为待处理，然后手动调用 CFRunLoopWakeUp(runloop) 来唤醒 RunLoop，让其处理这个事件
 
 #### Source1
 > Source1 包含了一个 mach_port 和一个回调（函数指针），被用于通过内核和其他线程相互发送消息。这种 Source 能主动唤醒 RunLoop 的线程
 */

/*:
 ### CFRunLoopTimerRef
 > 基于时间的触发器，它和 NSTimer 是toll-free bridged 的，可以混用。其包含一个时间长度和一个回调（函数指针）。当其加入到 RunLoop 时，RunLoop会注册对应的时间点，当时间点到时，RunLoop会被唤醒以执行那个回调
 */

/*:
 ### CFRunLoopObserverRef
 > 观察者，每个 Observer 都包含了一个回调（函数指针），当 RunLoop 的状态发生变化时，观察者就能通过回调接受到这个变化。
 
 可以观测的时间点有
 ```objc
 typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
     kCFRunLoopEntry         = (1UL << 0), // 即将进入Loop
     kCFRunLoopBeforeTimers  = (1UL << 1), // 即将处理 Timer
     kCFRunLoopBeforeSources = (1UL << 2), // 即将处理 Source
     kCFRunLoopBeforeWaiting = (1UL << 5), // 即将进入休眠
     kCFRunLoopAfterWaiting  = (1UL << 6), // 刚从休眠中唤醒
     kCFRunLoopExit          = (1UL << 7), // 即将退出Loop
 };
 ```
 */
