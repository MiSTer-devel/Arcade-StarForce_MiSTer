//=======================================================
/* FPGA STARFORCE PCB board3 module
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

module starforc_board3
  (


   input wire         grpclk2,
   input wire         grpclk1,
   input wire         cpuclk,

   input wire         b1H,b2H,b4H,b8H,b16H,bn256H,b256H,
   input wire         f8H,f16H,f32H,f64H,f128H,
   input wire         nCS_BGV1,nCS_BGV2,nCS_BGV3,
   input wire [9:0]   bA,
   input wire         FLIP,
   input wire [7:0]   dcon_in,
   output wire [7:0]  dcon_out,
   output wire [7:0]  rgb_out,

      
   input wire         nCS_BGPOS,
   input wire         nCMPBLKs,
   input wire         nCMPBLKs2,
   input wire         nCS_PAL,
   input wire         f1V,f2V,f4V,f8V,f16V,f32V,f64V,f128V,
   input wire         b32H,b64H,
   output wire        f3_7,f3_12,
   input wire         nMERD,nMEWR,
   input wire         OC0,OC1,OC2,OC3,OC4,
   input wire         SV0,SC0,SC1,SC2,
   input wire         OV0,OV1,OV2,
   input wire         CN3_39,CN3_38,
   input wire         CN4_3,CN4_4,CN4_5,CN4_6,
   output wire        BGV1_CNCD,
   output wire        BGV2_CNDX,
   output wire        BGV3_CNDX,
   
   output wire [7:0]  BGPOS_D,
   output wire [8:0]  SCRL,
   output wire [11:0] sfrgb_out,
   
   //memory
   output wire [12:0] sw12_a,
   output wire [12:0] rom1517_a,
   output wire [12:0] rom1820_a,
   input wire [7:0]   sw1_o,sw2_o,sw1b_o,
   input wire [7:0]   rom15_o,rom16_o,rom17_o,
   input wire [7:0]   rom18_o,rom19_o,rom20_o,
   output wire        sw12_a12
   
   );


	parameter [7:0] bg_v_deviation = 8'b1;

	
   reg nx0H,nx4H,nx8H,nx12H,nx16H,nx20H,nx24H,nx28H;
   
   always @(posedge grpclk1)
     if (grpclk2) begin
        if ( b2H ^ b1H ) 
          begin
             nx0H  = ~ ( ~b4H & ~b8H & ~b16H );
             nx4H  = ~ (  b4H & ~b8H & ~b16H );
             nx8H  = ~ ( ~b4H &  b8H & ~b16H );
             nx12H = ~ (  b4H &  b8H & ~b16H );
             nx16H = ~ ( ~b4H & ~b8H &  b16H );
             nx20H = ~ (  b4H & ~b8H &  b16H );
             nx24H = ~ ( ~b4H &  b8H &  b16H );
             nx28H = ~ (  b4H &  b8H &  b16H );
          end
        else
          begin
             nx0H  <= 1'b1;
             nx4H  <= 1'b1;
             nx8H  <= 1'b1;
             nx12H <= 1'b1;
             nx16H <= 1'b1;
             nx20H <= 1'b1;
             nx24H <= 1'b1;
             nx28H <= 1'b1;
             
          end // else: !if( b2H ^ b1H )
     end // if (grpclk2)
   
   reg [3:0] uL1_q,uL2_q,uR1_q,uR2_q,uL3_q,uR3_q;
   reg [8:0] uL12_q;
	
	
	
   always @(posedge grpclk1)
     if (grpclk2) begin
        if ( b2H & b1H )
          begin
             if ( ~b4H & ~b8H & ~b16H ) begin // x0H
                uL12_q = BGPOS_D + bg_v_deviation;
					 uL1_q = uL12_q[3:0];
					 uL2_q = uL12_q[7:4];
             end
             if ( ~b4H &  b8H & ~b16H ) begin // x8H
                uR1_q <= BGPOS_D[3:0];
                uR2_q <= BGPOS_D[7:4];
             end
             if (  b4H & ~b8H & ~b16H ) begin // x4H
                uL3_q[2:0] <= BGPOS_D[2:0] + uL12_q[8];
					 uL3_q[3] <= 1'b0;
             end
             if (  b4H &  b8H & ~b16H ) begin // x12H
                uR3_q[1:0] <= BGPOS_D[1:0];
					 uR3_q[3:2] <= 2'b0;
             end
          end // if ( b2H & b1H )
     end // if (grpclk2)
   
   wire [3:0] uM1_S,uM2_S,uM3_S;
   wire       uM1_c4,uM2_c4;

   ls283 uM1
     (
      .A ( uL1_q ),
      .B ( { f8V, f4V, f2V, f1V } ),
      .c0 ( 1'b0 ),
      .S ( uM1_S ),
      .c4 ( uM1_c4 )
      );
   
   ls283 uM2
     (
      .A ( uL2_q ),
      .B ( { f128V, f64V, f32V, f16V } ),
      .c0 ( uM1_c4 ),
      .S ( uM2_S ),
      .c4 ( uM2_c4 )
      );
   
   ls283 uM3
     (
      .A ( {1'b0, uL3_q[2:0] } ),
      .B ( 4'b0 ),
      .c0 ( uM2_c4 ),
      .S ( uM3_S ),
      .c4 ()
      );

   //p10,p2,p3
   wire [3:0] p10_Z;
   assign p10_Z = p123s ? ~uR1_q : 4'b1111;

   wire [3:0] p2_Z;
   assign p2_Z = p123s ? ~uR2_q : 4'b1111;

   wire [3:0] p3_Z;
   assign p3_Z = p123s ? ~uR3_q : 4'b1111;
   
   //N1
   wire       uN1_c4;
   ls283 uN1
     (
      .A ( uM1_S ),
      .B ( p10_Z ),
      .c0 ( 1'b0 ),
      .S ( SCRL[3:0] ),
      .c4 ( uN1_c4 )
      );

   wire       uN2_c4;
   ls283 uN2
     (
      .A ( uM2_S ),
      .B ( p2_Z ),
      .c0 ( uN1_c4 ),
      .S ( SCRL[7:4] ),
      .c4 ( uN2_c4 )
      );
   
   wire [3:0] uN3_S;
   ls283 uN3
     (
      .A ( { 2'b0, uM3_S[1:0] } ),
      .B ( { 2'b0, p3_Z[1:0] } ),
      .c0 ( uN2_c4 ),
      .S ( uN3_S ),
      .c4 ( )
           
      );
   
   assign SCRL[8] = uN3_S[0];

   //uS1 LS85
   wire uS1_AbiB;
   wire uS1_AeqB;
   wire uS1_AsmB;
   
   ls85 uS1
     (
      .A ( uM1_S ),
      .B ( uR1_q ),
      .iAsmB ( 1'b0 ),
      .iAeqB ( 1'b1 ),
      .iAbiB ( 1'b0 ),
      .oAsmB ( uS1_AsmB ),
      .oAeqB ( uS1_AeqB ),
      .oAbiB ( uS1_AbiB )
      );

   wire uS2_AsmB;
   wire uS2_AeqB;
   wire uS2_AbiB;


   ls85 uS2
     (
      .A ( uM2_S ),
      .B ( uR2_q ),
      .iAsmB ( uS1_AsmB ),
      .iAeqB ( uS1_AeqB ),
      .iAbiB ( uS1_AbiB ),
      .oAsmB ( uS2_AsmB ),
      .oAeqB ( uS2_AeqB ),
      .oAbiB ( uS2_AbiB )
  );

   wire uS3_AsmB;
   wire uS3_AeqB;
   wire uS3_AbiB;
   wire p123s;
   
   ls85 uS3
     (
      .A ( {1'b0, uM3_S[2:0]} ),
      .B ( {2'b00, uR3_q[1:0]} ),
      .iAsmB ( uS2_AsmB ),
      .iAeqB ( uS2_AeqB ),
      .iAbiB ( uS2_AbiB ),
      .oAsmB ( ),
      .oAeqB ( ),
      .oAbiB ( p123s )
      );


   //BG part
   wire n256Hx20H = bn256H | nx20H;
   wire f3_4,f3_5,f3_6;
   
   ls139 uF3A
     (
      .A1 ( b64H ),
      .A0 ( b32H ),
      .nE ( n256Hx20H ),
      .nO0 ( f3_4 ),
      .nO1 ( f3_5 ),
      .nO2 ( f3_6 ),
      .nO3 ( f3_7 )
      );

   wire n256Hx28H = bn256H | nx28H;

   ls139 uF3B
     (
      .A1 ( b64H ),
      .A0 ( b32H ),
      .nE ( n256Hx28H ),
      .nO0 ( f3_12 ),
      .nO1 ( ),
      .nO2 ( ),
      .nO3 ( )
      );
   
   reg [7:0] bc8_c;
   
   wire [7:0] sw12_dout;
   wire       sw12_l468cp;


   //StarField
   //sw12
	
   bgpart sw12
     (
      .grpclk2 ( grpclk2 ),
      .grpclk1 ( grpclk1 ),
      .cpuclk ( cpuclk ),
      .bc468pe ( f3_4 ),
      .a456789_cp ( f3_4 ),
      .BGPOS_D ( BGPOS_D ),
      .nCMPBLKs2 ( nCMPBLKs2 ),
      .nCS_BGV ( nCS_BGV3 ),
      .nMERD ( nMERD ),
      .nMEWR ( nMEWR ),
      .SCRL ( SCRL ),
      .bA ( bA ),
      .FLIP ( FLIP ),
      .BGV_CNDx ( BGV3_CNDX ),
      .BGV2_CNDx ( ),
      .DCON_out ( sw12_dout ),
      .DCON_in ( dcon_in ),
      .s0_194x6 ( sw12_s0 ),
      .s1_194x6 ( sw12_s1 ),
      .SWxs ( sw12s_a ),
      .SWx ( sw12_a ),
      .SW12_a12 ( sw12_a12 ),
      .l8_cn011_next_cp (l8cp)
      
      );

   wire       l8cp;

   assign dcon_out = sw12_dout | bg1820_dout | bg1517_dout | bgpos_do | pal_do;

   wire [12:0] sw12s_a;
   wire        sw12_s0,sw12_s1;
          
   wire [7:0]  sw2_ser;
   ls194x2 uP89
     (
      .clk ( grpclk2 ),
      .CR ( 1'b1 ),
      .P ( {sw2_o[0],sw2_o[1],sw2_o[2],sw2_o[3],sw2_o[4],sw2_o[5],sw2_o[6],sw2_o[7]} ),
      .DR ( 1'b0 ),
      .DL ( 1'b0 ),
      .S ( {sw12_s1,sw12_s0} ),
      .Q ( sw2_ser )

      );           

   wire        sw2_s1 = sw2_ser[0];
   wire        sw2_s2 = sw2_ser[7];

   wire [7:0]  sw1_ser;
     
   ls194x2 ujk8
     (
      .clk ( grpclk2 ),
      .CR ( 1'b1 ),
      .P ( {sw1_o[0],sw1_o[1],sw1_o[2],sw1_o[3],sw1_o[4],sw1_o[5],sw1_o[6],sw1_o[7]} ),
      .DR ( 1'b0 ),
      .DL ( 1'b0 ),
      .S ( {sw12_s1,sw12_s0} ),
      .Q ( sw1_ser )

      );           
   
   wire        sw1_s1 = sw1_ser[0];
   wire        sw1_s2 = sw1_ser[7];

   //l8 273
   reg [7:0]   sw1_ds;
   always @(posedge grpclk1 )
     if (grpclk2) begin
        if  (l8cp)     
          sw1_ds <= sw1_o;
        
     end
                
   wire [7:0] sw1s_ser;
   
   ls194x2 umn8_b
     (
      .clk ( grpclk2 ),
      .CR ( 1'b1 ),
      .P ( {sw1b_o[0],sw1b_o[1],sw1b_o[2],sw1b_o[3],sw1b_o[4],sw1b_o[5],sw1b_o[6],sw1b_o[7]} ),
      .DR ( 1'b0 ),
      .DL ( 1'b0 ),
      .S ( {sw12_s1,sw12_s0} ),
      .Q ( sw1s_ser )

      );
   wire       sw1s_s1 = sw1s_ser[0];
   wire       sw1s_s2 = sw1s_ser[7];
   
   wire       SW1SER = FLIP ? sw1_s2 : sw1_s1;
   wire       SW2SER = FLIP ? sw2_s2 : sw2_s1;
   wire       SW1sSER = FLIP ? sw1s_s2 : sw1s_s1;

   
   // bgpart 18-20 ground scroll
   // 1bit late? -> 1bit forward
   
   wire	      BGV2_CNDx;
   wire [7:0] bg1820_dout;
   wire	      rom1820_s0,rom1820_s1;
   
   bgpart rom1820
     (
      .grpclk2 ( grpclk2 ),
      .grpclk1 ( grpclk1 ),
      .cpuclk ( cpuclk ),
      .bc468pe ( f3_6 ),
      .a456789_cp ( f3_6 ),
      .BGPOS_D ( BGPOS_D ),
      .nCMPBLKs2 ( nCMPBLKs2 ),
      .nCS_BGV ( nCS_BGV2 ),
      .nMERD ( nMERD ),
      .nMEWR ( nMEWR ),
      .SCRL ( SCRL ),
      .bA ( bA ),
      .FLIP ( FLIP ),
      .BGV_CNDx ( ),
      .BGV2_CNDx ( BGV2_CNDx ),
      .DCON_out ( bg1820_dout ),
      .DCON_in ( dcon_in ),
      .s0_194x6 ( rom1820_s0 ),
      .s1_194x6 ( rom1820_s1 ),
      .SWxs ( rom1820s_a ),
      .SWx ( rom1820_a ),
      .SW12_a12 ( ),
      .l8_cn011_next_cp ( ),
      .deviation ( 8'h001 ),
      .pal_deviation ( )
      );

   wire [12:0] rom1820s_a;
   wire [7:0]  rom18_ser;

   ls194x2b ujk6
     (
      .clk ( grpclk1 ),
      .en ( grpclk2 ),
      .CR ( 1'b1 ),
      .P ( {rom18_o[0],rom18_o[1],rom18_o[2],rom18_o[3],rom18_o[4],rom18_o[5],rom18_o[6],rom18_o[7]} ),
      .DR ( 1'b0 ),
      .DL ( 1'b0 ),
      .S ( {rom1820_s1,rom1820_s0} ),
      .Q ( rom18_ser )

      );           

   wire        rom18_s1 = rom18_ser[0];
   wire        rom18_s2 = rom18_ser[7];
   wire [7:0]  rom19_ser;

   ls194x2b umn6
     (
      .clk ( grpclk1 ),
      .en ( grpclk2 ),
      .CR ( 1'b1 ),
      .P ( {rom19_o[0],rom19_o[1],rom19_o[2],rom19_o[3],rom19_o[4],rom19_o[5],rom19_o[6],rom19_o[7]} ),
      .DR ( 1'b0 ),
      .DL ( 1'b0 ),
      .S ( {rom1820_s1,rom1820_s0} ),
      .Q ( rom19_ser )

      );           
   
   wire        rom19_s1 = rom19_ser[0];
   wire        rom19_s2 = rom19_ser[7];
   wire [7:0]  rom20_ser;

   ls194x2b up67
     (
      .clk ( grpclk1 ),
      .en ( grpclk2 ),
      .CR ( 1'b1 ),
      .P ( {rom20_o[0],rom20_o[1],rom20_o[2],rom20_o[3],rom20_o[4],rom20_o[5],rom20_o[6],rom20_o[7]} ),
      .DR ( 1'b0 ),
      .DL ( 1'b0 ),
      .S ( {rom1820_s1,rom1820_s0} ),
      .Q ( rom20_ser )

      );           
   
   wire        rom20_s1 = rom20_ser[0];
   wire        rom20_s2 = rom20_ser[7];
   
   wire        SW18SER = FLIP ? rom18_s2 : rom18_s1;
   wire        SW19SER = FLIP ? rom19_s2 : rom19_s1;
   wire        SW20SER = FLIP ? rom20_s2 : rom20_s1;



   wire       BGV1_CNDx;
   wire [7:0] bg1517_dout;
   wire       rom1517_s0,rom1517_s1;
   
   //bgpart 15-17  surface objects
   
   bgpart rom1517
     (
      .grpclk2 ( grpclk2 ),
      .grpclk1 ( grpclk1 ),
      .cpuclk ( cpuclk ),
      .bc468pe ( f3_6 /*SCRL[8]*/ ),
      .a456789_cp ( f3_6 ),
      .BGPOS_D ( BGPOS_D ),
      .nCMPBLKs2 ( nCMPBLKs2 ),
      .nCS_BGV ( nCS_BGV1 ),
      .nMERD ( nMERD ),
      .nMEWR ( nMEWR ),
      .SCRL ( SCRL ),
      .bA ( bA ),
      .FLIP ( FLIP ),
      .BGV_CNDx ( BGV1_CNCD ),
      .BGV2_CNDx ( ),
      .DCON_out ( bg1517_dout ),
      .DCON_in ( dcon_in ),
      .s0_194x6 ( rom1517_s0 ),
      .s1_194x6 ( rom1517_s1 ),
      .SWxs ( rom1517s_a ),
      .SWx ( rom1517_a ),
      .SW12_a12 ( ),
      .l8_cn011_next_cp ( ),
      .deviation (  )   ,
      .pal_deviation ( 4'hf )
      );

   wire [12:0] rom1517s_a;
   wire [7:0]  rom15_ser;

   ls194x2 ujk4
     (
      .clk ( grpclk2 ),
      .CR ( 1'b1 ),
      .P ( {rom15_o[0],rom15_o[1],rom15_o[2],rom15_o[3],rom15_o[4],rom15_o[5],rom15_o[6],rom15_o[7]} ),
      .DR ( 1'b0 ),
      .DL ( 1'b0 ),
      .S ( {rom1517_s1,rom1517_s0} ),
      .Q ( rom15_ser )

      );           

   wire        rom15_s1 = rom15_ser[0];
   wire        rom15_s2 = rom15_ser[7];

   wire [7:0]  rom16_ser;

   ls194x2 umn4
     (
      .clk ( grpclk2 ),
      .CR ( 1'b1 ),
      .P ( {rom16_o[0],rom16_o[1],rom16_o[2],rom16_o[3],rom16_o[4],rom16_o[5],rom16_o[6],rom16_o[7]} ),
      .DR ( 1'b0 ),
      .DL ( 1'b0 ),
      .S ( {rom1517_s1,rom1517_s0} ),
      .Q ( rom16_ser )

      );           
   
   wire        rom16_s1 = rom16_ser[0];
   wire        rom16_s2 = rom16_ser[7];

   wire [7:0]  rom17_ser;
   
   ls194x2 up45
     (
      .clk ( grpclk2 ),
      .CR ( 1'b1 ),
      .P ( {rom17_o[0],rom17_o[1],rom17_o[2],rom17_o[3],rom17_o[4],rom17_o[5],rom17_o[6],rom17_o[7]} ),
      .DR ( 1'b0 ),
      .DL ( 1'b0 ),
      .S ( {rom1517_s1,rom1517_s0} ),
      .Q ( rom17_ser )

      );           
   
   wire        rom17_s1 = rom17_ser[0];
   wire        rom17_s2 = rom17_ser[7];
   
   wire        SW15SER = FLIP ? rom15_s2 : rom15_s1;
   wire        SW16SER = FLIP ? rom16_s2 : rom16_s1;
   wire        SW17SER = FLIP ? rom17_s2 : rom17_s1;

   //posram
   //uhj1
   wire        h1a = bn256H ? f8H : b4H ;
   wire        h1b = bn256H ? f16H : b8H ;
   wire        h1c = bn256H ? f32H : b16H ;
   wire        h1d = bn256H ? f64H : b32H ;
   wire        j1a = bn256H ? f128H : b64H;
   
   wire        h3a = nCS_BGPOS ? h1a : bA[0];
   wire        h3b = nCS_BGPOS ? h1b : bA[1];
   wire        h3c = nCS_BGPOS ? h1c : bA[2];
   wire        h3d = nCS_BGPOS ? h1d : bA[3];
   wire        j3a = nCS_BGPOS ? j1a : bA[4];
   wire        j3b = nCS_BGPOS ? b256H : bA[5];

   wire [5:0]  POS_A = { j3b, j3a, h3d, h3c, h3b, h3a };

   wire        nBGPOS_WR = nCS_BGPOS | nMEWR;
   wire        nBGPOS_RD = nCS_BGPOS | nMERD;
   wire        nBGPOS_RDWR = nBGPOS_WR & nBGPOS_RD;

   spram6 posram
     (
      .address ( POS_A ),
      .data ( dcon_in  ),
      .q ( BGPOS_D  ),
      .clock ( grpclk1 ), 
      .wren ( ~nBGPOS_WR )
      );

   //dcon out
   wire [7:0] bgpos_do = ( nBGPOS_WR & ~nBGPOS_RDWR ) ? BGPOS_D : 8'b0;

   
   //VIDEO MIXER
   wire	      u3A_4,u3A_5,u3A_6,u3A_7;
   
   //u3A
   ls139 u3A
     (
      .A1 ( OC4 ),
      .A0 ( OC3 ),
      .nE ( ~(OV0 | OV1 | OV2 ) ),
      .nO0 ( u3A_4 ),
      .nO1 ( u3A_5 ),
      .nO2 ( u3A_6 ),
      .nO3 ( u3A_7 )
      );

   wire [2:0] uU4_s;
   wire       u5A = ~ ( SW1sSER | SW1SER | SW2SER ) ;
   wire       u5B = ~ ( SW15SER | SW16SER | SW17SER );
   wire       u5C = ~ ( SW18SER | SW19SER | SW20SER );
   wire       t3B = ~ ( CN3_39 | CN3_38 | SV0 );
   wire       uU4_gs;

   ls148 uU4
     (
      .i ( { t3B, u3A_7, u5B, u3A_6, u5C, u3A_5, u5A, u3A_4} ),
      .ei ( 1'b0 ),
      .eo (),
      .s ( uU4_s ),
      .gs ( uU4_gs )
      
      );
   
   //uT6
   wire T6Za,T6Zb;
   
   ls153 uT6
     (
      .p6 ( CN3_39 ),       .p5 ( SW15SER ),       .p4 ( SW18SER ),       .p3 ( SW1SER),
      .p1 ( 0 ),
      .p7 ( T6Za ),
      .p10 ( CN3_38 ),      .p11 ( SW16SER ),      .p12 ( SW19SER ),      .p13 ( SW1sSER ),
      .p15 ( 0 ),
      .p9 ( T6Zb ),

      .p14 ( uU4_s[1] ),
      .p2 ( uU4_s[2] )
                 
      );
   
   wire U7Za,U7Zb;
  
   ls153 uU7
     (
      .p6 ( T6Za ),          .p5 ( OV0 ),          .p4 ( 0 ),             .p3 ( CN4_3 ),
      .p1 ( 0 ),
      .p7 ( U7Za ),
      .p10 ( T6Zb ),        .p11 ( OV1 ),          .p12 ( 0 ),            .p13 ( CN4_4 ),
      .p15 ( 0 ),
      .p9 ( U7Zb ),

      .p14 ( uU4_s[0] ),
      .p2 ( uU4_gs )

      );
     
   wire T5Za,T5Zb;
   
   ls153 uT5
     (
      .p6 ( SV0 ),          .p5 ( SW17SER ),       .p4 ( SW20SER ),       .p3 ( SW2SER ),
      .p1 ( 0 ),
      .p7 ( T5Za ),
      .p10 ( SC0 ),       .p11 ( rom1517s_a[12] ),      .p12 ( rom1820s_a[10] ),      .p13 ( sw12s_a[10] ),
      .p15 ( 0 ),
      .p9 ( T5Zb ),

      .p14 ( uU4_s[1] ),
      .p2 ( uU4_s[2] )
      );
   

   wire U8Za,U8Zb;
   ls153 uU8
     (
      .p6 ( T5Za ),          .p5 ( OV2 ),          .p4 ( 0 ),             .p3 ( CN4_5 ),
      .p1 ( 0 ),
      .p7 ( U8Za ),
      .p10 ( T5Zb ),         .p11 ( OC0 ),         .p12 ( 0 ),            .p13 ( CN4_6 ),
      .p15 ( 0 ),
      .p9 ( U8Zb ),
      
      .p14 ( uU4_s[0] ),
      .p2 ( uU4_gs )

      );

   wire T4Za,T4Zb;
   ls153 uT4
     (
      .p6 ( SC1 ),          .p5 ( rom1517s_a[10] ),.p4 ( rom1820s_a[11] ),.p3 ( sw12s_a[11] ),
      .p1 ( 0 ),
      .p7 ( T4Za ),
      .p10 ( SC2 ),         .p11 ( rom1517s_a[11] ),.p12 ( rom1820s_a[12] ),.p13 ( sw12s_a[9] ),
      .p15 ( 0 ),
      .p9 ( T4Zb ),
      
      .p14 ( uU4_s[1] ),
      .p2 ( uU4_s[2] )

      );

   wire T8Za,T8Zb;
   ls153 uT8 
     (
      .p6 ( T4Za ),         .p5 ( OC1 ),            .p4 ( 0 ),             .p3 ( 0 ),
      .p1 ( 0 ),
      .p7 ( T8Za ),
      .p10 ( T4Zb ),        .p11 ( OC2 ),           .p12 ( 0 ),            .p13 ( 0 ),
      .p15 ( 0 ),
      .p9 ( T8Zb ),

      .p14 ( uU4_s[0] ),
      .p2 ( uU4_gs )

      );
   
   wire T7Za,T7Zb;
   
   ls153 uT7
     (
      .p6 (  uU4_s[1] ),         .p5 ( OC4 ),            .p4 ( 0 ),             .p3 ( 0 ),
      .p1 ( 0 ),
      .p7 ( T7Za ),
      .p10 ( uU4_s[2] ),        .p11 ( 0 ),             .p12 ( 0 ),            .p13 ( 1 ),
      .p15 ( 0 ),
      .p9 ( T7Zb ),

      .p14 ( uU4_s[0] ),
      .p2 ( uU4_gs )

      );

   reg [8:0] bgx;
   reg       u9q5;
   
   always @(posedge grpclk1)
     begin
        if (nCMPBLKs == 0 )
          bgx <= 9'b000000000;
        else begin
           if (grpclk2)    begin
              bgx <= { uU4_s[0],T7Zb,T7Za,T8Zb,T8Za,U8Zb,U8Za,U7Zb,U7Za };
           end
        end
     end // always @ (posedge grpclk1 or negedge nCMPBLKs )
 
   wire [8:0] PAL_A;
   wire [7:0] PAL_D;
   
   assign PAL_A = nCS_PAL ? bgx : bA[8:0];
   
   wire nPAL_RD = nMERD | nCS_PAL;
   wire nPAL_WR = nMEWR | nCS_PAL;
   wire nPALRDWR = nPAL_RD & nPAL_WR;
   wire pal_do = ( nPAL_WR & ~nPALRDWR ) ? PAL_D : 8'b0;
   
   spram10 cd2
     ( .address ( PAL_A ), .data ( dcon_in  ), .q ( PAL_D ), .clock ( grpclk1 ), .wren ( ~nPAL_WR ) );
   
   reg  rgb1,rgb0;
   reg	bb3,bb2,rr3,rr2,gg3,gg2;
   
   always @(posedge grpclk2)
     begin
        rgb1 <= PAL_D[7];
        rgb0 <= PAL_D[6];
        bb3 <= PAL_D[5];
        bb2 <= PAL_D[4];
        gg3 <= PAL_D[3];
        gg2 <= PAL_D[2];
        rr3 <= PAL_D[1];
        rr2 <= PAL_D[0];
     end
        
   wire nbb23 = ~( bb2 | bb3 );
   wire ngg23 = ~( gg2 | gg3 );
   wire nrr23 = ~( rr2 | rr3 );
   
   wire [3:0] R;
   wire [3:0] G;
   wire [3:0] B;
   
   assign B[3:0] = ~nbb23 ? { bb3, bb2, rgb1, rgb0 } : 4'b0;
   assign R[3:0] = ~nrr23 ? { rr3, rr2, rgb1, rgb0 } : 4'b0;
   assign G[3:0] = ~ngg23 ? { gg3, gg2, rgb1, rgb0 } : 4'b0;
   assign rgb_out = { R[3:1], G[3:1], B[3:2] };
   assign sfrgb_out = { R,G,B };
        
endmodule // starforc_board3

module bgpart
  (
   input wire        grpclk2,
   input wire        grpclk1,
   input wire        cpuclk,
   input wire        bc468pe,
   input wire        a456789_cp,
   input wire [7:0]  BGPOS_D,
   input wire        nCMPBLKs2,
   input wire        nCS_BGV,
   input wire        nMERD,
   input wire        nMEWR,
   input wire [8:0]  SCRL,
   input wire [9:0]  bA,
   input wire        FLIP,
   output wire       BGV_CNDx,
   output wire       BGV2_CNDx,
   output wire [7:0] DCON_out,
   input wire [7:0]  DCON_in,
   output wire       s0_194x6,
   output wire       s1_194x6,
   output reg [12:0] SWxs,
   output reg [12:0] SWx,
   output wire       SW12_a12,
   output wire       l8_cn011_next_cp,

   input wire [7:0]  deviation,
   input wire [3:0]  pal_deviation
 );
   
   reg [7:0]       bc468c;
 
   wire            nBGV_RD = nCS_BGV | nMERD;
   wire            nBGV_WR = nCS_BGV | nMEWR;
   
   always @(posedge grpclk1 )
     if ( grpclk2 ) begin
        if (bc468pe == 0) bc468c <= BGPOS_D + deviation;
        else
          if ( nCMPBLKs2 ) // cep,cet
            begin
               bc468c = bc468c + 1;
               SWx[3] = bc468c[3] ^ FLIP;
            end
     end
   
   assign l8_cn011_next_cp = (bc468c[2:0] == 3'b100 );
   
   wire uA579C = ~( bc468c[2] & bc468c[1] & bc468c[0] );
   assign SW12_a12 = bc468c[2];
   assign BGV_CNDx = bc468c[3] ^ bc468c[2];
   assign BGV2_CNDx = bc468c[3];
   
   always @(posedge grpclk1 )
     if (grpclk2) begin
        if (bc468c[2:0] == (3'b111 + pal_deviation)) ///suppose -1 is good 
          SWxs[12:9] = SWx[12:9];
     end

   //ls174 part
   reg [5:0] u174_q;
   
   always @(posedge a456789_cp )
     begin
        SWx[0] <= SCRL[0];
        SWx[1] <= SCRL[1];
        SWx[2] <= SCRL[2];
        SWx[4] <= SCRL[3];
        u174_q[4] <= SCRL[4];
        u174_q[5] <= SCRL[5];
        u174_q[2:0] <= SCRL[8:6];
     end
   
   wire [9:0] BGVxRAM_A;
   
   //ls157
   assign BGVxRAM_A = nCS_BGV ? { 1'b0, u174_q[2:0], u174_q[5:4], bc468c[7:4] ^ {4{FLIP}} } :
                      bA;

   wire snBGV_WR = nCS_BGV ? 1 : nBGV_WR;
   wire [7:0] BGVxRAM_Dout_a,BGVxRAM_Dout_b;


spram10 ef579
     (
      .address (   BGVxRAM_A ),
      .data ( DCON_in ),
      .q ( BGVxRAM_Dout_b ),
      .clock  ( ~grpclk1 ),
      .wren  ( ~snBGV_WR  )
      );

   
   wire [7:0] BGVxRAM_Dout;
   wire [7:0] BGVxRAM_Din;
   wire       f468_nce = nBGV_RD & snBGV_WR;
   
   assign DCON_out = (  ~f468_nce & snBGV_WR ) ? BGVxRAM_Dout_b : 8'b0;
   assign BGVxRAM_Dout = (  ~f468_nce & snBGV_WR ) ? 8'b0 : BGVxRAM_Dout_b; //BGVxRAM_Dout_a;

   always @(posedge grpclk1 )
     if (grpclk2) begin
        if (bc468c[3:1] == 3'b001)
          SWx[12:5] <= BGVxRAM_Dout;
     end


   assign s0_194x6 =  FLIP | ~uA579C;
   assign s1_194x6 = ~FLIP | ~uA579C;
   
endmodule // bgpart
     
