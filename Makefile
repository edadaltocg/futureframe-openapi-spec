.PHONY: setup test compile build preview all clean help

# Pull necessary Docker images
setup:
	docker pull redocly/cli
	go install github.com/google/yamlfmt/cmd/yamlfmt@latest
	brew install yamllint

# Format the OpenAPI specification
fmt:
	yamlfmt src/

# Lint the OpenAPI specification
test:
	yamllint -d relaxed src/
	docker run --rm \
		-v ./src:/spec \
		redocly/cli lint /spec/main.yaml

# Bundle the OpenAPI specification
compile:
	docker run --rm \
		-v ./src:/spec \
		-v ./:/build \
		redocly/cli bundle --output /build/openapi.yaml --ext yaml /spec/main.yaml

# Build the HTML documentation from the OpenAPI spec
build: compile
	docker run --rm \
		-v ./openapi.yaml:/spec/openapi.yaml \
		-v ./build:/build \
		redocly/cli build-docs /spec/openapi.yaml -o /build/index.html

# Preview the OpenAPI documentation
preview:
	docker run --rm \
		-d \
		-p 9090:80 \
		-v ./build:/usr/share/nginx/html \
		--name built-redoc \
		nginx

# Run all necessary steps to setup, test, compile, build, and host the documentation
all: test build

# Watch the source directory for changes and run all necessary steps
dev:
	fswatch -o src | xargs -n1 -I{} make all

# Clean up the build directory
clean:
	rm -rf openapi.yaml build/

# Display help for each target
help:
	@awk '/^#/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print substr($$1,1,index($$1,":")),c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t