// File: android/settings.gradle
include ':app'

def localProperties = new Properties()
def localPropertiesFile = new File(settingsDir, "local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterSdkPath = localProperties.getProperty('flutter.sdk')
if (flutterSdkPath == null) {
    throw new GradleException("Flutter SDK not found in local.properties")
}

apply from: "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle"