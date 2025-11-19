`timescale 1ns / 1ps
module spi_bridge (
    input clk,
    input rst_n,
    input sclk,
    input cs_n,
    input mosi,
    output miso,
    output byte_sync,
    output[7:0] data_in,
    input[7:0] data_out
);

    reg[7:0] data_in_reg;
    reg[7:0] data_out_reg;
    reg[2:0] bit_cnt;
    
    reg sclk_d1, sclk_d2;
    wire sclk_posedge = (sclk_d1 == 1'b1) && (sclk_d2 == 1'b0);
    wire sclk_negedge = (sclk_d1 == 1'b0) && (sclk_d2 == 1'b1);
    
    reg  miso_reg;
    reg  byte_sync_pulse;

    assign data_in = data_in_reg;
    assign byte_sync = byte_sync_pulse;
    assign miso = (cs_n) ? 1'bz : miso_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'h00;
            data_out_reg <= 8'h00;
            bit_cnt <= 3'd0;
            sclk_d1 <= 1'b0;
            sclk_d2 <= 1'b0;
            miso_reg <= 1'b0;
            byte_sync_pulse <= 1'b0;
        end else begin
            sclk_d1 <= sclk;
            sclk_d2 <= sclk_d1;
            
            byte_sync_pulse <= 1'b0;

            if (cs_n) begin
                bit_cnt <= 3'd0;
                miso_reg <= 1'b0;
                data_out_reg <= data_out;
            end 
            else begin
                if (sclk_posedge) begin
                    data_in_reg <= {data_in_reg[6:0], mosi};
                    bit_cnt <= bit_cnt + 1;
                    
                    if (bit_cnt == 3'd7) begin
                        byte_sync_pulse <= 1'b1;
                        data_out_reg <= data_out;
                    end
                end
                
                if (sclk_negedge) begin
                    miso_reg <= data_out_reg[7];
                    data_out_reg <= {data_out_reg[6:0], 1'b0};
                end
            end
        end
    end
    
endmodule
