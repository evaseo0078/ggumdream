plugins {
    // ... 다른 플러그인들 (예: android tools, kotlin) ...

    // 🔥 Google Services 플러그인 버전을 선언합니다.
    id("com.google.gms.google-services") version "4.3.15" apply false // 최신 버전 확인 후 사용
}
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
subprojects {
    project.evaluationDependsOn(":app")
}

// Align Java/Kotlin toolchains across all modules to silence Java 8 warnings.
subprojects {
    tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
        // Suppress obsolete source/target warnings emitted by JDK 21+ when plugins compile with Java 8 defaults.
        options.compilerArgs.add("-Xlint:-options")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
