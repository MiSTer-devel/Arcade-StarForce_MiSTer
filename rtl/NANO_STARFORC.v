//=======================================================
/* FPGA STARFORCE top level module
   Copyright 2025, madov
 
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.
 
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
 
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
  MA 02110-1301, USA.
 
*/
 //=======================================================

`default_nettype none

module NANO_STARFORC
  (

   input wire	      FPGA_CLK1_50,
   input wire	      clk_48m,
   input wire	      clk_32m,
    
   output wire [2:0]  red,green,
   output wire [1:0]  blue,
   output wire        csync,
   output wire        HSync,VSync,HBlank,VBlank,
   output wire [11:0] sfrgb,

   input wire         ctrl_in,

   output wire        pxclk,
   input wire [1:0]   KEY,
   input wire [7:0]   rom_d,
   output wire [18:0] rom_a,
   input wire         gamesw,
   output wire        shld,
   output wire        nrom_oe2,
   output wire        debug1,debug2,debug3,debug4,
   output wire [7:0]  c99_out,

   input wire         reset,
   input wire         clk_sys,
   input wire         ROMCL,
   input wire [17:0]  ROMAD,
   input wire [7:0]   ROMDT,
   input wire         ROMEN,
   output wire [15:0] SOUT,
  
   input wire [6:0]   UDLRTSC,
   input wire [15:0]  dipsw,
	input wire muteki
 
   );

   wire [15:0]      dipsw_port;
   wire             coin,start,up,down,left,right,t1,t2;
   reg [4:0]        dsw_counter;
   reg [15:0]       ctrlr;
   reg              shld_reg;
   assign  shld = shld_reg;



   // clock gen
   reg [3:0] ctr_even;   
   reg [3:0] ctr_odd;
   wire      clk_12m;
   wire      clk_6m;
   wire      clk_4m_en;
   wire      clk_2m_en;
   wire      clk_6048;
   wire      clk_12096;
   wire      clk_4m;
   
   reg [3:0] ctr2_even;
   
   always @(posedge clk_32m)    ctr2_even <= ctr2_even + 1;
   
   always @(posedge clk_48m)
     begin
        ctr_even <= ctr_even + 1;
        if (ctr_odd == 4'hb )
          ctr_odd <= 4'b0;
        else ctr_odd <= ctr_odd + 1;
     end
   assign clk_12m =   ctr_even[1];
   assign clk_6m =    ctr_even[2];
   assign clk_4m_en = clk_4m;
   assign clk_4m =    ctr2_even[2];
   assign clk_2m_en = ctr2_even[3];
   assign clk_12096 = clk_12m;
   assign clk_6048 =  clk_6m;   

   wire [7:0] JOY = { 1'h0, UDLRTSC };
   
   //board edge connector signals
   //memory connection
   wire [15:0] CPU0_A, CPU1_A;
   wire [7:0]  CPU0_DO,CPU1_DO;
   wire [7:0]  sndrom,ram0,sndram,rom23,rom45;
   wire        ram0_we,sndram0_we;
   wire [12:0] ROMA_addr;
   wire [7:0]  rom9_o,rom10_o,rom11_o,rom12_o,rom13_o,rom14_o;
   
   wire [6:0]  u1KJ_B;
   wire [7:0]  u2KL_D,u2KL_D2;
   wire        n2KLWR;
   wire [7:0]  u34P_addr, u56P_addr;
   wire [7:0]  u34P_di,u56P_di;
   wire        u34P_we,u56P_we;
   wire [7:0]  u34P_out,u56P_out;
   wire [10:0] cram_a_read;
   wire [7:0]  cram_d,cram_d2;
   wire        cram_nwe;
   wire [11:0] romb_addr;
   wire [7:0]  rom6_o,rom7_o,rom8_o;

   wire [12:0] sw12_a,rom1517_a,rom1820_a;
   wire [7:0]  sw1_o,sw2_o,sw1b_o;
   wire [7:0]  rom15_o,rom16_o,rom17_o,rom18_o,rom19_o,rom20_o;
   wire        sw12_a12;
        
        wire [7:0] sndprom_a;
        wire [7:0] sndprom_d;
        
   
   //PCB connector 1
  
   wire       nCS_V90;
   wire       f3_7;
   wire       nCS_BGPOS;
   wire       nMERD;
   wire       BMP1_Ser;
   wire       BMP2_Ser;
   wire       nCS_BGV3;
   wire       nCS_BGV2;
   wire       nCS_BGV1;
   wire       BGV1_CNCD;
   wire       BGV2_CNDX;
   wire       BGV3_CNDX;
   wire       CLK6M_a;
   wire       nCMPBLKs2;
   wire       FLIP;
   wire       nMEWR;
   wire [8:0] SCRL;
   wire [7:0] BGPOS;
   wire       nSW;
    
   //PCB connector 2
   
   wire [7:0] DCON_out;
   wire [7:0] DCON_in;
   wire [10:0] CPU_A;
   wire        bn256H;
   wire        nVBLANK;
   wire        nADDR9A9BXX;
   wire        nCS_SPR;
   wire        nCS_PAL;

   //PCB connector 3
   wire        bCLK6M;
   wire        SC0,SC1,SC2;
   wire        SV0,SV1,SV2;
   wire        CN3_38;
   wire        CN3_39;
   wire        nCMPBLKs;
   wire        f3_12;
   wire        OC3,OC4,OC0,OC1,OC2,OV2;

   //PCB connector 4
   wire        OV0,OV1;
   wire        CN4_3,CN4_4,CN4_5,CN4_6;
   wire        f1V,f2V,f4V,f8V,f16V,f32V,f64V,f128V;
   wire        b1H,b2H,b4H,b8H,b16H,b32H,b64H,b256H,nTVSYNC;
   wire        f8H,f16H,f32H,f64H,f128H;

   //Data connector
   wire [7:0]  DCON_out_board1,DCON_out_board2, DCON_out_board3;
   
   assign csync = nTVSYNC;

   wire [15:0] bd1_sout;
   assign SOUT = bd1_sout;
        
   
   starforc_board1 gamemain1
     (
      .cpuclk (clk_4m_en),
      .sndclk (clk_2m_en),
      .ctrlr  (JOY),
      .dipsw  ( dipsw ) , 
      .clk48m ( clk_48m ),
      .clk12m ( clk_12m ),
      .sout ( bd1_sout ),
      .reset ( reset ),

      //connector 1
      .nCS_V90  ( nCS_V90 ),
      .f3_7     ( f3_7 ),
      .nCS_BGPOS (nCS_BGPOS),
      .nMERD ( nMERD ),
      .nCS_BGV3 ( nCS_BGV3 ),
      .nCS_BGV2 ( nCS_BGV2 ),
      .nCS_BGV1 ( nCS_BGV1 ),
      .BGV1_CNCD ( BGV1_CNCD ),
      .BGV2_CNDX ( BGV2_CNDX ),
      .BGV3_CNDX ( BGV3_CNDX ),
      .CLK6M_a ( CLK6M_a ),
      .nCMPBLKs2 ( nCMPBLKs2 ),
      .FLIP ( FLIP ),
      .nMEWR ( nMEWR ),
      .SCRL ( SCRL ),
      .BGPOS ( BGPOS ),
      .nSW ( nSW ),
    
      //connector2
      .DCON_out ( DCON_out_board1 ),
      .DCON_in ( DCON_out_board2 | DCON_out_board3 ),
      .CPU_A ( CPU_A ),
      .bn256H ( bn256H ),
      .b64H ( b64H ),
      .b32H ( b32H ),
      .b16H ( b16H ),
      .b8H ( b8H ),
      .b2H ( b2H ),
      .nVBLANK ( nVBLANK ),
      .nADDR9A9BXX ( nADDR9A9BXX ),
      .nCS_SPR ( nCS_SPR ),
      .nCS_PAL ( nCS_PAL ),
      
      //memory module
      .CPU0_A ( CPU0_A ),
      .CPU1_A ( CPU1_A ),
      .CPU0_DO ( CPU0_DO ),
      .CPU1_DO ( CPU1_DO ),
      .sndrom ( sndrom ),
      .rom23 ( rom23 ),
      .rom45 ( rom45 ),
                
                .sndprom_din ( sndprom_d ),
                .sndprom_aout ( sndprom_a ),
					 
					 .muteki ( muteki )
                
      
      );
        
   wire nHSYNC,nVSYNC,nHBLANK;
        
   assign HSync = ~nHSYNC;
   assign VSync = ~nVSYNC;
   assign HBlank = ~nHBLANK;
   assign VBlank = ~nVBLANK;
   assign pxclk = clk_6048;

   starforc_board2 gamemain2
     (
      .grpclk1 (clk_12096),
      .grpclk2 (clk_6048),
      .cpuclk  ( clk_4m ),
      .clk48m  ( clk_48m ),
   
      .nVSYNC ( nVSYNC ),
      .nHSYNC ( nHSYNC ),
      .nHBLANK ( nHBLANK ),
      
    //connector 1                                                                                                
      .nCS_V90 ( nCS_V90 ),
      .nMERD ( nMERD ),
      .BMP1_Ser ( BMP1_Ser ),
      .BMP2_Ser ( BMP2_Ser ),
      .FLIP ( FLIP ),
      .nMEWR ( nMEWR ),
      .nSW ( nSW ),

    //connector2                                                                                                 
      .DCON_out ( DCON_out_board2 ),
      .DCON_in ( DCON_out_board1),
      .CPU_A ( CPU_A ),
      .nVBLANK ( nVBLANK ),
      .nADDR9A9BXX ( nADDR9A9BXX ),
      .nCS_SPR ( nCS_SPR ),

    //connector3
      .nCMPBLKs2 ( nCMPBLKs2 ),
      .BGPOS ( BGPOS ),
      .SC0 ( SC0 ), .SC1 ( SC1 ), .SC2 ( SC2 ),
      .SV0 ( SV0 ), .SV1 ( SV1 ), .SV2 ( SV2 ),
      .nCMPBLKs ( nCMPBLKs ),
      .f3_12 ( f3_12 ),
      .OC0 ( OC0 ), .OC1 ( OC1 ), .OC2 ( OC2 ), .OC3 ( OC3 ), .OC4 ( OC4 ),
      .OV2 ( OV2 ),

      //connector 4
      .OV0 ( OV0 ), .OV1 ( OV1 ),
      .f1V ( f1V ), .f2V ( f2V ), .f4V ( f4V ) , .f8V ( f8V ), .f16V ( f16V ), .f32V ( f32V ),
      .f64V ( f64V ), .f128V ( f128V ),
      .b1H ( b1H ), .b2H ( b2H ), .b4H ( b4H ), .b8H ( b8H ), .b16H ( b16H ),
      .b32H ( b32H ), .b64H ( b64H ), .b256H ( b256H ),  .bn256H ( bn256H ),
      .nTVSYNC ( nTVSYNC ),
      .f8H ( f8H ), .f16H ( f16H ), .f32H ( f32H ), .f64H ( f64H ), .f128H ( f128H ),

      //memory
      .ROMA_addr ( ROMA_addr ),
      .rom9_o ( rom9_o ),
      .rom10_o ( rom10_o),
      .rom11_o ( rom11_o),
      .rom12_o ( rom12_o),
      .rom13_o ( rom13_o),
      .rom14_o ( rom14_o),
      .romb_addr ( romb_addr ),
      .rom6_o (rom6_o),
      .rom7_o (rom7_o),
      .rom8_o ( rom8_o )
      
      );

   starforc_board3 gamemain3
     (
      .grpclk1 ( clk_12096 ),
      .grpclk2 ( clk_6048 ),
      .cpuclk ( clk_4m ),

      .rgb_out ( {red,green,blue} ),

      .b1H ( b1H ), .b2H ( b2H ), .b4H ( b4H ), .b8H ( b8H ), .b16H ( b16H ),
      .b32H ( b32H ), .b64H ( b64H ), .bn256H ( bn256H ), .b256H ( b256H ),
      .f8H ( f8H ), .f16H ( f16H ), .f32H ( f32H ), .f64H ( f64H ), .f128H ( f128H ),
      .nCS_BGV1 ( nCS_BGV1 ),
      .nCS_BGV2 ( nCS_BGV2 ),
      .nCS_BGV3 ( nCS_BGV3 ),

      .bA ( CPU_A[9:0] ),
      .FLIP ( FLIP ),
      .dcon_in ( DCON_out_board1),
      .dcon_out ( DCON_out_board3 ),

      .nCS_BGPOS ( nCS_BGPOS ),
      .nCMPBLKs ( nCMPBLKs ),
      .nCMPBLKs2 ( nCMPBLKs2 ),
      .nCS_PAL ( nCS_PAL ),
      .f1V ( f1V ), .f2V ( f2V ), .f4V ( f4V ) , .f8V ( f8V ), .f16V ( f16V ), .f32V ( f32V ),
      .f64V ( f64V ), .f128V ( f128V ),
      .f3_7 ( f3_7 ),
      .f3_12 ( f3_12 ),

      .nMERD ( nMERD ),
      .nMEWR ( nMEWR ),
      .OC0 ( OC0 ), .OC1 ( OC1 ), .OC2 ( OC2 ), .OC3 ( OC3 ), .OC4 ( OC4 ),
      .OV2 ( OV2 ),
      .OV0 ( OV0 ), .OV1 ( OV1 ),

      .SC0 ( SC0 ), .SC1 ( SC1 ), .SC2 ( SC2 ),
      .SV0 ( SV0 ),

      .CN3_39 ( SV2 ),
      .CN3_38 ( SV1 ),
      .BGV1_CNCD ( BGV1_CNCD ),
      .BGV2_CNDX ( BGV2_CNDX ),
      .BGV3_CNDX ( BGV3_CNDX ),

      .BGPOS_D ( BGPOS ),
      .SCRL ( SCRL ),
      
      .sw12_a ( sw12_a ),
      .rom1517_a ( rom1517_a ),
      .rom1820_a ( rom1820_a ),
      .sw1_o ( sw1_o ),
      .sw2_o ( sw2_o ),
      .sw1b_o ( sw1b_o ),
      .rom15_o ( rom15_o ),
      .rom16_o ( rom16_o ),
      .rom17_o ( rom17_o ),
      .rom18_o ( rom18_o ),
      .rom19_o ( rom19_o ),
      .rom20_o ( rom20_o ),
      .sw12_a12 ( sw12_a12 ),
      .sfrgb_out ( sfrgb )

      );
    
   starforce_memory mem0 
     (
      .CPU0_A ( CPU0_A ),
      .CPU1_A ( CPU1_A ),
      .sndrom ( sndrom ),
      .rom23 ( rom23 ),
      .rom45 ( rom45 ),
      .cpuclk (clk_4m_en),
      .sndclk (clk_2m_en),
      .grpclk1 (clk_12096),
      .grpclk2 (clk_6048),
      .ROMA_addr ( ROMA_addr ),
      .rom9_o ( rom9_o ),
      .rom10_o ( rom10_o),
      .rom11_o ( rom11_o),
      .rom12_o ( rom12_o),
      .rom13_o ( rom13_o),
      .rom14_o ( rom14_o),
      .romb_addr ( romb_addr ),
      .rom6_o (rom6_o),
      .rom7_o (rom7_o),
      .rom8_o ( rom8_o ),
      .sw12_a ( sw12_a ),
      .rom1517_a ( rom1517_a ),
      .rom1820_a ( rom1820_a ),
      .sw12_a12 ( sw12_a12 ),
      .sw1_o ( sw1_o ),
      .sw1b_o ( sw1b_o ),
      .sw2_o ( sw2_o ),
      .rom15_o ( rom15_o ),
      .rom16_o ( rom16_o ),
      .rom17_o ( rom17_o ),
      .rom18_o ( rom18_o ),
      .rom19_o ( rom19_o ),
      .rom20_o ( rom20_o ),
		
      .sndprom_dout ( sndprom_d ),
      .sndprom_ain  ( sndprom_a ),
		

      .ROMCL ( ROMCL ),
      .ROMAD ( ROMAD ),
      .ROMDT ( ROMDT ),
      .ROMEN ( ROMEN )

);
endmodule


module ls139 
  (
   input wire  nE,
   input wire  A0,A1,
   output wire nO0,nO1,nO2,nO3
   );

   assign nO0 =  ( nE |  A0 |  A1 );
   assign nO1 =  ( nE | ~A0 |  A1 );
   assign nO2 =  ( nE |  A0 | ~A1 );
   assign nO3 =  ( nE | ~A0 | ~A1 );

endmodule // LS139

   
module ls138 
  (
   input wire	     E3,
   input wire	     nE1,nE2,
   input wire	     A0,A1,A2,
   output wire [7:0] nO );

   wire		     nE = ~E3 | nE2 | nE1 ;
   
   assign nO[0] = ( nE |  A2 |  A1 |  A0 );
   assign nO[1] = ( nE |  A2 |  A1 | ~A0 );
   assign nO[2] = ( nE |  A2 | ~A1 |  A0 );
   assign nO[3] = ( nE |  A2 | ~A1 | ~A0 );
   assign nO[4] = ( nE | ~A2 |  A1 |  A0 );
   assign nO[5] = ( nE | ~A2 |  A1 | ~A0 );
   assign nO[6] = ( nE | ~A2 | ~A1 |  A0 );
   assign nO[7] = ( nE | ~A2 | ~A1 | ~A0 );

endmodule // LS138

module ls283 
  (
   input wire [3:0]  A,
   input wire [3:0]  B,
   input wire	     c0,
   output wire [3:0] S,
   output wire	     c4
   );
   
   assign {c4,S} = ( {1'b0,A} + {1'b0,B} ) + c0;
   
endmodule // ls283

module ls194x2
  (
   input wire	    clk,
   input wire	    CR,
   input wire [7:0] P,
   input wire	    DR,DL,
   input wire [1:0] S,
   output reg [7:0] Q
   );
   always@ (posedge clk or negedge CR)
     begin
        if ( CR==0 )
          Q = 8'b0;
        else
	  //Q=Q;
	  case( S )
            2'b11:      	
              Q = P;
            2'b01:
              Q = { Q[6:0],DR };
            2'b10:
              Q = { DL,Q[7:1] };
            2'b00:
              Q = Q;
	    
          endcase
     end

endmodule // ls194x2

module ls194 
  (
  input wire	    clk,
  input wire	    CR,
  input wire	    A,B,C,D,
  input wire	    DR,DL,
  input wire [1:0] S,
  output reg [3:0] Q
    );
   
   always@ (posedge clk or negedge CR)
     begin
        if ( CR==0 )                    
	  Q = 4'b0;
	else 
	  
	  //Q=Q;
          case( S )
            2'b11:            
              Q = {D,C,B,A};          
            2'b01:
              Q = {Q[2:0],DR};        
            2'b10:
              Q = {DL,Q[3:1]};        
            2'b00:
              Q = Q;                  
	    
          endcase
     end

endmodule // ls194

module ls194x2b
  (
   
   input wire	    clk,
   input wire	    CR,
   input wire [7:0] P,
   input wire	    DR,DL,
   input wire [1:0] S,
   input wire       en,
   output reg [7:0] Q
   );
   always@ (posedge clk or negedge CR)
     begin
        if ( CR==0 )
          Q = 8'b0;
        else
    if (en )

	  //Q=Q;
	  case( S )
            2'b11:      	
              Q = P;
            2'b01:
              Q = { Q[6:0],DR };
            2'b10:
              Q = { DL,Q[7:1] };
            2'b00:
              Q = Q;
	    
          endcase
     end

endmodule // ls194x2b

module ls85
  (
   input wire [3:0] A,
   input wire [3:0] B,
   input wire	    iAsmB,
   input wire	    iAeqB,
   input wire	    iAbiB,
   output wire	    oAsmB,
   output wire	    oAeqB,
   output wire	    oAbiB
   
   );
   
   wire		    abi1,abi2,abi3,abi4,abi5,abi6;
   wire		    asm1,asm2,asm3,asm4,asm5,asm6;

   wire		    a3b3x = ~( ( A[3] & ~( A[3] & B[3] ) ) | ( B[3] & ~( A[3] & B[3] ) ) );
   wire		    a2b2x = ~( ( A[2] & ~( A[2] & B[2] ) ) | ( B[2] & ~( A[2] & B[2] ) ) );
   wire		    a1b1x = ~( ( A[1] & ~( A[1] & B[1] ) ) | ( B[1] & ~( A[1] & B[1] ) ) );
   wire		    a0b0x = ~( ( A[0] & ~( A[0] & B[0] ) ) | ( B[0] & ~( A[0] & B[0] ) ) );
   
   assign abi1 = B[3] & ~( A[3] & B[3] );
   assign abi2 = B[2] & ~( A[2] & B[2] ) & a3b3x;
   assign abi3 = B[1] & ~( A[1] & B[1] ) & a3b3x & a2b2x;
   assign abi4 = B[0] & ~( A[0] & B[0] ) & a3b3x & a2b2x & a1b1x;
   assign abi5 = a3b3x & a2b2x & a1b1x & a0b0x & iAsmB;
   assign abi6 = a3b3x & a2b2x & a1b1x & a0b0x & iAeqB;
   assign oAbiB = ( ~abi1 & ~abi2 & ~abi3 & ~abi4 & ~abi5 & ~abi6 );
   assign oAeqB = a3b3x & a2b2x & iAeqB & a1b1x & a0b0x;
   assign asm1 = iAeqB & a0b0x & a1b1x & a2b2x & a3b3x;
   assign asm2 = iAbiB & a0b0x & a1b1x & a2b2x & a3b3x;
   assign asm3 = a1b1x & a2b2x & a3b3x & ~( A[0] & B[0]) & A[0];
   assign asm4 = a3b3x & a2b2x & ~( A[1] & B[1] ) & A[1] ;
   assign asm5 = a3b3x & ~( A[2] & B[2] ) & A[2] ;
   assign asm6 = ~( A[3] & B[3] ) & A[3];

   assign oAsmB = ( ~asm1 & ~asm2 & ~asm3 & ~asm4 & ~asm5 & ~asm6 );

endmodule // ls85

module ls148
  (
   input wire [7:0] i,
   input wire ei,
   output wire [2:0] s,
   output wire gs,
   output wire eo
   );

   assign eo = ~ ( ( i == 8'b11111111 ) & ~ei );
   assign gs = ~ ( eo & ~ei );
   assign s[0] = ~ ( ( ~i[1] & i[2] & i[4] & i[6] & ~ei ) | 
		    ( ~i[3] & i[4] & i[6] & ~ei ) | 
		    ( ~i[5] & i[6] & ~ei ) | 
		    ( ~i[7] & ~ei ) );

   assign s[1] = ~( ( ~i[2] & i[4] & i[5] & ~ei ) | 
		    ( ~i[3] & i[4] & i[5] & ~ei ) | 
		    ( ~i[6] & ~ei ) | 
		    ( ~i[7] & ~ei ) );
   
   assign s[2] = ~( ( ~i[4] & ~ei ) | 
		    ( ~i[5] & ~ei ) | 
		    ( ~i[6] & ~ei ) | 
		    ( ~i[7] & ~ei ) );

endmodule // ls148

module ls153 
  (
   //          1 g/ b c3 c2 c1 c0 2g/   a  2c3 2c2 2c1 2c0 
   input wire p1,p2,p3,p4,p5,p6,p15,p14,p13,p12,p11,p10,
   //1y 2y
   output wire p7,p9
   // ba - select
   // LL - y=c0
   // LH - y=c1
   // HL - y=c2
   // HH - y=c3
   // g/==H -> Y=L
   
   );
   
   assign p7 = p1 ? 0 : (
			 (~p2 & ~p14 ) ? p6 :
			 (~p2 &  p14 ) ? p5 :
			 ( p2 & ~p14 ) ? p4 : p3 );
   
   assign p9 = p15 ? 0 : (
			  (~p2 & ~p14 ) ? p10 :
			  (~p2 &  p14 ) ? p11 :
			  ( p2 & ~p14 ) ? p12 : p13 );
   
endmodule // ls153
