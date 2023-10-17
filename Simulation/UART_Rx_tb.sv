/*#############################################################################\
##                                                                            ##
##       APPLIED ELECTRONICS - Physics Department - University of Padova      ##
##                                                                            ## 
##       ---------------------------------------------------------------      ##
##                                                                            ##
##                        FPGA Music Keyboard Project                         ##
##                                                                            ##
\#############################################################################*/


// Set timescale (default time unit if not otherwise specified).
`timescale 1ns / 1ps

module UART_RX_tb();

    // ==========================================================================
    // ==                               Parameters                             ==
    // ==========================================================================

    // Timing properties.
    parameter C_CLK_FRQ = 100_000_000;               // Input clock frequency.
    parameter C_CLK_JTR          = 50;               // Main clock jitter [ps].
    localparam real C_CLK_PERIOD = 1E9 / C_CLK_FRQ;  // Master clock period [ns].

    // UART parameters.
    parameter C_UART_RATE = 115_200;    // Transmission BAUD rate.
    parameter C_UART_DATA_WIDTH = 8;     // Transmission word size.


    // ==========================================================================
    // ==                              Seeding                                 ==
    // ==========================================================================
    
    // Seeding for (repeatable) random number generation.
    static int seed = $urandom + 0;


    // ==========================================================================
    // ==                      DUT Params and Signals                          ==
    // ==========================================================================

    parameter CLKS_PER_BIT = C_CLK_FRQ / C_UART_RATE;
    parameter C_BIT_PERIOD = CLKS_PER_BIT * C_CLK_PERIOD;
  
    reg rClk = 0;
    reg rRstb = 0;
    reg r_RX_Serial = 1;

    wire w_RX_DV;
    wire w_RX_Invalid;
    wire [C_UART_DATA_WIDTH-1:0] w_RX_Byte;
  

    // Takes in input byte and serializes it 
    task UART_WRITE_BYTE;
        input [C_UART_DATA_WIDTH-1:0] i_Data;
        integer                       ii;
        begin
            // Send Start Bit
            r_RX_Serial <= 1'b0;
            #(C_BIT_PERIOD);
      
            // Send Data Byte
            for (ii = 0; ii < C_UART_DATA_WIDTH; ii = ii+1) begin
                r_RX_Serial <= i_Data[ii];
                #(C_BIT_PERIOD);
            end
      
            // Send Stop Bit
            r_RX_Serial <= 1'b1;
            #(C_BIT_PERIOD);
        end
    endtask // UART_WRITE_BYTE


    // ==========================================================================
    // ==                                 DUTs                                 ==
    // ==========================================================================
  
    UART_RX #(
        .C_CLK_FRQ(C_CLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH)
    ) DUT (
        .i_Rst_L(rRstb),
        .i_Clock(rClk),
        .i_RX_Serial(r_RX_Serial),

        .o_RX_DV(w_RX_DV),
        .o_RX_Invalid(w_RX_Invalid),
        .o_RX_Byte(w_RX_Byte)
    );
  
    // Main clock generation. This process generates a clock with period equal to 
    // C_CLK_PERIOD. It also add a pseudorandom jitter, normally distributed 
    // with mean 0 and standard deviation equal to 'kClockJitter'.  
    always begin
        #(0.001 * $dist_normal(seed, 1000.0 * C_CLK_PERIOD / 2, C_CLK_JTR));
        rClk = ! rClk;
    end  

  
    // Main Testing:
    initial begin
        rRstb = 1'b0;
		rClk = 1'b0;
        #200 rRstb = 1'b1;

        #(4*C_BIT_PERIOD);

        // Send a command to the UART (exercise Rx)
        @(posedge rClk);
        UART_WRITE_BYTE(8'h37);
        @(posedge rClk);
        
        #(6*C_BIT_PERIOD);

        // Send a command to the UART (exercise Rx)
        @(posedge rClk);
        UART_WRITE_BYTE(8'hA8);
        @(posedge rClk);
            
        // Check that the correct command was received
        if (w_RX_Byte == 8'hA8)
            $display("Test Passed - Correct Byte Received");
        else
            $display("Test Failed - Incorrect Byte Received");
    end

endmodule
