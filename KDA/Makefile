# Make file for a Hammer project

# Make sure this is set to the top level directory containing module_top.mk
TOP_DIR = $(realpath ../../ee477-hammer-cad)
OBJ_DIR := build
INPUT_CFGS =cfg/cfg.yml cfg/src.yml
TB_CFGS = cfg/tb.yml

TRACE_FILE = v/bsg_trace_master_0.tr
HAMMER_SIM_DEPENDENCIES=$(TRACE_FILE)

# Main Hammer Targets
include $(TOP_DIR)/module_top.mk
