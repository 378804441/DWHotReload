# DWBaseAdapter

[![CI Status](https://img.shields.io/travis/378804441@qq.com/DWBaseAdapter.svg?style=flat)](https://travis-ci.org/378804441@qq.com/DWBaseAdapter)
[![Version](https://img.shields.io/cocoapods/v/DWBaseAdapter.svg?style=flat)](https://cocoapods.org/pods/DWBaseAdapter)
[![License](https://img.shields.io/cocoapods/l/DWBaseAdapter.svg?style=flat)](https://cocoapods.org/pods/DWBaseAdapter)
[![Platform](https://img.shields.io/cocoapods/p/DWBaseAdapter.svg?style=flat)](https://cocoapods.org/pods/DWBaseAdapter)

## Example

项目写着写着会，控制器层会越来越臃肿。
项目里99%的场景基础打底控件都可以通过tableView 来解决。
该框架就是 将控制器里的tableView dataSource 拆分出独立模块， 通过数据源驱动方式来进行模块化编程。
框架支持Cell高度的缓存, 面向协议做的tableView delegate 拆分等公共能, 可以让使用者专注于数据源的更改。


## pod集成

```ruby
pod 'DWBaseAdapter', :git => "https://github.com/378804441/DWAdapter.git"
```

