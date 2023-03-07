---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the DATAPATH
-- autor:    Andreas Engel
-- date:    27.07.07
-- runtime: 600ns
--
-- toleriated error messages:
--   NUMERIC_STD."<": metavalue detected, returning FALSE
--   NUMERIC_STD."=": metavalue detected, returning FALSE
--   NUMERIC_STD."/=": metavalue detected, returning TRUE 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result wilL be 'X'(es).
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
entity datapath_tb is
end datapath_tb;
---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of datapath_tb is
	
	-- Stimulie	
	signal clk, jal, selxres         : std_logic     := '0';
	signal rela, ivalid              : std_logic     := '0';
	signal reset, regwrite           : std_logic     := '1';
	signal aop, bop, xdatain         : t_word        := x"00000000";
	signal iop                       : t_short       := x"0000";
	signal opc                       : t_opcode      := opc_ADD;
	signal pcinc                     : t_pmemoryAdr  := "000000000000";
		
	-- beobachtete Signale
	signal xdataout, wop             : t_word        := (others => '0');
	signal ov, zero                  : std_logic     := '0';
	signal xadr                      : unsigned(12 downto 0) := (others => '0');	
	signal pcnew                     : unsigned(11 downto 0) := (others => '0');
	signal sisalvl                   : unsigned(1 downto 0) := (others => '0');
	signal xadr_slv                  : std_logic_vector(12 downto 0) := (others => '0');	
	signal pcnew_slv                 : std_logic_vector(11 downto 0) := (others => '0');
	signal sisalvl_slv               : std_logic_vector(1 downto 0) := (others => '0');
  
begin

	-- Unit Under Test
	UUT: entity datapath
		port map (
			CLK      => clk,
			RESET    => reset,
			AOP      => aop,
			BOP      => bop,
			IOP      => iop,
			OPC      => opc,
			JAL      => jal,
			RELA     => rela,
			REGWRITE => regwrite,
			SELXRES  => selxres,
			XDATAIN  => xdatain,
			PCINC    => std_logic_vector(pcinc),
			IVALID   => ivalid,
			XDATAOUT => xdataout,
			XADR     => xadr_slv,
			OV       => ov,
			ZERO     => zero,
			WOP      => wop,
			PCNEW    => pcnew_slv,
			SISALVL  => sisalvl_slv
		);

	-- do type conversions
	xadr    <= unsigned(xadr_slv);
	pcnew   <= unsigned(pcnew_slv);
	sisalvl <= unsigned(sisalvl_slv);
	
	-- CLK Stimulus [50MHz]
	clk <= not clk after 10 ns;  
	
	-- RESET Stimulus
	reset <= '0' after 5 ns;
	
	-- Beschaltung der Eingänge und Beobachtung der Ausgänge
	test: process
	
		-- Beobachtungsprozedur
		procedure prove(d: std_logic_vector) is
		begin
		  case d'length is 
			  when  1 => assert ov = d(0) 
			             report "wrong OV " & std_logic'image(ov) & "; expected " & std_logic'image(d(0))  
			             severity error;      
			  when 12 => assert pcnew = unsigned(d)
			             report "wrong PCNEW 0x" & to_hex(pcnew) & "; expected 0x" & to_hex(d)  
			             severity error;
			  when 13 => assert xadr = unsigned(d)
			             report "wrong XADR 0x" & to_hex(xadr) & "; expected 0x" & to_hex(d)  
			             severity error;
			  when 32 => assert wop = d 
			             report "wrong WOP 0x" & to_hex(wop) & "; expected 0x" & to_hex(d)  
			             severity error;
			  when others => report "wrong operand length, expected 1, 12, 19 or 32 bit"
			                severity error;      
		end case;
		end procedure;

		procedure wait_result is
		begin
		wait for 40 ns;
		end procedure;

		procedure wait_ov is
		begin
			regwrite <= '1';
			wait for 20 ns;
			regwrite <= '0';
			wait for 20 ns;
		end procedure;
		
	begin
  
		regwrite <= '0';
		wait for 20 ns;
   
-- ADD mit Overflow -------------------------------------------------------------------------------	

		-- setze input
		aop <= x"7FFFFF00";
		bop <= x"00000100"; 
		opc <= opc_ADD;
		
		-- prüfe ergebniss
		wait_result;
		prove(x"80000000"); -- In Vorlage falsch, 80000000 richtig						-- 60 ns
		
		-- prüfe OV-flag
		wait_ov;
		prove("1");																		-- 100 ns
      
-- SUBI mit Overflow ------------------------------------------------------------------------------ 

		-- setze input
		aop    <= x"7FFFFFFF";
		iop    <= x"FFFF";
		ivalid <= '1';
		opc    <= opc_SUB;
		
		-- prüfe ergebniss
		wait_result;
		prove(x"80000000");																-- 140 ns
		
		-- prüfe OV-flag
		wait_ov;
		prove("1");																		-- 180 ns
		
-- ADD ohne Overflow ------------------------------------------------------------------------------

		-- setze input
		aop    <= x"00000001";
		bop    <= x"7FFFFFFE";
		ivalid <= '0';
		opc    <= opc_ADD;
		
		-- prüfe ergebniss
		wait_result;
		prove(x"7FFFFFFF");																-- 220 ns
		
		-- prüfe OV-flag
		wait_ov;
		prove("0"); -- In Vorlage falsch, OV muss 0 sein								-- 260 ns
		
-- JAL => PCINC muss gesichert werden -------------------------------------------------------------  

		-- setze input
		iop    <= x"0555";
		ivalid <= '1';
		opc    <= opc_Pass;
		pcinc  <= "101010101010";
		jal    <= '1';
		rela   <= '1';
		
		-- prüfe ergebniss
		wait_result;
		-- In Vorlage falsch, Operandenlänge zu groß, letzte 0 weg
		prove(x"00000AAA"); 															-- 300 ns
		prove(x"FFF");																	-- 300 ns

-- JREG ------------------------------------------------------------------------------------------

		-- setze input
		aop    <= x"00000333";
		bop    <= x"00000000";
		ivalid <= '0';
		opc    <= opc_CSHL;
		pcinc  <= "101010101010";
		jal    <= '0';
		rela   <= '0';
		
		-- prüfe ergebniss
		wait_result;
		prove(x"00000333");																-- 340 ns
		prove(x"333");																	-- 340 ns

-- LOAD => (invalide) XBus-Adresse berechnen und XDATAIN sichern ----------------------------------

		-- setze input
		aop     <= x"AAAAAAA0";
		iop     <= x"000A";
		ivalid  <= '1';
		opc     <= opc_ADD;
		xdatain <= x"12345678";
		selxres <= '1';
		
		-- prüfe ergebniss
		wait_result;
		prove(x"12345678");	
		prove("1101010101010");														-- 380 ns
		
-- LDUI => unsigned Expansion von IOP -------------------------------------------------------------

		-- setze input
		aop     <= x"00000000";
		iop     <= x"FFFF";
		ivalid  <= '1';
		opc     <= opc_OR;
		selxres <= '0';
		
		-- prüfe ergebniss
		wait_result;
		prove(x"0000FFFF");																-- 420 ns
		
		-- prüfe OV-flag
		wait_ov;
		prove("0");																		-- 460 ns
		               
-- XNOR -------------------------------------------------------------------------------------------

		-- setze input
		aop     <= x"F0F00000";
		bop     <= x"F0F0FFFF";
		ivalid  <= '0'; 
		opc     <= opc_XNOR;
		
		-- prüfe ergebniss
		wait_result;
		prove(x"FFFF0000");																-- 500 ns
		
-- XOR --------------------------------------------------------------------------------------------

	-- setze input
	aop     <= x"F0F00000";
	bop     <= x"F0F0FFFF";
	opc     <= opc_XOR;
	
	-- prüfe ergebniss
	wait_result;
	prove(x"0000FFFF");      															-- 540 ns
 
	report "!!!TEST DONE !!!"
		severity NOTE;
    	wait;
  end process;
  
end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
