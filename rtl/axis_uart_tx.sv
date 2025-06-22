module axis_uart_tx

#(
    parameter   CLOCK       = 100_000_000,
    parameter   BAUD_RATE   = 115_200
)

(
    input   logic                               aclk,
    input   logic                               aresetn,

    output  logic                               uart_tx,

    axis_if.s_axis                              s_axis
);

    localparam COUNT_SPEED  = CLOCK/BAUD_RATE;

    logic [$clog2(COUNT_SPEED)-1:0]     count_baud;
    logic [2:0]                         count_bit;

    logic [7:0]                         uart_buf;                  

    // FSM UART_TX
    typedef enum logic [1:0]
    {  
        UART_TX_IDLE,
        UART_TX_START,
        UART_TX_DATA,
        UART_TX_STOP
    } state_type_uart_tx;

    state_type_uart_tx state_tx;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_tx <= UART_TX_IDLE;
            s_axis.tready <= 1'd0;
            count_baud <= '0;
            count_bit <= '0;
        end else begin
            case (state_tx)
                UART_TX_IDLE:
                    begin
                        if (!s_axis.tvalid) begin
                            state_tx <= UART_TX_IDLE;
                        end else begin
                            state_tx <= UART_TX_START;
                            uart_buf <= s_axis.tdata;
                            s_axis.tready <= 1'd1;
                        end
                    end
                UART_TX_START:
                    begin
                        if (count_baud < COUNT_SPEED - 1'd1) begin
                            count_baud <= count_baud + 1'd1;
                        end else begin
                            state_tx <= UART_TX_DATA;
                            count_baud <= '0;
                        end

                        s_axis.tready <= 1'd0;
                    end
                UART_TX_DATA:
                    begin
                        if (!((count_baud == COUNT_SPEED - 1'd1) && (count_bit == 3'd7))) begin
                            if (count_baud < COUNT_SPEED - 1'd1) begin
                                count_baud <= count_baud + 1'd1;
                            end else begin
                                count_baud <= '0;
                                count_bit <= count_bit + 1'd1;
                            end
                        end else begin
                            state_tx <= UART_TX_STOP;
                            count_baud <= '0;
                            count_bit <= '0;
                        end
                    end
                UART_TX_STOP:
                    begin
                        if (count_baud < COUNT_SPEED - 1'd1) begin
                            count_baud <= count_baud + 1'd1;
                        end else begin
                            state_tx <= UART_TX_IDLE;
                            count_baud <= '0;
                        end
                    end
            endcase
        end
    end

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            uart_tx <= 1'd1;
        end else begin
            case (state_tx)
                UART_TX_IDLE:  uart_tx <= 1'd1;
                UART_TX_START: uart_tx <= 1'd0;
                UART_TX_DATA:  uart_tx <= uart_buf[count_bit];
                UART_TX_STOP:  uart_tx <= 1'd1;
            endcase
        end
    end

endmodule