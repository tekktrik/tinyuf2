# ---------------------------------------
# Common make definition for all
# ---------------------------------------

ifneq ($(lastword a b),b)
$(error This Makefile require make 3.81 or newer)
endif

# Set TOP to be the path to get from the current directory (where make was
# invoked) to the top of the tree. $(lastword $(MAKEFILE_LIST)) returns
# the name of this makefile relative to where make was invoked.

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
TOP := $(shell realpath $(THIS_MAKEFILE))
TOP := $(patsubst %/ports/make.mk,%,$(TOP))

CURRENT_PATH := $(shell realpath --relative-to=$(TOP) `pwd`)

#-------------- Handy check parameter function ------------
check_defined = \
    $(strip $(foreach 1,$1, \
    $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
    $(error Undefined make flag: $1$(if $2, ($2))))
    
#-------------- Select the board to build for. ------------
BOARD_LIST = $(sort $(subst /.,,$(subst boards/,,$(wildcard boards/*/.))))

ifeq ($(filter $(BOARD),$(BOARD_LIST)),)
  $(info You must provide a BOARD parameter with 'BOARD=', supported boards are:)
  $(foreach b,$(BOARD_LIST),$(info - $(b)))
  $(error Invalid BOARD specified)
endif

# Build directory
BUILD = _build/build-$(BOARD)

#-------------- Source files and compiler flags --------------

# Bootloader src, board folder and TinyUSB stack
TINYUSB_LIB = lib/tinyusb/src
SRC_C += \
  $(subst $(TOP)/,,$(wildcard $(TOP)/src/*.c)) \
  $(subst $(TOP)/,,$(wildcard $(TOP)/ports/$(PORT)/boards/$(BOARD)/*.c)) \
	$(TINYUSB_LIB)/tusb.c \
	$(TINYUSB_LIB)/common/tusb_fifo.c \
	$(TINYUSB_LIB)/device/usbd.c \
	$(TINYUSB_LIB)/device/usbd_control.c \
	$(TINYUSB_LIB)/class/cdc/cdc_device.c \
	$(TINYUSB_LIB)/class/dfu/dfu_rt_device.c \
	$(TINYUSB_LIB)/class/hid/hid_device.c \
	$(TINYUSB_LIB)/class/midi/midi_device.c \
	$(TINYUSB_LIB)/class/msc/msc_device.c \
	$(TINYUSB_LIB)/class/net/net_device.c \
	$(TINYUSB_LIB)/class/usbtmc/usbtmc_device.c \
	$(TINYUSB_LIB)/class/vendor/vendor_device.c

INC += \
  $(TOP)/src \
  $(TOP)/ports/$(PORT) \
  $(TOP)/ports/$(PORT)/boards/$(BOARD) \
  $(TOP)/$(TINYUSB_LIB)

# Compiler Flags
CFLAGS += \
  -ggdb \
  -fdata-sections \
  -ffunction-sections \
  -fsingle-precision-constant \
  -fno-strict-aliasing \
  -Wdouble-promotion \
  -Wstrict-prototypes \
  -Wall \
  -Wextra \
  -Werror \
  -Wfatal-errors \
  -Werror-implicit-function-declaration \
  -Wfloat-equal \
  -Wundef \
  -Wshadow \
  -Wwrite-strings \
  -Wsign-compare \
  -Wmissing-format-attribute \
  -Wunreachable-code \
  -Wcast-align

# Debugging/Optimization
ifeq ($(DEBUG), 1)
  CFLAGS += -Og
else
  CFLAGS += -Os
endif

# Log level is mapped to TUSB DEBUG option
ifneq ($(LOG),)
  CFLAGS += -DCFG_TUSB_DEBUG=$(LOG)
endif

# Logger: default is uart, can be set to rtt or swo
ifeq ($(LOGGER),rtt)
  RTT_SRC = lib/SEGGER_RTT
  CFLAGS += -DLOGGER_RTT -DSEGGER_RTT_MODE_DEFAULT=SEGGER_RTT_MODE_BLOCK_IF_FIFO_FULL
  INC   += $(TOP)/$(RTT_SRC)/RTT
  SRC_C += $(RTT_SRC)/RTT/SEGGER_RTT.c
else ifeq ($(LOGGER),swo)
  CFLAGS += -DLOGGER_SWO
endif

# Board specific define
include $(TOP)/ports/$(PORT)/boards/$(BOARD)/board.mk
