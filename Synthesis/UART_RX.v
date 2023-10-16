/*#############################################################################\
##                                                                            ##
##       APPLIED ELECTRONICS - Physics Department - University of Padova      ##
##                                                                            ## 
##       ---------------------------------------------------------------      ##
##                                                                            ##
##                        FPGA Music Keyboard Project                         ##
##                                                                            ##
\#############################################################################*/

// INFO
// This code is a slight modification of the one written by Russel Merrick,
// in order to accept variable number of transmission word bits.
// The original is available at https://github.com/nandland/nandland/tree/master/uart
//
// The UART_Rx module receives 1-byte values through a RS232-like single line
// communication channel. When receive is complete o_RX_DV will be driven high
// for one clock cycle.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// C_CLK_FRQ:         frequency of the clock in [cycles per second] {100000000}. 
// C_UART_RATE:       transmission bit frequency [BAUD] {1000000}.
// C_UART_DATA_WIDTH: transmission word width [bit] {8}.


// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// i_Rst_L:         INPUT, synchronous reset, ACTIVE LOW.
// i_Clk:           INPUT, master clock. Defines the timing of the transmission.
// i_RX_Serial:     INPUT, the bit-line carrying the UART communication.
//
// o_RX_DV:         OUTPUT, data validation. High for one clock cycle after data
//                  has been correctly read.
// o_RX_Byte:       OUTPUT, data byte. The received data byte. It will stay valid
//                  as long as o_RX_Invalid is LOW, i.e. when new data is not being
//                  read.
// o_RX_Invalid:    OUTPUT, indicates when the data on the 'o_RX_Byte' port are
//                  not valid.

module UART_RX #(
    parameter C_CLK_FRQ = 100_000_000,  // Input clock frequency.
    parameter C_UART_RATE = 1_000_000,  // Transmission BAUD rate.
    parameter C_UART_DATA_WIDTH = 8     // Transmission word size.
    // parameter C_UART_STOP = 1           // Transmisison stop bits.
    ) (
    input            i_Rst_L,
    input            i_Clock,
    input            i_RX_Serial,
    output reg       o_RX_DV,
    output reg [C_UART_DATA_WIDTH-1:0] o_RX_Byte,
    output reg       o_RX_Invalid
    );
   
     // Get the 1 bit transmission period cycle in terms of main clock cycles.
    localparam CLKS_PER_BIT = C_CLK_FRQ / C_UART_RATE;
    localparam C_PERIOD_WIDTH = $clog2(CLKS_PER_BIT);   // Counter bitsize.

    // State machine.
    localparam IDLE         = 3'b000;
    localparam RX_START_BIT = 3'b001;
    localparam RX_DATA_BITS = 3'b010;
    localparam RX_STOP_BIT  = 3'b011;
    localparam CLEANUP      = 3'b100;
  

    reg [C_PERIOD_WIDTH-1:0] r_Clock_Count;
    reg [$clog2(C_UART_DATA_WIDTH)-1:0] r_Bit_Index; // register for transmitted data.
    reg [2:0] r_SM_Main = IDLE;                      // State register.
  
  
    // Purpose: Control RX state machine
    always @(posedge i_Clock or negedge i_Rst_L)
    begin
        if (~i_Rst_L) begin
            r_SM_Main    <= 3'b000;
            o_RX_DV      <= 1'b0;
            o_RX_Invalid <= 1'b1;
        end
        else begin
            case (r_SM_Main)
            
                IDLE : begin
                    o_RX_DV       <= 1'b0;
                    r_Clock_Count <= 0;
                    r_Bit_Index   <= 0;
          
                    if (i_RX_Serial == 1'b0) begin       // Start bit detected
                        r_SM_Main <= RX_START_BIT;
                    end
                    else begin
                        r_SM_Main <= IDLE;
                    end
                end // case: IDLE
      
                // Check middle of start bit to make sure it's still low
                RX_START_BIT : begin
                    if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
                        if (i_RX_Serial == 1'b0) begin
                            r_Clock_Count <= 0;  // reset counter, found the middle
                            r_SM_Main     <= RX_DATA_BITS;
                            o_RX_Invalid  <= 1'b1; // commencing reading operations
                        end
                        else begin
                            r_SM_Main <= IDLE;
                        end
                    end
                    else begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        r_SM_Main     <= RX_START_BIT;
                    end
                end // case: RX_START_BIT
      
      
                // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
                RX_DATA_BITS : begin
                    if (r_Clock_Count < CLKS_PER_BIT-1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        r_SM_Main     <= RX_DATA_BITS;
                    end
                    else begin
                        r_Clock_Count          <= 0;
                        o_RX_Byte[r_Bit_Index] <= i_RX_Serial;
            
                        // Check if we have received all bits
                        if (r_Bit_Index < C_UART_DATA_WIDTH - 1) begin
                            r_Bit_Index <= r_Bit_Index + 1;
                            r_SM_Main   <= RX_DATA_BITS;
                        end
                        else begin
                            r_Bit_Index <= 0;
                            r_SM_Main   <= RX_STOP_BIT;
                        end
                    end
                end // case: RX_DATA_BITS
      
      
                // Receive Stop bit.  Stop bit = 1
                RX_STOP_BIT : begin
                    // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                    if (r_Clock_Count < CLKS_PER_BIT-1) begin
                        r_Clock_Count <= r_Clock_Count + 1;
                        r_SM_Main     <= RX_STOP_BIT;
                    end
                    else begin
                        o_RX_DV       <= 1'b1;
                        r_Clock_Count <= 0;
                        o_RX_Invalid  <= 1'b0;
                        r_SM_Main     <= CLEANUP;
                    end
                end // case: RX_STOP_BIT
      
                // Stay here 1 clock 
                CLEANUP : begin
                    r_SM_Main <= IDLE;
                    o_RX_DV   <= 1'b0;
                end
       
                default : begin
                    r_SM_Main <= IDLE;
                end
      
            endcase
    
        end // else: !if(~i_Rst_L)
    
    end // always @ (posedge i_Clock or negedge i_Rst_L)
  
endmodule // UART_RX
