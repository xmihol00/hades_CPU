---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the PCLOGIC
-- autor:    Andreas Engel
-- date:    28.07.07
-- runtime: 1400ns
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
entity pclogic_tb is
end pclogic_tb;
---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of pclogic_tb is
	
	-- Stimulie	
	signal clk, ov, zero, intr : std_logic := '0';
	signal reset, pcwrite : std_logic := '1';	
	signal pcnew, isra, isrr  : t_pmemoryAdr := (others => '0');
	signal pcnew_x, isra_x, isrr_x : integer := 0; 	
	signal pccontr : std_logic_vector(5 downto 0) := (others => '0');
	
	-- alternative Bezeichnungen für die Flags aus PCCONTR
	alias bnez : std_logic is pccontr(0);
	alias beqz : std_logic is pccontr(1);
	alias bov  : std_logic is pccontr(2);
	alias reti : std_logic is pccontr(3); 
	alias jreg	 : std_logic is pccontr(4);
	alias jal  : std_logic is pccontr(5);	
	
	-- beobachtete Signale
	signal pcakt, pcinc, pcnext : t_pmemoryAdr := (others => '0');		
	
	-- beobachtete Signale (std_logic_vector)
	signal pcakt_slv  : std_logic_vector(pcakt'range)  := (others => '0');
	signal pcinc_slv  : std_logic_vector(pcinc'range)  := (others => '0');
	signal pcnext_slv : std_logic_vector(pcnext'range) := (others => '0');
	
	-- Beobachtungsprozedur
	procedure prove(
		pcakt_x, pcnext_x : integer := -1;                       
		signal a : out std_logic_vector(5 downto 0);
		signal b, c, d : out std_logic;
		d1 : time := 20 ns; d2 : time := 40 ns;
		reset : boolean := true
	) is
		variable pcinc_x : integer;
		variable temp : integer;	 
	begin
		wait for d1;	  	  
		if reset then
			a <= (others => '0');
			b <= '0'; 
			c <= '0';
			d <= '0';
		end if;
		wait for d2;
		
		if pcakt_x >= 0 then
			temp := to_integer(pcakt);
			assert temp = pcakt_x	    
				report   "wrong PCAKT " & integer'image(temp) & "; expected " & integer'image(pcakt_x)
				severity error;
			pcinc_x := (pcakt_x+1 mod 4096);
			temp := to_integer(pcinc);
			assert temp = pcinc_x  
				report   "wrong PCINC " & integer'image(temp) & "; expected " & integer'image(pcinc_x)
				severity error; 
		end if;
		
		if pcnext_x >= 0 then
			temp := to_integer(pcnext);
			assert temp = pcnext_x	    
				report   "wrong PCNEXT " & integer'image(temp) & "; expected " & integer'image(pcnext_x)
				severity error; 
		end if;
	end procedure;

begin

	-- Unit Under Test
	UUT: entity pclogic
		port map (
			CLK     => clk,
			RESET   => reset,
			PCNEW   => std_logic_vector(pcnew),
			ISRA    => std_logic_vector(isra),
			ISRR    => std_logic_vector(isrr),
			PCWRITE => pcwrite,
			PCCONTR => pccontr,
			OV      => ov,
			ZERO    => zero,
			INTR    => intr,
			PCAKT   => pcakt_slv,
			PCINC   => pcinc_slv,
			PCNEXT  => pcnext_slv
		);
	
	-- do type conversions
	pcakt  <= unsigned(pcakt_slv);
	pcinc  <= unsigned(pcinc_slv);
	pcnext <= unsigned(pcnext_slv);

	-- CLK Stimulus [50MHz]
	clk <= not clk after 10 ns;
	
	-- RESET Stimulus
	reset <= '0' after 4 ns;
	
	-- PCWRITE Stimulus
	pcwrite <= '1' after 40 ns when pcwrite = '0' else '0' after 20 ns;
 
	-- Beschaltung der Eingänge und Beobachtung der Ausgänge
	test: process  
	begin           
  
--   5ns: RESET ----------------------------------------------------------------------------------
 	prove(0, 1, pccontr, zero, ov, intr, d1 => 0 ns, d2 => 5 ns);

--  60ns: keine Verzweigung (normales PC-Inkrement) ----------------------------------------------
	prove(1, 2, pccontr, zero, ov, intr, d1 => 15 ns);

--  120ns: BOV ohne OV (normales PC-Inkrement) ----------------------------------------------------
	bov <= '1'; ov <= '0';
	prove(2, 3, pccontr, zero, ov, intr);

--  180ns: BEQZ ohne ZERO (normales PC-Inkrement) -------------------------------------------------
	beqz <= '1'; zero <= '0';
	prove(3, 4, pccontr, zero, ov, intr);
    
--  240ns: BNEZ mit ZERO (normales PC-Inkrement) --------------------------------------------------
	bnez <= '1'; zero <= '1';
	prove(4, 5, pccontr, zero, ov, intr);  
    
--  300ns: BOV mit OV (Branch) --------------------------------------------------------------------
	bov <= '1'; ov <= '1'; pcnew_x <= 64;
	prove(64, 65, pccontr, zero, ov, intr);  
    
--  360ns: BEQZ mit ZERO (Branch) -----------------------------------------------------------------
	beqz <= '1'; zero <= '1'; pcnew_x <= 68;
	prove(68, 69, pccontr, zero, ov, intr);
    
--  420ns: BNEZ ohne ZERO (Branch) ----------------------------------------------------------------
	bnez <= '1'; zero <= '0'; pcnew_x <= 4;
	prove(4, 5, pccontr, zero, ov, intr);
    
--  480ns: JREG ------------------------------------------------------------------------------------
	jreg <= '1'; pcnew_x <= 512;
	prove(512, 513, pccontr, zero, ov, intr); 
    
-- 540ns: JAL  -----------------------------------------------------------------------------------
	jal <= '1'; pcnew_x <= 32;
	prove(32, 33, pccontr, zero, ov, intr); 
    
-- 600ns: RETI -----------------------------------------------------------------------------------
	reti <= '1'; isrr_x <= 0;
	prove(0, 1, pccontr, zero, ov, intr); 
    
-- 660ns: keine Verzweigung + Interrupt ----------------------------------------------------------
	intr <= '1'; isra_x <= 128;     
	prove(-1,    1, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
	prove(128, 129, pccontr, zero, ov, intr, d1 => 15 ns); 

-- 720ns: BOV ohne OV + Interrupt ----------------------------------------------------------------
	intr <= '1'; isra_x <= 256; bov <= '1'; ov <= '0'; pcnew_x <= 16;
	prove(-1,  129, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
	prove(256, 257, pccontr, zero, ov, intr, d1 => 15 ns); 
    
-- 780ns: BEQZ ohne ZERO + Interrupt -------------------------------------------------------------
    intr <= '1'; isra_x <= 512; beqz <= '1'; zero <= '0'; pcnew_x <= 16;
    prove(-1,  257, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
    prove(512, 513, pccontr, zero, ov, intr, d1 => 15 ns);    
    
-- 840ns: BNEZ mit ZERO + Interrupt --------------------------------------------------------------
    intr <= '1'; isra_x <= 256; bnez <= '1'; zero <= '1'; pcnew_x <= 16;
    prove(-1,  513, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
    prove(256, 257, pccontr, zero, ov, intr, d1 => 15 ns); 
    
-- 900ns: BOV mit OV + Interrupt -----------------------------------------------------------------
    intr <= '1'; isra_x <= 128; bov <= '1'; ov <= '1'; pcnew_x <= 64;
    prove(-1,   64, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
    prove(128, 129, pccontr, zero, ov, intr, d1 => 15 ns); 

-- 960ns: BEQZ mit ZERO + Interrupt --------------------------------------------------------------
    intr <= '1'; isra_x <= 256; beqz <= '1'; zero <= '1'; pcnew_x <= 68;
    prove(-1,   68, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
    prove(256, 257, pccontr, zero, ov, intr, d1 => 15 ns);    
    
-- 1020ns: BNEZ ohne ZERO + Interrupt -------------------------------------------------------------
    intr <= '1'; isra_x <= 512; bnez <= '1'; zero <= '0'; pcnew_x <= 4;
    prove(-1,    4, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
    prove(512, 513, pccontr, zero, ov, intr, d1 => 15 ns); 

-- 1080ns: JREG + Interrupt ------------------------------------------------------------------------
    intr <= '1'; isra_x <= 256; jreg <= '1'; pcnew_x <= 32;
    prove(-1,   32, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
    prove(256, 257, pccontr, zero, ov, intr, d1 => 15 ns); 

-- 1140ns: JAL + Interrupt ------------------------------------------------------------------------
    intr <= '1'; isra_x <= 128; jal <= '1'; pcnew_x <= 8;
    prove(-1,    8, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
    prove(128, 129, pccontr, zero, ov, intr, d1 => 15 ns); 

-- 1200ns: RETI + Interrupt -----------------------------------------------------------------------
    intr <= '1'; isra_x <= 512; reti <= '1'; isrr_x <= 0;
    prove(-1,    0, pccontr, zero, ov, intr, d1 => 5 ns, d2 => 0 ns, reset => false);
    prove(512, 513, pccontr, zero, ov, intr, d1 => 15 ns); 
    
	report "!!!TEST DONE !!!"
		severity NOTE;
    wait;
  end process;

  -- Adressen konvertieren (integer => std_logic_vector)
  isra  <= to_unsigned(isra_x,  isra'length);
  isrr  <= to_unsigned(isrr_x,  isrr'length);
  pcnew <= to_unsigned(pcnew_x, pcnew'length);

end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
