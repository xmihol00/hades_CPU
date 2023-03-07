---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the IRQLOGIC
-- autor:    Andreas Engel
-- date:    29.07.07
-- runtime: 900ns
--
-- tolerated error messages :
-- NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0
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
entity irqlogic_tb is
end irqlogic_tb;

---------------------------------------------------------------------------------------------------

-- Architecture:
architecture TB_ARCHITECTURE of irqlogic_tb is
	
	-- Stimulie:
	signal clk, xnaintr, xperintr, xmemintr : std_logic                    := '0';
	signal reset, pcwrite                   : std_logic                    := '1';	
	signal pcnew, pcnext                    : t_pmemoryAdr                 := (others => '0');
	signal sisalvl                          : t_sisaLvl                    := (others => '0');
	signal pccontr                          : std_logic_vector(4 downto 0) := (others => '0');
	signal pcnew_x, pcnext_x, sisalvl_x     : integer                      := 0;
	
	-- alternative Bezeichnungen für die Flags aus PCCONTR
	alias swi  : std_logic is PCCONTR(4);
	alias reti : std_logic is PCCONTR(3);
	alias eni  : std_logic is PCCONTR(2);
	alias dei  : std_logic is PCCONTR(1);
	alias sisa : std_logic is PCCONTR(0);
	
	-- beobachtete Signale:
	signal intr        : std_logic                    := '0';
	signal isra, isrr  : t_pmemoryAdr                 := (others => '0');
	
	-- beobachtete Signale (std_logic_vector)
	signal isra_slv    : std_logic_vector(isra'range) := (others => '0');
	signal isrr_slv    : std_logic_vector(isrr'range) := (others => '0');
	
	-- Beobachtungsprozedur
	procedure prove(intr_x, isra_x, isrr_x : integer := -1) is
		variable temp : integer := 0;
	begin
		
		if intr_x >= 0 then
			if intr = '1'
				then temp := 1;
				else temp := 0; 
			end if;
			assert temp = intr_x 
				report "wrong INTR; expected " & integer'image(intr_x)
				severity error;
		end if;
		
		if isra_x >= 0 then
		  temp := to_integer(isra);
		  assert temp = isra_x
			  report   "wrong ISRA " & integer'image(temp) & "; expected " & integer'image(isra_x)
			  severity error;
		end if;
		
		if isrr_x >= 0 then
			temp := to_integer(isrr);
			assert temp = isrr_x
				report   "wrong ISRR " & integer'image(temp) & "; expected " & integer'image(isrr_x)
				severity error;
		end if;
    
  end procedure;
	
begin

	-- Unit Under Test
	UUT: entity irqlogic
		port map (
			CLK      => clk,
			RESET    => reset,
			PCNEW    => std_logic_vector(pcnew),
			PCNEXT   => std_logic_vector(pcnext),
			SISALVL  => std_logic_vector(sisalvl),
			XNAINTR  => xnaintr,
			XPERINTR => xperintr,
			XMEMINTR => xmemintr,
			PCWRITE  => pcwrite,
			PCCONTR  => pccontr,
			INTR     => intr,
			ISRA     => isra_slv,
			ISRR     => isrr_slv
		);

	-- do type conversions
	isra <= unsigned(isra_slv);
	isrr <= unsigned(isrr_slv);
	
	-- CLK Stimulus [50MHz]
	clk <= not clk after 10 ns;
	
	-- PCWRITE Stimulus
	pcwrite <= '1' after 40 ns when pcwrite = '0' else '0' after 20 ns; 
	
	
	process
	begin
  
-- RESET ------------------------------------------------------------------------------------------
		wait for  0 ns; reset <= '1', '0' after 15 ns;
		wait for 20 ns; prove(intr_x => 0, isra_x => 0, isrr_x => 4094);                  --   20ns

-- XMEMINTR => Sprung zu Standard ISRA 4095 -------------------------------------------------------   
		wait for 5 ns; xmemintr <= '1' after 2 ns, '0' after 7 ns;
		                pcnext_x  <= 42;
		wait for 10 ns; prove(intr_x => 0, isra_x => 4095, isrr_x => 4094);               --   35ns
		wait for 30 ns; prove(intr_x => 1, isra_x => 4095, isrr_x => 4094);               --   65ns
		wait for 10 ns; prove(intr_x => 0,                 isrr_x =>   42);               --   75ns
    
-- RETI => Rücksprung (Stack leer) ----------------------------------------------------------------    
		wait for 25 ns; reti <= '1', '0' after 40 ns;
		wait for 25 ns; prove(intr_x => 0,                 isrr_x =>   42);               --  125ns
		wait for 10 ns; prove(intr_x => 0,                 isrr_x => 4094);               --  135ns
    
-- SISA #3, #1024 ---------------------------------------------------------------------------------
		wait for 25 ns; sisa <= '1', '0' after 40 ns; sisalvl_x <= 3; pcnew_x <= 1024;
		wait for 35 ns; prove(intr_x => 0,                 isrr_x => 4094);               --  195ns
		
-- SISA #2, #512 ----------------------------------------------------------------------------------
		wait for 25 ns; sisa <= '1', '0' after 40 ns; sisalvl_x <= 2; pcnew_x <= 512;
		wait for 35 ns; prove(intr_x => 0,                 isrr_x => 4094);               --  255ns
    
-- SISA #1, #256 ----------------------------------------------------------------------------------
		wait for 25 ns; sisa <= '1', '0' after 40 ns; sisalvl_x <= 1; pcnew_x <= 256;
		wait for 35 ns; prove(intr_x => 0,                 isrr_x => 4094);               --  315ns
    
-- SISA #0, #128 ----------------------------------------------------------------------------------
		wait for 25 ns; sisa <= '1', '0' after 40 ns; sisalvl_x <= 0; pcnew_x <= 128;
		wait for 35 ns; prove(intr_x => 0,                 isrr_x => 4094);               --  375ns
    
-- SWINTR => Sprung zu gespeicherter ISRA 128 ---------------------------------------------------
		wait for 10 ns; swi <= '1' after 2 ns, '0' after 52 ns; pcnext_x <= 3;
		wait for 40 ns; prove(intr_x => 1, isra_x =>  128, isrr_x => 4094);               --  425ns
		wait for 10 ns; prove(intr_x => 0,                 isrr_x =>    3);               --  435ns
		
-- XPERINTR => Sprung zu gespeicherter ISRA 256 ---------------------------------------------------
		wait for 10 ns; xperintr <= '1' after 2 ns, '0' after 50 ns; pcnext_x <= 33;
		wait for 10 ns; prove(intr_x => 0, isra_x =>  256, isrr_x =>    3);               --  455ns
		wait for 30 ns; prove(intr_x => 1, isra_x =>  256, isrr_x =>    3);               --  485ns
		wait for 10 ns; prove(intr_x => 0,                 isrr_x =>   33);               --  495ns

-- XNAINTR => Sprung zu gespeicherter ISRA 512 ---------------------------------------------------- 
		wait for 10 ns; xnaintr <= '1' after 2 ns, '0' after 7 ns; pcnext_x <= 333;
		wait for 10 ns; prove(intr_x => 0, isra_x =>  512, isrr_x =>   33);               --  515ns
		wait for 30 ns; prove(intr_x => 1, isra_x =>  512, isrr_x =>   33);               --  545ns
		wait for 10 ns; prove(intr_x => 0,                 isrr_x =>  333);               --  555ns

-- XMEMINTR => Sprung zu gespeicherter ISRA 1024 --------------------------------------------------
		wait for 10 ns; xmemintr <= '1' after 2 ns, '0' after 7 ns; pcnext_x <= 3333;
		wait for 10 ns; prove(intr_x => 0, isra_x => 1024, isrr_x =>  333);               --  575ns
		wait for 30 ns; prove(intr_x => 1, isra_x => 1024, isrr_x =>  333);               --  605ns
		wait for 10 ns; prove(intr_x => 0,                 isrr_x => 3333);               --  615ns

-- RETI => Rücksprung auf ISRR (level 3) ----------------------------------------------------------    
		wait for 25 ns; reti <= '1', '0' after 40 ns;
		wait for 25 ns; prove(intr_x => 0,                isrr_x => 3333);                --  665ns
		wait for 10 ns; prove(intr_x => 0,                isrr_x =>  333);                --  675ns

-- RETI => Rücksprung auf ISRR (level 2) ---------------------------------------------------------- 
		wait for 25 ns; reti <= '1', '0' after 40 ns;
		wait for 25 ns; prove(intr_x => 0,                isrr_x =>  333);                --  725ns
		wait for 10 ns; prove(intr_x => 0,                isrr_x =>   33);                --  735ns
		
-- RETI => Rücksprung auf ISRR (level 1) ---------------------------------------------------------- 
		wait for 25 ns; reti <= '1', '0' after 40 ns;
		wait for 25 ns; prove(intr_x => 0,                isrr_x =>   33);                --  785ns
		wait for 10 ns; prove(intr_x => 0,                isrr_x =>    3);                --  795ns

-- RETI => Rücksprung (Stack leer) ----------------------------------------------------------------    
		wait for 25 ns; reti <= '1', '0' after 40 ns;
		wait for 25 ns; prove(intr_x => 0,                isrr_x =>    3);                --  845ns
		wait for 10 ns; prove(intr_x => 0,                isrr_x => 4094);                --  855ns

		report "!!!TEST DONE !!!"
			severity NOTE;
    wait;
  end process;
  
  -- Eingaben konvertieren (integer => std_logic_vector)
  pcnext  <= to_unsigned(pcnext_x, pcnext'length);
  pcnew   <= to_unsigned(pcnew_x,  pcnew'length);
  sisalvl <= to_unsigned(sisalvl_x,sisalvl'length);
  
  
end TB_ARCHITECTURE;
