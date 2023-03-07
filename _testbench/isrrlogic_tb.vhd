---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the ISRRLOGIC
-- autor:    Andreas Engel
-- date:    29.07.07
-- runtime: 700ns
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
entity isrrlogic_tb is
end isrrlogic_tb;
---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of isrrlogic_tb is
	
	-- Stimulie
	signal clk, intr, reti  : std_logic    := '0';
	signal reset, pcwrite   : std_logic    := '1';
	signal pcnext           : t_pmemoryAdr := (others => '0'); 	
	signal curlvl           : t_irqLvl     := "000";
	signal curlvl_x, pcnext_x : integer    := 0;
	
	-- beobachtete Signale
	signal isrr             : t_pmemoryAdr     := (others => '0'); 	
	signal retilvl          : t_irqLvl := "000";	
	
	-- beobachtete Signale (std_logic_vector)
	signal isrr_slv         : std_logic_vector(isrr'range) := (others => '0');
	signal retilvl_slv      : std_logic_vector(retilvl'range) := (others => '0');
	
	-- Beobachtungsprozedur
	procedure prove(retilvl_x, isrr_x : integer) is	  
	begin
		wait for 20 ns;
		
		assert to_integer(retilvl) = retilvl_x
			report   "wrong RETILVL " & integer'image(to_integer(retilvl)) & 
			         "; expected " & integer'image(retilvl_x)
			severity error;
		
		assert to_integer(isrr) = isrr_x
			report   "wrong ISRR " & integer'image(to_integer(isrr)) & 
			         "; expected " & integer'image(isrr_x)
			severity error;
		
		wait for 20 ns;
	end procedure;

begin

	-- Unit Under Test
	UUT : entity isrrlogic
		port map (
			CLK     => clk,
			RESET   => reset,
			PCNEXT  => std_logic_vector(pcnext),
			PCWRITE => pcwrite,
			INTR    => intr,
			RETI    => reti,
			CURLVL  => std_logic_vector(curlvl),
			ISRR    => isrr_slv,
			RETILVL => retilvl_slv
		);
		
	-- do type conversions
	isrr    <= unsigned(isrr_slv);
	retilvl <= unsigned(retilvl_slv);

	-- CLK Stimulus [50MHz]
	clk <= not clk after 10 ns;  
	
	-- Beschaltung der Eingänge und Beobachtung der Ausgänge
	test: process
	begin      
  
--   20ns: RESET ----------------------------------------------------------------------------------
		reset <= '1', '0' after 12 ns;
		prove(0, 4094);
    
--  60ns: kein Push ohne INTR --------------------------------------------------------------------
		curlvl_x <= 3; pcnext_x <= 512;
		prove(0, 4094);
    
--  100ns: kein Push bei INTR und RETI ------------------------------------------------------------
		intr <= '1', '0' after 20 ns; reti <= '1', '0' after 20 ns;
		prove(0, 4094);
    
--  140ns: kein Push bei INTR ohne PCWRITE --------------------------------------------------------
		intr <= '1', '0' after 20 ns; pcwrite <= '0', '1' after 20 ns;
		prove(0, 4094);    
    
--  180ns: Push -----------------------------------------------------------------------------------
		curlvl_x <= 3; pcnext_x <= 512; intr <= '1', '0' after 20 ns;
		prove(3, 512);
    
--  220ns: Push -----------------------------------------------------------------------------------
		curlvl_x <= 2; pcnext_x <= 256; intr <= '1', '0' after 20 ns;
		prove(2, 256);
    
--  260ns: Push -----------------------------------------------------------------------------------
		curlvl_x <= 1; pcnext_x <= 128; intr <= '1', '0' after 20 ns;
		prove(1, 128);
    
--  300ns: Push -----------------------------------------------------------------------------------
		curlvl_x <= 0; pcnext_x <= 64; intr <= '1', '0' after 20 ns;
		prove(0, 64);
		
--  340ns: Push (erster Wert [3,512] geht verloren) -----------------------------------------------
		curlvl_x <= 2; pcnext_x <= 32; intr <= '1', '0' after 20 ns;
		prove(2, 32);
    
--  380ns: kein Pop ohne RETI ---------------------------------------------------------------------
		curlvl_x <= 1; pcnext_x <= 42;
		prove(2, 32);
    
--  420ns: kein Pop bei RETI und INTR -------------------------------------------------------------
		intr <= '1', '0' after 20 ns; reti <= '1', '0' after 20 ns;
		prove(2, 32);
    
--  460ns: kein Pop bei RETI ohne PCWRITE ---------------------------------------------------------
		reti <= '1', '0' after 20 ns; pcwrite <= '0', '1' after 20 ns;
		prove(2, 32);
        
--  500ns: Pop ------------------------------------------------------------------------------------
		reti <= '1', '0' after 20 ns;
		prove(0, 64);
    
--  540ns: Pop ------------------------------------------------------------------------------------
		reti <= '1', '0' after 20 ns;
		prove(1, 128);
		
--  580ns: Pop ------------------------------------------------------------------------------------
		reti <= '1', '0' after 20 ns;
		prove(2, 256);
    
--  620ns: Pop (leerer Stack) ---------------------------------------------------------------------
		reti <= '1', '0' after 20 ns;
		prove(0, 4094);
    
--  660ns: Push + asynchrones RESET ---------------------------------------------------------------
		intr <= '1', '0' after 20 ns; reset <= '1' after 12 ns, '0' after 16 ns;
		prove(0, 4094);                            
    
		report "!!!TEST DONE !!!"
			severity NOTE;
		wait;
	end process;
    
	-- Eingaben konvertieren (integer => std_logic_vector)
	pcnext  <= to_unsigned(pcnext_x, pcnext'length);
	curlvl  <= to_unsigned(curlvl_x, curlvl'length);            
            
end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
