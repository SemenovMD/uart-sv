module axis_uart_wrapper_v

#(
    parameter   CLOCK       = 100_000_000,
    parameter   BAUD_RATE   = 115_200
)

(
    input  wire         aclk,
    input  wire         aresetn,

    input  wire         uart_rx,
    output wire         uart_tx,

    input  wire   [7:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,

    output wire   [7:0] m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready
);

    axis_uart_wrapper_sv #(.CLOCK(CLOCK), .BAUD_RATE(BAUD_RATE)) axis_uart_wrapper_sv_inst 
    (
        .aclk(aclk),
        .aresetn(aresetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

endmodule