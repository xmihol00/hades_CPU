---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the PMEMORY
-- autor:    Andreas Engel
-- date:    24.07.07
-- runtime: 550ns
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
entity pmemory_tb is
end pmemory_tb;

---------------------------------------------------------------------------------------------------

-- Architecture:
architecture TB_ARCHITECTURE of pmemory_tb is

	-- Stimulie
	signal clk, pwrite, reset : std_logic    := '0';
	signal loadir             : std_logic    := '0';
	signal radr, wadr         : t_pmemoryAdr := "000000000000";	
	signal datain             : t_word;	
	
	-- beobachtete Signale
	signal dataout            : t_word;
  
begin

  -- Unit Under Test
	UUT: entity pmemory
    generic map ("../_testbench/pmemory_tb.hex")                            
		port map (
			CLK      => clk,
			RESET    => reset,
			RADR     => std_logic_vector(radr),
			LOADIR   => loadir,
			DATAIN   => datain,
			WADR     => std_logic_vector(wadr),
			PWRITE   => pwrite,
			DATAOUT  => dataout
		);           

  -- CLK Stimulus [50MHz]
  clk <= not clk after 10 ns;    	   
  
  -- Beschaltung der Eingänge und Beobachtung der Ausgänge
  test: process
	procedure prove(ra,wa : integer; wd,rd: t_word) is
	begin
		-- set input
		wadr   <= to_unsigned(wa, wadr'length);
		radr   <= to_unsigned(ra, radr'length);
		
    datain <= wd;
		
		-- wait some time
		wait for 10 ns;
	
		-- check output
		assert dataout = rd 
			report "wrong DATAOUT 0x" & to_hex(dataout) & "; expected 0x" & to_hex(rd)  
			severity error;
			
		-- wait reset of cycle
		wait for 10 ns;
	end;
  begin  
         
    wait for 6 ns; 
	
	-- read-only
    pwrite <= '0'; 
	loadir <= '1';
	prove(   0,   0, x"ABCDEF00", x"11111111"); --  16ns
	prove(   2,   2, x"ABCDEF01", x"33333333"); --  36ns
	prove(   4,   4, x"ABCDEF02", x"55555555"); --  56ns
	prove(   6,   6, x"ABCDEF03", x"77777777"); --  76ns
	prove(   8,   8, x"ABCDEF04", x"99999999"); --  96ns
	prove(1022,1022, x"ABCDEF05", x"E1B2C3F4"); -- 116ns
    
	-- nothing
    pwrite <= '0'; 
	loadir <= '0';
	prove(   0,   0, x"ABCDEF10", x"E1B2C3F4"); -- 136ns
	prove(   2,   2, x"ABCDEF11", x"E1B2C3F4"); -- 156ns
	prove(   4,   4, x"ABCDEF12", x"E1B2C3F4"); -- 176ns
	prove(   6,   6, x"ABCDEF13", x"E1B2C3F4"); -- 196ns
	prove(   8,   8, x"ABCDEF14", x"E1B2C3F4"); -- 216ns
	
	-- write-only
    pwrite <= '1'; 
	loadir <= '0';
	prove(   0,   0, x"ABCDEF20", x"E1B2C3F4"); -- 236ns
	prove(   2,   2, x"ABCDEF21", x"E1B2C3F4"); -- 256ns
	prove(   4,   4, x"ABCDEF22", x"E1B2C3F4"); -- 276ns
	prove(   6,   6, x"ABCDEF23", x"E1B2C3F4"); -- 296ns
	prove(   8,   8, x"ABCDEF24", x"E1B2C3F4"); -- 316ns
	
	-- read-only
    pwrite <= '0'; 
	loadir <= '1';
	prove(   0,   0, x"ABCDEF30", x"ABCDEF20"); -- 336ns
	prove(   2,   2, x"ABCDEF31", x"ABCDEF21"); -- 356ns
	prove(   4,   4, x"ABCDEF32", x"ABCDEF22"); -- 376ns
	prove(   6,   6, x"ABCDEF33", x"ABCDEF23"); -- 396ns
	prove(   8,   8, x"ABCDEF34", x"ABCDEF24"); -- 416ns
	
	-- read/write
    pwrite <= '1'; 
	loadir <= '1';
	prove(   0,   2, x"ABCDEF40", x"ABCDEF20"); -- 436ns
	prove(   2,   4, x"ABCDEF41", x"ABCDEF40"); -- 456ns
	prove(   4,   6, x"ABCDEF42", x"ABCDEF41"); -- 476ns
	prove(   6,   8, x"ABCDEF43", x"ABCDEF42"); -- 496ns
	prove(   8,  10, x"ABCDEF44", x"ABCDEF43"); -- 516ns


	-- done
    pwrite <= '0';
	loadir <= '0';
	report "!!!TEST DONE :) !!!"
		severity NOTE;
    wait;
  end process;
  
  
end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
