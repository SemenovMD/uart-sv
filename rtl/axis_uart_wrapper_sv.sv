module axis_uart_wrapper_sv

#(
    parameter   CLOCK       = 100_000_000,
    parameter   BAUD_RATE   = 115_200
)

(
    input   logic           aclk,
    input   logic           aresetn,

    input   logic           uart_rx,
    output  logic           uart_tx,

    input   logic   [7:0]   s_axis_tdata,
    input   logic           s_axis_tvalid,
    output  logic           s_axis_tready,

    output  logic   [7:0]   m_axis_tdata,
    output  logic           m_axis_tvalid,
    input   logic           m_axis_tready
);

    axis_if m_axis();
    axis_if s_axis();

    assign m_axis_tdata  = m_axis.tdata;
    assign m_axis_tvalid = m_axis.tvalid;
    assign m_axis.tready = m_axis_tready;

    assign s_axis.tdata  = s_axis_tdata;
    assign s_axis.tvalid = s_axis_tvalid;
    assign s_axis_tready = s_axis.tready;
    
    axis_uart #(.CLOCK(CLOCK), .BAUD_RATE(BAUD_RATE)) axis_uart_inst (.*);
    
endmodule