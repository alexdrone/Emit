apple_library(
  name = 'Observable',
  visibility = ['PUBLIC'],
  preprocessor_flags = ['-D', 'PRODUCT_NAME=Observable'],
  exported_headers = glob([
    'src/**/*.h'
  ]),
  srcs = glob([
    'src/**/*.swift',
  ]), 
)

apple_resource(
    name = 'DemoResources',
    dirs = [],
    files = glob(['res/**/*']),
)

apple_binary(
    name = 'DemoBinary',
    srcs = glob(['demo/src/*.swift']),
    deps = [':Observable'],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$SDKROOT/System/Library/Frameworks/UIKit.framework',
    ],
)

apple_bundle(
    name = 'DemoApp',
    binary = ':DemoBinary',
    deps = [':DemoResources'],
    extension = 'app',
    info_plist = 'demo/src/Info.plist',
)
