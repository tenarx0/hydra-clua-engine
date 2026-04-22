# Hydra C-Lua Engine

![Lua 5.5](https://img.shields.io/badge/Lua-5.5-blue.svg)
![C++20 NDK](https://img.shields.io/badge/C%2B%2B20-NDK-green.svg)
![Platform](https://img.shields.io/badge/Platform-Android-lightgrey.svg)
![License](https://img.shields.io/badge/License-Proprietary-red.svg)

Compiled release artifacts for the Hydra C-Lua Engine.

The Hydra C-Lua Engine source code is proprietary and closed-source. This repository serves exclusively as the distribution hub for pre-compiled binaries, allowing developers to integrate the engine into Android projects manually or via the Hydra CLua IDE.

---

## Technical Overview

The Hydra C-Lua Engine is a bare-metal, high-performance Lua 5.5 runtime explicitly engineered for Android. Powered by C++20, it bypasses standard JVM bottlenecks to deliver hardware-accelerated performance, exposing a zero-overhead native bridge that allows Android applications to execute Lua scripts with full access to the Android OS.

### Core Subsystems
* **Dynamic JNI Reflection:** Instantly instantiate Java classes, invoke methods, and marshal data types between Lua and Java with automatic, GC-bound memory management. ETC...
* **Hardware-Accelerated UI:** A complete declarative layout engine featuring reactive state bindings, Vsync-synchronized render loops (Choreographer), and zero-allocation Canvas drawing. ETC...
* **Low-Latency Multimedia:** Native integration with Android's NDK Camera2 API for zero-copy YUV streaming and the AAudio engine for high-performance procedural sound generation. ETC...
* **Asynchronous Isolates:** True background processing. Offload heavy computation to C++ worker threads using Lua coroutines without blocking the Main UI Thread. ETC...
* **Advanced Security:** Built-in POSIX-level anti-tamper mechanisms, including memory locking, scanning for instrumentation frameworks, and root detection. ETC...

---

## Release Contents

Each release ZIP (`lua_engine.zip`) contains the core Dalvik Executables and the compiled native shared libraries for all major Android ABIs:

```text
lua_engine.zip
├── classes.dex                  <- Java/Kotlin bridge and UI proxies
├── classes2.dex
└── lib/
    ├── arm64-v8a/
    │   └── libhydra_loader.so   <- Native Lua engine (C++, ARM64)
    ├── armeabi-v7a/
    │   └── libhydra_loader.so   <- Native Lua engine (C++, ARM32)
    ├── x86/
    │   └── libhydra_loader.so   <- Native Lua engine (C++, x86 Emulator)
    └── x86_64/
        └── libhydra_loader.so   <- Native Lua engine (C++, x86_64 Emulator)
```

---

## Integration Guide

### Option A: Hydra CLua IDE (Automatic)
If you are building your application using the Hydra CLua IDE, the engine is bundled and injected automatically during the build pipeline. No manual steps are required.

### Option B: Manual Android Project Inclusion
To integrate the engine into a standard Android Studio or Gradle project:

1. **Download** the latest `lua_engine.zip` from the Releases page.
2. **Extract** the archive to your local environment.
3. **Merge DEX Files:** Include `classes.dex` and `classes2.dex` into your project's build path or load them dynamically via a custom `DexClassLoader`.
4. **Link Native Libraries:** Copy the extracted `lib/` directory contents into your project's native library directory, typically located at: `app/src/main/jniLibs/`

---

## Versioning

Releases adhere strictly to Semantic Versioning (`vMAJOR.MINOR.PATCH`).

Please refer to the Releases tab for the latest version, binary downloads, and detailed changelogs.

---

## License & Copyright

**Copyright (c) 2026 @tenarx0. All rights reserved.**

The compiled binaries distributed in this repository are provided for free use in any commercial or non-commercial Android application.

**Restrictions:**
* **Redistribution of the source code is strictly prohibited.** The engine's internal implementation is proprietary intellectual property owned entirely by @tenarx0.
* You may embed, ship, and utilize the compiled artifacts (`.so` and `.dex` files) within your applications without restriction.
* You may **not** decompile, reverse-engineer, modify, or attempt to extract the source code of the native libraries or the accompanying DEX files.

---

## Support & Source Code

The source code for the Hydra C-Lua Engine is maintained in a secure, private repository and is not publicly accessible. 

For bug reports, feature requests, integration assistance, or enterprise licensing inquiries, please open an Issue in this repository.