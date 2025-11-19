module regs (
    // peripheral clock signals
    input clk,
    input rst_n,

    // decoder facing signals
    input read,
    input write,
    input [5:0] addr,
    output reg [7:0] data_read,
    input [7:0] data_write,

    // counter programming signals
    input [15:0] counter_val,
    output reg [15:0] period,
    output reg en,
    output reg count_reset,
    output reg upnotdown,
    output reg [7:0] prescale,

    // PWM signal programming values
    output reg pwm_en,
    output reg [7:0] functions,
    output reg [15:0] compare1,
    output reg [15:0] compare2
);

// ------------------------------------------------------------
// INTERNAL WIRES FOR REGISTER ACCESS
// ------------------------------------------------------------
wire addr_valid =
    (addr == 6'h00) || (addr == 6'h01) ||   // PERIOD
    (addr == 6'h02) ||                      // COUNTER_EN
    (addr == 6'h03) || (addr == 6'h04) ||   // COMPARE1
    (addr == 6'h05) || (addr == 6'h06) ||   // COMPARE2
    (addr == 6'h07) ||                      // COUNTER_RESET
    (addr == 6'h08) || (addr == 6'h09) ||   // COUNTER_VAL (RO)
    (addr == 6'h0A) ||                      // PRESCALE
    (addr == 6'h0B) ||                      // UPNOTDOWN
    (addr == 6'h0C) ||                      // PWM_EN
    (addr == 6'h0D);                        // FUNCTIONS


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        period     <= 16'h0000;
        en         <= 1'b0;
        compare1   <= 16'h0000;
        compare2   <= 16'h0000;
        prescale   <= 8'h00;
        upnotdown  <= 1'b1;
        pwm_en     <= 1'b0;
        functions  <= 8'h00;
        count_reset <= 1'b0;
    end else begin
        // default: counter_reset auto-clear
        count_reset <= 1'b0;

        if (write) begin
            case (addr)

                // PERIOD (16 bit)
                6'h00: period[7:0]   <= data_write;
                6'h01: period[15:8]  <= data_write;

                // COUNTER_EN
                6'h02: en <= data_write[0];

                // COMPARE1 (16 bit)
                6'h03: compare1[7:0]  <= data_write;
                6'h04: compare1[15:8] <= data_write;

                // COMPARE2 (16 bit)
                6'h05: compare2[7:0]  <= data_write;
                6'h06: compare2[15:8] <= data_write;

                // COUNTER_RESET (write 1 -> pulse)
                6'h07: count_reset <= data_write[0];

                // PRESCALE
                6'h0A: prescale <= data_write;

                // UPNOTDOWN
                6'h0B: upnotdown <= data_write[0];

                // PWM_EN
                6'h0C: pwm_en <= data_write[0];

                // FUNCTIONS (2 bits)
                6'h0D: functions[1:0] <= data_write[1:0];

                default: ; // ignore invalid address
            endcase
        end
    end
end


always @(*) begin
    if (!read || !addr_valid) begin
        data_read = 8'h00;
    end else begin
        case (addr)

            // PERIOD (16 bit)
            6'h00: data_read = period[7:0];
            6'h01: data_read = period[15:8];

            // COUNTER_EN
            6'h02: data_read = {7'b0, en};

            // COMPARE1
            6'h03: data_read = compare1[7:0];
            6'h04: data_read = compare1[15:8];

            // COMPARE2
            6'h05: data_read = compare2[7:0];
            6'h06: data_read = compare2[15:8];

            // COUNTER_RESET (RO ? always 0)
            6'h07: data_read = 8'h00;

            // COUNTER_VAL (16 bit) ? read-only
            6'h08: data_read = counter_val[7:0];
            6'h09: data_read = counter_val[15:8];

            // PRESCALE
            6'h0A: data_read = prescale;

            // UPNOTDOWN
            6'h0B: data_read = {7'b0, upnotdown};

            // PWM_EN
            6'h0C: data_read = {7'b0, pwm_en};

            // FUNCTIONS
            6'h0D: data_read = functions;

            default: data_read = 8'h00;
        endcase
    end
end

endmodule
