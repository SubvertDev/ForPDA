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

### ios set_marketing_version

```sh
[bundle exec] fastlane ios set_marketing_version
```

Sets marketing version

### ios upload

```sh
[bundle exec] fastlane ios upload
```

Uploads to TestFlight

### ios upload_oneoff

```sh
[bundle exec] fastlane ios upload_oneoff
```

One-off upload to TF without tests/notify/bump

### ios prepare_certificates

```sh
[bundle exec] fastlane ios prepare_certificates
```

Prepare certificates via match

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

### ios tests

```sh
[bundle exec] fastlane ios tests
```

Runs tests

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

Builds and signs ipa file

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

### ios bump_and_tag

```sh
[bundle exec] fastlane ios bump_and_tag
```

Commits changes and adds a tag with version/build

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
