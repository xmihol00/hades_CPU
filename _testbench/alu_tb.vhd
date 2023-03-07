---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the ALU
-- autor:    Andreas Engel
-- date:    26.07.07
-- runtime: 4300ns
--
-- tolerated messages:
--   NUMERIC_STD."=": metavalue detected, returning FALSE
--   NUMERIC_STD."/=": metavalue detected, returning TRUE
--
---------------------------------------------------------------------------------------------------


-- Libraries:
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.all;
	use work.hadescomponents.all;

---------------------------------------------------------------------------------------------------


-- Entity:
entity alu_tb is
end entity alu_tb;																							   
---------------------------------------------------------------------------------------------------

-- Architecture:
architecture TB_ARCHITECTURE of alu_tb is
             			 
	-- Stimulie	
	signal clk, reset, regwrite	: std_logic := '1';	
	signal achannel, bchannel   : t_word    := (others => '0');
	signal opcode 	            : t_opcode  := opc_ADD;
	
	-- beobachtete Signale
	signal result               : t_word    := (others => '0');
	signal zero, overflow       : std_logic := '0';
		
begin

	-- Unit Under Test
	UUT: entity alu
		port map (
			CLK 	   => clk,
			RESET 	 => reset,
			ACHANNEL => achannel,
			BCHANNEL => bchannel,
			OPCODE   => opcode,
			REGWRITE => regwrite,
			RESULT   => result,
			ZERO 	   => zero,
			OVERFLOW => overflow
		);
	
	-- CLK Stimulus [50MHz]
	clk <= not clk after 10 ns;
	
	-- Beschaltung der Eingänge und Beobachtung der Ausgänge
	test: process
	
		-- Beobachtungsprozedur
		procedure prove(op,a,b,res: std_logic_vector; ov, z, ro: std_logic := '0') is
			variable oov : std_logic;
		begin
			-- set input
			opcode   <= op;
			achannel <= a;
			bchannel <= b;
			regwrite <= not ro;

			-- remember curent OV-flag
			oov := overflow;

			-- wait one cycle
			wait for 20 ns;
			
			-- check result
			if res'length = 32 then
				assert result = res 
					report "wrong RESULT 0x" & to_hex(result) & "; expected 0x" & to_hex(res)  
					severity error;
			else
				assert result(15 downto 0) = res 
					report "wrong RESULT(15 downto 0) 0x" & to_hex(result(15 downto 0)) & 
			                "; expected 0x" & to_hex(res)  
					severity error;
			end if;
			
			-- check zero-flag
			assert zero = z  
				report "wrong ZERO " & std_logic'image(zero) & "; expected " & std_logic'image(z)
				severity error;
				
			-- ensure that overflow-flag has not changed yet
			assert overflow = oov  
				report "wrong OVERFLOW " & std_logic'image(overflow) & "; expected " & std_logic'image(oov)
				severity error;
				
			-- deassert reg-write
			regwrite <= '0';
			
			-- wait one cycle
			wait for 20 ns;
			
			-- check overflow-flag
			assert overflow = ov  
				report "wrong OVERFLOW " & std_logic'image(overflow) & "; expected " & std_logic'image(ov)
				severity error;
		end;
	
	begin 
	
		achannel <= x"00000000";
		bchannel <= x"00000000";
		wait for 10 ns;
		
-- Shift left, logical ----------------------------------------------------------------------------

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		   
		-- do checks
		prove(opc_SHL, x"30000006",x"00000000", x"30000006",'0'); -- 30ns
		prove(opc_SHL, x"30000006",x"00000001", x"6000000C",'0'); -- 70ns
		prove(opc_SHL, x"30000006",x"00000002", x"C0000018",'0'); -- 110ns
		prove(opc_SHL, x"30000006",x"00000003", x"80000030",'1'); -- 150ns
		prove(opc_SHL, x"30000006",x"00000004", x"00000060",'1'); -- 190ns
		
---- Shift right, logical ---------------------------------------------------------------------------		

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		   
		-- do checks
		prove(opc_SHR, x"30000006",x"00000000", x"30000006",'0'); -- 250ns
		prove(opc_SHR, x"30000006",x"00000001", x"18000003",'0'); -- 290ns
		prove(opc_SHR, x"30000006",x"00000002", x"0C000001",'1'); -- 330ns
		prove(opc_SHR, x"30000006",x"00000000", x"30000006",'0'); -- 370ns
		prove(opc_SHR, x"30000006",x"0000001F", x"00000000",'1'); -- 410ns
			
---- Shift left, cyclic -----------------------------------------------------------------------------	

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove(opc_CSHL, x"30000006",x"00000000", x"30000006"); -- 470ns
		prove(opc_CSHL, x"30000006",x"00000001", x"6000000C"); -- 510ns
		prove(opc_CSHL, x"30000006",x"00000002", x"C0000018"); -- 550ns
		prove(opc_CSHL, x"30000006",x"00000003", x"80000031"); -- 590ns
		prove(opc_CSHL, x"30000006",x"00000004", x"00000063"); -- 630ns
			
---- Shift right, cyclic ----------------------------------------------------------------------------

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		opcode <= opc_CSHR;
		prove(opc_CSHR, x"30000006",x"00000000", x"30000006"); -- 690ns
		prove(opc_CSHR, x"30000006",x"00000001", x"18000003"); -- 730ns
		prove(opc_CSHR, x"30000006",x"00000002", x"8C000001"); -- 770ns
		prove(opc_CSHR, x"30000006",x"00000003", x"C6000000"); -- 810ns
		prove(opc_CSHR, x"30000006",x"00000004", x"63000000"); -- 850ns
	
---- Shift right, logical, OVFF disabled ------------------------------------------------------------

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove(opc_SHR, x"30000006",x"00000000", x"30000006", ro=>'1'); -- 910ns
		prove(opc_SHR, x"30000006",x"00000001", x"18000003", ro=>'1'); -- 950ns
		prove(opc_SHR, x"30000006",x"00000002", x"0C000001", ro=>'1'); -- 990ns
		prove(opc_SHR, x"30000006",x"00000003", x"06000000", ro=>'1'); -- 1030ns
		prove(opc_SHR, x"30000006",x"00000004", x"03000000", ro=>'1'); -- 1070ns
		
---- bitweise logische Verknüpfungen ----------------------------------------------------------------  

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove(opc_AND,  x"000FFFFF",x"FFFFF000", x"000FF000"); -- 1130ns
		prove(opc_OR,   x"000FFFFF",x"FFFFF000", x"FFFFFFFF"); -- 1170ns
		prove(opc_XOR,  x"000FFFFF",x"FFFFF000", x"FFF00FFF"); -- 1210ns
		prove(opc_XNOR, x"000FFFFF",x"FFFFF000", x"000FF000"); -- 1250ns
		prove(opc_AND,  x"0000FFFF",x"FFF0F000", x"0000F000"); -- 1290ns
		prove(opc_OR,   x"0000FFFF",x"FFF0F000", x"FFF0FFFF"); -- 1330ns
		prove(opc_XOR,  x"0000FFFF",x"FFF0F000", x"FFF00FFF"); -- 1370ns
		prove(opc_XNOR, x"0000FFFF",x"FFF0F000", x"000FF000"); -- 1410ns
  
---- Branch -----------------------------------------------------------------------------------------

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove(opc_BNEZ, x"00000000",x"12345678", x"5678",'0','1'); -- 1470ns
		prove(opc_BEQZ, x"00000000",x"12345678", x"5678",'0','1'); -- 1510ns
		prove(opc_BNEZ, x"00000001",x"12345678", x"5678",'0','0'); -- 1550ns
		prove(opc_BEQZ, x"00000001",x"12345678", x"5678",'0','0'); -- 1590ns															

---- PassImmed --------------------------------------------------------------------------------------  

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove(opc_Pass, x"00000000",x"12345678", x"5678"); -- 1650ns
	
---- Arithmetik ohne overflow -----------------------------------------------------------------------    

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks (A1=100, A2=-100, B1=200, B2=-200)
		prove(opc_SUB, x"00000064",x"000000C8", x"FFFFFF9C"); -- A1-B1=-100 	-- 1710ns
		prove(opc_ADD, x"00000064",x"000000C8", x"0000012C"); -- A1+B1= 300  	-- 1750ns
		prove(opc_SUB, x"FFFFFF9C",x"000000C8", x"FFFFFED4"); -- A2-B1=-300 	-- 1790ns
		prove(opc_ADD, x"FFFFFF9C",x"000000C8", x"00000064"); -- A2+B1= 100 	-- 1830ns
		prove(opc_SUB, x"FFFFFF9C",x"FFFFFF38", x"00000064"); -- A2-B2= 100 	-- 1870ns
		prove(opc_ADD, x"FFFFFF9C",x"FFFFFF38", x"FFFFFED4"); -- A2+B2=-300  	-- 1910ns
		
---- Arithmetik mit overflow ------------------------------------------------------------------------    

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove(opc_ADD, x"7FFFFFFF",x"00000064", x"80000063",'1'); -- 1970ns
		prove(opc_SUB, x"7FFFFFFF",x"00000064", x"7FFFFF9B",'0'); -- 2010ns
		prove(opc_ADD, x"80000000",x"00000064", x"80000064",'0'); -- 2050ns
		prove(opc_SUB, x"80000000",x"00000064", x"7FFFFF9C",'1'); -- 2090ns
		
---- Multiplikation ---------------------------------------------------------------------------------  

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove(opc_MUL, x"000003E8",x"000003E8", x"000F4240", '0'); -- 2150ns
		prove(opc_MUL, x"000003E8",x"FFFFFC18", x"FFF0BDC0", '0'); -- 2190ns
		prove(opc_MUL, x"FFFFFC18",x"000003E8", x"FFF0BDC0", '0'); -- 2230ns
		prove(opc_MUL, x"FFFFFC18",x"FFFFFC18", x"000F4240", '0'); -- 2270ns
		
		prove(opc_MUL, x"000186A0",x"000186A0", x"540BE400", '1'); -- 2310ns
		prove(opc_MUL, x"000186A0",x"FFFE7960", x"ABF41C00", '1'); -- 2350ns
		prove(opc_MUL, x"FFFE7960",x"000186A0", x"ABF41C00", '1'); -- 2390ns
		prove(opc_MUL, x"FFFE7960",x"FFFE7960", x"540BE400", '1'); -- 2430ns
		
		prove(opc_MUL, x"3FFFFFFF",x"00000002", x"7FFFFFFE", '0'); -- 2470ns
		prove(opc_MUL, x"40000000",x"00000002", x"80000000", '1'); -- 2510ns
		prove(opc_MUL, x"C0000001",x"00000002", x"80000002", '0'); -- 2550ns
		prove(opc_MUL, x"C0000000",x"00000002", x"80000000", '0'); -- 2590ns
		prove(opc_MUL, x"BFFFFFFF",x"00000002", x"7FFFFFFE", '1'); -- 2630ns
		
---- Overflow-Control -------------------------------------------------------------------------------   

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove(opc_GETOV, x"00000000",x"FFFFFFFF", x"00000000",'0'); -- 2690ns
		prove(opc_SETOV, x"00000000",x"FFFFFFFF", x"00000000",'1'); -- 2730ns
		prove(opc_GETOV, x"00000000",x"FFFFFFFF", x"00000001",'1'); -- 2770ns
		prove(opc_SETOV, x"00000000",x"FFFFFFFE", x"00000000",'0'); -- 2810ns
		prove(opc_GETOV, x"00000000",x"FFFFFFFE", x"00000000",'0'); -- 2850ns
		
---- SetCondition -----------------------------------------------------------------------------------

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks (A1=-200,A2=100,A3=200,B=100)
		prove(opc_SNE, x"FFFFFF38",x"00000064", x"00000001"); -- A1 != B     -- 2910ns
		prove(opc_SEQ, x"FFFFFF38",x"00000064", x"00000000"); -- A1 == B     -- 2950ns
		prove(opc_SGT, x"FFFFFF38",x"00000064", x"00000000"); -- A1 >  B     -- 2990ns
		prove(opc_SGE, x"FFFFFF38",x"00000064", x"00000000"); -- A1 >= B     -- 3030ns
		prove(opc_SLT, x"FFFFFF38",x"00000064", x"00000001"); -- A1 <  B     -- 3070ns
		prove(opc_SLE, x"FFFFFF38",x"00000064", x"00000001"); -- A1 <= B     -- 3110ns
		prove(opc_SNE, x"00000064",x"00000064", x"00000000"); -- A2 != B     -- 3150ns
		prove(opc_SEQ, x"00000064",x"00000064", x"00000001"); -- A2 == B     -- 3190ns
		prove(opc_SGT, x"00000064",x"00000064", x"00000000"); -- A2 >  B     -- 3230ns
		prove(opc_SGE, x"00000064",x"00000064", x"00000001"); -- A2 != B     -- 3270ns
		prove(opc_SLT, x"00000064",x"00000064", x"00000000"); -- A2 <  B     -- 3310ns
		prove(opc_SLE, x"00000064",x"00000064", x"00000001"); -- A2 <= B     -- 3350ns
		prove(opc_SNE, x"000000C8",x"00000064", x"00000001"); -- A3 != B     -- 3390ns
		prove(opc_SEQ, x"000000C8",x"00000064", x"00000000"); -- A3 == B     -- 3430ns
		prove(opc_SGT, x"000000C8",x"00000064", x"00000001"); -- A3 >  B     -- 3470ns
		prove(opc_SGE, x"000000C8",x"00000064", x"00000001"); -- A3 >= B     -- 3510ns
		prove(opc_SLT, x"000000C8",x"00000064", x"00000000"); -- A3 <  B     -- 3550ns
		prove(opc_SLE, x"000000C8",x"00000064", x"00000000"); -- A3 <= B     -- 3590ns
		
---- Software Interrupts -----------------------------------------------------------------------------

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove(opc_GETSWI, x"F0F0F0F0",x"00000000", x"00000000");     -- 3650ns
		prove(opc_GETSWI, x"0F0F0F0F",x"00000001", x"00000000");     -- 3690ns
		prove(opc_SWI,    x"11223344",x"55667788", x"00000000");     -- 3730ns
		prove(opc_GETSWI, x"F0F0F0F0",x"00000000", x"55667788");     -- 3770ns
		prove(opc_GETSWI, x"0F0F0F0F",x"00000001", x"11223344");     -- 3810ns
		prove(opc_GETSWI, x"F0F0F0F0",x"11111110", x"55667788");     -- 3850ns
		prove(opc_GETSWI, x"0F0F0F0F",x"11111111", x"11223344");     -- 3890ns
		
---- Invalid OPCODE ---------------------------------------------------------------------------------  

		-- reset ALU
		reset <= '1', '0' after 2 ns;
		wait for 20 ns;  
		
		-- do checks
		prove("00000", x"F0F0F0F0",x"0F0F0F0F", x"00000000");     -- 3950ns		
		prove("01111", x"F0F0F0F0",x"0F0F0F0F", x"00000000");     -- 3990ns
		prove("10101", x"F0F0F0F0",x"0F0F0F0F", x"00000000");     -- 4030ns
		prove("10110", x"F0F0F0F0",x"0F0F0F0F", x"00000000");     -- 4070ns
		prove("10111", x"F0F0F0F0",x"0F0F0F0F", x"00000000");     -- 4110ns
		prove("11110", x"F0F0F0F0",x"0F0F0F0F", x"00000000");     -- 4150ns
		prove("11111", x"F0F0F0F0",x"0F0F0F0F", x"00000000");     -- 4190ns

		report "!!!TEST DONE !!!"
			severity NOTE;
		wait;										
	end process;

end TB_ARCHITECTURE;  
---------------------------------------------------------------------------------------------------
