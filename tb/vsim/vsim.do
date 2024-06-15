# Enable transcript logging
transcript on

# Create the work library
vlib work

# Compile the packages
vlog -sv tb/pkg_tb.sv

# Compile the interfaces
vlog -sv rtl/axis_if.sv

# Compile the design and testbench
vlog -sv rtl/axis_uart_tx.sv
vlog -sv rtl/axis_uart_rx.sv
vlog -sv rtl/axis_uart_transceiver.sv
vlog -sv tb/axis_uart_tb.sv

# Simulate the testbench
vsim -t 1ns -L altera_mf_ver -voptargs="+acc" axis_uart_tb

# Add signals to the waveform window
add wave -radix binary          axis_uart_transceiver_inst/aclk
add wave -radix binary          axis_uart_transceiver_inst/aresetn

add wave -radix binary          axis_uart_transceiver_inst/uart_rx
add wave -radix binary          axis_uart_transceiver_inst/uart_tx

add wave -radix binary          axis_uart_transceiver_inst/rx_done
add wave -radix binary          axis_uart_transceiver_inst/rx_error
add wave -radix binary          axis_uart_transceiver_inst/tx_done

add wave -radix hexadecimal     axis_uart_transceiver_inst/m_axis/tdata
add wave -radix binary          axis_uart_transceiver_inst/m_axis/tvalid
add wave -radix binary          axis_uart_transceiver_inst/m_axis/tready

add wave -radix hexadecimal     axis_uart_transceiver_inst/s_axis/tdata
add wave -radix binary          axis_uart_transceiver_inst/s_axis/tvalid
add wave -radix binary          axis_uart_transceiver_inst/s_axis/tready

add wave -radix unsigned        axis_uart_transceiver_inst/axis_uart_rx_inst/state_rx
add wave -radix unsigned        axis_uart_transceiver_inst/axis_uart_rx_inst/count_baud
add wave -radix unsigned        axis_uart_transceiver_inst/axis_uart_rx_inst/count_bit
add wave -radix unsigned        axis_uart_transceiver_inst/axis_uart_rx_inst/count_byte

add wave -radix unsigned        axis_uart_transceiver_inst/axis_uart_tx_inst/state_tx
add wave -radix unsigned        axis_uart_transceiver_inst/axis_uart_tx_inst/count_baud
add wave -radix unsigned        axis_uart_transceiver_inst/axis_uart_tx_inst/count_bit
add wave -radix unsigned        axis_uart_transceiver_inst/axis_uart_tx_inst/count_byte

# Run the simulation for the specified time
run 10ms

# Zoom out to show all waveform data
wave zoom full