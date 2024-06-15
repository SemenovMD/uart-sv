package pkg_tb;

    parameter AXI_DATA_WIDTH = 8;
    parameter CLOCK = 20_000_000;
    parameter BAUD_RATE = 115_200;
    parameter DATA_BITS = 8;
    parameter STOP_BITS = 1;
    parameter PARITY_BITS = 0;

    parameter AXI_TRAN_MIN_DELAY = 2;
    parameter AXI_TRAN_MAX_DELAY = 17;

    parameter UART_RX_MIN_DELAY = 5;
    parameter UART_RX_MAX_DELAY = 20;

endpackage