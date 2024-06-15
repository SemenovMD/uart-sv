module axis_uart_rx

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

    // Receiver
    input   logic                               uart_rx,

    // Flag State
    output  logic                               rx_done,
    output  logic [1:0]                         rx_error,

    // Interface
    axis_if.m_axis                              m_axis
);

    localparam COUNT_SPEED  = CLOCK/BAUD_RATE;
    localparam DATA_BYTE    = AXI_DATA_WIDTH/DATA_BITS;
    localparam COUNT_WDT    = COUNT_SPEED*(DATA_BYTE*(1 + DATA_BITS + 1 + STOP_BITS));

    logic [$clog2(COUNT_SPEED)-1:0]     count_baud;
    logic [$clog2(DATA_BITS)-1:0]       count_bit;
    logic [$clog2(DATA_BYTE)-1:0]       count_byte;
    logic [$clog2(DATA_BYTE)-1:0]       count_parity_byte;

    logic [AXI_DATA_WIDTH-1:0]          uart_buf;

    logic [2:0]                         majority_in;
    logic                               majority_out;

    logic [$clog2(COUNT_WDT)-1:0]       count_wdt;
    logic                               flag_wdt;

    // FSM UART_RX
    typedef enum logic [2:0]
    {  
        UART_RX_IDLE,
        UART_RX_START,
        UART_RX_DATA,
        UART_RX_PARITY,
        UART_RX_STOP,
        UART_RX_PARITY_DONE,
        UART_RX_STOP_DONE,
        UART_RX_BLOCK
    } state_type_uart_rx;

    state_type_uart_rx state_rx;

    always_ff @(posedge aclk)
    begin
        if (!aresetn)
        begin
            state_rx <= UART_RX_IDLE;
            rx_done <= 1'b0;
            rx_error <= '0;
            count_baud <= '0;
            count_bit <= '0;
            count_byte <= '0;
            count_parity_byte <= '0;
        end else
        begin
            case (state_rx)
                UART_RX_IDLE:
                    begin
                        if (uart_rx)
                        begin
                            state_rx <= UART_RX_IDLE;
                        end else
                        begin
                            state_rx <= UART_RX_START;
                        end

                        rx_done <= 1'b0;
                    end
                UART_RX_START:
                    begin
                        if (count_baud < COUNT_SPEED - 1)
                        begin
                            state_rx <= UART_RX_START;
                            count_baud <= count_baud + 1;
                        end else
                        begin
                            count_baud <= '0;

                            if (!majority_out)
                            begin
                                state_rx <= UART_RX_DATA;
                            end else
                            begin
                                state_rx <= UART_RX_BLOCK;
                                rx_error <= 2'b01;
                            end
                        end
                    end
                UART_RX_DATA:
                    begin
                        if (!((count_baud == COUNT_SPEED - 1) && (count_bit == DATA_BITS - 1) && (count_byte == DATA_BYTE - 1)))
                        begin
                            if (!((count_baud == COUNT_SPEED - 1) && (count_bit == DATA_BITS - 1)))
                            begin
                                if (count_baud < COUNT_SPEED - 1)
                                begin
                                    state_rx <= UART_RX_DATA;
                                    count_baud <= count_baud + 1;
                                end else
                                begin
                                    state_rx <= UART_RX_DATA;
                                    count_baud <= '0;
                                    count_bit <= count_bit + 1;
                                end
                            end else
                            begin
                                state_rx <= UART_RX_PARITY;
                                count_baud <= '0;
                                count_bit <= '0;
                                count_byte <= count_byte + 1;
                            end
                        end else
                        begin
                            state_rx <= UART_RX_PARITY_DONE;
                            count_baud <= '0;
                            count_bit <= '0;
                        end
                    end
                UART_RX_PARITY:
                    begin
                        if (count_baud < COUNT_SPEED - 1)
                        begin
                            state_rx <= UART_RX_PARITY;
                            count_baud <= count_baud + 1;
                        end else
                        begin
                            count_baud <= '0;

                            if (PARITY_BITS)
                            begin
                                if (majority_out == ^uart_buf[(AXI_DATA_WIDTH - 1 - count_parity_byte*DATA_BITS) -: DATA_BITS])
                                begin
                                    state_rx <= UART_RX_STOP;
                                end else
                                begin
                                    state_rx <= UART_RX_BLOCK;
                                    rx_error <= 2'b11;
                                end
                            end else
                            begin
                                if (majority_out == !(^uart_buf[(AXI_DATA_WIDTH - 1 - count_parity_byte*DATA_BITS) -: DATA_BITS]))
                                begin
                                    state_rx <= UART_RX_STOP;
                                end else
                                begin
                                    state_rx <= UART_RX_BLOCK;
                                    rx_error <= 2'b11;
                                end
                            end
                        end
                    end
                UART_RX_STOP:
                    begin
                        if (!((count_baud == COUNT_SPEED - 1) && (count_bit == STOP_BITS - 1)))
                        begin
                            if (count_baud < COUNT_SPEED - 1)
                            begin
                                state_rx <= UART_RX_STOP;
                                count_baud <= count_baud + 1;
                            end else
                            begin
                                state_rx <= UART_RX_STOP;
                                count_baud <= '0;
                                count_bit <= count_bit + 1;
                            end
                        end else
                        begin
                            count_baud <= '0;
                            count_bit <= '0;
                            count_parity_byte <= count_parity_byte + 1;

                            if (majority_out)
                            begin
                                state_rx <= UART_RX_START;
                            end else
                            begin
                                state_rx <= UART_RX_BLOCK;
                                rx_error <= 2'b10;
                            end
                        end
                    end
                UART_RX_PARITY_DONE:
                    begin
                        if (count_baud < COUNT_SPEED - 1)
                        begin
                            state_rx <= UART_RX_PARITY_DONE;
                            count_baud <= count_baud + 1;
                        end else
                        begin
                            count_baud <= '0;

                            if (PARITY_BITS)
                            begin
                                if (majority_out == ^uart_buf[(AXI_DATA_WIDTH - 1 - count_parity_byte*DATA_BITS) -: DATA_BITS])
                                begin
                                    state_rx <= UART_RX_STOP_DONE;
                                end else
                                begin
                                    state_rx <= UART_RX_BLOCK;
                                    rx_error <= 2'b11;
                                end
                            end else
                            begin
                                if (majority_out == !(^uart_buf[(AXI_DATA_WIDTH - 1 - count_parity_byte*DATA_BITS) -: DATA_BITS]))
                                begin
                                    state_rx <= UART_RX_STOP_DONE;
                                end else
                                begin
                                    state_rx <= UART_RX_BLOCK;
                                    rx_error <= 2'b11;
                                end
                            end
                        end
                    end
                UART_RX_STOP_DONE:
                    begin
                        if (!((count_baud == COUNT_SPEED - 1) && (count_bit == STOP_BITS - 1)))
                        begin
                            if (count_baud < COUNT_SPEED - 1)
                            begin
                                state_rx <= UART_RX_STOP_DONE;
                                count_baud <= count_baud + 1;
                            end else
                            begin
                                state_rx <= UART_RX_STOP_DONE;
                                count_baud <= '0;
                                count_bit <= count_bit + 1;
                            end
                        end else
                        begin
                            count_baud <= '0;
                            count_bit <= '0;
                            count_byte <= '0;
                            count_parity_byte <= '0;

                            if (majority_out)
                            begin
                                state_rx <= UART_RX_IDLE;
                                rx_done <= 1'b1;
                            end else
                            begin
                                state_rx <= UART_RX_BLOCK;
                                rx_error <= 2'b10;
                            end
                        end
                    end
                UART_RX_BLOCK:
                    begin
                        count_baud <= '0;
                        count_bit <= '0;
                        count_byte <= '0;
                        count_parity_byte <= '0;

                        if (flag_wdt)
                        begin
                            state_rx <= UART_RX_BLOCK;
                        end else
                        begin
                            state_rx <= UART_RX_IDLE;
                            rx_error <= 2'b00;
                        end
                    end
            endcase
        end
    end

    // Majority Element
    always_ff @(posedge aclk)
    begin
        if (!aresetn)
        begin
            majority_in <= '0;
            uart_buf <= '0;
        end else
        begin
            case (state_rx)
                UART_RX_IDLE:
                    begin
                        majority_in <= '0;
                    end
                UART_RX_START, UART_RX_STOP, UART_RX_PARITY, UART_RX_STOP_DONE, UART_RX_PARITY_DONE:
                    begin
                        case (count_baud)
                            COUNT_SPEED/2 - 1: majority_in[0] <= uart_rx;
                            COUNT_SPEED/2    : majority_in[1] <= uart_rx;
                            COUNT_SPEED/2 + 1: majority_in[2] <= uart_rx;
                            default:           majority_in <= majority_in;
                        endcase
                    end
                UART_RX_DATA:
                    begin
                        case (count_baud)
                            COUNT_SPEED/2 - 1: majority_in[0] <= uart_rx;
                            COUNT_SPEED/2    : majority_in[1] <= uart_rx;
                            COUNT_SPEED/2 + 1: majority_in[2] <= uart_rx;
                            COUNT_SPEED/2 + 2: uart_buf[AXI_DATA_WIDTH - DATA_BITS + count_bit - count_byte*DATA_BITS] <= uart_rx;
                            default:           majority_in <= majority_in;
                        endcase
                    end
            endcase
        end
    end

    always_comb
    begin
        begin
            case (majority_in)
                3'b000, 3'b001, 3'b010, 3'b100: majority_out = 0;
                3'b011, 3'b101, 3'b110, 3'b111: majority_out = 1;
            endcase
        end
    end

    // FSM Watchdog Timer
    typedef enum logic
    {  
        IDLE_WDT,
        TIMER_WDT
    } state_type_wdt;

    state_type_wdt state_wdt;

    always_ff @(posedge aclk)
    begin
        if (!aresetn)
        begin
            state_wdt <= IDLE_WDT;
            count_wdt <= '0;
            flag_wdt <= 1'b0;
        end else
        begin
            case (state_wdt)
                IDLE_WDT:
                    begin
                        if (uart_rx)
                        begin
                            state_wdt <= IDLE_WDT;
                        end else
                        begin
                            state_wdt <= TIMER_WDT;
                            flag_wdt <= 1'b1;
                        end
                    end
                TIMER_WDT:
                    begin
                        if (count_wdt < COUNT_WDT - 1)
                        begin
                            state_wdt <= TIMER_WDT;
                            count_wdt <= count_wdt + 1;
                        end else
                        begin
                            state_wdt <= IDLE_WDT;
                            count_wdt <= '0;
                            flag_wdt <= 1'b0;
                        end
                    end
            endcase
        end
    end

    // FSM AXI-Stream
    typedef enum logic
    {  
        IDLE_RD,
        HAND_RD
    } state_type_rd;

    state_type_rd state_rd;

    always_ff @(posedge aclk)
    begin
        if (!aresetn)
        begin
            state_rd <= IDLE_RD;
            m_axis.tvalid <= 1'b0;
            m_axis.tdata <= '0;
        end else
        begin
            case (state_rd)
                IDLE_RD:
                    begin
                        if (!rx_done)
                        begin
                            state_rd <= IDLE_RD;
                        end else
                        begin
                            state_rd <= HAND_RD;
                            m_axis.tvalid <= 1'b1;
                            m_axis.tdata <= uart_buf;
                        end
                    end
                HAND_RD:
                    begin
                        if (!m_axis.tready)
                        begin
                            state_rd <= HAND_RD;
                        end else
                        begin
                            state_rd <= IDLE_RD;
                            m_axis.tvalid <= 1'b0;
                            m_axis.tdata <= '0;
                        end
                    end
            endcase
        end
    end

endmodule