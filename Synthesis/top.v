/*#############################################################################\
##                                                                            ##
##       APPLIED ELECTRONICS - Physics Department - University of Padova      ##
##                                                                            ## 
##       ---------------------------------------------------------------      ##
##                                                                            ##
##                        FPGA Music Keyboard Project                         ##
##                                                                            ##
\#############################################################################*/

// The top module is the topmost wrapper of the whole project, and contains
// all the I/O ports used by the FPGA.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------

// Timing
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 
// C_DBC_INTERVAL:  debouncing interval on external "mech" inputs [ms].
//
// UART interface
// C_UART_RATE:     transmission bit frequency [BAUD] {1000000}.
// C_UART_DATA_WIDTH: transmission word width [bit] {8}.
// C_UART_PARITY:   transmission parity bit [bit] {0, 1}.
// C_UART_STOP:     transmission stop bit(s) [bit] {0, 1, 2}.



// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// sysRstb:         INPUT, synchronous reset, ACTIVE LOW.
// sysClk:          INPUT, master clock. Defines the timing of the transmission.
//
// [3:0] sw:        INPUT, connected to the board switches.
// [3:0] btn:       INPUT, connected to the board push buttons.
// [3:0] led:       OUTPUT, connected to the board LEDs.
// [11:0] ledRGB:   INPUT, connected to the board RGB LEDs, grouped by 3 for
//                  each LED: [11:9] = R,G,B for led 3, [8:6] = R,G,B for led 2,
//                  [5:3] = R,G,B for led 1, [2:0] = R,G,B for led 0,
//
// UART_Rx:         INPUT, the bit-line carrying the UART communication.
// UART_Tx:         OUTPUT, the bit-line sourcing the UART communication.




// -----------------------------------------------------------------------------
// --                            DEBUG FEATURES                               --
// -----------------------------------------------------------------------------

// LEDs
// led[3]:          Blinks when the firmware is loaded.
// led[2]:          
// led[1]:          
// led[0]:          If ON indicates the UART mirroring is enabled.
//
// Switches:
// sw[3]:           
// sw[2]:           
// sw[1]:           
// sw[0]:           MIRROR: enables UART mirroring (for debug).
//
//
// Buttons:
// btn[3]:          
// btn[2]:          
// btn[1]:          
// btn[0]:          Send "Hello": send "Hhllo" through the UART Tx line.



// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module top # (
        
        // Timing.
        parameter C_SYSCLK_FRQ = 100_000_000,   // System clock frequency [Hz].
        parameter C_DBC_INTERVAL = 10,          // Debouncing interval [ms].          
        parameter C_BLINK_PERIOD = 2000,        // Blinking period [ms].      
        parameter C_MUSIC = 500,                // Sound period [ms].        
        
        // UART properties.
        parameter C_UART_RATE = 115_200,        // UART BAUD rate.
        parameter C_UART_DATA_WIDTH = 8         // UART word width.
        // parameter C_UART_PARITY = 0,            // UART parity bits {0, 1, 2}.
        // parameter C_UART_STOP = 1,              // UART stop bits {0, 1}.
    ) (
        // Timing.
        input sysRstb,                  // System reset, active low.
        input sysClk,                   // System clock, SE input.
                
        // External switches and buttons inputs.
        input [3:0] sw,                 // Switches.
        input [3:0] btn,                // Push buttons.
        
        // Standard LEDs outputs.
        output [3:0] led,   
        output [11:0] ledRGB,
                
        // UART iterface (reference direction is controller toward FPGA).
        input UART_Rx                  // Data from the controller toward the FPGA.
    );
        
    
    // =========================================================================
    // ==                                Wires                                ==
    // =========================================================================
    
    // Timing.
    wire wSysRstb;      // System reset (from the board push-button).
    wire wSysClk;       // System clock (from the board oscillator).
        
    // Wires from the debouncer(s) toward the fabric.
    wire [3:0] wSw;     // Switches.
    wire [3:0] wBtn;    // Push buttons.

    // Control wiring for lights and sounds.
    wire [C_UART_DATA_WIDTH - 1:0] wCtrl;
    
    
    // -------------------------------------------------------------------------
    // --                           UART wiring                               --
    // -------------------------------------------------------------------------
    
    // Wires from UART Rx module.
    wire wRxValid;
    wire [C_UART_DATA_WIDTH - 1 : 0] wRxData;
    wire wRxErr;
        
    // UART
    wire wRx;

    
    // =========================================================================
    // ==                            I/O buffering                            ==
    // =========================================================================

    // System clock buffer. The IBUFG primitive ensures a clock network is 
    // connected to the buffer output.
    IBUFG clk_inst (
        .O(wSysClk),
        .I(sysClk)
    );
    
    // Input debouncer(s).
    // -------------------------------------------------------------------------
    genvar i;
    
    // Reset button.
    debounce #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_INTERVAL(C_DBC_INTERVAL)
    ) DBC_BTN (
        .rstb(1'b1),    // Note that the reset debouncer never reset!
        .clk(wSysClk),
        .in(sysRstb),
        .out(wSysRstb)
    );
    
    // Buttons.
    generate 
        for (i = 0; i < 4; i=i+1) begin
            debounce #(
                .C_CLK_FRQ(C_SYSCLK_FRQ),
                .C_INTERVAL(C_DBC_INTERVAL)
            ) DBC_BTN (
                .rstb(wSysRstb),
                .clk(wSysClk),
                .in(btn[i]),
                .out(wBtn[i])
            );
        end
    endgenerate
    
    // Switches.
    generate 
        for (i = 0; i < 4; i=i+1) begin
            debounce #(
                .C_CLK_FRQ(C_SYSCLK_FRQ),
                .C_INTERVAL(C_DBC_INTERVAL)
            ) DBC_SW (
                .rstb(wSysRstb),
                .clk(wSysClk),
                .in(sw[i]),
                .out(wSw[i])
            );
        end
    endgenerate
    
    
    // =========================================================================
    // ==                          UART interface                             ==
    // =========================================================================
    
    // UART Rx.
    UART_RX #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH)
    ) URx (
        .i_Rst_L(wSysRstb),
        .i_Clock(wSysClk),
        .i_RX_Serial(wRx),
        
        .o_RX_DV(wRxValid),
        .o_RX_Byte(wRxData),
        .o_RX_Invalid(wRxErr)
    );    



    // =========================================================================
    // ==                             Control                                 ==
    // =========================================================================

    // Main control unit.
    control #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),              // Clock frequency [Hz].
        .C_MUSIC(C_MUSIC),                      // Sound interval [ms].
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH)  // Transmission word size.
    ) CONTROL (
        
        // Timing.
        .rstb(wSysRstb),
        .clk(wSysClk),
        
        // Inputs.
        .UART_err(wRxErr),                 // From URx. 
        .UART_valid(wRxValid),             // From URx.
	    .UART_msg(wRxData),                // From URx.
        
        // Outputs.
        .out(wCtrl)
    );

   

    // =========================================================================
    // ==                              Lights                                 ==
    // =========================================================================

     // State to RGB LEDs conversion.
    light LIGHT (
        .rstb(wSysRstb),
        .clk(wSysClk),
        .inSel(wCtrl),                  // Light status from Control.  
        .outLED(ledRGB)                 // Toward output RGB LEDs.
    );

    
    
    // =========================================================================
    // ==                           DEBUG services                            ==
    // =========================================================================
    
    blinker #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_PERIOD(C_BLINK_PERIOD)
    ) BLINK (
        .rstb(wSysRstb),
        .clk(wSysClk),
        .out(wBlink)
    );
      
    

    // =========================================================================
    // ==                              Routing                                ==
    // =========================================================================
    
    // UART.
    assign wRx = UART_Rx;
    
    // LEDs.
    assign led[3] = wBlink;         // Blinking LED.
    assign led[2] = wBtn[1];
    assign led[1] = wSw[1];         // Switch between PWM level and sine.
    assign led[0] = wSw[0];         // UART Mirror enabled.
  
    // PWM Ground.
    //assign PWM_Out_p = wPWM;
    //assign PWM_Out_n = 1'b0;
    
    // Connect registers 0,1,2,3 LSBs to RGB LEDs.  
    //assign ledRGB = {wRegReg[3][2:0], wRegReg[2][2:0], wRegReg[1][2:0], wRegReg[0][2:0]};
    //assign ledRGB[11 : 8] = wSw;
    //assign ledRGB[7 : 0] = wRxData; 
    //assign ledRGB[7 : 0] = wSineData;
    
//    // Blinking LED register.
//    reg [23:0] rCount = 0;
     
//    // Simple counter process.
//    always @ (posedge(wSysClk)) begin
//        rCount <= rCount + 1;
//    end

endmodule



