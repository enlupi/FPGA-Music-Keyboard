/*#############################################################################\
##                                                                            ##
##       APPLIED ELECTRONICS - Physics Department - University of Padova      ##
##                                                                            ## 
##       ---------------------------------------------------------------      ##
##                                                                            ##
##                        FPGA Music Keyboard Project                         ##
##                                                                           ##
\#############################################################################*/


// Set timescale (default time unit if not otherwise specified).
`timescale 1ns / 1ps

// Define Module for Test Fixture
module control_tb ();

    // ==========================================================================
    // ==                               Parameters                             ==
    // ==========================================================================
    
    // Timing properties.
    parameter C_CLK_FRQ         = 100_000_000;       // Main clock frequency [Hz].
    parameter C_CLK_JTR         = 50;                // Main clock jitter [ps].
    localparam real C_CLK_PERIOD = 1E9 / C_CLK_FRQ;  // Master clock period [ns].
    
    // Input UART parametrs.
    parameter C_UART_RATE = 115_200;                 // Transmission BAUD rate.
    
    
    // ==========================================================================
    // ==                              Seeding                                 ==
    // ==========================================================================
    
    // Seeding for (repeatable) random number generation.
    static int seed = $urandom + 0;


    // ==========================================================================
    // ==                      DUT Params and Signals                           ==
    // ==========================================================================
            
    // Parameters.
	parameter C_MUSIC = 5;   		    // Light/sound duration [ms].
    parameter C_UART_DATA_WIDTH = 8;    // Transmission word size.
    
    parameter CLKS_PER_BIT = C_CLK_FRQ / C_UART_RATE;
        
    // Timing signal.
    reg rRstb;
    reg rClk;
    
    // Data in.
    reg rUART_valid = 1'b0;
    reg rUART_err = 1'b0;
    reg [C_UART_DATA_WIDTH-1:0] rUART_msg = { C_UART_DATA_WIDTH {1'b0} };
    
    // Data out.
    wire [C_UART_DATA_WIDTH-1:0] wOut;



    // ==========================================================================
    // ==                                 DUTs                                 ==
    // ==========================================================================

    // Instantiate the 'control' DUT
    control #(
    
        // Intervals.
        .C_CLK_FRQ(C_CLK_FRQ),                 // Clock frequency [Hz].
        .C_MUSIC(C_MUSIC),                     // Sound interval [ms].
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH)  // Transmission word size.
  
    ) DUT (
        
         // Timing.
        .rstb(rRstb),
        .clk(rClk),
        
        // Inputs.
        .UART_err(rUART_err),                 // From URx. 
        .UART_valid(rUART_valid),             // From URx.
	    .UART_msg(rUART_msg),                // From URx.
        
        // Outputs.
        .out(wOut)
    );

    // Initialize Inputs
    initial begin
		$display ($time, " << Starting the Simulation >> ");
        rRstb = 1'b0;
		rClk = 1'b0;
		rUART_err = 1'b0;
		rUART_valid = 1'b0;
		rUART_msg = 8'b00000000;
        #200 rRstb = 1'b1;
    end

    // Main clock generation. This process generates a clock with period equal to 
    // C_CLK_PERIOD. It also add a pseudorandom jitter, normally distributed 
    // with mean 0 and standard deviation equal to 'kClockJitter'.  
    always begin
        #(0.001 * $dist_normal(seed, 1000.0 * C_CLK_PERIOD / 2, C_CLK_JTR));
        rClk = ! rClk;
    end  
    
    // Pseudosequence.
    always begin
		#5ms
                      rUART_msg <= 8'b00000000;
        #CLKS_PER_BIT rUART_msg <= 8'b00000010;
        #CLKS_PER_BIT rUART_msg <= 8'b00000010;
        #CLKS_PER_BIT rUART_msg <= 8'b00001010;
        #CLKS_PER_BIT rUART_msg <= 8'b00011010;
        #CLKS_PER_BIT rUART_msg <= 8'b00111010;
        #CLKS_PER_BIT rUART_msg <= 8'b01111010;
        #CLKS_PER_BIT rUART_msg <= 8'b01111010;
        #CLKS_PER_BIT rUART_valid <= 1'b1;
        #C_CLK_PERIOD rUART_valid <= 1'b0;

        #10ms
                      rUART_msg <= 8'b00000001;
        #CLKS_PER_BIT rUART_msg <= 8'b00000001;
        #CLKS_PER_BIT rUART_msg <= 8'b00000001;
        #CLKS_PER_BIT rUART_msg <= 8'b00000001;
        #CLKS_PER_BIT rUART_msg <= 8'b00010001;
        #CLKS_PER_BIT rUART_msg <= 8'b00010001;
        #CLKS_PER_BIT rUART_msg <= 8'b00010001;
        #CLKS_PER_BIT rUART_msg <= 8'b10010001;
        #CLKS_PER_BIT rUART_valid <= 1'b1;
        #C_CLK_PERIOD rUART_valid <= 1'b0;

        #2ms
                      rUART_msg <= 8'b00000000;
        #CLKS_PER_BIT rUART_msg <= 8'b00000010;
        #CLKS_PER_BIT rUART_msg <= 8'b00000110;
        #CLKS_PER_BIT rUART_msg <= 8'b00001110;
        #CLKS_PER_BIT rUART_msg <= 8'b00001110;
        #CLKS_PER_BIT rUART_msg <= 8'b00101110;
        #CLKS_PER_BIT rUART_msg <= 8'b01101110;
        #CLKS_PER_BIT rUART_msg <= 8'b01101110;
        #CLKS_PER_BIT rUART_valid <= 1'b1;
        #C_CLK_PERIOD rUART_valid <= 1'b0;

        #10ms;
	end

endmodule