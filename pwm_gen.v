module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input[15:0] period,
    input[7:0] functions,
    input[15:0] compare1,
    input[15:0] compare2,
    input[15:0] count_val,
    // top facing signals
    output pwm_out
);
    
    reg pwm_out_int;

    assign pwm_out = pwm_out_int;

    always @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
	begin
            pwm_out_int <= 1'b0;
        end
	else if (!pwm_en) 
	begin
            pwm_out_int <= 1'b0;
        end
        else
	begin
            if (functions == 8'd0) 
	    begin
	    		pwm_out_int <= 1'd1;
                	if (count_val < compare1) 
			begin
				pwm_out_int <= 1'd1;
			end
			else 
			begin
				pwm_out_int <= 1'd0;
			end
	    end
	    else if (functions == 8'd1)
	    begin
	    		pwm_out_int <= 1'd0;
                	if (count_val < compare1) 
			begin
				pwm_out_int <= 1'd0;
			end
			else 
			begin
				pwm_out_int <= 1'd1;
			end
	    end
	    else
	    begin
			pwm_out_int <= 0;
                	if (compare1 < compare2) 
			begin
				if (count_val >= compare1 && count_val < compare2)
				begin
					pwm_out_int <= 1'd1;
				end
				else
				begin
					pwm_out_int <= 1'd0;
				end

			end
			else 
			begin
				pwm_out_int <= 1'd1;
			end
	    end
	end
    end
endmodule