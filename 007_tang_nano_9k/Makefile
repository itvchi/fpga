all:
	@echo "Specify a project and sub-target, e.g., 'make led_counter'"

PROJECTS := led_counter uart uart_led_driver lan8720
TESTBENCHES := $(addsuffix _tb, $(PROJECTS))
FLASH := $(addsuffix _flash, $(PROJECTS))

$(PROJECTS):
	$(MAKE) $@ -C $@

$(TESTBENCHES):
	$(MAKE) $@ -C $(patsubst %_tb, %, $@)

$(FLASH):
	$(MAKE) $@ -C $(patsubst %_flash, %, $@)

.PHONY: all $(PROJECTS)
