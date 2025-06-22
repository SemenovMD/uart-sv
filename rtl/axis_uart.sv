module axis_uart

#(
    parameter   CLOCK       = 100_000_000,
    parameter   BAUD_RATE   = 115_200
)

(
    input   logic                               aclk,
    input   logic                               aresetn,

    input   logic                               uart_rx,
    output  logic                               uart_tx,

    axis_if.m_axis                              m_axis,
    axis_if.s_axis                              s_axis
);

    axis_uart_tx #(.CLOCK(CLOCK), .BAUD_RATE(BAUD_RATE)) axis_uart_tx_inst (.*);
    axis_uart_rx #(.CLOCK(CLOCK), .BAUD_RATE(BAUD_RATE)) axis_uart_rx_inst (.*);

endmodule