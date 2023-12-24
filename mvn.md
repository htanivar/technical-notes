| File Name                                                                    | Purpose                                                                                                                                                               |
|------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `pom.xml`                                                                    | The Project Object Model (POM) file. It defines the configuration for the Maven build, including dependencies, plugins, and other project settings.                   |
| `settings.xml`                                                               | The Maven settings file. It contains configuration settings for Maven, such as repository locations, authentication details, and build profiles.                      |
| `maven-wrapper.properties`                                                   | The Maven Wrapper properties file. It is used to configure the Maven Wrapper, allowing you to build a project without requiring a pre-installed Maven version.        |
| `toolchains.xml`                                                             | The Maven toolchains file. It is used to define specific JDK installations to be used during the build process.                                                       |
| `dependencyManagement` section in `pom.xml`                                  | A section within the POM file that is used to centralize dependency versions for consistency across multiple modules in a multi-module project.                       |
| `maven-metadata-local.xml`                                                   | Local metadata file stored in the local repository, containing information about locally installed artifacts.                                                         |
| `.mvn/extensions.xml`                                                        | The Maven Extensions file. It allows the configuration of build extensions that are applied to the build process.                                                     |
| `.mvn/maven.config`                                                          | A configuration file that can be used to pass command-line options to the Maven build.                                                                                |
| `.mvn/wrapper/maven-wrapper.jar` and `.mvn/wrapper/maven-wrapper.properties` | Maven Wrapper files that are used to encapsulate Maven within a project, ensuring consistent builds across different environments.                                    |
| `*.properties` files                                                         | Custom property files that may be used in Maven projects for additional configuration. For example, `application.properties` for application-specific configurations. |

| Directory            | Purpose                                                                                                                                                  |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `.mvn`               | Directory containing Maven-specific configuration files, including the Maven Wrapper and Extensions configuration.                                       |
| `src/main/resources` | Standard location for resource files that are packaged with the application. Configuration files (e.g., `application.properties`) are often placed here. |
| `src/test/resources` | Similar to `src/main/resources`, but for test resources. Configuration files used during testing may be placed here.                                     |
| `target`             | The default output directory for compiled classes and packaged artifacts. This directory is created during the build process.                            |
| `~/.m2/repository`   | The default local Maven repository where downloaded dependencies are stored.                                                                             |

| Command               | Description                                                                        |
|-----------------------|------------------------------------------------------------------------------------|
| `mvn clean`           | Clean the project by removing the `target` directory.                              |
| `mvn compile`         | Compile the source code of the project.                                            |
| `mvn test`            | Run tests using a testing framework.                                               |
| `mvn package`         | Package compiled code into a distributable format, such as a JAR.                  |
| `mvn install`         | Install the packaged artifact into the local repository.                           |
| `mvn deploy`          | Copy the final package to the remote repository for sharing with other developers. |
| `mvn site`            | Generate project site documentation.                                               |
| `mvn clean install`   | Clean the project, compile the code, and install the packaged artifact.            |
| `mvn clean test`      | Clean the project and run tests.                                                   |
| `mvn dependency:tree` | Display the project's dependency tree.                                             |
| `mvn help:describe`   | Display information about a Maven plugin.                                          |

| Command                                                                                                                                                                      | Description                                                                             |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `mvn archetype:generate`                                                                                                                                                     | Generate a new project from an archetype (a predefined project template).               |
| `mvn archetype:generate -DgroupId=com.example -DartifactId=my-java-project -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false`                         | Example command to generate a basic Java project with a specific group and artifact ID. |
| `mvn archetype:generate -Dfilter=org.apache.maven.archetypes:`                                                                                                               | Display a list of available archetypes for generation.                                  |
| `mvn archetype:generate -DarchetypeGroupId=org.apache.maven.archetypes -DarchetypeArtifactId=maven-archetype-webapp -DgroupId=com.example -DartifactId=my-webapp`            | Example command to generate a simple web application project.                           |
| `mvn archetype:generate -DarchetypeGroupId=org.apache.maven.archetypes -DarchetypeArtifactId=maven-archetype-quickstart -DgroupId=com.example -DartifactId=my-quickstart`    | Example command to generate a quickstart Java project.                                  |
| `mvn archetype:generate -DarchetypeGroupId=org.apache.maven.archetypes -DarchetypeArtifactId=maven-archetype-j2ee-simple -DgroupId=com.example -DartifactId=my-j2ee-project` | Example command to generate a simple J2EE project.                                      |
| `mvn archetype:generate -DarchetypeGroupId=org.codehaus.mojo.archetypes -DarchetypeArtifactId=exec-java -DgroupId=com.example -DartifactId=my-java-executable`               | Example command to generate a Java project for an executable JAR.                       |
| `mvn archetype:generate -DarchetypeGroupId=org.codehaus.mojo.archetypes -DarchetypeArtifactId=webapp-javaee7 -DgroupId=com.example -DartifactId=my-javaee7-webapp`           | Example command to generate a Java EE 7 web application project.                        |

| Command                                                                 | Description                                                                                                                                           |
|-------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| `mvn compile`                                                           | Compile the main source code of the project.                                                                                                          |
| `mvn compile -DskipTests`                                               | Compile the code, skipping the execution of tests.                                                                                                    |
| `mvn compile -Pcustom-profile`                                          | Compile the project using a specific Maven profile (replace `custom-profile` with the actual profile name).                                           |
| `mvn compile -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8`   | Compile the code and specify the Java source and target versions.                                                                                     |
| `mvn compile -Dmaven.compiler.source=1.11 -Dmaven.compiler.target=1.11` | Compile the code for Java 11. Adjust the source and target versions as needed.                                                                        |
| `mvn clean compile`                                                     | Clean the project and then compile the main source code.                                                                                              |
| `mvn compile -DsourceDirectory=src/main/java-custom`                    | Compile the code from a custom source directory (replace `src/main/java-custom` with the actual path).                                                |
| `mvn compile -Dmaven.test.skip=true`                                    | Compile the code while skipping the execution of tests.                                                                                               |
| `mvn compile -Dmaven.compiler.verbose=true`                             | Compile the code with verbose output, showing detailed information about the compilation process.                                                     |
| `mvn compile -X`                                                        | Compile the code with debug output. This provides detailed information about the build process, including plugin execution and dependency resolution. |

| Command                                                          | Description                                                                                                                             |
|------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `mvn test`                                                       | Run tests for the project.                                                                                                              |
| `mvn test -Dtest=TestClassName`                                  | Run tests for a specific test class (replace `TestClassName` with the actual class name).                                               |
| `mvn test -Dtest=TestClassName#testMethodName`                   | Run a specific test method within a test class (replace `TestClassName` with the class name and `testMethodName` with the method name). |
| `mvn test -Dmaven.test.failure.ignore=true`                      | Run tests and ignore test failures, allowing the build to continue.                                                                     |
| `mvn test -Dtest=TestClassName -Dmaven.test.skip=true`           | Skip the execution of tests for a specific class.                                                                                       |
| `mvn test -Dtest=TestClassName -DfailIfNoTests=false`            | Run tests for a specific class and do not fail the build if no tests are found.                                                         |
| `mvn test -Dtest=TestClassName -Dmaven.test.skip.exec=true`      | Skip the execution of tests for a specific class during the test phase.                                                                 |
| `mvn test -Dtest=TestClassName -Dtest=AnotherTestClass`          | Run tests for multiple test classes (replace `TestClassName` and `AnotherTestClass` with the actual class names).                       |
| `mvn test -Dmaven.test.redirectTestOutputToFile=true`            | Redirect test output to a file for each test class.                                                                                     |
| `mvn test -Dtest=TestClassName -Dmaven.test.failure.ignore=true` | Run tests for a specific class and ignore test failures.                                                                                |

| Command                                                                 | Description                                                                                 |
|-------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| `mvn package`                                                           | Package the compiled code into a distributable format, such as a JAR or WAR.                |
| `mvn package -DskipTests`                                               | Package the code, skipping the execution of tests.                                          |
| `mvn package -Dmaven.test.skip=true`                                    | Package the code while skipping the execution of tests.                                     |
| `mvn package -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8`   | Package the code and specify the Java source and target versions.                           |
| `mvn package -Dmaven.compiler.source=1.11 -Dmaven.compiler.target=1.11` | Package the code for Java 11. Adjust the source and target versions as needed.              |
| `mvn clean package`                                                     | Clean the project and then package the compiled code.                                       |
| `mvn package -Dmaven.javadoc.skip=true`                                 | Package the code while skipping the generation of Javadoc.                                  |
| `mvn package -Dmaven.source.skip=true`                                  | Package the code while skipping the creation of source JARs.                                |
| `mvn package -Dmaven.test.failure.ignore=true`                          | Package the code and ignore test failures, allowing the build to continue.                  |
| `mvn package -Dmaven.test.error.ignore=true`                            | Package the code and ignore test errors (non-fatal errors), allowing the build to continue. |

| Command                                                                                                                             | Description                                                                                |
|-------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| `mvn install`                                                                                                                       | Install the packaged artifact into the local Maven repository.                             |
| `mvn install -DskipTests`                                                                                                           | Install the artifact, skipping the execution of tests.                                     |
| `mvn install -Dmaven.test.skip=true`                                                                                                | Install the artifact while skipping the execution of tests.                                |
| `mvn install -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8`                                                               | Install the artifact and specify the Java source and target versions.                      |
| `mvn install -Dmaven.compiler.source=1.11 -Dmaven.compiler.target=1.11`                                                             | Install the artifact for Java 11. Adjust the source and target versions as needed.         |
| `mvn clean install`                                                                                                                 | Clean the project and then install the packaged artifact into the local repository.        |
| `mvn install:install-file -Dfile=path/to/artifact.jar -DgroupId=com.example -DartifactId=my-artifact -Dversion=1.0 -Dpackaging=jar` | Install an external JAR file into the local repository. Adjust the parameters accordingly. |
| `mvn install -Dmaven.javadoc.skip=true`                                                                                             | Install the artifact while skipping the generation of Javadoc.                             |
| `mvn install -Dmaven.source.skip=true`                                                                                              | Install the artifact while skipping the creation of source JARs.                           |
| `mvn install -Dmaven.test.failure.ignore=true`                                                                                      | Install the artifact and ignore test failures, allowing the build to continue.             |

| Command                                                                                                       | Description                                                                                  |
|---------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `mvn deploy`                                                                                                  | Copy the final packaged artifact to the remote repository for sharing with other developers. |
| `mvn deploy -DskipTests`                                                                                      | Deploy the artifact, skipping the execution of tests.                                        |
| `mvn deploy -Dmaven.test.skip=true`                                                                           | Deploy the artifact while skipping the execution of tests.                                   |
| `mvn deploy -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8`                                          | Deploy the artifact and specify the Java source and target versions.                         |
| `mvn deploy -Dmaven.compiler.source=1.11 -Dmaven.compiler.target=1.11`                                        | Deploy the artifact for Java 11. Adjust the source and target versions as needed.            |
| `mvn clean deploy`                                                                                            | Clean the project and then deploy the final packaged artifact to the remote repository.      |
| `mvn deploy -Dmaven.javadoc.skip=true`                                                                        | Deploy the artifact while skipping the generation of Javadoc.                                |
| `mvn deploy -Dmaven.source.skip=true`                                                                         | Deploy the artifact while skipping the creation of source JARs.                              |
| `mvn deploy -Dmaven.test.failure.ignore=true`                                                                 | Deploy the artifact and ignore test failures, allowing the deployment to continue.           |
| `mvn deploy -DaltDeploymentRepository=myRepo::default::http://repo.example.com/content/repositories/releases` | Deploy the artifact to a specific repository. Adjust the repository URL and ID accordingly.  |
| `mvn deploy -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true`                        | Deploy the artifact to a repository with SSL verification disabled. Use with caution.        |

| Command                                              | Description                                                                                               |
|------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| `mvn site`                                           | Generate the project site documentation.                                                                  |
| `mvn site:run`                                       | Generate and preview the project site locally. Access the site at `http://localhost:8080` by default.     |
| `mvn site -Dmaven.test.skip=true`                    | Generate the project site while skipping the execution of tests.                                          |
| `mvn site -Dmaven.site.skip=true`                    | Skip the generation of the project site. Useful for a faster build when site documentation is not needed. |
| `mvn site:deploy`                                    | Deploy the generated site to a remote server for public access.                                           |
| `mvn site:stage-deploy`                              | Deploy the generated site to a staging environment for review before the final deployment.                |
| `mvn site -Dmaven.site.deploy.skip=true`             | Generate the project site but skip the deployment phase.                                                  |
| `mvn site:stage`                                     | Generate and stage the project site for review.                                                           |
| `mvn site:stage -Dmaven.test.skip=true`              | Generate and stage the project site while skipping the execution of tests.                                |
| `mvn clean site`                                     | Clean the project and then generate the project site documentation.                                       |
| `mvn site:run -Dmaven.tomcat.port=9090`              | Specify a custom port (e.g., `9090`) when previewing the project site locally.                            |
| `mvn site:stage -DstagingDirectory=/path/to/staging` | Specify a custom staging directory when staging the project site for review.                              |

| Command                                                           | Description                                                       |
|-------------------------------------------------------------------|-------------------------------------------------------------------|
| `mvn dependency:analyze`                                          | Analyze dependencies and report if any are declared but not used. |
| `mvn dependency:analyze-only`                                     | Analyze dependencies without generating a full project build.     |
| `mvn dependency:copy-dependencies`                                | Copy project dependencies to a specified directory.               |
| `mvn dependency:tree`                                             | Display the project's dependency tree.                            |
| `mvn dependency:list`                                             | List all dependencies for the project.                            |
| `mvn dependency:list-repositories`                                | List all repositories used by the project.                        |
| `mvn dependency:resolve`                                          | Resolve all project dependencies.                                 |
| `mvn dependency:resolve-plugins`                                  | Resolve all plugin dependencies.                                  |
| `mvn dependency:sources`                                          | Download and attach source files for project dependencies.        |
| `mvn dependency:build-classpath`                                  | Build the classpath for the project's dependencies.               |
| `mvn dependency:purge-local-repository`                           | Purge the local repository of all project dependencies.           |
| `mvn dependency:analyze-duplicate`                                | Analyze dependencies and report if there are any duplicates.      |
| `mvn dependency:go-offline`                                       | Download all dependencies and plugins for offline use.            |
| `mvn dependency:resolve-plugins -DincludeArtifactIds=plugin-name` | Resolve dependencies for a specific plugin.                       |
| `mvn dependency:resolve -Dclassifier=sources`                     | Resolve sources for project dependencies.                         |
| `mvn dependency:tree -Dincludes=group:artifact`                   | Display the dependency tree for a specific group and artifact.    |

