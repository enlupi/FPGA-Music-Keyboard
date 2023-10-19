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
// The light module transforms a 2-bit signal (4 states) into a color-coded
// output for the Arty board.


// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// rstb:                INPUT, synchronous reset, ACTIVE LOW. 
// clk:                 INPUT, master clock.
// in [1 : 0]:          INPUT, the light state signal.
// out_LED [11 : 0]:    OUTPUT: the signal toward the board RGB LEDs.
//                              each LED is RGB and used 3 bit to encode the color.

// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module  light (
		input rstb,               // Reset (bar).  
		input clk,                // Clock.
		input [7:0] inSel,        // Selection (light selection).
		output [11:0] outLED      // Output LED to fabric.
	);


   	// =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

    reg [11:0] rColor;                  // Output mask.
	

	// =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================
	
	// Output bitlist.
	assign outLED = rColor; 
	
	
	// =========================================================================
    // ==                        Synchronous processes                        ==
    // =========================================================================

	// Update the output accordingly to the selection signal.
	always @ (posedge clk) begin
	   if (rstb == 1'b0) begin
            rColor <= 12'b000000000000;
        end else begin
            case (inSel)
                8'b01111010: rColor <= 12'b000000000001; // z -> C  (DO)  = 1st LED Blue
		  	    8'b01110011: rColor <= 12'b000000000010; // s -> C# (DO#) = 1st LED Green
			    8'b01111000: rColor <= 12'b000000000100; // x -> D  (RE)  = 1st LED Red
			    8'b01100100: rColor <= 12'b000000001000; // d -> D# (RE#) = 2nd LED Blue
			    8'b01100011: rColor <= 12'b000000010000; // c -> E  (MI)  = 2nd LED Green
			    8'b01110110: rColor <= 12'b000000100000; // v -> F  (FA)  = 2nd LED Red
			    8'b01100111: rColor <= 12'b000001000000; // g -> F# (FA#) = 3rd LED Blue
			    8'b01100010: rColor <= 12'b000010000000; // b -> G  (SOL) = 3rd LED Green
			    8'b01101000: rColor <= 12'b000100000000; // h -> G# (SOL#)= 3rd LED Red
			    8'b01101110: rColor <= 12'b001000000000; // n -> A  (La)  = 4th LED Blue
			    8'b01101010: rColor <= 12'b010000000000; // j -> A# (La#) = 4th LED Green
			    8'b01101101: rColor <= 12'b100000000000; // m -> B  (SI)  = 4th LED Red

			    default: rColor <= 12'b000000000000;
            endcase
        end
	end
	
endmodule


