fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios setup

```sh
[bundle exec] fastlane ios setup
```

Setups project

Options: 'master:true' for account holder setup

### ios set_marketing_version

```sh
[bundle exec] fastlane ios set_marketing_version
```

Sets marketing version

Options: 'version:1.0.0'

### ios upload

```sh
[bundle exec] fastlane ios upload
```

Uploads to TestFlight

### ios prepare_certificates

```sh
[bundle exec] fastlane ios prepare_certificates
```

Prepare certificates via match

Options: 'master:true' for registering new devices

### ios update_build_number

```sh
[bundle exec] fastlane ios update_build_number
```

Updates build number to total commit count

### ios run_tuist

```sh
[bundle exec] fastlane ios run_tuist
```

Runs Tuist install & generate

Options: 'open:true' 

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```



### ios upload_dsym_to_sentry

```sh
[bundle exec] fastlane ios upload_dsym_to_sentry
```

Uploads DSYM files to Sentry

### ios upload_app_to_testflight

```sh
[bundle exec] fastlane ios upload_app_to_testflight
```

Uploads app to TestFlight

### ios notify_all

```sh
[bundle exec] fastlane ios notify_all
```

Notifies to all available channels

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
