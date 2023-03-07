---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench von ISRALOGIC
-- autor:    Andreas Engel
-- date:    29.07.07
-- runtime: 850ns
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
entity isralogic_tb is
end isralogic_tb;
---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of isralogic_tb is
	
	-- Stimulie
	signal clk, reset, sisa   : std_logic    := '0';
	signal pcwrite            : std_logic    := '1';
	signal sisalvl            : t_sisaLvl    := "00";	
	signal selisra            : t_irqLvl     := "000";	
	signal pcnew              : t_pmemoryAdr := (others => '0');
	signal irqlvl_x, pcnew_x  : integer      := 0;
	
	-- beobachtete Signale
	signal isra             : t_pmemoryAdr := (others => '0');
  
	-- beobachtete Signale (std_logic_vector)
	signal isra_slv         : std_logic_vector(isra'range) := (others => '0');

begin

	-- Unit Under Test
	UUT: entity isralogic
	port map (
		CLK     => clk,
		RESET   => reset,
		PCWRITE => pcwrite,
		SISA    => sisa,
		SISALVL => std_logic_vector(sisalvl),
		PCNEW   => std_logic_vector(pcnew),
		SELISRA => std_logic_vector(selisra),
		ISRA    => isra_slv
	);
	
	-- do type conversions
	isra <= unsigned(isra_slv);

	-- CLK Stimulus [50MHz]
	clk <= not clk after 10 ns;  

	-- Beschaltung der Eingänge und Beobachtung der Ausgänge
	test: process 
		-- Beobachtungsprozedur
		procedure prove(signal sel : out t_irqLvl; ssi: in std_logic; a1, a2, a3, a4 : integer := 4095) is
			variable temp : integer;
			type t_vals is array(0 to 4) of integer;
			variable vals : t_vals := (0, a1, a2, a3, a4);     
		begin
			sisa    <= ssi;
			pcwrite <= '1';
			wait for 20 ns;
			sisa    <= '0';
			pcwrite <= '0';
			for i in vals'range loop
				sel <= to_unsigned(i, sel'length);
				wait for 10 ns;
				temp := to_integer(isra);
				assert temp = vals(i)
					report   "wrong ISRA(" & integer'image(i) & ") = " & integer'image(temp) & 
				                                 "; expected " & integer'image(vals(i)) 
					severity error;
			end loop;  
			wait for 10 ns; 
		end procedure;	
	begin
       
--  40-70ns: RESET -------------------------------------------------------------------------------
		pcwrite <= '0';
		sisa    <= '0';
		reset   <= '1', '0' after 20 ns;     
		prove(selisra,'0');    
    
-- 110-150ns: Schreiben auf ISRA(0) ohne SISA wirkungslos -----------------------------------------
		pcnew_x <= 42; irqlvl_x <= 0;  
		prove(selisra,'0');
    
-- 190-230ns: Schreiben auf ISRA(1) ohne SISA wirkungslos -----------------------------------------
		pcnew_x <= 42; irqlvl_x <= 1;  
		prove(selisra,'0');
    
-- 270-310ns: Schreiben auf ISRA(2) ohne SISA wirkungslos -----------------------------------------
		pcnew_x <= 42; irqlvl_x <= 2;  
		prove(selisra,'0');
		
-- 350-390ns: Schreiben auf ISRA(3) ohne SISA wirkungslos -----------------------------------------
		pcnew_x <= 42; irqlvl_x <= 3;  
		prove(selisra,'0');
    
-- 430-470ns: Schreiben auf ISRA(0) mit SISA ------------------------------------------------------
		pcnew_x <= 128; irqlvl_x <= 0; 
		prove(selisra,'1', 128);
    
-- 510-550ns: Schreiben auf ISRA(1) mit SISA ----------------------------------------------------
		pcnew_x <= 256; irqlvl_x <= 1; 
		prove(selisra,'1', 128, 256);
    
-- 590-630ns: Schreiben auf ISRA(2) mit SISA ----------------------------------------------------
		pcnew_x <= 512; irqlvl_x <= 2; 
		prove(selisra,'1', 128, 256, 512);
		
-- 670-710ns: Schreiben auf ISRA(3) mit SISA ----------------------------------------------------
		pcnew_x <= 1024; irqlvl_x <= 3; 
		prove(selisra,'1', 128, 256, 512, 1024);
    
-- 750-790ns: asynchrones Reset -----------------------------------------------------------------
		reset <= '1' after 17 ns, '0' after 20 ns; 
		prove(selisra,'0');                
    
		report "!!!TEST DONE !!!"
			severity NOTE;
    wait;
  end process;
  
  -- Eingaben konvertieren (integer => std_logic_vector)
  pcnew   <= to_unsigned(pcnew_x,   pcnew'length);
  sisalvl <= to_unsigned(irqlvl_x,  sisalvl'length);  
  
end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
