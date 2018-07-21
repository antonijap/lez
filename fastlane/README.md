fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios install_cocoapods
```
fastlane ios install_cocoapods
```
Install dependencies
### ios release
```
fastlane ios release
```
Push a new release build to the App Store
### ios refresh_dsyms
```
fastlane ios refresh_dsyms
```
Refresh dSYM files from iTunes Connect

Also uploads them to Crashlytics
### ios make_ipa
```
fastlane ios make_ipa
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
