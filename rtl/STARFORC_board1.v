//=======================================================
/* FPGA STARFORCE PCB board1 module
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

module starforc_board1 
  (
   input wire	      cpuclk,
   input wire	      sndclk,
   input wire	      clk48m,
   input wire	      clk12m,
   input wire [7:0]   ctrlr,
   input wire [15:0]  dipsw, 

   output wire [15:0] sout,

   output wire	      nCS_V90,
   input wire	      f3_7,
   output wire	      nCS_BGPOS,
   output wire	      nMERD,
   output wire	      nCS_BGV3,
   output wire	      nCS_BGV2,
   output wire	      nCS_BGV1,
   input wire	      BGV1_CNCD,
   input wire	      BGV2_CNDX,
   input wire	      BGV3_CNDX,
   input wire	      CLK6M_a,
   input wire	      nCMPBLKs2,
   output reg	      FLIP,
   output wire	      nMEWR,
   input wire [8:0]   SCRL,
   input wire [7:0]   BGPOS,
   input wire	      nSW,
    
    //connector2
   output wire [7:0]  DCON_out,
   input wire [7:0]   DCON_in,
   output wire [10:0] CPU_A,
   input wire	      bn256H,
   input wire	      b64H,
   input wire	      b32H,
   input wire	      b16H,
   input wire	      b8H,
   input wire	      b2H,
   input wire	      nVBLANK,
   output wire	      nADDR9A9BXX,
   output wire	      nCS_SPR,
   output wire	      nCS_PAL,
   
   //memory
   output wire [15:0] CPU0_A,
   output wire [15:0] CPU1_A,
   output wire [7:0]  CPU0_DO,
   output wire [7:0]  CPU1_DO,
   input wire [7:0]   sndrom,
   input wire [7:0]   rom23,
   input wire [7:0]   rom45,
   output wire	      ram0_we,
   output wire	      sndram0_we,
   output wire [7:0]  sndprom_aout,
   input wire [7:0]   sndprom_din,
        
   //MiSTer side
   input wire	      reset,

	input wire muteki
	
   
   );
    
   assign CPU_A = CPU0_A[10:0];
    
   //memory board
   assign ram0_we = ~nMEWR & ( ~nRAM1_CS | ~nRAM2_CS )  ;
   assign sndram0_we = ~nCPU1_WR & ~nSNDRAM_CS ;
 
   //board 1
   wire         nRESET = nWDTRESET;
   wire         VBL_INT;
   wire         nRFSH;
   wire         nWAIT;
   wire         nRD,nWR;
   wire         nMREQ;
   reg          n120Hs;
   wire         b256H = ~bn256H;
   wire         n120H = ~( b64H & b32H & b16H & b8H );
   wire         nCPU1_WR,nCPU1_RD;
   wire         nCPU1_IORQ,nCPU1_MREQ;
   wire         nCPU1_M1;
   
   always @(posedge b2H or negedge b256H)
     if (b256H == 0) n120Hs <= 0;
     else n120Hs <= n120H;

   //address decoder,function signals
   //not used in StarForce
   //reg SC6,SC7;
   /*   always @(posedge f3_7)
    begin
    SC6 <= SCRL[6];
    SC7 <= SCRL[7];
     end
    */ 
   
   wire         nSC67 = 1;
   wire         n6b = ~ ( nSC67 | nCS_B8XX | n120Hs );
   wire         n6a = ~ ( BGV1_CNCD | nCS_B0XX | n120Hs );
   wire         n6c = ~ ( BGV2_CNDX | nCS_A8XX | n120Hs );
   wire         p5c = ~ ( nCS_A0XX | n120Hs | BGV3_CNDX);
   wire         p5b = ~ ( nSW | nCS_90XX | n120Hs );
   wire         p6a = n6b | n6a;
   wire         p6c = n6c | p5c;
   wire         p6d = p6a | p6c;
   wire         l4d = p6d | p5b ;

   reg          l4ds,l4dss;

   always @(posedge clk12m or negedge nVBLANK )
     if (nVBLANK == 0) l4ds <= 0;
     else if ( cpuclk ) begin
        l4ds <= l4d;
     end
  
   always @(posedge clk12m)
     if ( cpuclk ) l4dss <= l4ds;
   
   assign nWAIT = ~( l4d | l4dss );
   wire p3c = l4d & l4ds;
   wire nCSEN = nMREQ | p3c;
   assign nMEWR = nWR | nMREQ;
   assign nMERD = nRD | nMREQ;
   
   wire nFLIP_SCR;
   wire	nSCDCMD;
   wire nHitDog;
   wire nPORT_WRITE = nCSD0XX | nMEWR;
   wire nPORT_READ = nCSD0XX | nMERD;
   
   wire nPORT_IN01,nPORT_IN23,nPORT_DSW01;
   wire nSNDCMD;

   wire nCSD0XX = ~( ( CPU0_A[13:11]==3'b010 ) & nRFSH & (CPU0_A[15:14]==2'b11) & ~nCSEN );
   wire nCS_B8XX, nCS_B0XX, nCS_A8XX, nCS_A0XX, nCS_98XX, nCS_90XX, nCS_88XX, nCS_80XX;
   wire nCS_RADAR,nCS_SPRPAL;
   wire nRAM1_CS,nRAM2_CS;
   wire nROM1_CS,nROM2_CS,nROM3_CS,nROM4_CS;
 
   //port read/write decoder
   ls139 R3A 
     (
      .nE ( nPORT_READ ),
      .A0 ( CPU0_A[1] ),
      .A1 ( CPU0_A[2] ),
      .nO0 ( nPORT_IN01 ),
      .nO1 ( nPORT_IN23 ),
      .nO2 ( nPORT_DSW01 ),
      .nO3 ()
      );
   
   ls139 R3B 
     (
      .nE ( nPORT_WRITE ),
      .A0 ( CPU0_A[1] ),
      .A1 ( CPU0_A[2] ),
      .nO0 ( nFLIP_SCR ),
      .nO1 ( nHitDog ),
      .nO2 ( nSNDCMD ),
      .nO3 ()
      
      );

   //flip fetch
   always @(posedge cpuclk )
     if ( ~nPORT_WRITE && ( CPU0_A[2:1] == 1'b00 ) )
       FLIP <= CPU0_DO[0];
   
   //address decoder
   ls138 M5 
     (
      .E3 ( nRFSH ),
      .nE2 ( ~( CPU0_A[15] & ~CPU0_A[14] ) ), //A15:14==10
      .nE1 ( nCSEN ),
      .A0 ( CPU0_A[11] ),
      .A1 ( CPU0_A[12] ),
      .A2 ( CPU0_A[13] ),
      .nO ( { nCS_RADAR, nCS_BGV1, nCS_BGV2, nCS_BGV3, nCS_SPRPAL, nCS_V90, nRAM2_CS, nRAM1_CS } )
      );
   
   ls138 N5 
     (
      .E3 ( 1'b1 ),
      .nE2 ( ~( CPU0_A[15] & ~CPU0_A[14] ) ), //A15:14==10
      .nE1 ( 0 ),
      .A0 ( CPU0_A[11] ),
      .A1 ( CPU0_A[12] ),
      .A2 ( CPU0_A[13] ),
      .nO ( { nCS_B8XX, nCS_B0XX, nCS_A8XX, nCS_A0XX, nCS_98XX, nCS_90XX, nCS_88XX, nCS_80XX } )
      );
   
   ls139 K5B 
     (
      .nE ( nCS_SPRPAL ),
      .A0 ( CPU0_A[9] ),
      .A1 ( CPU0_A[10] ),
      .nO0 ( nCS_SPR ),
      .nO1 ( nADDR9A9BXX ),
      .nO2 ( nCS_PAL ),
      .nO3 ( nCS_BGPOS )
      );

   ls139 L5A 
     (
      .nE ( CPU0_A[15] ),
      .A0 ( CPU0_A[13] ),
      .A1 ( CPU0_A[14] ),
      .nO0 ( nROM1_CS ),
      .nO1 ( nROM2_CS ),
      .nO2 ( nROM3_CS ),
      .nO3 ( nROM4_CS )
      );
   
   wire [7:0] rom23o,rom45o;
   assign rom23o = ( ~nROM1_CS | ~nROM2_CS ) ? rom23 : 8'b0;
   assign rom45o = ( ~nROM3_CS | ~nROM4_CS ) ? rom45 : 8'b0;
      
   wire [7:0] ram0;
   wire [7:0] ramo = ( ~nRAM1_CS | ~nRAM2_CS ) ? ram0 : 8'b0;
   wire [7:0] sndram;
 
   //WDT
   reg [3:0]  wdtcounter;
   wire       nWDTRESET = ~wdtcounter[3] & ~reset ;
   wire       WDC = ~T3C;
   wire       T3C = nHitDog & nPORT_IN23;
   
   always @(negedge nVBLANK or posedge WDC)
     begin
        if (WDC==1 ) wdtcounter <= 4'b0000;
        else wdtcounter <= wdtcounter + 1'b1;
     end
   
   //VBlank int
   reg VBs;
   always @(posedge bn256H )
     VBs <= ~nVBLANK;
   
   assign       VBL_INT = VBs | nVBLANK;

   //DIPSW and controller
   //treat 1P,2P as same

   wire [7:0] CTRL_o01;
   wire [7:0] CTRL_o23;
   wire [7:0] CTRL_dsw;
//   wire	      muteki = 1;

   //JOY = {T2,U1,D1,L1,R1,T1,S1,C1};
   assign CTRL_o01[0] = ctrlr[3]; //R1; //FLIP 0 = 1P in, FLIP 1 = 2P
   assign CTRL_o01[1] = ctrlr[4];   
   assign CTRL_o01[2] = ctrlr[6];
   assign CTRL_o01[3] = ctrlr[5];
   assign CTRL_o01[4] = ctrlr[2];
   assign CTRL_o01[5] = 0;
   assign CTRL_o01[6] = 0;
   assign CTRL_o01[7] = 0;

   reg [9:0]xc;
   always @(negedge nVBLANK) begin
      xc<=xc+1;
      if ( xc > 10'h3f0 ) xc <= 10'h3f0;
   end
   wire button1_on = ( xc > 10'h1e0 ) && ( xc < 10'h1e5 );
   wire button2_on = ( xc > 10'h2e8 ) && ( xc < 10'h2ef );
   
   assign CTRL_o23[0] = CPU0_A[0] ? muteki : ctrlr[0]; //button1_on; 
   assign CTRL_o23[1] = CPU0_A[0] ? 1'b0 : 1'b0;
   assign CTRL_o23[2] = CPU0_A[0] ? 1'b0 : ctrlr[1];//button2_on;//ctrlr[1]; 
   assign CTRL_o23[3] = CPU0_A[0] ? 1'b0 : 1'b0;
   assign CTRL_o23[7:4] = 4'b0000;

   assign CTRL_dsw[0] = CPU0_A[0] ? dipsw[8] : dipsw [0];
   assign CTRL_dsw[1] = CPU0_A[0] ? dipsw[9] : dipsw [1];
   assign CTRL_dsw[2] = CPU0_A[0] ? dipsw[10] : dipsw [2];
   assign CTRL_dsw[3] = CPU0_A[0] ? dipsw[11] : dipsw [3];
   assign CTRL_dsw[4] = CPU0_A[0] ? dipsw[12] : dipsw [4];
   assign CTRL_dsw[5] = CPU0_A[0] ? dipsw[13] : dipsw [5];
   assign CTRL_dsw[6] = CPU0_A[0] ? dipsw[14] : dipsw [6];
   assign CTRL_dsw[7] = CPU0_A[0] ? dipsw[15] : dipsw [7];

   wire [7:0] other_out = (~nPORT_IN01) ? CTRL_o01 :
                          (~nPORT_IN23) ? CTRL_o23 :
                          (~nPORT_DSW01) ? CTRL_dsw : 8'b0;
    


   //SOUND COMMAND latch
   reg [7:0]  sndlatch;
   reg        SndInt;
        
   always @(posedge sndclk or negedge nSNDCMD )
     begin
        if (nSNDCMD == 0)
          begin
             sndlatch <= CPU0_DO;
             SndInt <= 1;
          end
        else
          //CPUACK
          if ( ~nCPU1_M1 && ~nCPU1_IORQ ) SndInt <= 0;
     end

   // ** CTC always sets "0A" if m1,iorq == 00 **
   // tweak..
   reg sndint_delay;
   reg sndint_d2;
   always @(posedge sndclk )
     begin
        sndint_delay <= SndInt;
        sndint_d2<=sndint_delay;
     end
   
   //sound adec
   ls139 K5A 
     (
      .nE ( CPU1_A[15] | nCPU1_MREQ ),
      .A0 ( CPU1_A[13] ),
      .A1 ( CPU1_A[14] ),
      .nO0 ( nSNDROM1_CS ),
      .nO1 ( nSNDROM2_CS ),
      .nO2 ( nSNDRAM_CS ),
      .nO3 ( )
      );

   wire D6_Cp = ( ~nCPU1_WR & ~nCPU1_MREQ ) & CPU1_A[15] ;
   reg [7:0] s76489;
   wire [7:0] e6_nOE;

   wire unsigned [7:0] psg_d8_o;
   wire unsigned [7:0] psg_c8_o;
   wire unsigned [7:0] psg_d7_o;
   
   wire                rdy_d8,rdy_c8,rdy_d7;
   
   //wire unsigned [11:0] smix =  psg_d8_o * 5  +  psg_c8_o * 5 + psg_d7_o * 5  + ( sndprom_din * psgvol / 15) ;//promout;
   assign sout =( psg_d8_o + psg_c8_o + psg_d7_o ) * 8'd170 + (sndprom_din * psgvol * 2 ) ; //( smix * 8'd18 * 2 ) + ( sndrom_din * psgvol );
	
	
	//volume control
	//e6-10,e6-9 -> promout
	//e6-7       -> psg2
	//psg1,3 -> through

	reg [3:0] psgvol;
	always @(posedge clk12m)
	if ( sndclk ) begin
	if ( ~e6_nOE[5] ) psgvol <= CPU1_DO[3:0];
	end
	
	
   always @(posedge clk12m) 
     if ( sndclk ) begin
        if ( D6_Cp == 1 ) begin
           s76489 <= CPU1_DO;
           we_d8 <= ~e6_nOE[1];
           we_c8 <= ~e6_nOE[2];
           we_d7 <= ~e6_nOE[0];
			  
        end
        if ( rdy_d8 && we_d8 ) we_d8 <= 0;
        if ( rdy_c8 && we_c8 ) we_c8 <= 0;
        if ( rdy_d7 && we_d7 ) we_d7 <= 0;
     end

   reg we_d8, we_c8, we_d7; 

   //74689 select
   ls138 E6 
     (
      .E3 ( D6_Cp ),
      .nE2 ( 1'b0 ),
      .nE1 ( 1'b0 ),
      .A0 ( CPU1_A[12] ),
      .A1 ( CPU1_A[13] ),
      .A2 ( CPU1_A[14] ),
      .nO ( e6_nOE )
      );
//1
   sn76489_top psg_d8 
     (
      .clock_i ( sndclk ),
      .clock_en_i (1 ),
      .res_n_i ( nRESET ),
      .ce_n_i ( ~we_d8 & rdy_d8 ),
      .we_n_i ( ~we_d8), 
      .ready_o ( rdy_d8 ),
      .d_i ( s76489 ),
      .aout_o ( psg_d8_o )
      );
   //2
   sn76489_top psg_c8
     (
      .clock_i (sndclk),
      .clock_en_i (1 ),
      .res_n_i ( nRESET ),
      .ce_n_i ( ~we_c8 & rdy_c8 ),
      .we_n_i ( ~we_c8),
      .ready_o ( rdy_c8 ),
      .d_i ( s76489 ),
      .aout_o ( psg_c8_o )

      );
   //3
   sn76489_top psg_d7
     (
      .clock_i (sndclk),
      .clock_en_i (1 ),
      .res_n_i ( nRESET ),
      .ce_n_i ( ~we_d7 & rdy_d7 ),
      .we_n_i ( ~we_d7),
      .ready_o ( rdy_d7 ),
      .d_i ( s76489 ),
      .aout_o ( psg_d7_o )

      );   

   //cpu rom ram
   

   spram12 mainram0
     ( CPU0_A[11:0],~cpuclk,CPU0_DO,~nMEWR & ( ~nRAM1_CS | ~nRAM2_CS ) ,ram0 );
   spram10 sndram0
     ( CPU1_A[9:0], ~sndclk ,CPU1_DO , (~nCPU1_WR & ~nSNDRAM_CS & nCPU1_IORQ) , sndram );
   
   wire nSNDROM1_CS,nSNDROM2_CS;
   wire nSNDRAM_CS;
   wire nSNDROM12_CS = nSNDROM1_CS & nSNDROM2_CS;

   wire [7:0] sndromram = ( ~nSNDROM12_CS & ~nCPU1_RD  ) ? sndrom :
                          ( ~nSNDRAM_CS & ~nCPU1_RD ) ? sndram : 8'b0;
   
     
   wire [7:0] ramrom_out = rom23o | rom45o | ramo;

   wire [7:0] CPU0_DI = ( CPU0_A[15] & nCS_80XX & nCS_88XX & ~nMERD) ? other_out | DCON_in : 
                        ramrom_out ;
   wire [7:0] CPU1_DI = sndromram | CTC_in | sndlatch_in ;
             
   assign DCON_out = (nMERD & CPU0_A[15] & nCS_80XX & nCS_88XX ) ? CPU0_DO : 8'b0 ;
     
   wire [7:0] CTC_in = ( ~nCPU1_IORQ & ~nCPU1_M1 & ~sndint_d2 ) ? CTC_DO : 8'b0; // when sndint_d2 -> CTCin is disabled

   wire [7:0] sndlatch_in = ( ~CPU1_A[3] & ~nCPU1_IORQ &  nCPU1_M1 & ~nCPU1_RD ) ? sndlatch : 8'b0;


   //CTC
   wire       zc_to3,zc_to2,zc_to1,zc_to0;
   wire [7:0] CTC_DO;
   wire       ctc_int;
   reg [3:0]  sndcount;
   reg [7:0]  promout;

        
        always @(posedge zc_to2 ) sndcount <= sndcount + 1;
        
        assign sndprom_aout = sndcount;
        

   ctc z80_ctc 
     (
      .clk (sndclk),            .clk_sys_i (1),
      .res_n (nRESET),          .en ( ~CPU1_A[3] ),
      .dIn ( CPU1_DO ),         .dInCpu ( CPU1_DI ),
      .dOut (CTC_DO),           .cs ( {CPU1_A[1],CPU1_A[0]} ),
      .m1_n ( nCPU1_M1 ),       .iorq_n ( nCPU1_IORQ ),
      .rd_n ( nCPU1_RD ),       .int_n ( ctc_int ),
      .clk_trg ( { 1'b0, 1'b0, zc_to0, 1'b0 } ),
      .zc_to ( { zc_to3, zc_to2, zc_to1, zc_to0 } )
      
      );
   
   
   T80s z80_CPU0
     (
      .RESET_n(nWDTRESET),      .CLK(cpuclk),
      .WAIT_n( nWAIT ),         .INT_n(VBL_INT),
      .NMI_n( 1'b1 ),           .BUSRQ_n( 1'b1 ),
      .DI(CPU0_DI),             .M1_n(),
      .MREQ_n( nMREQ ),         .IORQ_n(),
      .RD_n( nRD ),             .WR_n( nWR ),
      .RFSH_n( nRFSH ),         .HALT_n(),
      .BUSAK_n(),             
      .A( CPU0_A ),             .DO(CPU0_DO)
      );
   

        
   T80s z80_CPU1
     (
      .RESET_n(nWDTRESET),      .CLK(sndclk),
      .WAIT_n(1'b1),            .INT_n(~SndInt & ctc_int ),
      .NMI_n(1'b1),             .BUSRQ_n(1'b1),
      .DI(CPU1_DI),             .M1_n(nCPU1_M1),
      .MREQ_n(nCPU1_MREQ),      .IORQ_n(nCPU1_IORQ),
      .RD_n(nCPU1_RD),          .WR_n(nCPU1_WR),
      .RFSH_n( ),               .HALT_n(),
      .BUSAK_n(),             
      .A(CPU1_A),               .DO(CPU1_DO)
      );

endmodule
    
