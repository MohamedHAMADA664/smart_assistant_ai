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

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        if (androidExtension != null) {
            val namespaceMethod = androidExtension.javaClass.methods.find {
                it.name == "getNamespace" && it.parameterCount == 0
            }
            val currentNamespace = namespaceMethod?.invoke(androidExtension) as? String

            if (currentNamespace.isNullOrBlank()) {
                val setNamespaceMethod = androidExtension.javaClass.methods.find {
                    it.name == "setNamespace" && it.parameterCount == 1
                }

                setNamespaceMethod?.invoke(
                    androidExtension,
                    "com.fix.${project.name.replace("-", "_")}",
                )
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
