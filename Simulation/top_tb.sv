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

// Define Module for Test Fixture
module top_tb ();

    // ==========================================================================
    // ==                               Parameters                             ==
    // ==========================================================================
    
    // Timing parameters.
    parameter C_CLK_FRQ         = 100_000_000;      // Main clock frequency [Hz].
    parameter C_CLK_JTR         = 50;               // Main clock jitter [ps].
    localparam real C_CLK_PERIOD = 1E9 / C_CLK_FRQ; // Master clock period [ns].
        
    
    
    
    // ==========================================================================
    // ==                              Seeding                                 ==
    // ==========================================================================
    
    // Seeding for (repeatable) random number generation.
    static int seed = $urandom + 0;


    // ==========================================================================
    // ==                      DUT Params and Signals                           ==
    // ==========================================================================
            
    // Clocking and timing parameters. Here the values are arranged to allow 
    // having a "reasonable" simulation time.
    parameter C_DBC_INTERVAL = 0.01;        // Debouncer lock interval [ms].
    parameter C_BLK_PERIOD = 1.0;           // Blinker period [ms].
    
    parameter C_MUSIC = 5.0;                // Sound period [ms].        
        
    // UART properties.
    parameter C_UART_RATE = 115_200;        // UART BAUD rate.
    parameter C_UART_DATA_WIDTH = 8;        // UART word width.

    parameter CLKS_PER_BIT = C_CLK_FRQ / C_UART_RATE;
    parameter C_BIT_PERIOD = CLKS_PER_BIT * C_CLK_PERIOD;

        
    // System timing signals.
    reg rSysRstb;
    reg rSysClk;
        
    // Data in.
    reg [3:0] rButton;
    reg [3:0] rSwitch;
    
    reg r_RX_Serial;

    // Data out.
    wire [3:0]  wLed;
    wire [11:0] wLedRGB;
    


    // ==========================================================================
    // ==                                 DUTs                                 ==
    // ==========================================================================


    // Instantiate the 'top' DUT
    top #(
        .C_SYSCLK_FRQ(C_CLK_FRQ),
        .C_DBC_INTERVAL(C_DBC_INTERVAL),
        .C_BLINK_PERIOD(C_BLK_PERIOD),
        .C_MUSIC(C_MUSIC),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH)
    ) TOP (
        
        // Timing.
        .sysRstb(rSysRstb),
        .sysClk(rSysClk),
        
        // Inputs.
        .sw(rSwitch),
        .btn(rButton),

        .UART_Rx(r_RX_Serial),
	    
        // Outputs.
        .led(wLed),
        .ledRGB(wLedRGB)
    );


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


    // Initialize Inputs
    initial begin
		$display ($time, " << Starting the Simulation >> ");
        rSysRstb <= 1'b0;
		rSysClk <= 1'b0;
		rSwitch <= 4'b0000;
		rButton <= 4'b0000;
        r_RX_Serial <= 1'b1;

        #2000 rSysRstb = 1'b1;
    end

    // Main clock generation. This process generates a clock with period equal to 
    // C_CLK_PERIOD. It also add a pseudorandom jitter, normally distributed 
    // with mean 0 and standard deviation equal to 'kClockJitter'.  
    always begin
        #(0.001 * $dist_normal(seed, 1000.0 * C_CLK_PERIOD / 2, C_CLK_JTR));
        rSysClk = ! rSysClk;
    end  
        
    // Main test.
    always begin
        #(5*C_BIT_PERIOD);

        // Send a command to the UART (exercise Rx)
        @(posedge rSysClk);
        UART_WRITE_BYTE(8'b01111010);  // z -> C  (DO)  = 1st LED Blue (000000000001)
        @(posedge rSysClk);
        
        #(3*C_MUSIC*1_000_000);

        // Send a command to the UART (exercise Rx)
        @(posedge rSysClk);
        UART_WRITE_BYTE(8'b01100111); // g -> F# (FA#) = 3rd LED Blue (000001000000)
        @(posedge rSysClk);

        #(0.5*C_MUSIC*1_000_000);

        // Send a command to the UART (exercise Rx)
        @(posedge rSysClk);
        UART_WRITE_BYTE(8'b11111111);
        @(posedge rSysClk);

        #(C_MUSIC*1_000_000);
    end  
        
   
endmodule