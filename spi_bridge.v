module spi_bridge (
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input mosi,    
    output miso,   
    // internal facing 
    output reg byte_sync,
    output [7:0] data_in,
    input [7:0] data_out
);

    reg [2:0] bit_cnt; 
    reg [7:0] shift_rx;
    reg [7:0] shift_tx;
    reg miso_reg;

    assign data_in = shift_rx;
    assign miso = (cs_n) ? 1'bz : miso_reg;

    //Logica Citire pe front crescator
    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            bit_cnt <= 3'd0;
            shift_rx <= 8'd0;
            byte_sync <= 1'b0;
        end else begin
            shift_rx <= {shift_rx[6:0], mosi};
            bit_cnt <= bit_cnt + 1;
            
            
            if (bit_cnt == 3'd7)
                byte_sync <= 1'b1;
            else
                byte_sync <= 1'b0;
        end
    end

    // Logica Scriere pe front descrescator
    always @(negedge sclk or posedge cs_n) begin
        if (cs_n) begin
            miso_reg <= 1'b0;
            shift_tx <= 8'd0; 
        end else begin
            miso_reg <= shift_tx[7];
            
            if (bit_cnt == 3'd0) begin
                shift_tx <= {data_out[6:0], 1'b0};
                miso_reg <= data_out[7];
            end else begin
                shift_tx <= {shift_tx[6:0], 1'b0};
            end
        end
    end
endmodule
