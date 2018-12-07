# HQFoundation

## 功能类
### 锁
iOS 中主要有三种锁：自旋锁 ~~`OSSpinLock`(由于[不安全](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)已经不推荐使用)~~ `os_unfair_lock` (iOS 10.0 +)、互斥锁 `pthread_mutex` 以及信号量 `DispatchSemaphore`

由于除了信号量之外的两种锁的使用都涉及一些指针的操作，因此针对锁的使用进行了一些封装；此外还使用 `Block` 包装了加锁&解锁的操作，简化开发中的使用

#### `HQLocking` 协议
定义了一些自动加锁解锁的方法 

```Swift
let lock = Mutex()
lock.autoLock {
    // do something ....
}
```

> DispatchSemaphore、 NSLock、NSRecursiveLock 都实现了该协议的方法

#### `Spin` 类
是对 `os_unfair_lock` 的封装，实现了 `NSLocking & HQLocking` 协议；iOS 10.0 以上可以使用

#### `Mutex` 类
是对 `pthread_mutex` 属性为 `PTHREAD_MUTEX_NORMAL` 的封装，实现了 `NSLocking & HQLocking` 协议

* `MutexRecursive` 是对 `pthread_mutex` 属性为 `PTHREAD_MUTEX_RECURSIVE` 的封装，是可递归锁
* `MutexError` `pthread_mutex` 属性为 `PTHREAD_MUTEX_ERRORCHECK` 的封装，加锁失败时会有错误信息

!> `MutexRecursive` 实质是 `NSRecursiveLock` 的类型别名；`MutexError` 是 `NSLock` 的类型别名

#### `Synchronized` 全局函数
OC 中可以通过 `@synchronized` 使用对象锁，但 Swift 需要使用 `objc_sync_enter & objc_sync_exit`

`Synchronized` 通过 Block 进行了封装，实现了和`@synchronized`同样的效果

### KeyChain
对 `KeyChain` 访问的简单封装类，实现了增删改查的方法

* `readItem` 通过 key 读取 value
* `readAllItems` 访问一个 group 下所有值
* `saveOrUpdateItem` 保存或更新值
* `renameItemKey` 重命名 key 名
* `delete` 删除键值对

## 扩展
### Collection
针对集合协议的扩展方法

* `func any(match predicate: (T.Iterator.Element) -> Bool) -> Bool`  检测集合中是否有符合条件的元素
* `func all(match predicate: (T.Iterator.Element) -> Bool) -> Bool`  检测集合中是否所有元素都符合条件

### Array
针对数组的扩展方法

* `func shuffle() -> T` 将数组的元素随机乱序后返回

### NSPointerArray
`NSPointerArray` 可以初始化时选择对内部元素是强引用还是弱引用。

它对元素的操作都是指针操作，因此对它的操作方法做了一些扩展封装，提供与普通 `Array` 类似的 API

### UIDevice
提供了一些常用设备信息的获取扩展

#### Device Info
* `deviceID`
* `deviceName`
* `deviceScreen`
* `deviceActiveDate`
* `ipAddressWIFI`
* `ipAddressCell`
* `isJailBroken`

#### Device Model
* `isPad`
* `isPhone`
* `isSimulator`
* `isTV`
* `isCarPlay`

#### Disk Info
* `diskSpace`
* `disSpaceFree`
* `diskSpaceUsed`

### DateFormatter
提供了一些常见时间格式的扩展方法

**日期**
* `func shortDateString(date: Date)`  e.g. "01/19/17"
* `func mediumDateString(date: Date)`  e.g. "Jan 19, 2017"
* `func longDateString(date: Date)`  e.g. "January 19, 2017"
* `func fullDateString(date: Date)`  e.g. "Thursday, January 19, 2017"

**时间**
* `func shortTimeString(date: Date)`  e.g. "5:30 PM"
* `func mediumTimeString(date: Date)`  e.g. "5:30:45 PM"
* `func longTimeString(date: Date)`  e.g. "5:30:45 PM PST"
* `func fullTimeString(date: Date)`  e.g. "5:30:45 PM PST"


### Date
提供了一些常见的日期判断属性

**天**
* `isToday`
* `isTomorrow`
* `isAfterTomorrow`
* `isYesterday`
* `isBeforeYesterday`
* `isWeekend`

**周**
* `isThisWeek`
* `isLastWeek`
* `isNextWeek`

**月**
* `isThisMonth`

**年**
* `isThisYear`

### Timer
从 `CFRunLoopTimer` 层面提供了一些定时器的扩展方法

#### 初始化方法
初始化方法创建的 `Timer` 需要手动添加到`Runloop` 中触发
* `func new(after interval: TimeInterval, _ block: @escaping () -> Void) -> Timer`  创建一个指定时间后执行的 Timer
* `new(every interval: TimeInterval, _ block: @escaping () -> Void) -> Timer`  创建一个指定时间重复执行的 Timer，第一次执行是在指定时间后

#### 触发方法
* `func start(runLoop: RunLoop = .current, modes: RunLoopMode...)`  将 `Timer` 添加到指定的 `Runloop` 

#### 工厂方法
工厂方法可以创建并触发 `Timer`

* `func after(_ interval: TimeInterval, _ block: @escaping () -> Void`
* `func every(_ interval: TimeInterval, _ block: @escaping () -> Void)`

### UIControl & UIGestureRecognizer & UIBarButtonItem
通过 `Block` 提供了简易的添加回调的扩展方法


