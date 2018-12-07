# 安装指南
HIComponents 是一个个独立的 Framework，你可以只安装你需要的那个 Framework。

## 版本依赖
HIComponents 是一个纯 Swift 的库，目前只支持在 iOS 平台上使用，语言层面从 swift 3 开始支持，系统版本上从 9.0 开始。

## 载入方式
### CocoaPods
CocoaPods 是一个 iOS 平台的包管理软件，可以自动管理依赖等。
由于 HIComponents 内部存在依赖，所以推荐使用这种方式管理，能减少很多流程。
对于更多关于 CocoaPods 的使用方式，推荐阅读这个[指南](https://www.raywenderlich.com/626-cocoapods-tutorial-for-swift-getting-started)

只需要将 HIComponents 中所需要的 Framework 添加到项目中的 `Podfile` 文件中即可

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target 'YourApp' do
  # your other pod
  pod 'HQFoundation', '~> 1.0'
  pod 'HQKit', '~> 1.0'
  # ...

end
```

### Carthage
Carthage 是一种新的 Cocoa 项目管理工具，对比 Cocoapods，它对项目的侵入性更小，相对的，你需要手动的添加 Framework 到项目中。
由于 HIComponents 中的所有 Framework 都存储在同一个 Repo 中，所以使用 Carthage 会有问题，针对这一情况，你需要使用我提供的脚本来辅助 Carthage 下载，同时你需要使用 release 分支中已经编译完成的 Carthage 压缩包来使用

## 使用
在将 Framework 导入到项目中之后，只需要 import 对应的包即可

```swift
import HQFoundation
```

