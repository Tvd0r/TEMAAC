module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,
    input[7:0] data_in,
    output[7:0] data_out,
    // register access signals
    output read,
    output write,
    output[5:0] addr,
    input[7:0] data_read,
    output[7:0] data_write
);

  
    // Registri interni pentru a controla iesirile
    reg read_int;
    reg write_int;
    reg [5:0] addr_int;
    reg [7:0] data_write_int;
    
    // Conectam iesirile modulelor la registrii interni
    assign read = read_int;
    assign write = write_int;
    assign addr = addr_int;
    assign data_write = data_write_int;
    
    // Conectam direct datele citite la iesire (pentru viteza maxima)
    assign data_out = data_read;

    // Definire Stari FSM
    localparam SETUP = 1'b0;
    localparam DATA  = 1'b1;
    
    reg state;
    
    // Registri pentru a memora comanda intre cei doi octeti
    reg operation;      // 1=Write, 0=Read
    reg [5:0] base_addr;// Adresa de baza

   
    // LOGICA FSM
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= SETUP;
            operation <= 0;
            base_addr <= 0;
            
            // Resetam iesirile
            read_int <= 0;
            write_int <= 0;
            addr_int <= 0;
            data_write_int <= 0;
        end else begin
            // Default: dezactivam semnalele de control (pulsuri de 1 ciclu)
            read_int <= 0;
            write_int <= 0;
            
            case (state)
            //Faza de setup
                SETUP: begin  
                    if (byte_sync) begin 
                   
                        operation   <= data_in[7];
                        base_addr   <= data_in[5:0];
                        
                      
                        if (data_in[7] == 1'b0) begin
                            read_int <= 1'b1;
                            addr_int <= data_in[5:0]; 
                        end
                        
                        state <= DATA;
                    end
                end
                //Faza de date
                DATA: begin
                    if (byte_sync) begin
                        //Pentru operatia de write
                        if(operation == 1'b1) begin
                            write_int <= 1'b1;
                            data_write_int <= data_in;
                            addr_int <= base_addr;
                        end
                        
                        state <= SETUP;
                    end
                end 
                
                default: state <= SETUP;
            endcase
        end
    end   

endmodule
