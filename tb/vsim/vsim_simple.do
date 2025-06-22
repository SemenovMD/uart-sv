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
vlog -sv rtl/axis_uart.sv
vlog -sv tb/axis_uart_simple_tb.sv

# Simulate the testbench
vsim -t 1ns -voptargs="+acc" axis_uart_simple_tb

# Add signals to the waveform window
add wave -radix binary          axis_uart_inst/aclk
add wave -radix binary          axis_uart_inst/aresetn

add wave -radix binary          axis_uart_inst/uart_rx
add wave -radix binary          axis_uart_inst/uart_tx

add wave -radix hexadecimal     axis_uart_inst/m_axis/tdata
add wave -radix binary          axis_uart_inst/m_axis/tvalid
add wave -radix binary          axis_uart_inst/m_axis/tready

add wave -radix hexadecimal     axis_uart_inst/s_axis/tdata
add wave -radix binary          axis_uart_inst/s_axis/tvalid
add wave -radix binary          axis_uart_inst/s_axis/tready

# Add internal signals for debugging
add wave -radix unsigned        axis_uart_inst/axis_uart_rx_inst/state_rx
add wave -radix unsigned        axis_uart_inst/axis_uart_rx_inst/count_baud
add wave -radix unsigned        axis_uart_inst/axis_uart_rx_inst/count_bit
add wave -radix hexadecimal     axis_uart_inst/axis_uart_rx_inst/uart_buf
add wave -radix binary          axis_uart_inst/axis_uart_rx_inst/flag

add wave -radix unsigned        axis_uart_inst/axis_uart_tx_inst/state_tx
add wave -radix unsigned        axis_uart_inst/axis_uart_tx_inst/count_baud
add wave -radix unsigned        axis_uart_inst/axis_uart_tx_inst/count_bit
add wave -radix hexadecimal     axis_uart_inst/axis_uart_tx_inst/uart_buf

# Add testbench signals
add wave -radix unsigned        test_index
add wave -radix unsigned        received_data

# Run the simulation for the specified time
run 5ms

# Zoom out to show all waveform data
wave zoom full 