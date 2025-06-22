interface axis_if;

    logic   [7:0]   tdata;
    logic           tvalid;
    logic           tready;

    modport m_axis
    (
        output tdata,
        output tvalid,
        input  tready
    );

    modport s_axis
    (
        input  tdata,
        input  tvalid,
        output tready
    );

endinterface
