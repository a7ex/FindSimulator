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
Examples:
First match for iOS simulator (default) with the latest OS version (default) and containing 'iPhone 1' in it's name.
```
destination=$(findsimulator "iPhone 1")
// platform=iOS Simulator,id=65213250-02E8-4FB2-8F75-F75C01430A57
```
List all iOS simulators (default) with the latest OS version (default) and containing 'iPhone 1' in their name.
```
destination=$(findsimulator -l "iPhone 1")
//platform=iOS Simulator,OS=15.4,id=65213250-02E8-4FB2-8F75-F75C01430A57,name=iPhone 13 mini
//...
//platform=iOS Simulator,OS=15.2,id=52B96F75-49C1-4EF0-BDD3-D205E448E468,name=iPhone 13 mini
//platform=iOS Simulator,OS=15.2,id=BB3CDAEF-EE05-463A-9D5E-D714F83D274D,name=iPhone 13 Pro Max
//platform=iOS Simulator,OS=15.2,id=1328ADB6-4229-4E27-A9E3-56FEFFFF0117,name=iPhone 13 Pro
```

Without the '--listAll|-l' flag the first match of the result with the '-l' flag is returned.
So that you always get the same simulator, without the '-l' flag.

## How to get it
### Using homebrew
```
brew tap a7ex/homebrew-formulae
brew install findsimulator
```
### Download binary
- Download `findsimulator.zip` binary from the latest [release](https://github.com/a7ex/FindSimulator/releases/latest)
- Copy `findsimulator` to your desktop
- Open a Terminal window and run this command to give the app permission to execute:

```
chmod +x ~/Desktop/findsimulator
```
**IMPORTANT NOTE:** This binary is not notarized/certified by Apple yet. So you must go to SystemSettings:Security and explicitely allow the app to execute, after the first attempt to launch it in the terminal, in case you want to take the risk.


Or build the tool yourself:

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

USAGE: findsimulator [--os-type <os-type>] [--major-os-version <major-os-version>] [--sub-os-version <sub-os-version>] [--pairs ...] [--list-all ...] [--version ...] [<name_contains>]

ARGUMENTS:
  <name_contains>         A string contains check on the name of the simulator.

OPTIONS:
  -o, --os-type <os-type> The os type. It can be either 'ios', 'watchos' or 'tvos'. Does only apply without '-pairs' option. (default: ios)
  -m, --major-os-version <major-os-version>
                          The major OS version. Can be something like '12' or '14', 'all' or 'latest', which is the latest installed major
                          version. Does only apply without '-pairs' option. (default: all)
  -s, --sub-os-version <sub-os-version>
                          The minor OS version. Can be something like '2' or '4', 'all' or 'latest', which is the latest installed minor version
                          of a given major version. Note, if 'majorOSVersion' is set to 'latest', then minor version will also be 'latest'. Does
                          only apply without '-pairs' option. (default: all)
  -p, --pairs             Find iPhone Simulator in available iPhone/Watch Pairs.
  -l, --list-all          List all available and matching simulators.
  -v, --version           Print version of this tool.
  -h, --help              Show help information.
```
Now that a copy of `findsimulator` is in your search path, delete it from your desktop.

You're ready to go! 🎉
