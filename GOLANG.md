go mod init
go mod tidy

go build

go test
go test -v -cover
go test ./...
