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

//Declarare variabile stari
parameter SETUP = 2'b00;
parameter DATA = 2'b01;
parameter WAIT_READ = 2'b10;

//Variabila pentru cele 3 stari
reg[1:0] state;
//Variabila pentru inregistrarea tipul de operatie : 1- write si 0 - read
reg operation;
//Bit de selectie pentru zona de memorie , 1-[15:8] si 0 -[7:0]
reg memory_zone;
//Zona unde se va tine addresa registrului
reg[5:0] addr_reg;

//Model FSM de tip Masina Mealy
always @(posedge clk or negedge rst_n) begin
     
     //Initilizare asincrona (Reset activ - rst_n = 0)
     if(!rst_n) begin
        state <= SETUP;
        operation <= 0;
        memory_zone <= 0;
        addr_reg <= 0;
        read <= 0;
        write <= 0;
        data_write <= 0;
        data_out <= 0;
    //Mod functionare normal (sincron)
    end else begin
        
        
        read <= 0;
        write <= 0;
            
        case (state)
            //Astepta primirea primului octet
            SETUP:begin  
                    if (byte_sync) begin 
                        operation  <= data_in[7];
                        memory_zone <= data_in[6];
                        addr_reg <= data_in[5:0];
                        state <= DATA;
                    end
                end
            //Asteapta primirea celui de al doilea octet     
            DATA:begin
                  if (byte_sync) begin
                        if(operation == 1) begin
                            write <= 1;
                            data_write <= data_in;
                            addr <= addr_reg;
                            state <= SETUP;
                        end else begin
                            read <= 1;
                            addr <= addr_reg;
                            state <= WAIT_READ ;
                       end
                  end
                end 
                //Asteapta un ciclu pentru citirea datelor din memorie
            WAIT_READ:begin
                    data_out <= data_read;
                    state <= SETUP;
                end
            default: state <=SETUP ;
        endcase
    end
end   
  

endmodule