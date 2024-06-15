module axis_uart_tx

#(parameter AXI_DATA_WIDTH    = 8,
            CLOCK             = 100_000_000,
            BAUD_RATE         = 115_200,
            DATA_BITS         = 8,
            STOP_BITS         = 1,
            PARITY_BITS       = 0)

(
    // Global signals
    input   logic                               aclk,
    input   logic                               aresetn,

    // Transmitter
    output  logic                               uart_tx,

    // Flag State
    output  logic                               tx_done,

    // Interface
    axis_if.s_axis                              s_axis
);

    localparam COUNT_SPEED  = CLOCK/BAUD_RATE;
    localparam DATA_BYTE    = AXI_DATA_WIDTH/DATA_BITS;

    logic [$clog2(COUNT_SPEED)-1:0]     count_baud;
    logic [$clog2(DATA_BITS)-1:0]       count_bit;
    logic [$clog2(DATA_BYTE)-1:0]       count_byte;
    logic [$clog2(DATA_BYTE)-1:0]       count_parity_byte;  

    logic [AXI_DATA_WIDTH-1:0]          uart_buf;                  

    // FSM UART_TX
    typedef enum logic [2:0]
    {  
        UART_TX_IDLE,
        UART_TX_START,
        UART_TX_DATA,
        UART_TX_PARITY,
        UART_TX_STOP,
        UART_TX_PARITY_DONE,
        UART_TX_STOP_DONE
    } state_type_uart_tx;

    state_type_uart_tx state_tx;

    always_ff @(posedge aclk)
    begin
        if (!aresetn)
        begin
            state_tx <= UART_TX_IDLE;
            tx_done <= 1'b0;
            s_axis.tready <= 1'b0;
            count_baud <= '0;
            count_bit <= '0;
            count_byte <= '0;
            count_parity_byte <= '0;
        end else
        begin
            case (state_tx)
                UART_TX_IDLE:
                    begin
                        if (!s_axis.tvalid)
                        begin
                            state_tx <= UART_TX_IDLE;
                        end else
                        begin
                            state_tx <= UART_TX_START;
                            s_axis.tready <= 1'b1;
                            uart_buf <= s_axis.tdata;
                        end

                        tx_done <= 1'b0;
                    end
                UART_TX_START:
                    begin
                        if (count_baud < COUNT_SPEED - 1)
                        begin
                            state_tx <= UART_TX_START;
                            count_baud <= count_baud + 1;
                        end else
                        begin
                            state_tx <= UART_TX_DATA;
                            count_baud <= '0;
                        end

                        s_axis.tready <= 1'b0;
                    end
                UART_TX_DATA:
                    begin
                        if (!((count_baud == COUNT_SPEED - 1) && (count_bit == DATA_BITS - 1) && (count_byte == DATA_BYTE - 1)))
                        begin
                            if (!((count_baud == COUNT_SPEED - 1) && (count_bit == DATA_BITS - 1)))
                            begin
                                if (count_baud < COUNT_SPEED - 1)
                                begin
                                    state_tx <= UART_TX_DATA;
                                    count_baud <= count_baud + 1;
                                end else
                                begin
                                    state_tx <= UART_TX_DATA;
                                    count_baud <= '0;
                                    count_bit <= count_bit + 1;
                                end
                            end else
                            begin
                                state_tx <= UART_TX_PARITY;
                                count_baud <= '0;
                                count_bit <= '0;
                                count_byte <= count_byte + 1;
                            end
                        end else
                        begin
                            state_tx <= UART_TX_PARITY_DONE;
                            count_baud <= '0;
                            count_bit <= '0;
                        end
                    end
                UART_TX_PARITY:
                    begin
                        if (count_baud < COUNT_SPEED - 1)
                        begin
                            state_tx <= UART_TX_PARITY;
                            count_baud <= count_baud + 1;
                        end else
                        begin
                            state_tx <= UART_TX_STOP;
                            count_baud <= '0;
                            count_parity_byte <= count_parity_byte + 1;
                        end
                    end
                UART_TX_STOP:
                    begin
                        if (!((count_baud == COUNT_SPEED - 1) && (count_bit == STOP_BITS - 1)))
                        begin
                            if (count_baud < COUNT_SPEED - 1)
                            begin
                                state_tx <= UART_TX_STOP;
                                count_baud <= count_baud + 1;
                            end else
                            begin
                                state_tx <= UART_TX_STOP;
                                count_baud <= '0;
                                count_bit <= count_bit + 1;
                            end
                        end else
                        begin
                            state_tx <= UART_TX_START;
                            count_baud <= '0;
                            count_bit <= '0;
                        end
                    end
                UART_TX_PARITY_DONE:
                    begin
                        if (count_baud < COUNT_SPEED - 1)
                        begin
                            state_tx <= UART_TX_PARITY_DONE;
                            count_baud <= count_baud + 1;
                        end else
                        begin
                            state_tx <= UART_TX_STOP_DONE;
                            count_baud <= '0;
                        end
                    end
                UART_TX_STOP_DONE:
                    begin
                        if (!((count_baud == COUNT_SPEED - 1) && (count_bit == STOP_BITS - 1)))
                        begin
                            if (count_baud < COUNT_SPEED - 1)
                            begin
                                state_tx <= UART_TX_STOP_DONE;
                                count_baud <= count_baud + 1;
                            end else
                            begin
                                state_tx <= UART_TX_STOP_DONE;
                                count_baud <= '0;
                                count_bit <= count_bit + 1;
                            end
                        end else
                        begin
                            state_tx <= UART_TX_IDLE;
                            count_baud <= '0;
                            count_bit <= '0;
                            count_byte <= '0;
                            count_parity_byte <= '0;   
                            tx_done <= 1'b1;
                        end
                    end
            endcase
        end
    end
    
    always_ff @(posedge aclk)
    begin
        if (!aresetn)
        begin
            uart_tx <= 1'b1;
        end else
        begin
            case (state_tx)
                UART_TX_IDLE:
                    begin
                        uart_tx <= 1'b1;
                    end
                UART_TX_START:
                    begin
                        uart_tx <= 1'b0;
                    end
                UART_TX_DATA:
                    begin
                        case (count_bit)
                            count_bit: uart_tx <= uart_buf[AXI_DATA_WIDTH - DATA_BITS + count_bit - count_byte*DATA_BITS];
                        endcase
                    end
                UART_TX_PARITY, UART_TX_PARITY_DONE:
                    begin
                        if (PARITY_BITS)
                        begin
                            uart_tx <= ^uart_buf[(AXI_DATA_WIDTH - 1 - count_parity_byte*DATA_BITS) -: DATA_BITS];
                        end else
                        begin
                            uart_tx <= !(^uart_buf[(AXI_DATA_WIDTH - 1 - count_parity_byte*DATA_BITS) -: DATA_BITS]);
                        end
                    end
                UART_TX_STOP, UART_TX_STOP_DONE:
                    begin
                        uart_tx <= 1'b1;
                    end
            endcase
        end
    end

endmodule