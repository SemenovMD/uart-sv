package pkg_tb;

    parameter CLOCK = 100_000_000;
    parameter BAUD_RATE = 115_200;

    parameter CLK_PERIOD_NS = 1_000_000_000 / CLOCK;
    parameter DUTY_BITS = 1_000_000_000 / BAUD_RATE;

    parameter AXI_TRAN_MIN_DELAY = 2;
    parameter AXI_TRAN_MAX_DELAY = 17;

    parameter UART_RX_MIN_DELAY = 5;
    parameter UART_RX_MAX_DELAY = 20;

endpackage