# Load version from version.txt
VERSION_FILE = version.txt
VERSION = $(shell cat $(VERSION_FILE))

ROJO = rojo

ROJO_PROJECT = default.project.json
ROJO_PROJECT_TEST = test.project.json

OUT = ActionContext-v$(VERSION).rbxmx
OUT_TEST = ActionContext.rbxlx

SRC = src

.PHONY = test serve docs clean clean-docs clean-build clean-test

# Main build

$(OUT) : $(ROJO_PROJECT) $(SRC)
	$(ROJO) build $(ROJO_PROJECT) --output $(OUT)

$(SRC) : $(shell find $(SRC) -type f)

# Test

SRC_TEST = test

test : $(OUT_TEST)

$(OUT_TEST) : $(ROJO_PROJECT_TEST) $(SRC_TEST)
	$(ROJO) build $(ROJO_PROJECT_TEST) --output $(OUT_TEST)

$(SRC_TEST) : $(shell find $(SRC) -type f)

serve :
	$(ROJO) serve $(ROJO_PROJECT_TEST)

# Docs

MOONWAVE = moonwave

docs : clean-docs
	$(MOONWAVE) build --code $(SRC)

docs-serve :
	$(MOONWAVE) dev --code $(SRC)

# Clean

clean : clean-build clean-test

clean-docs :
	$(RM) -r build

clean-build :
	$(RM) $(OUT)

clean-test :
	$(RM) $(OUT_TEST)