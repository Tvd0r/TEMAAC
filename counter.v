module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output[15:0] count_val,
    input[15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input[7:0] prescale
);

    reg [15:0] count_val_reg;
    reg [7:0]  prescale_cnt;

    assign count_val = count_val_reg;
    always @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
	begin
            count_val_reg <= 16'd0;
            prescale_cnt  <= 8'd0;
        end

        else if (count_reset) 
	begin
            count_val_reg <= 16'd0;
            prescale_cnt  <= 8'd0;
        end

        else if (en) 
	begin
            if (prescale_cnt == prescale) 
	    begin
                prescale_cnt <= 8'd0;
                if (!upnotdown) 
		begin 
                    if (count_val_reg == period - 1) 
		    begin
                        count_val_reg <= 16'd0;
                    end else begin
                        count_val_reg <= count_val_reg + 1;
                    end
                end 
                else begin 
                    if (count_val_reg == 16'd0) 
		    begin
                        count_val_reg <= period - 1;
                    end else begin
                        count_val_reg <= count_val_reg - 1;
                    end
                end
                
            end 
            else begin
                prescale_cnt <= prescale_cnt + 1;
            end
        end
    end

endmodule