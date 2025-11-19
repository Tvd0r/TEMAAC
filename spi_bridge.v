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
    
    // Sincronizare semnal SCLK cu ceasul sistemului (CLK)
    reg sclk_d1, sclk_d2;
    wire sclk_posedge = (sclk_d1 == 1'b1) && (sclk_d2 == 1'b0);
    wire sclk_negedge = (sclk_d1 == 1'b0) && (sclk_d2 == 1'b1);
    
    reg  miso_reg;
    reg  byte_sync_pulse;

    assign data_in = data_in_reg;
    assign byte_sync = byte_sync_pulse;
    // MISO este High-Z cand CS_N este inactiv (1)
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
            // 1. Sincronizare SCLK
            sclk_d1 <= sclk;
            sclk_d2 <= sclk_d1;
            
            // 2. Reset puls byte_sync (este activ doar un ciclu de ceas)
            byte_sync_pulse <= 1'b0;

            if (cs_n) begin
                // Resetare stare cand nu suntem selectati
                bit_cnt <= 3'd0;
                // Cand CS e inactiv, pregatim in avans datele disponibile de la decodor
                data_out_reg <= data_out; 
                miso_reg <= 1'b0; // Reset MISO
            end 
            else begin
                // --- Captura datelor (MOSI) pe frontul crescator al SCLK ---
                if (sclk_posedge) begin
                    data_in_reg <= {data_in_reg[6:0], mosi};
                    bit_cnt <= bit_cnt + 1;
                    
                    // Daca am primit toti cei 8 biti (0..7)
                    if (bit_cnt == 3'd7) begin
                        byte_sync_pulse <= 1'b1; // Anuntam decodorul
                    end
                end
                
                // --- Transmiterea datelor (MISO) pe frontul descrescator al SCLK ---
                if (sclk_negedge) begin
                    // MISO primeste MSB-ul curent
                    miso_reg <= data_out_reg[7];
                    
                    if (bit_cnt == 3'd0) begin
                         data_out_reg <= {data_out[6:0], 1'b0}; // Incarcam byte nou si shiftam 1 bit
                         miso_reg <= data_out[7]; // Si actualizam imediat bitul pe fir
                    end else begin
                         // Altfel, continuam shiftarea normala
                         data_out_reg <= {data_out_reg[6:0], 1'b0};
                    end
                end
            end
        end
    end
    
endmodule