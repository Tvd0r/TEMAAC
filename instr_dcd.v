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

    // ---------------------------------------------------------
    // DEFINITII INTERNE (Nu modificam antetul)
    // ---------------------------------------------------------
    
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
    reg memory_zone;    // 1=High Byte, 0=Low Byte
    reg [5:0] base_addr;// Adresa de baza (fara offset-ul de zona)

    // ---------------------------------------------------------
    // LOGICA FSM
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= SETUP;
            operation <= 0;
            memory_zone <= 0;
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
                SETUP: begin  
                    if (byte_sync) begin 
                        // 1. Capturam informatiile despre comanda
                        operation   <= data_in[7];
                        memory_zone <= data_in[6];
                        base_addr   <= data_in[5:0];
                        
                        // 2. FIX CRITIC PENTRU CITIRE (Look-Ahead)
                        // Daca e citire (bit 7 e 0), activam semnalul ACUM, nu mai tarziu.
                        if (data_in[7] == 1'b0) begin
                            read_int <= 1'b1;
                            // Calculam adresa finala: Adresa Baza + Offset (Memory Zone)
                            addr_int <= data_in[5:0] + data_in[6];
                        end
                        
                        state <= DATA;
                    end
                end

                DATA: begin
                    if (byte_sync) begin
                        // Daca comanda anterioara a fost SCRIERE
                        if(operation == 1'b1) begin
                            write_int <= 1'b1;
                            data_write_int <= data_in;
                            // Calculam adresa finala folosind valorile memorate
                            addr_int <= base_addr + memory_zone;
                        end
                        
                        // Indiferent daca a fost scriere sau citire, ne intoarcem la SETUP
                        state <= SETUP;
                    end
                end 
                
                default: state <= SETUP;
            endcase
        end
    end   

endmodule