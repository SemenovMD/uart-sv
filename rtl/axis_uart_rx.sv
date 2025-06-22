module axis_uart_rx

#(
    parameter   CLOCK       = 100_000_000,
    parameter   BAUD_RATE   = 115_200
)

(
    input   logic   aclk,
    input   logic   aresetn,

    input   logic   uart_rx,

    axis_if.m_axis  m_axis
);

    localparam COUNT_SPEED  = CLOCK/BAUD_RATE;

    logic [$clog2(COUNT_SPEED)-1:0]     count_baud;
    logic [2:0]                         count_bit;
    logic [7:0]                         uart_buf;
    logic [7:0]                         uart_reg;

    logic [2:0]                         majority_in;
    logic                               majority_out;

    logic                               flag;

    // FSM UART_RX
    typedef enum logic [1:0]
    {  
        UART_RX_IDLE,
        UART_RX_START,
        UART_RX_DATA,
        UART_RX_STOP
    } state_type_uart_rx;

    state_type_uart_rx state_rx;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_rx <= UART_RX_IDLE;
            count_baud <= '0;
            count_bit <= '0;
            flag <= 1'd0;
        end else begin
            case (state_rx)
                UART_RX_IDLE:
                    begin
                        if (uart_rx) begin
                            state_rx <= UART_RX_IDLE;
                        end else begin
                            state_rx <= UART_RX_START;
                        end

                        flag <= 1'd0;
                    end
                UART_RX_START:
                    begin
                        if (count_baud < COUNT_SPEED - 2'd2) begin
                            count_baud <= count_baud + 1'd1;
                        end else begin
                            count_baud <= '0;
                            
                            if (majority_out) begin
                                state_rx <= UART_RX_IDLE;
                            end else begin
                                state_rx <= UART_RX_DATA;
                            end
                        end
                    end
                UART_RX_DATA:
                    begin
                        if (!((count_baud == COUNT_SPEED - 1'd1) && (count_bit == 3'd7))) begin
                            if (count_baud < COUNT_SPEED - 1) begin
                                count_baud <= count_baud + 1'd1;
                            end else begin
                                count_baud <= '0;
                                count_bit <= count_bit + 1'd1;
                            end
                        end else begin
                            state_rx <= UART_RX_STOP;
                            count_baud <= '0;
                            count_bit <= '0;
                        end

                        if (count_baud == (COUNT_SPEED/2 + 2'd2)) begin
                            uart_buf[count_bit] <= majority_out;
                        end else begin
                            uart_buf <= uart_buf;
                        end
                    end
                UART_RX_STOP:
                    begin
                        if (count_baud < COUNT_SPEED - 1'd1) begin
                            count_baud <= count_baud + 1'd1;
                        end else begin
                            state_rx <= UART_RX_IDLE;
                            count_baud <= '0;

                            if (!majority_out) begin
                                flag <= 1'd0;
                            end else begin
                                flag <= 1'd1;
                                uart_reg <= uart_buf;
                            end
                        end
                    end
            endcase
        end
    end

    // Majority Element
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            majority_in <= '0;
        end else begin
            case (count_baud)
                COUNT_SPEED/2 - 1'd1: majority_in[0] <= uart_rx;
                COUNT_SPEED/2       : majority_in[1] <= uart_rx;
                COUNT_SPEED/2 + 1'd1: majority_in[2] <= uart_rx;
                default:              majority_in    <= majority_in;
            endcase
        end
    end

    always_comb begin
        case (majority_in)
            3'b000, 3'b001, 3'b010, 3'b100: majority_out = 1'd0;
            3'b011, 3'b101, 3'b110, 3'b111: majority_out = 1'd1;
        endcase
    end

    // FSM AXI-Stream
    typedef enum logic
    {  
        IDLE_WR,
        HAND_WR
    } state_type_wr;

    state_type_wr state_wr;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            state_wr <= IDLE_WR;
            m_axis.tvalid <= 1'd0;
            m_axis.tdata <= '0;
        end else begin
            case (state_wr)
                IDLE_WR:
                    begin
                        if (!flag) begin
                            state_wr <= IDLE_WR;
                        end else begin
                            state_wr <= HAND_WR;
                            m_axis.tdata <= uart_reg;
                            m_axis.tvalid <= 1'd1;
                        end
                    end
                HAND_WR:
                    begin
                        if (!m_axis.tready) begin
                            state_wr <= HAND_WR;
                        end else begin
                            state_wr <= IDLE_WR;
                            m_axis.tdata <= '0;
                            m_axis.tvalid <= 1'd0;
                        end
                    end
            endcase
        end
    end

endmodule