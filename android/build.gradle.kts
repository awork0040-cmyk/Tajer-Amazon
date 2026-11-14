import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 1. إجبار المكتبات على استخدام compileSdk 36 (يجب أن يكون قبل evaluationDependsOn)
subprojects {
    afterEvaluate {
        val isAndroid = plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")
        if (isAndroid) {
            val android = extensions.findByName("android") as? BaseExtension
            if (android != null) {
                android.compileSdkVersion(36)
            }
        }
    }
}

// 2. هذا السطر يجب أن يكون في النهاية
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}