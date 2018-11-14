# Carthage

Carthage 只能指定单个仓库， 想要指定某个 Component 的指定版本，只能通过下载对应 Tag 的 Release 二进制包完成。

* 需要使用某个Component 就在 Cartfile 文件中指定对应的版本
* 如果需要同时使用多个Component， 则需要在 Cartfile.self 文件中依次指定；再调用 carthage.sh 脚本下载对应的 Framework 

* carthage.travis.yml 是 travis 自动发布 release 包的脚本