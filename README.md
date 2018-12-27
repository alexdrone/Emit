

# Emit [![Swift](https://img.shields.io/badge/swift-4.2-orange.svg?style=flat)](#) [![Platform](https://img.shields.io/badge/platform-iOS|macOS-lightgrey.svg?style=flat)](#)
Event propagation and object observation library.

### Installing the framework

```
cd {PROJECT_ROOT_DIRECTORY}
curl "https://raw.githubusercontent.com/alexdrone/Emit/master/bin/dist.zip" > dist.zip && unzip dist.zip && rm dist.zip;
```

Drag `Emit.framework` in your project and add it as an embedded binary.

If you use [xcodegen](https://github.com/yonaskolb/XcodeGen) add the framework to your *project.yml* like so:

```
targets:
  YOUR_APP_TARGET:
    ...
    dependencies:
      - framework: PATH/TO/YOUR/DEPS/Emit.framework
```
