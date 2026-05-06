SWIFT_SRC := swift/imauto.swift
BIN_DIR   := bin
BIN       := $(BIN_DIR)/imauto

.PHONY: build clean check

build: $(BIN)

$(BIN): $(SWIFT_SRC)
	@mkdir -p $(BIN_DIR)
	swiftc -O -framework Carbon -o $(BIN) $(SWIFT_SRC)

check: build
	$(BIN)

clean:
	rm -rf $(BIN_DIR)
