# usage $(call CheckSubmoduleTemplate (name,MAKEFILE VAR,repo name))
# usage $(call CheckSubmoduleTemplate (mono,MONO,mono))

define CheckSubmoduleTemplate
#$(eval NEEDED_$(2)_VERSION:=$(shell git ls-tree HEAD --full-tree -- external/$(1) | awk -F' ' '{printf "%s",$$3}'))
#$(eval $(2)_VERSION:=$$$$(shell cd $($(2)_PATH) 2>/dev/null && git rev-parse HEAD 2>/dev/null))

check-$(1)::
ifeq ($$(IGNORE_$(2)_VERSION),)
	@if test ! -d $($(2)_PATH); then \
		if test x$$(RESET_VERSIONS) != "x"; then \
			make reset-$(1) || exit 1; \
		else \
			echo "Your $(1) checkout is missing, please run 'git submodule update --init --recursive -- external/$(1)'"; \
			touch .check-versions-failure; \
		fi; \
	else \
		if test "x$($(2)_VERSION)" != "x$(NEEDED_$(2)_VERSION)" ; then \
			if test x$$(RESET_VERSIONS) != "x"; then \
				make reset-$(1) || exit 1; \
			else \
				echo "Your $(1) version is out of date, please run 'make reset-$(1)' (found $($(2)_VERSION), expected $(NEEDED_$(2)_VERSION))"; \
				test -z "$(BUILD_REVISION)" || $(MAKE) test-$(1); \
				touch .check-versions-failure; \
			fi; \
		else \
			echo "$(1) is up-to-date."; \
		fi; \
	fi
else
	@echo "$(1) is ignored."
endif

test-$(1)::
	@echo $(1)
	@echo "   NEEDED_$(2)_VERSION=$(NEEDED_$(2)_VERSION)"
	@echo "   $(2)_VERSION=$($(2)_VERSION)"
	@echo "   $(2)_PATH=$($(2)_PATH) => $(abspath $($(2)_PATH))"

reset-$(1)::
ifneq ($$(IGNORE_$(2)_VERSION),)
	@echo "*** Not resetting $(1) because IGNORE_$(2)_VERSION is set"
else
	@echo "*** git submodule update --init --recursive --force -- $(TOP)/external/$(1)"
	@git submodule update --init --recursive --force -- $(TOP)/external/$(1)
endif

print-$(1)::
	@printf "*** %-16s %-45s %s (%s)\n" "$(1)" "$(shell git config submodule.external/$(1).url)" "$(NEEDED_$(2)_VERSION)" "$(shell git config -f $(abspath $(TOP)/.gitmodules) submodule.external/$(1).branch)"

.PHONY: check-$(1) reset-$(1) print-$(1)

reset-versions:: reset-$(1)
check-versions:: check-$(1)
print-versions:: print-$(1)
endef

check-versions::
	@if test -e .check-versions-failure; then  \
		rm .check-versions-failure; \
		echo One or more modules needs update;  \
		exit 1; \
	else \
		echo All dependent modules up to date;  \
	fi

all-local:: check-versions

reset:
	@make check-versions RESET_VERSIONS=1
