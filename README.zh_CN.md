![PromiseKit](http://promisekit.org/public/img/logo-tight.png)

![badge-pod] ![badge-languages] ![badge-pms] ![badge-platforms] ![badge-mit]

[English](README.markdown)

---

现代编程语言都很好的支持了异步编程，因此在 swift 编程中，拥有功能强大且轻量级的异步编程工具的需求变得很强烈。

```swift
UIApplication.shared.isNetworkActivityIndicatorVisible = true

firstly {
    when(URLSession.dataTask(with: url).asImage(), CLLocationManager.promise())
}.then { image, location -> Void in
    self.imageView.image = image;
    self.label.text = "\(location)"
}.always {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
}.catch { error in
    UIAlertView(/*…*/).show()
}
```
PromiseKit 是一款 swift 编写的支持 iOS，macOS，tvOS，watchOS 等多平台的轻量级异步编程库，同时 PromiseKit 完美的支持了 Objective-C 桥接。

# 快速预览

我们推荐您使用 [CocoaPods] 或者 [Carthage] 来集成 ProkiseKit，您也可以通过把 `PromiseKit.xcodeproj` 拖拽到项目中并导入 `PromiseKit.framework` 来手动集成。

## Xcode 8 / Swift 3

```ruby
# CocoaPods >= 1.1.0-rc.2
swift_version = "3.0"
pod "PromiseKit", "~> 4.0"

# Carthage
github "mxcl/PromiseKit" ~> 4.0

# SwiftPM
let package = Package(
    dependencies: [
        .Package(url: "https://github.com/mxcl/PromiseKit", majorVersion: 4)
    ]
)
```

## Xcode 8 / Swift 2.3 or Xcode 7

```ruby
# CocoaPods
swift_version = "2.3"
pod "PromiseKit", "~> 3.5"

# Carthage
github "mxcl/PromiseKit" ~> 3.5
```

# 文档

您可以通过 [promisekit.org] 站点来查看全部文档

## 概览

在 `then` 方法中定义异步任务：

```swift
login().then { json in
    //…
}
```

链式调用：

```swift
login().then { json -> Promise<UIImage> in
    return fetchAvatar(json["username"])
}.then { avatarImage in
    self.imageView.image = avatarImage
}
```

`catch` 链式调用进行错误处理：

```swift
login().then {
    return fetchAvatar()
}.then { avatarImage in
    //…
}.catch { error in
    UIAlertView(/*…*/).show()
}
```

组合调用：

```swift
let username = login().then{ $0["username"] }

when(username, CLLocationManager.promise()).then { user, location in
    return fetchAvatar(user, location: location)
}.then { image in
    //…
}
```

简单重构：

```swift
func avatar() -> Promise<UIImage> {
    let username = login().then{ $0["username"] }

    return when(username, CLLocationManager.promise()).then { user, location in
        return fetchAvatar(user, location: location)
    }
}
```

您也可以创建一个新的异步任务：

```swift
func fetchAvatar(user: String) -> Promise<UIImage> {
    return Promise { fulfill, reject in
        MyWebHelper.GET("\(user)/avatar") { data, err in
            guard let data = data else { return reject(err) }
            guard let img = UIImage(data: data) else { return reject(MyError.InvalidImage) }
            guard let img.size.width > 0 else { return reject(MyError.ImageTooSmall) }
            fulfill(img)
        }
    }
}
```

## 更多用法

您可以通过 [promisekit.org] 站点获得更多用法。

## PromiseKit vs. Xcode

由于 Xcode 支持不同版本的 swift，下面是 PromiseKit 与 Xcode 的对应关系：

| Swift | Xcode | PromiseKit |   CI Status  |   Release Notes   |
| ----- | ----- | ---------- | ------------ | ----------------- |
|   3   |   8   |      4     | ![ci-master] | [2016/09][news-4] |
|   2   |  7/8  |      3     | ![ci-swift2] | [2015/10][news-3] |
|   1   |   7   |      3     |       –      | [2015/10][news-3] |
| *N/A* |   *   |      1†    | ![ci-legacy] |         –         |

† PromiseKit 1 是纯 Objective-C 开发的，因此您可以在 Xcode 的任何版本中使用，当需要支持 iOS 7 或更低版本时只能选择 PromiseKit 1。

---

我们同时维护了一些分支来帮助您做 Swift 版本间的移植：


| Xcode | Swift | PromiseKit | Branch                      | CI Status |
| ----- | ----- | -----------| --------------------------- | --------- |
|  8.0  |  2.3  | 2          | [swift-2.3-minimal-changes] | ![ci-23]  |
|  7.3  |  2.2  | 2          | [swift-2.2-minimal-changes] | ![ci-22]  |
|  7.2  |  2.2  | 2          | [swift-2.2-minimal-changes] | ![ci-22]  |
|  7.1  |  2.1  | 2          | [swift-2.0-minimal-changes] | ![ci-20]  |
|  7.0  |  2.0  | 2          | [swift-2.0-minimal-changes] | ![ci-20]  |

我们通常不会再对这些分支做维护，但同样欢迎提交 PR。

# 扩展

Promises 仅在执行异步任务时非常有用，因此我们把苹果绝大部分接口都转换成了异步任务。当导入 Promises 时已经默认包含了 UIKit 和 Foundation。其他框架需要在 `Podfile` 中单独声明：

```ruby
pod "PromiseKit/MapKit"        # MKDirections().promise().then { /*…*/ }
pod "PromiseKit/CoreLocation"  # CLLocationManager.promise().then { /*…*/ }
```

扩展的所有 repo 请访问 [PromiseKit org ](https://github.com/PromiseKit)。

在 `Cartfile` 中声明：

```ruby
github "PromiseKit/MapKit" ~> 1.0
```

## 选择网络库

直接使用 `NSURLSession` 通常是不可取的，您可以选择使用 [Alamofire] or [OMGHTTPURLRQ]:

```swift
// pod 'PromiseKit/Alamofire'  
Alamofire.request("http://example.com", withMethod: .GET).responseJSON().then { json in
    //…
}.catch { error in
    //…
}

// pod 'PromiseKit/OMGHTTPURLRQ'
URLSession.GET("http://example.com").asDictionary().then { json in
    
}.catch { error in
    //…
}
```
[AFNetworking] 我们推荐使用 [csotiriou/AFNetworking]。

# 需要将您的代码转换到 Promises?

[有偿帮助](mailto:mxcl@me.com)，我有几年 Promises 编码经验并在移动开发领域已有 10 年的开发经验。

# 支持 

如果您有任何问题可以访问 [Gitter chat channel](https://gitter.im/mxcl/PromiseKit)，也可以进行 [bug 追踪](https://github.com/mxcl/PromiseKit/issues/new)


[travis]: https://travis-ci.org/mxcl/PromiseKit
[ci-master]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=master
[ci-legacy]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=legacy-1.x
[ci-swift2]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.x
[ci-23]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.3-minimal-changes
[ci-22]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.2-minimal-changes
[ci-20]: https://travis-ci.org/mxcl/PromiseKit.svg?branch=swift-2.0-minimal-changes
[news-2]: http://promisekit.org/news/2015/05/PromiseKit-2.0-Released/
[news-3]: https://github.com/mxcl/PromiseKit/blob/master/CHANGELOG.markdown#300-oct-1st-2015
[news-4]: http://promisekit.org/news/2016/09/PromiseKit-4.0-Released/
[swift-2.3-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.3-minimal-changes
[swift-2.2-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.2-minimal-changes
[swift-2.0-minimal-changes]: https://github.com/mxcl/PromiseKit/tree/swift-2.0-minimal-changes
[promisekit.org]: http://promisekit.org/docs/
[badge-pod]: https://img.shields.io/cocoapods/v/PromiseKit.svg?label=version
[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg
[badge-languages]: https://img.shields.io/badge/languages-Swift%20%7C%20ObjC-orange.svg
[badge-mit]: https://img.shields.io/badge/license-MIT-blue.svg
[badge-pms]: https://img.shields.io/badge/supports-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-green.svg
[OMGHTTPURLRQ]: https://github.com/mxcl/OMGHTTPURLRQ
[Alamofire]: http://alamofire.org
[AFNetworking]: https://github.com/AFNetworking/AFNetworking
[csotiriou/AFNetworking]: https://github.com/csotiriou/AFNetworking-PromiseKit
[CocoaPods]: http://cocoapods.org
[Carthage]: 2016-09-05-PromiseKit-4.0-Released
