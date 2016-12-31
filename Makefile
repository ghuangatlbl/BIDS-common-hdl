BUILD_DIR = ./build

.PHONY: all
all: targets
include $(BUILD_DIR)/top_rules.mk
include rules.mk

