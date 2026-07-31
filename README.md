<div align="center">

  <h1>Bird IDE</h1>

  <p><b>A community-driven, fully native, cross-platform IDE for Flutter development — written in Flutter itself.</b></p>
  <p><b>⚡ Zero WebViews • Zero Monaco • Zero Electron ⚡</b></p>

  <p>
    <a href="#-overview">Overview</a> •
    <a href="#-key-features">Key Features</a> •
    <a href="#-tech-stack">Tech Stack</a> •
    <a href="#-getting-started">Getting Started</a> •
    <a href="#-roadmap">Roadmap</a> •
    <a href="#-contributing">Contributing</a> •
    <a href="#-license">License</a>
  </p>

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-^3.10.4-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)](#)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#-contributing)

</div>

---

## 🚀 Overview

**Bird IDE** is a modern, lightweight, and blazingly fast Integrated Development Environment designed specifically for Flutter developers.

Unlike traditional IDEs that rely on memory-heavy web shells (Electron), web code editors (Monaco), or embedded WebViews, **Bird IDE is 100% native**. Built completely in **Flutter**, Bird delivers pixel-perfect UI, smooth high-frame-rate performance, and minimal memory footprint across macOS, Linux, and Windows.

---

## ✨ Key Features

- 🏎️ **100% Native Performance**: Built natively with Flutter desktop without Electron, WebViews, or DOM overhead.
- 📝 **Advanced Code Editor**: Powered by [`code_forge`](https://pub.dev/packages/code_forge) and [`re_highlight`](https://pub.dev/packages/re_highlight) for rich syntax highlighting and code editing.
- 🗂️ **Multi-Tab Workspace**: Effortlessly open, manage, and switch between multiple source files with real-time state synchronization.
- 💻 **Integrated Terminal**: Embedded PTY terminal (`xterm` + `flutter_pty`) allowing native shell execution, running `flutter run`, and executing CLI commands directly inside the IDE.
- 📁 **Interactive File Explorer**: Full directory navigation, dynamic file type icons, and intuitive workspace management.
- 🎨 **Theme Engine & Dynamic Layouts**: Customizable dark/light UI themes, flexible pane splitters (`panes`), and custom titlebars.
- 🔌 **Extensible Design**: Architecture prepared for plugins and community extensions.
- ⌨️ **Native Shortcuts**: Built-in hotkeys for fast file opening, saving, tab switching, and editor operations.

---

## 🛠️ Tech Stack

| Component            | Technology / Library                                                                                                                                                  |
| :------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Framework**        | [Flutter Desktop](https://flutter.dev)                                                                                                                                |
| **Language**         | [Dart](https://dart.dev)                                                                                                                                              |
| **Editor Core**      | [`code_forge`](https://pub.dev/packages/code_forge) & [`re_highlight`](https://pub.dev/packages/re_highlight)                                                         |
| **Terminal**         | [`xterm`](https://pub.dev/packages/xterm) & [`flutter_pty`](https://pub.dev/packages/flutter_pty)                                                                     |
| **State Management** | [`provider`](https://pub.dev/packages/provider)                                                                                                                       |
| **Window & Layout**  | [`window_manager`](https://pub.dev/packages/window_manager) & [`panes`](https://pub.dev/packages/panes)                                                               |
| **Icons & Media**    | [`reicon_flutter`](https://pub.dev/packages/reicon_flutter), [`file_icon`](https://pub.dev/packages/file_icon), [`flutter_svg`](https://pub.dev/packages/flutter_svg) |

---

## 🚦 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.10.4` or later)
- Desktop build tools (Xcode for macOS, Visual Studio C++ for Windows, or build essentials / `clang` / `cmake` for Linux)

### Installation & Execution

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yakupkahraman/bird.git
   cd bird
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run Bird IDE locally:**

   ```bash
   # macOS
   flutter run -d macos

   # Linux
   flutter run -d linux

   # Windows
   flutter run -d windows
   ```

---

## 🗺️ Roadmap

- [ ] **Flutter LSP Integration**: Full Language Server Protocol support for Dart/Flutter auto-complete & diagnostics.
- [ ] **pub.dev Integration**: In-editor package search, version inspection, and one-click dependency management for `pubspec.yaml`.
- [ ] **Debugger Suite**: Built-in breakpoints, call stack inspection, and Dart DevTools integration.
- [ ] **Bundled Flutter SDK Management**: Built-in Flutter SDK version management, channel switching, and automated SDK setup.
- [ ] **Git Version Control Pane**: Visual diff viewer, branch switcher, and inline git status markers.
- [ ] **Extension Marketplace**: Community plugin system for custom themes, keybindings, and extensions.

---

## 🤝 Contributing

Contributions make the open-source community an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **GNU General Public License v3.0**. See [`LICENSE`](LICENSE) for details.

---

<div align="center">
  <sub>Built with ❤️ by Yakup Kahraman and the Flutter Community.</sub>
</div>
