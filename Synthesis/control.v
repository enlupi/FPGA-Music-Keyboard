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
// The control module implements the State Machine checking the UART input and
// controlling light and sound production.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 
// C_MUSIC:         the time interval of the produced light/sound. [ms] {10}.


// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// rstb:                INPUT, synchronous reset, ACTIVE LOW. 
// clk:                 INPUT, master clock.
// inMode:              INPUT, pedestrian mode (0 = vehicles priority, 1 = pedestrian priority).
// inPedestrian:        INPUT, pedestrian crossing.
// inTraffic:           INPUT, traffic status (0=empty road, 1=vehicles on road).
// outLight [1 : 0]:    OUTPUT: selected light

// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module control #(
    
    parameter C_CLK_FRQ = 100_000_000, 	// Clock frequency [Hz].
	parameter C_MUSIC = 500,   		    // Light/sound duration [ms].
    parameter C_UART_DATA_WIDTH = 8     // Transmission word size.
 )(	
	// Timing.
	input rstb,                        // Reset (bar).  
	input clk,                         // Clock.
	
	// External inputs.
    input UART_err,                             // Invalid state of UART data.
    input UART_valid,                           // UART data validation.
    input [C_UART_DATA_WIDTH-1:0] UART_msg,  // Input from UART.

	output reg[C_UART_DATA_WIDTH-1:0] out       // Output.
);


   	// =========================================================================
    // ==                Local parameters, Registers and wires                ==
    // =========================================================================
    
    // SM states names.
    localparam sIdle        = 2'b00;
    localparam sRead        = 2'b01;
    localparam sPlay        = 2'b10;

    // SM state ragister.
    reg [1:0] rState = sIdle;   // Defaults to idle state.
    reg [1:0] rStateOld;        // Old state, used to generate the counter reset signal.
    
    // SM next state logic.
    reg [1:0] lStateNext;       // Next state register, does not require initialization.
    wire wStateJump;            // Signals state(S) transitions.
        
   // Interval timer register.
    localparam C_PERIOD = C_CLK_FRQ * C_MUSIC; // / 1000;
    localparam C_PERIOD_WIDTH = $clog2(C_PERIOD);   // Counter bitsize.
    reg [C_PERIOD_WIDTH:0] rTimer = 0; // Double the requiredlength for edge cases.


	// =========================================================================
    // ==                        Synchronous processes                        ==
    // =========================================================================


	// State machine main synchronous process. Transfer 'lStateNext' into 'rState'
    always @(negedge rstb, posedge clk) begin
        
        // Reset (bar).
        if (rstb == 1'b0) begin
            rState <= sIdle;
            rStateOld <= sIdle;
            
        // State transition.
        end else begin
            
            // Store next state.
            rState <= lStateNext;
            
            // Store the current state (used by the counter to 
            // self-reset on state-change).
            rStateOld <= rState;
        end
    end

    
    // Interval counter.
    // It resets on 'rstb' and at every state transition. LOOK at the sensitivity
    // list: only "EDGED" events are used, otherwise the tool will not
    // correctly synthetize ot. (For simulation there are no issues).
    always @(negedge rstb, posedge wStateJump, posedge clk) begin
        
        // Master reset (bar).
        if (rstb == 1'b0) begin
            rTimer <= 0;
        
        // Reset because of a state jump.
        end else if(wStateJump == 1'b1) begin
            rTimer <= 0;
        
        // Increase the timer.
        end else begin
            if(rState == sPlay) rTimer <= rTimer + 1;
        end
    end
    
    // UART message register. Stores the last valid value of the UART message,
    // and is reset to zero when going back to Idle state. 
    always @(rstb, rState) begin
        
        // Reset (bar).
        if (rstb == 1'b0 || rState == sIdle) begin
            out <= 8'b00000000;
        end else begin
            // Copy UART input if in Read state.
            if (rState == sRead) begin
                out <= UART_msg;
            end else begin
                out <= out;
            end
        end
    end
    
    
    // =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

	// State jump signal. It stays high for 1 clock cycle every time the state
	// changes. It is used to reset the counter at every state transition.
	assign wStateJump = (rState != rStateOld) ? 1'b1 : 1'b0;
	
	
	// State machine async process. Update the next state considering the present 
	// state ('rState') 
    always @(rState, rTimer, UART_valid) begin
        
        // Select among states.
        case (rState)
            
            // Idle.
            sIdle: begin
                
                // If UART data is valid, go to Read state.
                if (UART_valid == 1'b1) begin
                    lStateNext <= sRead;  
                                    
                // Otherwise, just wait for new input.
                end else begin
                    lStateNext <= sIdle;
                end

            end
            

            // Read.
            sRead: begin
                
                // Copies UART message to UART register and goes to Play state.
                lStateNext <= sPlay;

            end
                

            // Play.
            sPlay: begin
                
                // Play sound for fixed amount of time.
                if (rTimer >= C_PERIOD - 1) begin
                    lStateNext <= sIdle;
                end else begin    
                    lStateNext <= sPlay;
                end
            end

            
            // Default (recovery from errors).
            default: begin
               lStateNext <= sIdle;
            end

        endcase
    end
    
endmodule


