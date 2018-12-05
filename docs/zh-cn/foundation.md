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

