# Make file for a Hammer project

# Make sure this is set to the top level directory containing module_top.mk
TOP_DIR = $(realpath ../../ee477-hammer-cad)
OBJ_DIR := build
INPUT_CFGS =cfg/cfg.yml cfg/src.yml
TB_CFGS = cfg/tb.yml

TRACE_FILE = v/bsg_trace_master_0.tr
HAMMER_SIM_DEPENDENCIES=$(TRACE_FILE)

# Default config file
TR_CFG ?= py/default_sim_cfg.yml

# Always re-generate the trace file
.PHONY: $(TRACE_FILE)
$(TRACE_FILE):
	python3 ./py/final_proj_pre_sim.py -cfg $(TR_CFG) -out $@

# Main Hammer Targets
include $(TOP_DIR)/module_top.mk
