


[Go Mod Commands](#go-mod)  
[Go Vendor Commands](#go-vendor)  
[Go Build Commands](#go-build)  
[Go Run Commands](#go-run)  
[Go Test Commands](#go-test)

````
GOOS=windows GOARCH=amd64 go build -o myprogram.exe
GOOS=linux GOARCH=amd64 go build -o myprogram
GOOS=darwin GOARCH=amd64 go build -o myprogram
set GOOS=linux
set GOARCH=amd64
go build -o myprogram

````

## go-mod
| Command                                       | Description                                       |
|-----------------------------------------------|---------------------------------------------------|
| `go mod init module`                          | Initialize a new module                           |
| `go mod tidy`                                 | Prune any dependencies that are no longer needed  |
| `go mod vendor`                               | Copy dependencies into the vendor directory      |
| `go mod download`                             | Download modules to local cache                   |
| `go mod verify`                               | Verify dependencies have expected content         |
| `go mod graph`                                | Print the module requirement graph                |
| `go mod why`                                  | Explain why packages or modules are needed        |
| `go mod edit`                                 | Edit go.mod from tools or scripts                 |
| `go mod vendor -v`                            | Enable verbose output for go mod vendor           |
| `go mod tidy -v`                              | Enable verbose output for go mod tidy             |
| `go mod download -x`                          | Print the commands used for downloading modules  |

## go-vendor
| Command                                       | Description                                       |
|-----------------------------------------------|---------------------------------------------------|
| `go vendor init`                              | Initialize the vendor directory                   |
| `go vendor add import-path`                   | Add a package to the vendor directory             |
| `go vendor remove import-path`                | Remove a package from the vendor directory        |
| `go vendor sync`                              | Update the vendor directory based on the manifest |
| `go vendor fetch import-path`                 | Fetch a specific package and its dependencies     |
| `go vendor list`                              | List all packages in the vendor directory         |

## go-build
| Command                                       | Description                                       |
|-----------------------------------------------|---------------------------------------------------|
| `go build`                                    | Build the Go executable in the current directory  |
| `go build -o output-file`                     | Specify the output file name for the executable   |
| `go build -ldflags "flag1=value1 flag2=value2"`| Set additional linker flags during compilation   |
| `go build -tags tagname`                       | Include build tags during the build process       |
| `go build -v`                                 | Enable verbose output during the build            |
| `go build -race`                              | Enable the race detector during the build         |
| `go build -mod=mod`                           | Use the module-aware mode for dependency resolution|
| `go build -trimpath`                          | Remove all file system paths from the executable  |
| `go build -a`                                 | Force rebuilding of all packages                  |
| `go build -i`                                 | Install the dependencies needed for the build     |
| `go build -x`                                 | Print the commands used for the build              |

## go-run
| Command                                       | Description                                       |
|-----------------------------------------------|---------------------------------------------------|
| `go run main.go`                              | Build and run the Go program in a single command  |
| `go run -tags tagname`                         | Include build tags during the run process         |
| `go run -race main.go`                        | Enable the race detector during the run           |
| `go run -mod=mod main.go`                     | Use the module-aware mode for dependency resolution|
| `go run -exec="executable args"`              | Run a precompiled binary with specific arguments  |

## go-test
| Command                                       | Description                                       |
|-----------------------------------------------|---------------------------------------------------|
| `go test`                                     | Run tests in the current package                  |
| `go test path/to/package`                      | Run tests in a specific package                   |
| `go test -v`                                  | Run tests with verbose output                     |
| `go test -run TestFunctionName`                | Run a specific test function                      |
| `go test -parallel N`                         | Run tests in parallel (replace N with a number)  |
| `go test -bench .`                            | Run benchmark tests                               |
| `go test -benchmem`                           | Run tests and display memory allocation           |
| `go test -cover`                              | Run tests with coverage                           |
| `go test -coverprofile=coverage.out`          | Generate coverage profile                         |
| `go tool cover -html=coverage.out`            | View coverage report in the browser               |
| `go test -race`                               | Run tests with the race detector                  |
| `go test ./path/to/subdirectory`              | Run tests in a subdirectory                       |
| `go test -tags tagname`                       | Run tests with build tags                         |

