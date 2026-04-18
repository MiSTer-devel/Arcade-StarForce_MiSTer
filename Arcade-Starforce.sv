//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
        //Master input clock
        input	      CLK_50M,

        //Async reset from top-level module.
        //Can be used as initial reset.
        input	      RESET,

        //Must be passed to hps_io module
        inout [48:0]  HPS_BUS,

        //Base video clock. Usually equals to CLK_SYS.
        output        CLK_VIDEO,

        //Multiple resolutions are supported using different CE_PIXEL rates.
        //Must be based on CLK_VIDEO
        output        CE_PIXEL,

        //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
        //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
        output [12:0] VIDEO_ARX,
        output [12:0] VIDEO_ARY,

        output [7:0]  VGA_R,
        output [7:0]  VGA_G,
        output [7:0]  VGA_B,
        output        VGA_HS,
        output        VGA_VS,
        output        VGA_DE,      // = ~(VBlank | HBlank)
        output        VGA_F1,
        output [1:0]  VGA_SL,
        output        VGA_SCALER,  // Force VGA scaler
        output        VGA_DISABLE, // analog out is off

        input [11:0]  HDMI_WIDTH,
        input [11:0]  HDMI_HEIGHT,
        output        HDMI_FREEZE,
        output        HDMI_BLACKOUT,
        output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
        // Use framebuffer in DDRAM
        // FB_FORMAT:
        //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
        //    [3]   : 0=16bits 565 1=16bits 1555
        //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
        //
        // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
        output        FB_EN,
        output [4:0]  FB_FORMAT,
        output [11:0] FB_WIDTH,
        output [11:0] FB_HEIGHT,
        output [31:0] FB_BASE,
        output [13:0] FB_STRIDE,
        input         FB_VBL,
        input         FB_LL,
        output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
        // Palette control for 8bit modes.
        // Ignored for other video modes.
        output        FB_PAL_CLK,
        output [7:0]  FB_PAL_ADDR,
        output [23:0] FB_PAL_DOUT,
        input [23:0]  FB_PAL_DIN,
        output        FB_PAL_WR,
`endif
`endif

        output        LED_USER,    // 1 - ON, 0 - OFF.

        // b[1]: 0 - LED status is system status OR'd with b[0]
        //       1 - LED status is controled solely by b[0]
        // hint: supply 2'b00 to let the system control the LED.
        output [1:0]  LED_POWER,
        output [1:0]  LED_DISK,

        // I/O board button press simulation (active high)
        // b[1]: user button
        // b[0]: osd button
        output [1:0]  BUTTONS,

        input         CLK_AUDIO,   // 24.576 MHz
        output [15:0] AUDIO_L,
        output [15:0] AUDIO_R,
        output        AUDIO_S,     // 1 - signed audio samples, 0 - unsigned
        output [1:0]  AUDIO_MIX,   // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

        //ADC
        inout [3:0]   ADC_BUS,

        //SD-SPI
        output        SD_SCK,
        output        SD_MOSI,
        input         SD_MISO,
        output        SD_CS,
        input         SD_CD,

        //High latency DDR3 RAM interface
        //Use for non-critical time purposes
        output        DDRAM_CLK,
        input         DDRAM_BUSY,
        output [7:0]  DDRAM_BURSTCNT,
        output [28:0] DDRAM_ADDR,
        input [63:0]  DDRAM_DOUT,
        input         DDRAM_DOUT_READY,
        output        DDRAM_RD,
        output [63:0] DDRAM_DIN,
        output [7:0]  DDRAM_BE,
        output        DDRAM_WE,

        //SDRAM interface with lower latency
        output        SDRAM_CLK,
        output        SDRAM_CKE,
        output [12:0] SDRAM_A,
        output [1:0]  SDRAM_BA,
        inout [15:0]  SDRAM_DQ,
        output        SDRAM_DQML,
        output        SDRAM_DQMH,
        output        SDRAM_nCS,
        output        SDRAM_nCAS,
        output        SDRAM_nRAS,
        output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
        //Secondary SDRAM
        //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
        input         SDRAM2_EN,
        output        SDRAM2_CLK,
        output [12:0] SDRAM2_A,
        output [1:0]  SDRAM2_BA,
        inout [15:0]  SDRAM2_DQ,
        output        SDRAM2_nCS,
        output        SDRAM2_nCAS,
        output        SDRAM2_nRAS,
        output        SDRAM2_nWE,
`endif

        input         UART_CTS,
        output        UART_RTS,
        input         UART_RXD,
        output        UART_TXD,
        output        UART_DTR,
        input         UART_DSR,

        // Open-drain User port.
        // 0 - D+/RX
        // 1 - D-/TX
        // 2..6 - USR2..USR6
        // Set USER_OUT to 1 to read from USER_IN.
        input [6:0]   USER_IN,
        output [6:0]  USER_OUT,

        input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

   assign ADC_BUS  = 'Z;
   assign USER_OUT = '1;
   assign {UART_RTS, UART_TXD, UART_DTR} = 0;
   assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
   assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

   //assign VGA_SL = 0;
   assign VGA_F1 = 0;
   assign VGA_SCALER  = 0;
   assign VGA_DISABLE = 0;
   assign HDMI_FREEZE = 0;
   assign HDMI_BLACKOUT = 0;
   assign HDMI_BOB_DEINT = 0;

   assign AUDIO_S = 0;
   assign AUDIO_L = Sout;//L;
   assign AUDIO_R = Sout;//R;

   assign AUDIO_MIX = 0;

   assign LED_DISK = 0;
   assign LED_POWER = 0;
   assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

   wire ar = status[1];
   wire VertHorz = status[2];
   

   assign VIDEO_ARX =    ar ? 8'd16 : ( status[2] ? 8'd40 : 8'd30 );
   assign VIDEO_ARY =    ar ? 8'd9  : ( status[2] ? 8'd30 : 8'd40 );

   
   // Status Bitmap:
   // 0          1          2          3
   // 01234567890123456789012345678901
   // 0123456789ABCDEFGHIJKLMNOPQRSTUV
   // -AOfffi-------------------------
   
`include "build_id.v" 
   localparam CONF_STR = {
                          "StarForce;;",
                          "-;",
                          "HFO1,Aspect Ratio,Original,Wide;",
                          "HFO2,Orientation,Vert,Horz;",
                          "O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
                          "-;",
                          "DIP;",
                          "-;",
                          "O6,Invincibility,OFF,ON;",
                          "R[0],Reset and close OSD;",
                          "v,0;", // [optional] config version 0-99. 
                          // If CONF_STR options are changed in incompatible way, then change version number too,
                          // so all options will get default values on first start.
                          "V,v",`BUILD_DATE 
};

   wire       forced_scandoubler;
   wire [1:0] buttons;
   wire [127:0] status;
   wire [10:0]  ps2_key;
   wire         ioctl_download;
   wire         ioctl_wr;
   wire [24:0]  ioctl_addr;
   wire [7:0]   ioctl_dout;
   wire [7:0]   ioctl_index;
   wire [15:0]  joystk1, joystk2;
   wire         direct_video;
   wire         flip_screen;
   wire         rotate_ccw;
   wire         no_rotate = status[2] | direct_video;
   wire         video_rotated;
   wire         flip = 0;

//screen_rotate screen_rotate (.*);

   hps_io #(.CONF_STR(CONF_STR)) hps_io
     (
      .clk_sys(clk_sys),
      .HPS_BUS(HPS_BUS),
      .EXT_BUS(),
      .gamma_bus(),
      .direct_video ( direct_video ),
      .forced_scandoubler(forced_scandoubler),
      
      .buttons(buttons),
      .status(status),
      .status_menumask({status[5]}),
      
      .ps2_key(ps2_key),
      
      
      .ioctl_download(ioctl_download),
      .ioctl_wr(ioctl_wr),
      .ioctl_addr(ioctl_addr),
      .ioctl_dout(ioctl_dout),
      .ioctl_index(ioctl_index),
      
      .joystick_0(joystk1),
      .joystick_1(joystk2)      
      
        
        
      );
        
   arcade_video #(.WIDTH(256), .DW(12)) arcade_video
     (
      .*,
      .clk_video(CLK_48M),
      .ce_pix ( ce_pix ),
      .RGB_in( sfrgb ),//video),
      
      .HBlank(HBlank),
      .VBlank(VBlank),
      .HSync(~HSync),
      .VSync(~VSync),
      .fx(status[5:3]),
      .gamma_bus ()
      
      );
        
`ifdef MISTER_FB

	screen_rotate screen_rotate
	(
		.*,
		.video_rotated(),
		.rotate_ccw(0)
	);

`else
	
	assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  
	
`endif        
        
        
        
        

///////////////////////   CLOCKS   ///////////////////////////////

   wire clk_sys;
   wire CLK_48M;
   wire CLK_32M;
        
   pll pll
     (
      .refclk(CLK_50M),
      .rst(0),
      .outclk_0(clk_sys),
      .outclk_1(CLK_48M),
      .outclk_2(CLK_32M)
                
      );

   wire reset = RESET | status[0] | buttons[1];
   wire [1:0] col = status[4:3];
   wire       HBlank;
   wire       HSync;
   wire       VBlank;
   wire       VSync;
   wire	      ce_pix;
   wire [7:0] video = { r,g,b };
   wire [2:0] r,g;
   wire [1:0] b;
   wire [11:0] sfrgb;
   wire        clk_vid;
   wire        rom_download = ioctl_download && !ioctl_index;
   wire        iRST  = RESET | status[0] | buttons[1] | rom_download;
   wire        pressed = ps2_key[9];
   wire [8:0]  code    = ps2_key[8:0];

   always @(posedge clk_sys) begin
      reg old_state;
      old_state <= ps2_key[10];
      
      if(old_state != ps2_key[10]) begin
         casex(code)
           'hX75: btn_up          <= pressed; // up
           'hX72: btn_down        <= pressed; // down
           'hX6B: btn_left        <= pressed; // left
           'hX74: btn_right       <= pressed; // right
           'h014: btn_trig1       <= pressed; // ctrl
           'h005: btn_one_player  <= pressed; // F1
           'h006: btn_two_players <= pressed; // F2
           
           // JPAC/IPAC/MAME Style Codes
           'h016: btn_start_1     <= pressed; // 1
           'h01E: btn_start_2     <= pressed; // 2
           'h02E: btn_coin_1      <= pressed; // 5
         endcase
      end
   end

   reg btn_up    = 0;
   reg btn_down  = 0;
   reg btn_right = 0;
   reg btn_left  = 0;
   reg btn_trig1 = 0;
   reg btn_one_player  = 0;
   reg btn_two_players = 0;
   
   reg btn_start_1 = 0;
   reg btn_start_2 = 0;
   reg btn_coin_1  = 0;


   wire m_start1  = btn_one_player  | joystk1[6] | joystk2[6] | btn_start_1;
   wire m_start2  = btn_two_players | joystk1[7] | joystk2[7] | btn_start_2;

   wire m_up1     = btn_up      | joystk1[3] ;
   wire m_down1   = btn_down    | joystk1[2] ;
   wire m_left1   = btn_left    | joystk1[1] ;
   wire m_right1  = btn_right   | joystk1[0] ;
   wire m_trig11  = btn_trig1   | joystk1[4] ;

   wire m_coin1   = btn_one_player | btn_coin_1 | joystk1[8];

   wire [6:0] UDLRTSC = { m_up1, m_down1, m_left1, m_right1, m_trig11, m_start1, m_coin1 };
   
   wire [15:0] Sout,SoutL,SoutR;

   //dipsw
   reg [7:0]   sw[8];
   always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;
   
   NANO_STARFORC starforce
     (
      
      .reset ( iRST ),
      .clk_48m ( CLK_48M ),
      .clk_32m ( CLK_32M ),
      
      .pxclk ( ce_pix ),
      
      .HBlank ( HBlank ),
      .VBlank ( VBlank ),
      .HSync ( HSync ),
      .VSync ( VSync ),
      .red ( r ),
      .blue ( b ),
      .green ( g ),
      .sfrgb ( sfrgb ),
      
      .clk_sys ( clk_sys ),
      .ROMCL ( clk_sys ),
      .ROMAD ( ioctl_addr ),
      .ROMDT ( ioctl_dout ),
      .ROMEN ( ioctl_wr & rom_download ),
      
      .SOUT ( Sout ),
      //.SOUTL ( SoutL ),
      //.SOUTR ( SoutR ),
      
      
      .UDLRTSC ( UDLRTSC ),
      .dipsw ( { sw[0],sw[1]} ),
      .muteki ( status[6] ),
      
      );
   
endmodule
