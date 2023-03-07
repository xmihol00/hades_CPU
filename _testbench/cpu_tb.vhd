---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench von CPU
-- autor:    Andreas Engel
-- date:    03.08.07
-- runtime: check *.mif
--
-- tolerated error messages:
--   ..\..\v87\synopsys\std_logic_arith.vhd:2024:16:@0ms:(assertion warning): CONV_INTEGER: There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, and it has been converted to 0.
--   ..\..\v87\synopsys\std_logic_arith.vhd:315:20:@0ms:(assertion warning): There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, the result will be 'X'(es).
-- 
---------------------------------------------------------------------------------------------------


-- Libraries:
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library std;
	use std.textio.all;
library xbus_sim;
    use xbus_sim.all;
library work;
	use work.all;
	use work.hadescomponents.all;
	
---------------------------------------------------------------------------------------------------

-- Entity:
entity cpu_tb is
end entity;

---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of cpu_tb is

	-- Stimulie:
	signal clk, reset                                : std_logic := '0';
	
	-- CPU Ausgänge
	signal xdataout                                  : t_word    := (others => '0');
	signal xadr		                                 : t_xbusAdr := (others => '0');
	signal xread, xwrite, dmemop                     : std_logic := '0';
	
	-- XBUS Ausgänge
	signal dataout                                   : t_word    := (others => '0');
	signal ack, perintr, memintr, dmembusy, xpresent : std_logic := '0';
	
	-- temporäre Datei, in der die Nummer des auszuführenden tests steht
	impure function getNum return integer is
	file numFile : text is "../_testbench/cpu_tb.num";
		variable l : line;
		variable i : integer;
	begin
		readline(numFile, l);
		read(l, i);
		return i;
	end function;
	
	constant N : integer := getNum;
	
begin
    	
	-- CPU ------------------------------------------------------------------------------------------
	CPU_instance: entity cpu
 		generic map (
			INIT 		=> "../_testbench/cpu_tb" & integer'image(N) & ".mif"
		)
		port map (
			CLK			=> clk,
			RESET		=> reset,
			DMEMBUSY	=> dmembusy,
			XACK		=> ack,
			XMEMINTR	=> memintr,
			XPERINTR	=> perintr,
			XPRESENT	=> xpresent,
			XDATAIN		=> dataout,
			DMEMOP		=> dmemop,
			XREAD		=> xread,
			XWRITE		=> xwrite,
			XADR		=> xadr,
			XDATAOUT	=> xdataout
		);	
	
	
	-- XBus -----------------------------------------------------------------------------------------	
	XBUS_instance: entity xbus_sim.xbus_sim 
		port map(
			CLK			=> clk,
			RESET		=> reset,
			ADR			=> xadr,
			DATAIN		=> xdataout,
			READ		=> xread,
			WRITE		=> xwrite,
			DMEMOP		=> dmemop,
			ACK			=> ack,
			XPRESENT	=> xpresent,
			DMEMBUSY	=> dmembusy,
			PERINTR		=> perintr,
			MEMINTR		=> memintr,
			DATAOUT		=> dataout
		);
		
	-- CLK Stimulus [50 MHz]
	clk <= not clk after 10 ns;
	
	-- RESET Stimulus
	reset <= '1', '0' after 25 ns;
	
	process
	begin	  	  
		wait for 100 ns;
		report "";
		report "== CPU Test " & integer'image(N) & " ==";
		report "Please check the specification in the _testbench/cpu_tb" & integer'image(N) & ".mif in the waveform!";
		wait;
	end process;
			
end architecture;
---------------------------------------------------------------------------------------------------
