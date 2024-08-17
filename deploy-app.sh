#!/usr/bin/env bash

set -e

source ~/.bin/dotfiles/.secrets.zconfig

flutter build apk --release
scp -r build/app/outputs/flutter-apk/app-release.apk shane@$NIGHTINGALE:~/synco/apps/synco.apk
