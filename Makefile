# Variables
SIM = tb/vsim/vsim.do

# Targets
all: sim

sim:
	@echo "Running simulation..."
	vsim -do $(SIM)
	@echo "Simulation completed"

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
	@echo "  clean      - Clean simulation files"
	@echo "  help       - Show this help message"

.PHONY: all sim clean help
