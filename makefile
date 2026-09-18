BUILD_DIR_VIVADO = build/vivado
BUILD_DIR_LIBRELANE = build/librelane
VIVADO_DIR = ../../targets/vivado
RTL_DIR = ../../rtl

.PHONY: all synth-vivado impl-vivado sim-vivado wave-vivado program-vivado clean

all: program-vivado

$(BUILD_DIR_VIVADO):
	mkdir -p $(BUILD_DIR_VIVADO)

$(BUILD_DIR_LIBRELANE):
	mkdir -p $(BUILD_DIR_LIBRELANE)

synth-vivado: $(BUILD_DIR_VIVADO)
	@echo "Running Synthesis..."
	cd $(BUILD_DIR_VIVADO) && vivado -mode batch -source $(VIVADO_DIR)/tcl/synth.tcl

impl-vivado: synth-vivado
	@echo "Running Implementation and Generating Bitstream..."
	cd $(BUILD_DIR_VIVADO) && vivado -mode batch -source $(VIVADO_DIR)/tcl/impl.tcl

sim-vivado: $(BUILD_DIR_VIVADO)
	@echo "Simulating the top module..."
	cd $(BUILD_DIR_VIVADO) && vivado -mode batch -source $(VIVADO_DIR)/tcl/sim.tcl

	@echo "Injecting GTKWave VCD Logging Commands..."

	@echo "open_vcd waveform.vcd" > $(BUILD_DIR_VIVADO)/sim_workspace/xsim/cmd.tcl
	@echo "log_vcd [get_objects -r *]" >> $(BUILD_DIR_VIVADO)/sim_workspace/xsim/cmd.tcl
	@echo "run all" >> $(BUILD_DIR_VIVADO)/sim_workspace/xsim/cmd.tcl
	@echo "close_vcd" >> $(BUILD_DIR_VIVADO)/sim_workspace/xsim/cmd.tcl
	@echo "exit" >> $(BUILD_DIR_VIVADO)/sim_workspace/xsim/cmd.tcl
	
	@echo "Running Simulation Engine..."
	cd $(BUILD_DIR_VIVADO)/sim_workspace/xsim && ./top_tb.sh
	
	@echo "Done! Waveform saved to: $(BUILD_DIR_VIVADO)/sim_workspace/xsim/waveform.vcd"

wave-vivado: $(BUILD_DIR_VIVADO) sim-vivado
	cd $(BUILD_DIR_VIVADO) && gtkwave sim_workspace/xsim/waveform.vcd &

program-vivado: impl-vivado
	@echo "Programming the Zybo Z7 over JTAG..."
	cd $(BUILD_DIR_VIVADO) && vivado -mode batch -source $(VIVADO_DIR)/tcl/program.tcl

run-librelane: $(BUILD_DIR_LIBRELANE)
	cp targets/librelane/config.yaml build/librelane/config.yaml
	librelane build/librelane/config.yaml

clean:
	@echo "Cleaning build directory..."
	rm -rf build/
