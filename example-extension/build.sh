#!/bin/bash
echo "Building Example Extension..."
./gradlew assembleDebug
if [ $? -eq 0 ]; then
    echo "Build successful!"
else
    echo "Build failed!"
fi
