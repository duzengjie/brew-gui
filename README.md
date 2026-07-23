# Brew GUI

Brew GUI 是一个面向 macOS 的原生 SwiftUI 应用，用来图形化管理常见的 Homebrew 工作流。

## 功能

- 搜索 formula 和 cask：`brew search TEXT` 或 `brew search /REGEX/`
- 查看软件包详情：`brew info`
- 安装、升级、卸载和列出 formula 或 cask
- 执行日常维护命令：`brew update`、`brew upgrade`、`brew config`、`brew doctor`
- 执行高级命令：`brew install --verbose --debug`、`brew create`、`brew edit`
- 在应用内实时显示命令输出，并保留命令历史
- 支持跟随 macOS「系统设置」中的应用语言偏好，内置英文和简体中文
- 已接入自定义 macOS 应用图标

## 从源码运行

```sh
swift run BrewGUI
```

## 构建 macOS 应用包

```sh
./scripts/build-app.sh
open .build/app/BrewGUI.app
```

构建完成后，应用会生成在：

```text
.build/app/BrewGUI.app
```

## Homebrew 路径

应用会按下面的顺序查找 `brew` 可执行文件：

- `/opt/homebrew/bin/brew`
- `/usr/local/bin/brew`
- 当前进程 `PATH` 中的 `brew`

## 多语言

应用使用原生 macOS 本地化机制。切换语言的方式：

1. 打开 macOS「系统设置」
2. 进入「通用」
3. 进入「语言与地区」
4. 在「应用程序」里为 Brew GUI 设置语言
5. 重启 Brew GUI

当前内置语言：

- English
- 简体中文

## 图标

当前应用图标位于：

```text
Sources/BrewGUI/Resources/AppIcon.icns
```

图标设计稿和导出过程位于：

```text
design/brew-gui-icon-options/
```

## 实现说明

应用通过 `Process` 直接调用 `brew`，并使用结构化参数数组传参。它不会把用户输入拼接成 shell 命令字符串。

## 验证

```sh
swift test
swift build -c release
./scripts/build-app.sh
plutil -lint .build/app/BrewGUI.app/Contents/Info.plist
```
