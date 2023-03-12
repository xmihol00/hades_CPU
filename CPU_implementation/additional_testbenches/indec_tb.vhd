---------------------------------------------------------------------------------------------------
--
-- titel:   Additional test bench for the indec component
-- autor:   David Mihola (12211951)
-- date:    12. 03. 2023
-- runtime: 300ns
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.all;
	use work.hadescomponents.all;
  
entity indec_tb is																							   
end indec_tb;																								   

architecture tb_architecture of indec_tb is
	-- stimulus
	signal iword      : std_logic_vector(31 downto 0) := (others => '0');
	
	-- tested signals
	signal inop       : std_logic; 
	signal outop      : std_logic;
	signal loadop     : std_logic;
	signal storeop    : std_logic;
	signal selxres    : std_logic;
	signal dmemop     : std_logic;
	signal dpma       : std_logic;
	signal epma       : std_logic;
	signal ivalid     : std_logic;
	signal pccontr    : std_logic_vector(10 downto 0); 
	signal aopadr     : std_logic_vector(2 downto 0);
	signal bopadr 	  : std_logic_vector(2 downto 0);
	signal wopadr 	  : std_logic_vector(2 downto 0);
	signal opc        : std_logic_vector(4 downto 0);
	signal iop        : std_logic_vector(15 downto 0);
		
	-- observation
	procedure prove ( 
		bnez_x, beqz_x, bov_x, sisa_x, dei_x, eni_x, reti_x, jreg_x, jal_x, swi_x, rela_x,
		inop_x, outop_x, loadop_x, storeop_x, selxres_x, dmemop_x, dpma_x, epma_x, ivalid_x : std_logic := '0';
		aopadr_x, bopadr_x, wopadr_x : std_logic_vector(2 downto 0)  := (others => '0');
		iop_x                        : std_logic_vector(15 downto 0) := (others => '0');
		opc_x                        : std_logic_vector(4 downto 0)  := (others => '0');
		pre_wait                     : time        					 := 10 ns
	) is     
		procedure assert_bit(current, expected: std_logic; name: string) is
		begin
			assert current = expected 
				report   "wrong " & name & "; expected " & std_logic'image(expected) 
				severity error;
		end procedure;
		
		procedure assert_bin(current, expected: std_logic_vector; name: string) is
		begin
			assert current = expected 
				report   "wrong " & name & " b" & to_bin(current) & "; expected b" & to_bin(expected)
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
		assert_bit(pccontr(7), jreg_x, "JREG");
		assert_bit(pccontr(8), jal_x,  "JAL");
		assert_bit(pccontr(9), swi_x,  "SWI");
		assert_bit(pccontr(10),rela_x, "RELA");
		
		assert_bit(inop,    inop_x,    "INOP");
		assert_bit(outop,   outop_x,   "OUTOP");
		assert_bit(loadop,  loadop_x,  "LOADOP");
		assert_bit(storeop, storeop_x, "STOREOP");
		assert_bit(dmemop,  dmemop_x,  "DMEMOP");
		assert_bit(selxres, selxres_x, "SELXRES");
		assert_bit(dpma,    dpma_x,    "DPMA");
		assert_bit(epma,    epma_x,    "EPMA");
		assert_bit(ivalid,  ivalid_x,  "IVALID");
		
		assert_bin(wopadr,  wopadr_x,  "WREG");
		assert_bin(opc,     opc_x,     "AOPC");
		
		if (aopadr_x(0) /= '-') then 
			assert_bin(aopadr, aopadr_x, "AREG");
		end if;     
		if (bopadr_x(0) /= '-') then 
			assert_bin(bopadr, bopadr_x, "BREG"); 
		end if;    	
		if (iop_x(0) /= '-') then 
		   assert iop = iop_x
				report "wrong IOP 0x" & to_hex(iop) & "; expected 0x" & to_hex(iop_x)
				severity error; 
    	end if;					
	end procedure;

	-- constants
	-- instruction opcodes
	constant ALU_iopc    : std_logic_vector(3 downto 0) := "0000";
	constant ALUI_iopc   : std_logic_vector(3 downto 0) := "0000";
	constant NOP_iopc    : std_logic_vector(3 downto 0) := "0000";
	constant SWI_iopc    : std_logic_vector(3 downto 0) := "0000";
	constant GETSWI_iopc : std_logic_vector(3 downto 0) := "0000";
	constant IN_iopc     : std_logic_vector(3 downto 0) := "0010";
	constant OUT_iopc    : std_logic_vector(3 downto 0) := "0011";
	constant ENI_iopc    : std_logic_vector(3 downto 0) := "0001";
	constant DEI_iopc    : std_logic_vector(3 downto 0) := "0100";
	constant BNEZ_iopc   : std_logic_vector(3 downto 0) := "0101";
	constant BEQZ_iopc   : std_logic_vector(3 downto 0) := "0110";
	constant BOV_iopc    : std_logic_vector(3 downto 0) := "0111";
	constant LOAD_iopc   : std_logic_vector(3 downto 0) := "1000";
	constant STORE_iopc  : std_logic_vector(3 downto 0) := "1001";
	constant JAL_iopc    : std_logic_vector(3 downto 0) := "1010";
	constant JREG_iopc   : std_logic_vector(3 downto 0) := "1011";
	constant RETI_iopc   : std_logic_vector(3 downto 0) := "1100";
	constant SISA_iopc   : std_logic_vector(3 downto 0) := "1101";
	constant DPMA_iopc   : std_logic_vector(3 downto 0) := "1110";
	constant EPMA_iopc   : std_logic_vector(3 downto 0) := "1111";

	-- ALU opcodes
	constant NOP_aopc    : std_logic_vector(4 downto 0) := "00000";
	constant SWI_aopc    : std_logic_vector(4 downto 0) := "00010";
	constant GETSWI_aopc : std_logic_vector(4 downto 0) := "00011";
	constant SHL_aopc    : std_logic_vector(4 downto 0) := "00100";
	constant SHR_aopc    : std_logic_vector(4 downto 0) := "00101";
	constant CSHL_aopc   : std_logic_vector(4 downto 0) := "00110";
	constant CSHR_aopc   : std_logic_vector(4 downto 0) := "00111";
	constant AND_aopc    : std_logic_vector(4 downto 0) := "01000";
	constant OR_aopc     : std_logic_vector(4 downto 0) := "01001";
	constant XOR_aopc    : std_logic_vector(4 downto 0) := "01010";
	constant XNOR_aopc   : std_logic_vector(4 downto 0) := "01011";
	constant BNEZ_aopc   : std_logic_vector(4 downto 0) := "01100";
	constant BEQZ_aopc   : std_logic_vector(4 downto 0) := "01101";
	constant PASS_aopc   : std_logic_vector(4 downto 0) := "01110";
	constant SUB_aopc    : std_logic_vector(4 downto 0) := "10000";
	constant ADD_aopc    : std_logic_vector(4 downto 0) := "10001";
	constant SETOV_aopc  : std_logic_vector(4 downto 0) := "10010";
	constant GETOV_aopc  : std_logic_vector(4 downto 0) := "10011";
	constant MUL_aopc    : std_logic_vector(4 downto 0) := "10100";
	constant SNE_aopc    : std_logic_vector(4 downto 0) := "11000";
	constant SEQ_aopc    : std_logic_vector(4 downto 0) := "11001";
	constant SGT_aopc    : std_logic_vector(4 downto 0) := "11010";
	constant SGE_aopc    : std_logic_vector(4 downto 0) := "11011";
	constant SLT_aopc    : std_logic_vector(4 downto 0) := "11100";
	constant SLE_aopc    : std_logic_vector(4 downto 0) := "11101";
	constant IN_aopc     : std_logic_vector(4 downto 0) := "01110";
	constant OUT_aopc    : std_logic_vector(4 downto 0) := "01110";
	constant ENI_aopc    : std_logic_vector(4 downto 0) := "00000";
	constant DEI_aopc    : std_logic_vector(4 downto 0) := "00000";
	constant BOV_aopc    : std_logic_vector(4 downto 0) := "01110";
	constant LOAD_aopc   : std_logic_vector(4 downto 0) := "10001";
	constant STORE_aopc  : std_logic_vector(4 downto 0) := "10001";
	constant JAL_aopc    : std_logic_vector(4 downto 0) := "01110";
	constant JREG_aopc   : std_logic_vector(4 downto 0) := "00110";
	constant RETI_aopc   : std_logic_vector(4 downto 0) := "00000";
	constant SISA_aopc   : std_logic_vector(4 downto 0) := "01110";
	constant DPMA_aopc   : std_logic_vector(4 downto 0) := "00000";
	constant EPMA_aopc   : std_logic_vector(4 downto 0) := "00000";
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
			AOPADR  => aopadr,
			BOPADR  => bopadr,
			WOPADR  => wopadr
		);
	
	test: process is
		-- variables to construct and test insturictions
		variable iopc        : std_logic_vector(3 downto 0);
		variable aopc        : std_logic_vector(4 downto 0);
		variable wreg        : std_logic_vector(2 downto 0);
		variable areg        : std_logic_vector(2 downto 0);
		variable breg        : std_logic_vector(2 downto 0);
		variable imop        : std_logic_vector(15 downto 0);
		variable imop_short  : std_logic_vector(12 downto 0);
		variable valid       : std_logic;
	begin
		
		iopc := NOP_iopc; aopc := NOP_aopc; wreg := "000"; areg := "000"; valid := '1'; imop := (others => '0'); imop_short := (others => '0');
    	iword <= iopc & aopc & wreg & areg & valid & imop;
    	prove(
    	  ivalid_x => valid
    	);  -- 10 ns

		areg := "001"; wreg := "010"; breg := "100"; valid := '0';
		imop := breg & imop_short;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  aopadr_x => areg,
		  bopadr_x => breg,
		  wopadr_x => wreg,
		  iop_x    => imop
    	);  -- 20 ns

		iopc := OUT_iopc; areg := "101"; wreg := "110"; breg := "011";
		imop := breg & imop_short;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  outop_x  => '1',
		  selxres_x => '1',
		  aopadr_x => areg,
		  bopadr_x => wreg,
		  wopadr_x => "000",
		  iop_x    => imop
    	);  -- 30 ns
    	
		iopc := STORE_iopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  storeop_x => '1',
		  dmemop_x  => '1',
		  selxres_x => '1',
		  aopadr_x  => areg,
		  bopadr_x  => wreg,
		  wopadr_x  => "000",
		  iop_x     => imop
    	); -- 40 ns

		iopc := ALU_iopc; aopc := NOP_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 50 ns

		iopc := ALUI_iopc; aopc := ADD_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 60 ns

		iopc := SWI_iopc; aopc := SWI_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  swi_x   => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 70 ns

		iopc := GETSWI_iopc; aopc := GETSWI_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 80 ns

		iopc := IN_iopc; aopc := IN_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  inop_x    => '1',
		  selxres_x => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 90 ns

		iopc := OUT_iopc; aopc := OUT_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  outop_x   => '1',
		  selxres_x => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => wreg,
		  wopadr_x  => "000",
		  iop_x     => imop
    	); -- 100 ns

		iopc := ENI_iopc; aopc := ENI_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  eni_x     => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 110 ns

		iopc := DEI_iopc; aopc := DEI_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  dei_x     => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 120 ns

		iopc := BNEZ_iopc; aopc := BNEZ_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  bnez_x    => '1',
		  rela_x    => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 130 ns

		iopc := BEQZ_iopc; aopc := BEQZ_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  beqz_x    => '1',
		  rela_x    => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 140 ns

		iopc := BOV_iopc; aopc := BOV_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  bov_x     => '1',
		  rela_x    => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 150 ns

		iopc := LOAD_iopc; aopc := LOAD_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  loadop_x  => '1',
		  dmemop_x  => '1',
		  selxres_x => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 160 ns

		iopc := STORE_iopc; aopc := STORE_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  storeop_x => '1',
		  dmemop_x  => '1',
		  selxres_x => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => wreg,
		  wopadr_x  => "000",
		  iop_x     => imop
    	); -- 170 ns

		iopc := JAL_iopc; aopc := JAL_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  jal_x     => '1',
		  rela_x    => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 180 ns

		iopc := JREG_iopc; aopc := JREG_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  jreg_x     => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 190 ns

		iopc := RETI_iopc; aopc := RETI_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  reti_x     => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 200 ns

		iopc := SISA_iopc; aopc := SISA_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  sisa_x    => '1',
		  rela_x    => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 210 ns

		iopc := DPMA_iopc; aopc := DPMA_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  dpma_x    => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 220 ns

		iopc := EPMA_iopc; aopc := EPMA_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  epma_x  => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 230 ns

		iopc := ALU_iopc; aopc := AND_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 240 ns

		iopc := ALU_iopc; aopc := CSHL_aopc;
		iword <= iopc & aopc & wreg & areg & valid & breg & imop_short;
		prove(
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => breg,
		  wopadr_x  => wreg,
		  iop_x     => imop
    	); -- 250 ns

		iopc := ALUI_iopc; aopc := OR_aopc; valid := '1'; imop := "1110001111000011";
		iword <= iopc & aopc & wreg & areg & valid & imop;
		prove(
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => "111",
		  wopadr_x  => wreg,
		  iop_x     => imop,
		  ivalid_x  => valid
		); -- 260 ns

		iopc := SWI_iopc; aopc := OR_aopc; areg := "000"; imop := "1110000000000011";
		iword <= iopc & aopc & wreg & areg & valid & imop;
		prove(
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => "111",
		  wopadr_x  => wreg,
		  iop_x     => imop,
		  ivalid_x  => valid
		); -- 270 ns

		iopc := BEQZ_iopc; aopc := BEQZ_aopc;
		iword <= iopc & aopc & wreg & areg & valid & imop;
		prove(
		  beqz_x    => '1',
		  rela_x    => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => "111",
		  wopadr_x  => wreg,
		  iop_x     => imop,
		  ivalid_x  => valid
		); -- 280 ns

		iopc := LOAD_iopc; aopc := LOAD_aopc;
		iword <= iopc & aopc & wreg & areg & valid & imop;
		prove(
		  loadop_x  => '1',
		  dmemop_x  => '1',
		  selxres_x => '1',
		  opc_x     => aopc,
		  aopadr_x  => areg,
		  bopadr_x  => "111",
		  wopadr_x  => wreg,
		  iop_x     => imop,
		  ivalid_x  => valid
		); -- 290 ns
		
		report "Test completed."
			severity NOTE;
		
    	wait;
	end process;
end tb_architecture;
