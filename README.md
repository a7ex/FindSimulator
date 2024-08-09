# FindSimulator

## Overview
Use simctl to find UDIDs of Xcode simulators to be used as 'destination' parameter in xcodebuild.

Get the 'destination' specifier of the first available simulator, which matches the query.

Specify whether to search for 'iOS', 'watchOS' or 'tvOS' simulators. Default is 'iOS'.
You can also specify a major and minor version of the OS, you want to target or specify 'latest' to get the latest and greatest.

There is also an option to list all matches along with all informations.
Be aware, that the list output contains values for 'id' AND 'name'.
As 'destination' for ```xcodebuild``` they are mutually exclusive.

You can also find iPhone simulators with paired watches.

## How to use it
The tool doesn't create any file. It justs outputs its results to standard out.
You can store the result in a shell variable:
```
destination=$(findsimulator --os-type ios --major-os-version latest iPhone)
xcrun xcodebuild test -workspace MyApp.xcworkspace -scheme MyApp -destination "$destination"
```

## Examples
First match for iOS simulator (default) with the latest OS version (default) and containing 'iPhone 1' in it's name.
```
findsimulator "iPhone 1"
// platform=iOS Simulator,id=65213250-02E8-4FB2-8F75-F75C01430A57
```
List all iOS simulators (default) with the latest OS version (default) and containing 'iPhone 1' in their name.
```
findsimulator -l "iPhone 1"
//platform=iOS Simulator,OS=15.4,id=65213250-02E8-4FB2-8F75-F75C01430A57,name=iPhone 13 mini
//...
//platform=iOS Simulator,OS=15.2,id=52B96F75-49C1-4EF0-BDD3-D205E448E468,name=iPhone 13 mini
//platform=iOS Simulator,OS=15.2,id=BB3CDAEF-EE05-463A-9D5E-D714F83D274D,name=iPhone 13 Pro Max
//platform=iOS Simulator,OS=15.2,id=1328ADB6-4229-4E27-A9E3-56FEFFFF0117,name=iPhone 13 Pro
```
Without the '--list-all|-l' flag the first match of the result with the '-l' flag is returned.
So that you always get the same simulator, without the '-l' flag.

A regular expression can further describe the device.
E.g. list only devices which END on the string "Pro" ($ => end of match). Only Pro devices, not Pro Max devices:
```
findsimulator -l -r "Pro$"
// platform=iOS Simulator,OS=17.5,id=D2E4C979-FFEA-4236-9F57-64C3209975A0,name=iPhone 15 Pro
// platform=iOS Simulator,OS=17.4,id=D135ADE1-6924-4D28-86F7-E11D5C03D60B,name=iPhone 15 Pro
// platform=iOS Simulator,OS=15.5,id=3A259DB0-3824-4AD1-B883-3250FF134CE3,name=iPhone 13 Pro
```
list only devices which END on the string "Pro" ($ => end of match) and contain the string 13 or 23 or 33, etc. in their name:
```
findsimulator -l -r "\d3\sPro$"
// platform=iOS Simulator,OS=15.5,id=3A259DB0-3824-4AD1-B883-3250FF134CE3,name=iPhone 13 Pro
```
You get the picture...

Simulators with watchOS 8 and minor version 'latest':
```
findsimulator -o watchOS -m 8 -s latest --list-all
// platform=watchOS Simulator,OS=8.5,id=5E86FE91-B033-4675-A399-65D9BF8DE055,name=Apple Watch Series 7 - 45mm
// platform=watchOS Simulator,OS=8.5,id=20E3510B-4955-42E2-B986-27FC47D61389,name=Apple Watch Series 7 - 41mm
// platform=watchOS Simulator,OS=8.5,id=6825047D-B5E9-4DFE-AEB5-BC6ADE089404,name=Apple Watch Series 6 - 44mm
// platform=watchOS Simulator,OS=8.5,id=C549ADA0-F294-49A8-B63B-6335C5F4B75C,name=Apple Watch Series 6 - 40mm
// platform=watchOS Simulator,OS=8.5,id=B56A7F31-8597-4E9F-842B-9D1706B1AD63,name=Apple Watch Series 5 - 44mm
// platform=watchOS Simulator,OS=8.5,id=84E856B2-2B8D-46E3-B254-9EAED4AD36C3,name=Apple Watch Series 5 - 40mm
```

Simulators with latest watchOS containing "Series 5" in their name:
```
findsimulator -o watchOS "Series 5" --list-all
// platform=watchOS Simulator,OS=8.5,id=B56A7F31-8597-4E9F-842B-9D1706B1AD63,name=Apple Watch Series 5 - 44mm
// platform=watchOS Simulator,OS=8.5,id=84E856B2-2B8D-46E3-B254-9EAED4AD36C3,name=Apple Watch Series 5 - 40mm
```

## How to get it
### Using homebrew
```
brew tap a7ex/homebrew-formulae
brew install findsimulator
```
### Build from source
- Clone the repository / Download the source code
- Run `swift build -c release` to build `findsimulator` executable
- Run `open .build/release` to open directory containing the executable file in Finder
- Drag `findsimulator` executable from the Finder window to your desktop

## How to install it
### Using homebrew
```
brew tap a7ex/homebrew-formulae
brew install findsimulator
```
### Downloaded binary
Assuming that the `findsimulator` app is on your desktop…

Open a Terminal window and run this command:
```
cp ~/Desktop/findsimulator /usr/local/bin/
```
Verify `findsimulator` is in your search path by running this in Terminal:
```
findsimulator -h
```
You should see the tool respond like this:
```
OVERVIEW: Interface to simctl in order to get suitable strings for destinations for the xcodebuild command.

USAGE: findsimulator [--os-type <os-type>] [--regex-pattern <regex-pattern>] [--major-os-version <major-os-version>] [--sub-os-version <sub-os-version>] [--pairs ...] [--list-all ...] [--version ...] [<name-contains>]

ARGUMENTS:
  <name-contains>         A simple 'string contains' check on the name of the simulator. Use the [-r | --regex-pattern] option for more finegrained searches instead.

OPTIONS:
  -o, --os-type <os-type> The os type. It can be either 'ios', 'watchos' or 'tvos'. Does only apply without '--pairs' option. (default: ios)
  -r, --regex-pattern <regex-pattern>
                          A regex pattern to match the device name. Does only apply without '--pairs' option.
  -m, --major-os-version <major-os-version>
                          The major OS version. Can be something like '12' or '14', 'all' or 'latest', which is the latest installed major version. Does only apply without '--pairs' option. (default: all)
  -s, --sub-os-version <sub-os-version>
                          The minor OS version. Can be something like '2' or '4', 'all' or 'latest', which is the latest installed minor version of a given major version. Note, if 'majorOSVersion' is set to 'latest', then minor version will also be 'latest'. Does only apply
                          without '-pairs' option. (default: all)
  -p, --pairs             Find iPhone Simulator in available iPhone/Watch Pairs.
  -l, --list-all          List all available and matching simulators.
  -v, --version           Print version of this tool.
  -h, --help              Show help information.
```
Now that a copy of `findsimulator` is in your search path, delete it from your desktop.

You're ready to go! 🎉