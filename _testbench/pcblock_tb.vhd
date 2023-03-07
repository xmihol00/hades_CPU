---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the PCBLOCK
-- autor:    Andreas Engel
-- date:    29.07.07
-- runtime: 1200ns
--
-- tolerated error messages:
--   ..\..\v87\synopsys\std_logic_arith.vhd:2024:16:@0ms:(assertion warning): CONV_INTEGER: There is an 'U'|'X'|'W'|'Z'|'-' in an arithmetic operand, and it has been converted to 0.
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
entity pcblock_tb is
end pcblock_tb;

---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of pcblock_tb is
	
	-- Stimulie
	signal clk, ov, zero               : std_logic                     := '0';   
    signal xperintr, xnaintr, xmemintr : std_logic                     := '0';
	signal reset, pcwrite              : std_logic                     := '1';
	signal pcnew                       : t_pmemoryAdr                  := (others => '0');
	signal sisalvl                     : t_sisaLvl                     := (others => '0');
	signal pccontr                     : std_logic_vector(10 downto 0) := (others => '0');
	signal pcnew_x, pcnewLvl_x         : integer := 0;

	-- beobachtete Signale
	signal pcakt,pcinc                 : t_pmemoryAdr                  := (others => '0');
	
	-- beobachtete Signale (std_logic_vector)
	signal pcakt_slv : std_logic_vector(pcakt'range) := (others => '0');
	signal pcinc_slv : std_logic_vector(pcinc'range) := (others => '0');
	
	-- alternative Bezeichnungen für die pccontr-Flags
	alias bnez : std_logic is pccontr(0);
	alias beqz : std_logic is pccontr(1);
	alias bov  : std_logic is pccontr(2);
	alias sisa : std_logic is pccontr(3);
	alias dei  : std_logic is pccontr(4);
	alias eni  : std_logic is pccontr(5);
	alias reti : std_logic is pccontr(6); 
	alias jreg  : std_logic is pccontr(7);
	alias jal  : std_logic is pccontr(8);
	alias swi  : std_logic is pccontr(9);
	alias rela : std_logic is pccontr(10);
	
	-- Beobachtungsprozedur
	procedure prove(pcakt_x : integer; pre_wait : time := 35 ns; post_wait : time := 25 ns) is
	begin
		wait for pre_wait;
		assert to_integer(pcakt) = pcakt_x
			report "wrong PCAKT " & integer'image(to_integer(pcakt)) & 
			 	   "; expected " & integer'image(pcakt_x)
				severity error;
    	wait for post_wait;
	end procedure;
	
begin

	-- Unit Under Test
	UUT: entity pcblock
		port map (
			CLK      => clk,
			RESET    => reset,
			PCNEW    => std_logic_vector(pcnew),
			SISALVL  => std_logic_vector(sisalvl),
			PCCONTR  => pccontr,
			OV       => ov,
			ZERO     => zero,
			PCWRITE  => pcwrite,
			XPERINTR => xperintr,
			XNAINTR  => xnaintr,
			XMEMINTR => xmemintr,
			PCAKT    => pcakt_slv,
			PCINC    => pcinc_slv
		);

	-- do type conversions
	pcakt <= unsigned(pcakt_slv);
	pcinc <= unsigned(pcinc_slv);
	
	-- CLK Stimulus [50MHz]
	clk <= not clk after 10 ns;
	
	-- PCWRITE Stimulus
	pcwrite <= '1' after 40 ns when pcwrite = '0' else '0' after 20 ns;
  
	process   
	begin    
  
--   15 ns: RESET => Bootloader -------------------------------------------------------------------
		reset <= '1', '0' after 15 ns;
		prove(0, pre_wait => 15 ns);
    
--   75 ns: SISA #3, #1024 ------------------------------------------------------------------------
		sisa <= '1', '0' after 40 ns; pcnewLvl_x <= 3; pcnew_x <= 1024; 
		prove(1);
		
--  135 ns: SISA #2, #512 -------------------------------------------------------------------------
		sisa <= '1', '0' after 40 ns; pcnewLvl_x <= 2; pcnew_x <= 512; 
		prove(2);
    
--  195 ns: SISA #1, #256 -------------------------------------------------------------------------
		sisa <= '1', '0' after 40 ns; pcnewLvl_x <= 1; pcnew_x <= 256; 
		prove(3);

--  255 ns: SISA #0, #128 -------------------------------------------------------------------------
		sisa <= '1', '0' after 40 ns; pcnewLvl_x <= 0; pcnew_x <= 128; 
		prove(4);
    
--  315 ns: BOV ohne OV ---------------------------------------------------------------------------
		bov <= '1', '0' after 40 ns; ov <= '0'; 
		prove(5);

--  375 ns: BEQZ ohne ZERO ------------------------------------------------------------------------
		beqz <= '1', '0' after 40 ns; zero <= '0'; 
		prove(6);
  
--  435 ns: BNEZ mit ZERO -------------------------------------------------------------------------
		bnez <= '1', '0' after 40 ns; zero <= '1';
		prove(7);
  
--  495 ns: BEQZ mit ZERO -------------------------------------------------------------------------
		beqz <= '1', '0' after 40 ns; zero <= '1'; pcnew_x <= 5;
		prove(5);

--  555 ns: BNEZ ohne ZERO ------------------------------------------------------------------------
		bnez <= '1', '0' after 40 ns; zero <= '0'; pcnew_x <= 55;
		prove(55);
      
--  615 ns: BOV mit OV ----------------------------------------------------------------------------
		bov <= '1', '0' after 40 ns; ov <= '1', '0' after 40 ns; pcnew_x <= 555;
		prove(555);

--  675 ns: JREG -----------------------------------------------------------------------------------
		jreg <= '1', '0' after 40 ns; pcnew_x <= 42;
		prove(42);

--  735 ns: JAL -----------------------------------------------------------------------------------
		jal <= '1', '0' after 40 ns; pcnew_x <= 7;
		prove(7);
    
--  795 ns: SWINTR => level 1 ---------------------------------------------------------------------
		swi <= '1' after 7 ns, '0' after 35 ns;
		prove(128);

--  855 ns: XMEMINTR => level 4 -------------------------------------------------------------------    
		xmemintr <= '1' after 7 ns, '0' after 12 ns;
		prove(1024);
    
--  915 ns: XNAINTR (level 3 wird gelatched) ------------------------------------------------------   
		xnaintr <= '1' after 7 ns, '0' after 12 ns;
		prove(1025);

--  975 ns: RETI => level 3 -----------------------------------------------------------------------    
		reti <= '1', '0' after 40 ns;
		prove(512);

-- 1035 ns: RETI => level 1 -----------------------------------------------------------------------    
		reti <= '1', '0' after 40 ns;
		prove(129);

-- 1095 ns: RETI => level 0 -----------------------------------------------------------------------    
		reti <= '1', '0' after 40 ns;
		prove(8);

-- 1155 ns: RETI => Stack leer --------------------------------------------------------------------    
	    reti <= '1', '0' after 40 ns;
	    prove(4094);

	report "!!!TEST DONE !!!"
		severity NOTE;
    wait;
  end process;
  
  -- Eingaben konvertieren (integer => std_logic_vector)
  sisalvl <= to_unsigned(pcnewLvl_x, sisalvl'length);
  pcnew   <= to_unsigned(pcnew_x,    pcnew'length);

end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
