| Configuration         | Description                                                           |
|-----------------------|-----------------------------------------------------------------------|
| `plugins`             | Defines the plugins applied to the project.                           |
| `repositories`        | Specifies the repositories where Gradle should look for dependencies. |
| `dependencies`        | Declares the project's dependencies.                                  |
| `task`                | Defines a custom task in the build script.                            |
| `doFirst`             | Specifies actions to be performed before a task's main action.        |
| `doLast`              | Specifies actions to be performed after a task's main action.         |
| `mainClassName`       | Specifies the main class for the application.                         |
| `application`         | Configures the application plugin.                                    |
| `sourceCompatibility` | Sets the Java source compatibility for the project.                   |
| `targetCompatibility` | Sets the Java target compatibility for the project.                   |
| `repositories`        | Specifies repositories for resolving dependencies.                    |
| `dependencies`        | Declares dependencies for the project.                                |
| `test`                | Configures the test task.                                             |
| `jar`                 | Configures the JAR task.                                              |
| `compileJava`         | Configures the Java compilation task.                                 |
| `compileTestJava`     | Configures the test Java compilation task.                            |
| `build`               | Configures the build process.                                         |
| `allprojects`         | Configures the specified action for all projects.                     |
| `subprojects`         | Configures the specified action for all subprojects.                  |
| `wrapper`             | Configures the Gradle wrapper.                                        |
| `shadowJar`           | Configures the Shadow JAR plugin.                                     |
| `apply plugin`        | Applies a plugin to the project.                                      |
| `repositories`        | Specifies the repositories for resolving plugins.                     |
| `tasks`               | Configures tasks in the build script.                                 |

| Command                    | Description                                                    |
|----------------------------|----------------------------------------------------------------|
| `./gradlew tasks`          | Lists the tasks available in the project.                      |
| `./gradlew build`          | Builds the project.                                            |
| `./gradlew clean`          | Cleans the build directory.                                    |
| `./gradlew assemble`       | Assembles the outputs of the project.                          |
| `./gradlew check`          | Runs all checks.                                               |
| `./gradlew test`           | Runs tests.                                                    |
| `./gradlew build -x test`  | Builds the project, excluding the execution of tests.          |
| `./gradlew build -x check` | Builds the project, excluding the check (test) task.           |
| `./gradlew run`            | Runs the main class of the project.                            |
| `./gradlew dependencies`   | Displays the dependencies of the project.                      |
| `./gradlew help`           | Displays help information about Gradle tasks.                  |
| `./gradlew properties`     | Displays the properties of the project.                        |
| `./gradlew tasks --all`    | Displays all available tasks, including internal ones.         |
| `./gradlew wrapper`        | Generates Gradle wrapper files.                                |
| `./gradlew clean build`    | Cleans and then builds the project.                            |
| `./gradlew <task>`         | Executes a specific task. Replace `<task>` with the task name. |

| Command                                                                                     | Description                                                                                                               |
|---------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| `./gradlew dependencies`                                                                    | Displays the dependencies of the project.                                                                                 |
| `./gradlew dependencies --configuration compile`                                            | Displays dependencies for the compile configuration.                                                                      |
| `./gradlew dependencies --configuration testCompile`                                        | Displays dependencies for the testCompile configuration.                                                                  |
| `./gradlew dependencies --configuration runtime`                                            | Displays dependencies for the runtime configuration.                                                                      |
| `./gradlew dependencies --configuration testRuntime`                                        | Displays dependencies for the testRuntime configuration.                                                                  |
| `./gradlew dependencyInsight --dependency <group:artifact:version>`                         | Displays insight into a specific dependency. Replace `<group:artifact:version>` with the actual dependency coordinates.   |
| `./gradlew dependencyUpdates`                                                               | Displays a report of the dependencies that are up-to-date or can be updated.                                              |
| `./gradlew dependencyUpdates -Drevision=release`                                            | Displays updates only for the release versions.                                                                           |
| `./gradlew dependencyUpdates -Drevision=release -Dmilestone=true`                           | Displays updates only for release and milestone versions.                                                                 |
| `./gradlew dependencies --scan`                                                             | Generates a dependency report and opens it in a browser for further analysis (requires a Gradle Enterprise subscription). |
| `./gradlew dependencyInsight --dependency <group:artifact:version>`                         | Displays insight into a specific dependency.                                                                              |
| `./gradlew dependencyInsight --dependency <group:artifact:version> --configuration compile` | Displays insight into a specific dependency in the compile configuration.                                                 |
| `./gradlew dependencyInsight --dependency <group:artifact:version> --configuration runtime` | Displays insight into a specific dependency in the runtime configuration.                                                 |

| Property                      | Description                                              | Command to Display     |
|-------------------------------|----------------------------------------------------------|------------------------|
| `sourceCompatibility`         | Sets the Java source compatibility for the project.      | `./gradlew properties` |
| `targetCompatibility`         | Sets the Java target compatibility for the project.      | `./gradlew properties` |
| `version`                     | Specifies the version of the project.                    | `./gradlew properties` |
| `group`                       | Specifies the group of the project.                      | `./gradlew properties` |
| `archivesBaseName`            | Specifies the base name of the archives.                 | `./gradlew properties` |
| `buildDir`                    | Specifies the directory where build files are generated. | `./gradlew properties` |
| `projectDir`                  | Specifies the project directory.                         | `./gradlew properties` |
| `project.buildDir`            | Specifies the build directory for the project.           | `./gradlew properties` |
| `project.name`                | Specifies the name of the project.                       | `./gradlew properties` |
| `project.version`             | Specifies the version of the project.                    | `./gradlew properties` |
| `project.group`               | Specifies the group of the project.                      | `./gradlew properties` |
| `project.sourceCompatibility` | Specifies the Java source compatibility for the project. | `./gradlew properties` |
| `project.targetCompatibility` | Specifies the Java target compatibility for the project. | `./gradlew properties` |

// Add more rows as needed
