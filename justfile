# justfile
default:
    @just --list

build:
    go build ./...

run:
    go run ./cmd/agent

test:
    gotestsum --format testname ./...

lint:
    golangci-lint run ./...

vet:
    go vet ./...

fmt:
    gofumpt -l -w .

vuln:
    govulncheck ./...

check: fmt vet lint vuln test
    @echo "✅ tudo passou"

dev:
    air

clean:
    go clean -cache -testcache -modcache
    rm -rf bin/