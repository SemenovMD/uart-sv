module axis_uart_transceiver_wrapper_v

#(parameter AXI_DATA_WIDTH    = 8,
            CLOCK             = 100_000_000,
            BAUD_RATE         = 115_200,
            DATA_BITS         = 8,
            STOP_BITS         = 1,
            PARITY_BITS       = 0)

(
    // Global signals
    input  wire                            aclk,
    input  wire                            aresetn,

    // Transmitter
    input  wire                            uart_rx,
    output wire                            uart_tx,

    // Flag State
    output wire                            tx_done,
    output wire                            rx_done,
    output wire   [1:0]                    rx_error,

    // Interface Slave
    input  wire   [AXI_DATA_WIDTH-1:0]     s_axis_tdata,
    input  wire                            s_axis_tvalid,
    output wire                            s_axis_tready,

    // Interface Master
    output wire   [AXI_DATA_WIDTH-1:0]     m_axis_tdata,
    output wire                            m_axis_tvalid,
    input  wire                            m_axis_tready
);

    axis_uart_transceiver_wrapper_sv #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .CLOCK(CLOCK),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS),
        .PARITY_BITS(PARITY_BITS)
    ) 

    axis_uart_transceiver_wrapper_sv_inst
    
    (
        .aclk(aclk),
        .aresetn(aresetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .tx_done(tx_done),
        .rx_done(rx_done),
        .rx_error(rx_error),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

endmodule
