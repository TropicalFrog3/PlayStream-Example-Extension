@echo off
echo Building project...
call gradlew.bat compileDebugKotlin compileDebugJavaWithJavac

echo.
echo Running test...
java -cp "build/intermediates/javac/debug/classes;build/tmp/kotlin-classes/debug;%USERPROFILE%\.gradle\caches\modules-2\files-2.1\*\*\*.jar" com.playstream.extension.example.MainKt

pause
