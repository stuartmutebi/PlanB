buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ...other classpaths
        classpath("com.google.gms:google-services:4.3.15") // or latest version
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Remove this line from project-level build.gradle.kts:
// apply(plugin = "com.google.gms.google-services")