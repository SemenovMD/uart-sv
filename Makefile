# Variables
SIM = tb/vsim/vsim.do
SIM_SIMPLE = tb/vsim/vsim_simple.do

# Targets
all: sim

sim:
	@echo "Running full simulation..."
	vsim -do $(SIM)
	@echo "Full simulation completed"

sim-simple:
	@echo "Running simple simulation..."
	vsim -do $(SIM_SIMPLE)
	@echo "Simple simulation completed"

clean:
	@echo "Cleaning up..."
	rm -rf work
	rm -f transcript
	rm -f vsim.wlf
	@echo "Clean completed."

help:
	@echo "Available targets:"
	@echo "  all        - Run full simulation (default)"
	@echo "  sim        - Run full simulation with random data"
	@echo "  sim-simple - Run simple simulation with predefined data"
	@echo "  clean      - Clean simulation files"
	@echo "  help       - Show this help message"

.PHONY: all sim sim-simple clean help
