allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Legacy pub.dev plugins predating AGP 8 declare their package in the
// AndroidManifest instead of a `namespace` in their build file, which AGP 8
// requires. Derive the namespace from the manifest package attribute for any
// subproject that does not set one. They also predate explicit Java/Kotlin
// target alignment: Java falls back to AGP's 1.8 default while modern Kotlin
// defaults to the toolchain JVM, which Gradle rejects as inconsistent. Pin
// every Android subproject to the app's target (11) on both sides.
subprojects {
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null) {
            if (!project.buildFile.readText().contains("namespace")) {
                val manifest = project.file("src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val pkg = Regex("package=\"([^\"]+)\"")
                        .find(manifest.readText())?.groupValues?.get(1)
                    if (pkg != null) {
                        val nsField = android.javaClass.methods.firstOrNull { it.name == "setNamespace" }
                        nsField?.invoke(android, pkg)
                    }
                }
            }
            try {
                val co = android.javaClass.methods
                    .firstOrNull { it.name == "getCompileOptions" }?.invoke(android)
                if (co != null) {
                    val setSource = co.javaClass.methods.firstOrNull { it.name == "setSourceCompatibility" }
                    val setTarget = co.javaClass.methods.firstOrNull { it.name == "setTargetCompatibility" }
                    setSource?.invoke(co, JavaVersion.VERSION_11)
                    setTarget?.invoke(co, JavaVersion.VERSION_11)
                }
            } catch (e: Exception) {
                throw GradleException("Failed to align Java target for ${project.name}: ${e.message}", e)
            }
            project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile::class.java).configureEach {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}