/*
 * Module: axis_uart_transceiver
 * 
 * Description:
 *   This module combines UART transmitter and receiver functionalities 
 *   for AXI stream data. It is designed to interface with AXI stream protocols 
 *   and provide UART communication.
 * 
 * Features:
 *   - UART transmission and reception
 *   - Designed for high-speed data transfer in AXI stream applications
 *   - Supports synchronous active-low reset
 *   - Handles data ready/valid flags for AXI stream interfaces
 * 
 * Parameters:
 *   - AXI_DATA_WIDTH : Width of the input data bus (default: 8 bits)
 *   - CLOCK          : System clock frequency (default: 100 MHz)
 *   - BAUD_RATE      : Baud rate for UART communication (default: 115200)
 *   - DATA_BITS      : Number of data bits in UART frame (default: 8)
 *   - STOP_BITS      : Number of stop bits in UART frame (default: 1)
 *   - PARITY_BITS    : Parity configuration for UART frame (default: 0, 1 means even parity, 0 means odd parity)
 * 
 * Ports:
 *   - aclk      : Input     : Clock signal
 *   - aresetn   : Input     : Synchronous active-low reset
 *   - uart_rx   : Input     : UART receive signal
 *   - uart_tx   : Output    : UART transmit signal
 *   - tx_done   : Output    : Flag indicating the completion of UART transmission
 *   - rx_done   : Output    : Flag indicating the completion of UART reception
 *   - rx_error  : Output    : Error flag for UART reception
 *   - m_axis    : Interface : Master AXI stream interface
 *   - s_axis    : Interface : Slave AXI stream interface
 * 
 * Notes:
 *   - Ensure that the module is properly reset before use.
 *   - The tx_done and rx_done signals indicate the completion of transmission and reception respectively.
 *   - The rx_error signal encodes different error states:
 *     - 00: No error
 *     - 01: Start bit error
 *     - 10: Stop bit error
 *     - 11: Parity bit error
 * 
 * License:
 *   This is open-source code. The author makes no warranties, expressed or implied,
 *   and assumes no responsibility for any damage or loss resulting from the use of this code.
 *   Use it at your own risk.
 * 
 * Standard:
 *   SystemVerilog IEEE 1800-2012
 * 
 * Author: Semenov Maxim
 * Email : makcsem64@gmail.com
 * Date  : 04.06.2024
 *
 * IMPORTANT: Please make sure that AXI_DATA_WIDTH and DATA_BITS are divisible without remainder for proper device operation.
 * AXI_DATA_WIDTH should be divisible by DATA_BITS.
 * For example, if AXI_DATA_WIDTH = 64 and DATA_BITS = 8, it is valid. 
 * However, if AXI_DATA_WIDTH = 64 and DATA_BITS = 7, it is not valid and may cause unexpected behavior.
 *
 */

`timescale 1ns / 1ps

module axis_uart_transceiver

#(parameter AXI_DATA_WIDTH    = 8,
            CLOCK             = 100_000_000,
            BAUD_RATE         = 115_200,
            DATA_BITS         = 8,
            STOP_BITS         = 1,
            PARITY_BITS       = 0)

(
    // Global signals
    input   logic                               aclk,
    input   logic                               aresetn,

    // Transmitter
    input   logic                               uart_rx,
    output  logic                               uart_tx,

    // Flag State
    output  logic                               tx_done,
    output  logic                               rx_done,
    output  logic [1:0]                         rx_error,

    // Interface
    axis_if.m_axis                              m_axis,
    axis_if.s_axis                              s_axis
);

    axis_uart_tx #
    (
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .CLOCK(CLOCK),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS),
        .PARITY_BITS(PARITY_BITS)
    )
    
    axis_uart_tx_inst

    (
        .*
    );

    axis_uart_rx #
    (
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .CLOCK(CLOCK),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS),
        .PARITY_BITS(PARITY_BITS)
    )
    
    axis_uart_rx_inst

    (
        .*
    );

endmodule