#!/bin/bash

# This script requires ImageMagick to be installed
# If not installed, run: brew install imagemagick

# Input file 
INPUT_FILE="/Users/rawaz/Desktop/halbzhera/assets/applogo.png"

# Create notification icons (must be white icon on transparent background)
convert "$INPUT_FILE" -resize 24x24 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/drawable-mdpi/ic_stat_notification.png"
convert "$INPUT_FILE" -resize 36x36 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/drawable-hdpi/ic_stat_notification.png"
convert "$INPUT_FILE" -resize 48x48 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/drawable-xhdpi/ic_stat_notification.png"
convert "$INPUT_FILE" -resize 72x72 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/drawable-xxhdpi/ic_stat_notification.png"
convert "$INPUT_FILE" -resize 96x96 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/drawable-xxxhdpi/ic_stat_notification.png"

# Create app icons for Android
convert "$INPUT_FILE" -resize 48x48 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
convert "$INPUT_FILE" -resize 72x72 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
convert "$INPUT_FILE" -resize 96x96 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
convert "$INPUT_FILE" -resize 144x144 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
convert "$INPUT_FILE" -resize 192x192 "/Users/rawaz/Desktop/halbzhera/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

echo "Icons have been created successfully!"
