`timescale 1ns / 1ps

module axis_uart_tb;

    import pkg_tb::*;

    axis_if #(.AXI_DATA_WIDTH(AXI_DATA_WIDTH)) m_axis();
    axis_if #(.AXI_DATA_WIDTH(AXI_DATA_WIDTH)) s_axis();

    logic                           aclk;
    logic                           aresetn;

    logic                           uart_rx;
    logic                           uart_tx;

    logic                           rx_done;
    logic [1:0]                     rx_error;
    logic                           tx_done;

    logic [1:0]                     flag;

    logic [DATA_BITS-1:0]           uart_reg_rx;
    logic                           uart_parity_rx;

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
        .aclk(aclk),
        .aresetn(aresetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .rx_done(rx_done),
        .rx_error(rx_error),
        .tx_done(tx_done),
        .m_axis(m_axis),
        .s_axis(s_axis)
    );

    initial
    begin
        aclk = 0;
        forever #(CLK_PERIOD_NS/2) aclk = ~aclk;
    end

    initial 
    begin
        aresetn = 0;
        #(10*CLK_PERIOD_NS/2) aresetn = 1; 
    end

    initial 
    begin
        s_axis.tvalid = 0;
        s_axis.tdata = 0;
        m_axis.tready = 0;

        uart_rx = 1;

        flag = 0;
        uart_reg_rx = 0;
        uart_parity_rx = 0;
    end

    initial
    begin
        #(15*CLK_PERIOD_NS/2);

        fork
            // AXI-Stream Slave
            forever
            begin
                repeat ($urandom_range(AXI_TRAN_MIN_DELAY, AXI_TRAN_MAX_DELAY)) @(posedge aclk);
                s_axis.tdata = $random;
                s_axis.tvalid = 1;
                wait(s_axis.tready);
                @(posedge aclk);
                s_axis.tdata = 0;
                s_axis.tvalid = 0;
            end

            // AXI-Stream Master
            forever
            begin
                repeat ($urandom_range(AXI_TRAN_MIN_DELAY, AXI_TRAN_MAX_DELAY)) @(posedge aclk);
                case (flag)
                    0:
                        begin
                            m_axis.tready = 1;
                            wait(m_axis.tvalid);
                            @(posedge aclk)
                            m_axis.tready = 0;
                            flag = $random;
                        end
                    1:
                        begin
                            wait(m_axis.tvalid);
                            @(posedge aclk);
                            m_axis.tready = 1;
                            @(posedge aclk);
                            m_axis.tready = 0;
                            flag = $random;
                        end
                    2:
                        begin
                            wait(m_axis.tvalid);
                            m_axis.tready = 1;
                            @(posedge aclk);
                            m_axis.tready = 0;
                            flag = $random;                                
                        end
                    3:
                        begin
                            wait(m_axis.tvalid);
                            repeat ($urandom_range(AXI_TRAN_MIN_DELAY, AXI_TRAN_MAX_DELAY)) @(posedge aclk);
                            m_axis.tready = 1;
                            @(posedge aclk);
                            m_axis.tready = 0;
                            flag = $random;
                        end
                endcase
            end

            // UART RX
            forever
            begin
                repeat ($urandom_range(UART_RX_MIN_DELAY, UART_RX_MAX_DELAY))
                begin
                    #DUTY_BITS;
                end
                
                for (int j = 0; j < AXI_DATA_WIDTH/DATA_BITS; j++)
                begin
                    uart_rx = 0;
                    #DUTY_BITS;

                    for (int i = 0; i < DATA_BITS; i++) 
                    begin
                        uart_rx = $random;
                        uart_reg_rx[i] = uart_rx;
                        #DUTY_BITS;
                    end

                    if (!PARITY_BITS)
                    begin
                        uart_parity_rx = !(^uart_reg_rx);
                        uart_rx = uart_parity_rx;
                    end else
                    begin
                        uart_parity_rx = ^uart_reg_rx;
                        uart_rx = uart_parity_rx;
                    end

                    #DUTY_BITS;

                    uart_rx = 1;
                    #(DUTY_BITS*STOP_BITS);
                end
            end
        join

        $finish;
    end

endmodule