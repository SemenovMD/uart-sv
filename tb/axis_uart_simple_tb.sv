`timescale 1ns / 1ps

module axis_uart_simple_tb;

    import pkg_tb::*;

    axis_if m_axis();
    axis_if s_axis();

    logic                           aclk;
    logic                           aresetn;

    logic                           uart_rx;
    logic                           uart_tx;

    // Test data
    logic [7:0]                     test_data[] = '{8'hA5, 8'h5A, 8'hFF, 8'h00, 8'h55, 8'hAA};
    logic [7:0]                     received_data[$];
    int                             test_index = 0;

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

    // Clock generation
    initial
    begin
        aclk = 0;
        forever #(CLK_PERIOD_NS/2) aclk = ~aclk;
    end

    // Reset generation
    initial 
    begin
        aresetn = 0;
        #(20*CLK_PERIOD_NS) aresetn = 1; 
    end

    // Initialization
    initial 
    begin
        s_axis.tvalid = 0;
        s_axis.tdata = 0;
        m_axis.tready = 1;  // Always ready to receive
        uart_rx = 1;        // Idle state
    end

    // Monitor received data
    always @(posedge aclk) begin
        if (m_axis.tvalid && m_axis.tready) begin
            received_data.push_back(m_axis.tdata);
            $display("Time %0t: Received: 0x%02h", $time, m_axis.tdata);
        end
    end

    // Main test sequence
    initial
    begin
        wait(aresetn);
        #(10*CLK_PERIOD_NS);

        // Send test data through AXI-Stream
        for (int i = 0; i < test_data.size(); i++) begin
            @(posedge aclk);
            s_axis.tdata = test_data[i];
            s_axis.tvalid = 1;
            wait(s_axis.tready);
            @(posedge aclk);
            s_axis.tvalid = 0;
            s_axis.tdata = 0;
            
            // Wait for transmission to complete
            #(20*DUTY_BITS);
        end

        // Wait for all data to be received
        #(100*CLK_PERIOD_NS);

        // Check results
        $display("Test completed:");
        $display("Sent %0d bytes", test_data.size());
        $display("Received %0d bytes", received_data.size());
        
        if (received_data.size() == test_data.size()) begin
            $display("All data received successfully!");
            for (int i = 0; i < test_data.size(); i++) begin
                if (received_data[i] === test_data[i]) begin
                    $display("Data %0d: 0x%02h - OK", i, test_data[i]);
                end else begin
                    $display("Data %0d: Expected 0x%02h, Got 0x%02h - ERROR", 
                             i, test_data[i], received_data[i]);
                end
            end
        end else begin
            $display("ERROR: Data count mismatch!");
        end

        $finish;
    end

endmodule 