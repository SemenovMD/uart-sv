`timescale 1ns / 1ps

module axis_uart_tb;

    import pkg_tb::*;

    axis_if m_axis();
    axis_if s_axis();

    logic                           aclk;
    logic                           aresetn;

    logic                           uart_rx;
    logic                           uart_tx;

    logic [1:0]                     flag;

    // Test data storage
    logic [7:0]                     tx_data_queue[$];
    logic [7:0]                     rx_data_queue[$];
    logic [7:0]                     expected_data;
    logic [7:0]                     received_data;
    int                             test_count = 0;
    int                             error_count = 0;

    axis_uart #
    (
        .CLOCK(CLOCK),
        .BAUD_RATE(BAUD_RATE)
    )
    axis_uart_inst 
    (
        .aclk(aclk),
        .aresetn(aresetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
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
        #(10*CLK_PERIOD_NS) aresetn = 1; 
    end

    initial 
    begin
        s_axis.tvalid = 0;
        s_axis.tdata = 0;
        m_axis.tready = 0;

        uart_rx = 1;

        flag = 0;
    end

    // Monitor for received data
    always @(posedge aclk) begin
        if (m_axis.tvalid && m_axis.tready) begin
            received_data = m_axis.tdata;
            rx_data_queue.push_back(received_data);
            $display("Time %0t: Received data: 0x%02h", $time, received_data);
            
            if (tx_data_queue.size() > 0) begin
                expected_data = tx_data_queue.pop_front();
                if (received_data === expected_data) begin
                    $display("Time %0t: Data match! Expected: 0x%02h, Received: 0x%02h", 
                             $time, expected_data, received_data);
                end else begin
                    $display("Time %0t: DATA MISMATCH! Expected: 0x%02h, Received: 0x%02h", 
                             $time, expected_data, received_data);
                    error_count++;
                end
                test_count++;
            end
        end
    end

    initial
    begin
        #(15*CLK_PERIOD_NS);

        fork
            // AXI-Stream Slave - Send data to UART TX
            forever
            begin
                repeat ($urandom_range(AXI_TRAN_MIN_DELAY, AXI_TRAN_MAX_DELAY)) @(posedge aclk);
                s_axis.tdata = $random;
                tx_data_queue.push_back(s_axis.tdata);
                s_axis.tvalid = 1;
                wait(s_axis.tready);
                @(posedge aclk);
                s_axis.tdata = 0;
                s_axis.tvalid = 0;
            end

            // AXI-Stream Master - Receive data from UART RX
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

            // UART RX - Simulate external UART data
            forever
            begin
                repeat ($urandom_range(UART_RX_MIN_DELAY, UART_RX_MAX_DELAY))
                begin
                    #DUTY_BITS;
                end
                
                // Send start bit
                uart_rx = 0;
                #DUTY_BITS;

                // Send data bits
                for (int i = 0; i < DATA_BITS; i++) 
                begin
                    uart_rx = $random;
                    #DUTY_BITS;
                end

                // Send stop bit(s)
                uart_rx = 1;
                #(DUTY_BITS * STOP_BITS);
            end
        join

        // Run for a reasonable time then finish
        #(1000*CLK_PERIOD_NS);
        
        $display("Test completed:");
        $display("Total tests: %0d", test_count);
        $display("Errors: %0d", error_count);
        $display("Success rate: %0.2f%%", (test_count > 0) ? (100.0 * (test_count - error_count) / test_count) : 0.0);
        
        $finish;
    end

endmodule