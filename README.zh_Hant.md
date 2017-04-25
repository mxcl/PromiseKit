![PromiseKit](http://promisekit.org/public/img/logo-tight.png)

![badge-pod] ![badge-languages] ![badge-pms] ![badge-platforms] ![badge-mit]

[English](README.markdown)

---

現今的程式開發大量使用非同步存取, 難道不正是時候該開始考慮使用合適的工具讓非同步程式更加的強大, 易用, 並且使用愉快?

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
PromiseKit 是一個使用 Swift 語言完整實作 Promise 概念的工具套件. 除了能夠完美的和現有的 Objective-C 程式進行整合之外, 也支援多個不同平台, 如, iOS, macOS, tvOs 以及 watchOS.

# 快速入門

我們推薦使用  [CocoaPods] 或 [Carthage] 等套件管理程式來進行安裝. 如不使用套件管理程式安裝, 也可以手動下載相關程式, 並把 `PromiseKit.xcodeproj` 拖曳加入您的專案中, 並將 `PromiseKit.framework` 加入. 

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

# 相關文件

您可以在 [promisekit.org] 查詢完整的相關文件.

## 總覽

使用 `then` 定義非同步的執行任務：

```swift
login().then { json in
    //…
}
```

鏈結使用：

```swift
login().then { json -> Promise<UIImage> in
    return fetchAvatar(json["username"])
}.then { avatarImage in
    self.imageView.image = avatarImage
}
```

串連式的錯誤/例外處理：

```swift
login().then {
    return fetchAvatar()
}.then { avatarImage in
    //…
}.catch { error in
    UIAlertView(/*…*/).show()
}
```

組合應用：

```swift
let username = login().then{ $0["username"] }

when(username, CLLocationManager.promise()).then { user, location in
    return fetchAvatar(user, location: location)
}.then { image in
    //…
}
```

毫無難度的重構：

```swift
func avatar() -> Promise<UIImage> {
    let username = login().then{ $0["username"] }

    return when(username, CLLocationManager.promise()).then { user, location in
        return fetchAvatar(user, location: location)
    }
}
```

您可以輕易地建構一個非同步任務：

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

## 更多詳細用法

您可以透過 [promisekit.org] 學習更多完整的用法. 

## PromiseKit vs. Xcode

PromiseKit 使用 Swift 進行開發, 下表列出 Xcode 以及 Swifit 的相關對應版本：

| Swift | Xcode | PromiseKit |   CI Status  |   Release Notes   |
| ----- | ----- | ---------- | ------------ | ----------------- |
|   3   |   8   |      4     | ![ci-master] | [2016/09][news-4] |
|   2   |  7/8  |      3     | ![ci-swift2] | [2015/10][news-3] |
|   1   |   7   |      3     |       –      | [2015/10][news-3] |
| *N/A* |   *   |      1†    | ![ci-legacy] |         –         |

† PromiseKit 1 使用純粹的 Objective-C 進行開發，因此可以在任意的 Xcode 版本中使用，若您需要支援 iOS7 或者更低版本時, 只能選擇使用 PromiseKit 1。

---

我們同時維護了一些分支來協助您做不同 Swift 版本間的移植：

| Xcode | Swift | PromiseKit | Branch                      | CI Status |
| ----- | ----- | -----------| --------------------------- | --------- |
|  8.0  |  2.3  | 2          | [swift-2.3-minimal-changes] | ![ci-23]  |
|  7.3  |  2.2  | 2          | [swift-2.2-minimal-changes] | ![ci-22]  |
|  7.2  |  2.2  | 2          | [swift-2.2-minimal-changes] | ![ci-22]  |
|  7.1  |  2.1  | 2          | [swift-2.0-minimal-changes] | ![ci-20]  |
|  7.0  |  2.0  | 2          | [swift-2.0-minimal-changes] | ![ci-20]  |

我們通常**不會**再對上述的分支進行維護, 但如果有任何的 PR 我們也歡迎提交.

# 相關擴充

Promises 僅對執行非同步任務非常有用, 因此我們把 Apple 絕大部份的 API 轉換成 Promises. 透過 CocoaPod 導入套件時即預設帶入 UIKit 和 Foundation, 而其他框架需要在您的 `Podfile` 檔案中進行額外的設定, 例如：

```ruby
pod "PromiseKit/MapKit"        # MKDirections().promise().then { /*…*/ }
pod "PromiseKit/CoreLocation"  # CLLocationManager.promise().then { /*…*/ }
```
我們所有相關的擴充專案可以到  [PromiseKit org ](https://github.com/PromiseKit) 查詢.

使用 `Cartfile` 進行設定：

```ruby
github "PromiseKit/MapKit" ~> 1.0
```

## 選擇使用網路相關函式庫

`URLSession` 一般來說很難勝任複雜的網路存取相關任務; 建議使用 [Alamofire] 或者  [OMGHTTPURLRQ]:

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
針對使用 [AFNetworking] 的開發者, 我們推薦使用 [csotiriou/AFNetworking].

# 有轉換您現有的程式碼到 Promises 的需求嗎?

[與我聯繫](mailto:mxcl@me.com), 我在 iOS 上使用 Promises 進行開發已經有多年的經驗, 同時也有 10 年以上開發行動裝置 App 的經驗.

# 支援

可以在 [Gitter chat channel](https://gitter.im/mxcl/PromiseKit) 詢問相關問題, 或者直接追蹤我們的 [bug tracker](https://github.com/mxcl/PromiseKit/issues/new) 


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
