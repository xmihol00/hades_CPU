---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the instruction decoder
-- autor:    Andreas Engel
-- date:    27.07.07
-- runtime: 600ns
--
---------------------------------------------------------------------------------------------------

-- Libraries Import:
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.all;
	use work.hadescomponents.all;
  
---------------------------------------------------------------------------------------------------

-- Entity:
entity indec_tb is																							   
end indec_tb;																								   
---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of indec_tb is

	-- Stimulie
	signal iw         : t_word;	
	signal iword      : t_word;
	
	-- beobachtete Signale
	signal inop, outop, loadop, storeop, selxres, dmemop, dpma, epma, ivalid : std_logic;
	signal pccontr : std_logic_vector(10 downto 0); 
	signal aopadr, bopadr, wopadr : t_haregsAdr;
	signal aopadr_slv, bopadr_slv, wopadr_slv : std_logic_vector(t_haregsAdr'range);
	signal opc : t_opcode;
	signal iop : t_short;
		
	-- Beobachtungsprozedur
	procedure prove ( 
		bnez_x, beqz_x, bov_x, sisa_x, dei_x, eni_x, reti_x, jreg_x, jal_x, swi_x, rela_x,
		inop_x, outop_x, loadop_x, storeop_x, selxres_x, dmemop_x, dpma_x, epma_x, ivalid_x : std_logic := '0';
		aopadr_x, bopadr_x, wopadr_x : t_haregsAdr := (others => '0');
		iop_x                        : t_short     := (others => '0');
		opc_x                        : t_opcode    := (others => '0');
		pre_wait                     : time        := 10 ns
	) is 
    
		procedure assert_bit(ist, soll: std_logic; name: string) is
		begin
			assert ist = soll 
				report   "wrong " & name & "; expected " & std_logic'image(soll) 
				severity error;
		end procedure;
		
		procedure assert_bin(ist, soll: std_logic_vector; name: string) is
		begin
			assert ist = soll 
				report   "wrong " & name & " b" & to_bin(ist) & "; expected b" & to_bin(soll)
				severity error;
		end procedure;
	
	begin
  	 
		wait for pre_wait;
	  
		assert_bit(pccontr(0), bnez_x, "BNEZ");
		assert_bit(pccontr(1), beqz_x, "BEQZ");
		assert_bit(pccontr(2), bov_x,  "BOV");
		assert_bit(pccontr(3), sisa_x, "SISA");
		assert_bit(pccontr(4), dei_x,  "DEI");
		assert_bit(pccontr(5), eni_x,  "ENI");
		assert_bit(pccontr(6), reti_x, "RETI");
		assert_bit(pccontr(7), jreg_x,  "JREG");
		assert_bit(pccontr(8), jal_x,  "JAL");
		assert_bit(pccontr(9), swi_x,  "SWI");
		assert_bit(pccontr(10),rela_x,  "RELA");
		
		assert_bit(inop,    inop_x,    "INOP");
		assert_bit(outop,   outop_x,   "OUTOP");
		assert_bit(loadop,  loadop_x,  "LOADOP");
		assert_bit(storeop, storeop_x, "STOREOP");
		assert_bit(dmemop,  dmemop_x,  "DMEMOP");
		assert_bit(selxres, selxres_x, "SELXRES");
		assert_bit(dpma,    dpma_x,    "DPMA");
		assert_bit(epma,    epma_x,    "EPMA");
		assert_bit(ivalid,  ivalid_x,  "IVALID");
		
		assert_bin(std_logic_vector(wopadr), std_logic_vector(wopadr_x), "WOPADR");		
		assert_bin(opc,     opc_x,     "OPC");
		
		if (aopadr_x(0) /= '-') then assert_bin(std_logic_vector(aopadr), std_logic_vector(aopadr_x), "AOPADR"); end if;     
		if (bopadr_x(0) /= '-') then assert_bin(std_logic_vector(bopadr), std_logic_vector(bopadr_x), "BOPADR"); end if;    	
		if (iop_x(0) /= '-') then 
		   assert iop = iop_x
				report "wrong IOP 0x" & to_hex(iop) & "; expected 0x" & to_hex(iop_x)
				severity error; 
    end if;			
				
	end procedure;
  	
begin

	-- Unit Under Test
	UUT: entity indec
		port map (
			IWORD   => iword,
			PCCONTR => pccontr,
			INOP    => inop,
			OUTOP   => outop,
			LOADOP  => loadop,
			STOREOP => storeop,
			SELXRES => selxres,
			DMEMOP  => dmemop,
			DPMA    => dpma,
			EPMA    => epma,
			OPC     => opc,
			IOP     => iop,
			IVALID  => ivalid,
			AOPADR  => aopadr_slv,
			BOPADR  => bopadr_slv,
			WOPADR  => wopadr_slv
		);
	
	-- do type conversions
	aopadr <= unsigned(aopadr_slv);
	bopadr <= unsigned(bopadr_slv);
	wopadr <= unsigned(wopadr_slv);
	
	-- Beschaltung der Eingänge und Beobachtung der Ausgänge
	test: process
	begin
    
--   10ns: IVALID ---------------------------------------------------------------------------------
    iw <= b"0000_00000_000_000_1_0000000000000000";
    prove(
      ivalid_x => '1'
    );    

--   20ns: SHL 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_00100_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_SHL
	);

--  30ns: SHLI 7, 5, #12 --------------------------------------------------------------------------
	iw <= b"0000_00100_111_101_1_0000000000001100";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "0000000000001100",  
		ivalid_x => '1',
		opc_x    => opc_SHL
	);

--  40ns: SHR 7, 5, 6------------------------------------------------------------------------------
	iw <= b"0000_00101_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_SHR
	);

--  50ns: SHRI 7, 5, #3 --------------------------------------------------------------------------
	iw <= b"0000_00101_111_101_1_0000000000000011";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "0000000000000011", 
		ivalid_x => '1',
		opc_x    => opc_SHR
	);

--  60ns: CSHL 7, 5, 6 ---------------------------------------------------------------------------
    iw <= b"0000_00110_111_101_0_1101101101101101";
    prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_CSHL
    );

--  70ns: CSHLI 7, 5, #12 ------------------------------------------------------------------------
	iw <= b"0000_00110_111_101_1_0000000000001100";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "0000000000001100",
		ivalid_x => '1',
		opc_x    => opc_CSHL
	);

--  80ns: CSHR 7, 5, 6 ---------------------------------------------------------------------------
	iw <= b"0000_00111_111_101_0_1101101101101101";
	prove(    
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_CSHR
	);

--  90ns: CSHRI 7, 5, #3 -------------------------------------------------------------------------
	iw <= b"0000_00111_111_101_1_0000000000000011";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "0000000000000011",
		ivalid_x => '1',
		opc_x    => opc_CSHR
	);

--  100ns: AND 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_01000_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_AND
	);

--  110ns: ANDI 7, 5, #DB6Dh ----------------------------------------------------------------------
	iw <= b"0000_01000_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "1101101101101101", 
		ivalid_x => '1',
		opc_x    => opc_AND    
	);

--  120ns: OR 7, 5, 6 -----------------------------------------------------------------------------
	iw <= b"0000_01001_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_OR
	);

--  130ns: ORI 7, 5, #DB6Dh -----------------------------------------------------------------------
    iw <= b"0000_01001_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_OR
	);

--  140ns: XOR 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_01010_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_XOR
	);

--  150ns: XORI 7, 5, #DB6Dh ----------------------------------------------------------------------
	iw <= b"0000_01010_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "1101101101101101",	
		ivalid_x => '1',
		opc_x    => opc_XOR
	);

--  160ns: XNOR 7, 5, 6 ---------------------------------------------------------------------------
	iw <= b"0000_01011_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_XNOR
	);

--  170ns: XNORI 7, 5, #DB6Dh ---------------------------------------------------------------------
	iw <= b"0000_01011_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "1101101101101101", 
		ivalid_x => '1',
		opc_x    => opc_XNOR
	);
    
--  180ns: SUB 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_10000_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_SUB
	);

--  190ns: SUBI 7, 5, #-9363 ----------------------------------------------------------------------
	iw <= b"0000_10000_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_SUB
	);

--  200ns: ADD 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_10001_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_ADD
	);

--  210ns: ADDI 7, 5, #-9363 ----------------------------------------------------------------------
	iw <= b"0000_10001_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_ADD
	);
	
-- 220ns: MUL 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_10100_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110", 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_MUL
	);

--  230ns: MULI 7, 5, #-9363 ----------------------------------------------------------------------
	iw <= b"0000_10100_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_MUL
	);
	
--  240ns: SETOV 6 --------------------------------------------------------------------------------
	iw <= b"0000_10010_000_101_0_1101101101101101";
	prove(
		aopadr_x => (others => '-'),
		bopadr_x => "110",
		iop_x    => (others => '-'),
		opc_x    => opc_SETOV
	);

--  250ns: SETOVI #1 ------------------------------------------------------------------------------
	iw <= b"0000_10010_000_101_1_0000000000000001";
	prove(
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'), 
		iop_x    => "0000000000000001",
		ivalid_x => '1',
		opc_x    => opc_SETOV
	);

--  260ns: GETOV 7 --------------------------------------------------------------------------------
	iw <= b"0000_10011_111_101_0_1101101101101101";
	prove(
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_GETOV
	);
    
--  270ns: SNE 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_11000_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110",
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_SNE
	);

--  280ns: SNEI 7, 5, #DB6Dh ----------------------------------------------------------------------
	iw <= b"0000_11000_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'),
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_SNE
	);

--  290ns: SEQ 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_11001_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110",
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_SEQ
	);

--  300ns: SEQI 7, 5, #DB6Dh ----------------------------------------------------------------------
	iw <= b"0000_11001_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'),
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_SEQ
	);

--  310ns: SGT 7, 5, 6 ----------------------------------------------------------------------------
    iw <= b"0000_11010_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110",
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_SGT
	);

--  320ns: SGTI 7, 5, #DB6Dh ----------------------------------------------------------------------
    iw <= b"0000_11010_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'),
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_SGT
	);

--  330ns: SGE 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_11011_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110",
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_SGE
	);

--  340ns: SGEI 7, 5, #DB6Dh ----------------------------------------------------------------------
    iw <= b"0000_11011_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'),
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_SGE
	);

--  350ns: SLT 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_11100_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110",
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_SLT
	);

--  360ns: SLTI 7, 5, #DB6Dh ----------------------------------------------------------------------
	iw <= b"0000_11100_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'),
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_SLT
	);

--  370ns: SLE 7, 5, 6 ----------------------------------------------------------------------------
	iw <= b"0000_11101_111_101_0_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => "110",
		wopadr_x => "111",
		iop_x    => (others => '-'),
		opc_x    => opc_SLE
	);

--  380ns: SLEI 7, 5, #DB6Dh ----------------------------------------------------------------------
	iw <= b"0000_11101_111_101_1_1101101101101101";
	prove(
		aopadr_x => "101",
		bopadr_x => (others => '-'),
		wopadr_x => "111",
		iop_x    => "1101101101101101",
		ivalid_x => '1',
		opc_x    => opc_SLE
	);    

--  390ns: BNEZ 5, #03FFh -------------------------------------------------------------------------
	iw <= b"0101_01100_000_101_1_0000001111111111";
	prove(
		bnez_x   => '1',
		rela_x   => '1',
		aopadr_x => "101",
		bopadr_x => (others => '-'),  
		iop_x    => "0000001111111111",			  
		ivalid_x => '1',
		opc_x    => opc_BNEZ
	);

--  400ns: BEQZ 5, #03FFh -------------------------------------------------------------------------
	iw <= b"0110_01101_000_101_1_0000001111111111";
	prove(
		beqz_x   => '1',
		aopadr_x => "101",
		rela_x   => '1',
		bopadr_x => (others => '-'),
		iop_x    => "0000001111111111",  
		ivalid_x => '1',
		opc_x    => opc_BEQZ
	);

--  410ns: BOV #03FFh -----------------------------------------------------------------------------
	iw <= b"0111_01110_000_000_1_0000001111111111";
	prove(
		bov_x    => '1',
		rela_x   => '1',
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		iop_x    => "0000001111111111",   
		ivalid_x => '1',
		opc_x    => opc_Pass
	);
    
--  420ns: SISA #2, #512 --------------------------------------------------------------------------
	iw <= b"1101_01110_000_000_1_0000101000000000";
	prove(
		sisa_x   => '1',
		rela_x   => '1',
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		iop_x    => "0000101000000000", 
		ivalid_x => '1',
		opc_x    => opc_Pass
	);
    
--  430ns: DEI ------------------------------------------------------------------------------------
	iw <= b"0100_00000_000_000_0_0000000000000000";
	prove(
		dei_x   => '1',
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		iop_x    => (others => '-'),
		opc_x    => opc_NOP
	);     
    
--  440ns: ENI  -----------------------------------------------------------------------------------
	iw <= b"0001_00000_000_000_0_0000000000000000";
	prove(
		eni_x    => '1',
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		iop_x    => (others => '-'),
		opc_x    => opc_NOP
	);   
    
--  450ns: RETI -----------------------------------------------------------------------------------
	iw <= b"1100_00000_000_000_0_0000000000000000";
	prove(
		reti_x   => '1',
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		iop_x    => (others => '-'),
		opc_x    => opc_NOP
	);       
				
--  460ns: JREG 5 ---------------------------------------------------------------------------------
	iw <= b"1011_00110_000_101_0_0000000000000000";
	prove(
		jreg_x    => '1',
		aopadr_x => "101",
		iop_x    => (others => '-'),
		opc_x    => opc_CSHL
	);    

--  470ns: JAL 7, #03FFh --------------------------------------------------------------------------
	iw <= b"1010_01110_111_000_1_0000001111111111";
	prove(
		jal_x    => '1',
		rela_x   => '1',
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		wopadr_x => "111",
		iop_x    => "0000001111111111", 
		ivalid_x => '1',
		opc_x    => opc_Pass
	); 

--  480ns: IN 7, #DB6Dh ---------------------------------------------------------------------------
	iw <= b"0010_01110_111_000_1_1101101101101101";
	prove(
		inop_x   => '1',
		selxres_x=> '1',
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		wopadr_x => "111",
		iop_x    => "1101101101101101",  
		ivalid_x => '1',
		opc_x    => opc_Pass
	);

--  490ns: OUT 6, #DB6Dh --------------------------------------------------------------------------
	iw <= b"0011_01110_110_000_1_1101101101101101";
	prove(
		outop_x  => '1',
		selxres_x=> '1',
		aopadr_x => (others => '-'),
		bopadr_x => "110",
		iop_x    => "1101101101101101", 
		ivalid_x => '1',
		opc_x    => opc_Pass
	);

-- 500ns: LOAD 7, 5, #5 --------------------------------------------------------------------------
	iw <= b"1000_10001_111_101_1_0000000000000101";
	prove(
		loadop_x => '1',
		dmemop_x => '1',
		selxres_x=> '1',
		aopadr_x => "101",
		bopadr_x => (others => '-'), 
		wopadr_x => "111",
		iop_x    => "0000000000000101",
		ivalid_x => '1',
		opc_x    => opc_ADD
	);

-- 510ns: STORE 5, 6, #7 -------------------------------------------------------------------------
	iw <= b"1001_10001_110_101_1_0000000000000111";
	prove(
		storeop_x=> '1',
		dmemop_x => '1',
		selxres_x=> '1',
		aopadr_x => "101",
		bopadr_x => "110", 
		iop_x    => "0000000000000111", 
		ivalid_x => '1',
		opc_x    => opc_ADD
	);

-- 520ns: DPMA -----------------------------------------------------------------------------------
	iw <= b"1110_00000_000_000_0_0000000000000000";
	prove(
		dpma_x   => '1',
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		iop_x    => (others => '-'),
		opc_x    => opc_NOP
	);

-- 530ns: EPMA -----------------------------------------------------------------------------------
	iw <= b"1111_00000_000_000_0_0000000000000000";
	prove(
		epma_x   => '1',
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		iop_x    => (others => '-'),
		opc_x    => opc_NOP
	);
	
-- 540ns: SWI #0x1234, 6 -------------------------------------------------------------------------
	iw <= b"0000_00010_000_110_1_0001001000110100";
	prove(
		swi_x    => '1',
		aopadr_x => "110",
		bopadr_x => (others => '-'),
		iop_x    => x"1234",
		ivalid_x => '1',
		opc_x    => opc_SWI
	);
	
-- 550ns: GETSWI 5, 1 ----------------------------------------------------------------------------
	iw <= b"0000_00011_101_000_1_0000000000000001";
	prove(
		aopadr_x => (others => '-'),
		bopadr_x => (others => '-'),
		wopadr_x => "101",
		iop_x    => x"0001",
		ivalid_x => '1',
		opc_x    => opc_GETSWI
	);
    
	report "!!!TEST DONE !!!"
		severity NOTE;
	
    wait;
	end process;
	
	-- Instruktion konvertieren (integer => std_logic_vector)
	iword <= iw;

end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
