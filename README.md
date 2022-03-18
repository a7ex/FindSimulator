# FindSimulator

## Overview
Use simctl to find UDIDs of Xcode simulators to be used as 'destination' parameter in xcodebuild.

Just get the ID of the first available simulator, which matches the query.
Speify whether to search for 'iOS', 'watchOS' or 'tvOS' simulators. You can also specify a major and minor version of the OS, you want to target or specify 'latest' to get the latest and greatest.

There is also an option to list all matches along with their names.

You can also find iPhone simulators with paired watches.

## How to use it
The tool doesn't create any file. It justs outputs its results to standard out.
You can store the result in a shell variable:
```
simulator_id=$(findsimulator -o ios -m latest iPhone)
xcrun xcodebuild test -workspace MyApp.xcworkspace -scheme MyApp -destination "id=$simulator_id"
```

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
OVERVIEW: Interface to simctl in order to get suitable strings for destinations
for the xcodebuild command.

USAGE: findsimulator [--os-type <os-type>] [--major-os-version <major-os-version>] [--sub-os-version <sub-os-version>] [--pairs ...] [--list-all ...] [--version ...] [<name_contains>]

ARGUMENTS:
  <name_contains>         A string contains check on the name to constrain
                          results. 

OPTIONS:
  -o, --os-type <os-type> The os type. It can be either 'ios', 'watchos' or
                          'tvos'. Defaults to 'ios'. Does only apply without
                          '-pairs' option. (default: ios)
  -m, --major-os-version <major-os-version>
                          The major OS version. Can be something like '12' or
                          '14'. Defaults to 'latest' which is the latest
                          installed major version. Does only apply without
                          '-pairs' option. (default: latest)
  -s, --sub-os-version <sub-os-version>
                          The minor OS version. Can be something like '2' or
                          '4'. Defaults to 'latest' which is the latest
                          installed minor version of a given major version.
                          Note, if 'majorOSVersion' is set to 'latest', then
                          minor version will also be 'latest'. Does only apply
                          without '-pairs' option. (default: latest)
  -p, --pairs             Find and iPhone in available iPhone/Watch Pairs. 
  -l, --list-all          List all available and mathcing simulators. 
  -v, --version           Print version of this tool. 
  -h, --help              Show help information.
```
Now that a copy of `findsimulator` is in your search path, delete it from your desktop.

You're ready to go! 🎉
