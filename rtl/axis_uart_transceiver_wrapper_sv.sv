module axis_uart_transceiver_wrapper_sv

#(parameter AXI_DATA_WIDTH    = 8,
            CLOCK             = 100_000_000,
            BAUD_RATE         = 115_200,
            DATA_BITS         = 8,
            STOP_BITS         = 1,
            PARITY_BITS       = 0)

(
    // Global signals
    input  logic                            aclk,
    input  logic                            aresetn,

    // Transmitter
    input  logic                            uart_rx,
    output logic                            uart_tx,

    // Flag State
    output logic                            tx_done,
    output logic                            rx_done,
    output logic   [1:0]                    rx_error,

    // Interface Slave
    input  logic   [AXI_DATA_WIDTH-1:0]     s_axis_tdata,
    input  logic                            s_axis_tvalid,
    output logic                            s_axis_tready,

    // Interface Master
    output logic   [AXI_DATA_WIDTH-1:0]     m_axis_tdata,
    output logic                            m_axis_tvalid,
    input  logic                            m_axis_tready
);

    axis_if #(.AXI_DATA_WIDTH(AXI_DATA_WIDTH)) m_axis();
    axis_if #(.AXI_DATA_WIDTH(AXI_DATA_WIDTH)) s_axis();

    generate
        assign m_axis_tdata  = m_axis.tdata;
        assign m_axis_tvalid = m_axis.tvalid;
        assign m_axis.tready = m_axis_tready;

        assign s_axis.tdata  = s_axis_tdata;
        assign s_axis.tvalid = s_axis_tvalid;
        assign s_axis_tready = s_axis.tready;
    endgenerate
    
    axis_uart_transceiver #
    (
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .CLOCK(CLOCK),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS),
        .PARITY_BITS(PARITY_BITS)
    )
    
    axis_uart_transceiver_inst
    
    (
        .*
    );

endmodule