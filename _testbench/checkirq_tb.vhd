---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the ISRRLOGIC
-- autor:    Andreas Engel
-- date:    29.07.07
-- runtime: 1350ns
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
entity checkirq_tb is
end checkirq_tb;

---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of checkirq_tb is
	
	-- Stimulie
	signal clk, eni, dei, reti                  : std_logic := '0';
	signal xmemintr, xnaintr, xperintr, swintr  : std_logic := '0';
	signal reset, pcwrite                       : std_logic := '1'; 	
	signal retilvl                              : t_irqLvl  := "000";
		
	-- beobachtete Signale
	signal intr                                 : std_logic;
	signal curlvl, selisra                      : t_irqLvl;
	signal curlvl_slv, selisra_slv              : std_logic_vector(t_irqLvl'range);
	
	-- Beobachtungsprozedur
	procedure prove(intr_x, curlvl_x, selisra_x : integer := -1) is
		variable temp : integer := 0;
	begin
		
		if intr_x >= 0 then
			if intr = '1' then temp := 1; else temp := 0; end if;
			assert temp = intr_x 
				report "wrong INTR; expected " & integer'image(intr_x)
				severity error;
		end if;
			
		if curlvl_x >= 0 then
			temp := to_integer(curlvl);
			assert temp = curlvl_x
				report   "wrong CURLVL " & integer'image(temp) & "; expected " & integer'image(curlvl_x)
				severity error;
		end if;
		
		if selisra_x >= 0 then
			temp := to_integer(selisra);
			assert temp = selisra_x
				report   "wrong SELISRA " & integer'image(temp) & "; expected " & integer'image(selisra_x)
				severity error;
		end if;
	end procedure;

begin

	-- Unit Under Test
	UUT: entity checkirq
		port map (
			CLK      => clk,
			RESET    => reset,
			PCWRITE  => pcwrite,
			ENI      => eni,
			DEI      => dei,
			SWINTR   => swintr,
			XMEMINTR => xmemintr,
			XNAINTR  => xnaintr,
			XPERINTR => xperintr,
			RETI     => reti,
			RETILVL  => std_logic_vector(retilvl),
			INTR     => intr,
			CURLVL   => curlvl_slv,
			SELISRA  => selisra_slv
		);
		
	-- do type conversions
	curlvl  <= unsigned(curlvl_slv);
	selisra <= unsigned(selisra_slv);

	-- CLK Stimulus [50MHz]
	clk <= not clk after 10 ns;
	
	-- PCWRITE Stimulus
	pcwrite <= '1' after 40 ns when pcwrite = '0' else '0' after 20 ns; 
  
	-- Beschaltung der Eingänge und Beobachtung der Ausgänge
	test: process
	begin
  
-- RESET ------------------------------------------------------------------------------------------
	wait for  0 ns; reset <= '1', '0' after 15 ns;                                        --    0ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 0);                                    --   20ns
    
-- DEI + XMEMINTR (wird gelatched) ----------------------------------------------------------------
	wait for 20 ns; dei      <= '1'            , '0' after 40 ns;                         --   40ns
	                xmemintr <= '1' after 7 ns, '0' after 12 ns; 
	wait for 35 ns; prove(intr_x => 0);                                                   --  75ns
        
--  weitere parallele Interrupts (werden gelatched) -----------------------------------------------
	wait for  5 ns; xnaintr  <= '1' after 7 ns, '0' after 12 ns;                         --   80ns
	                swintr   <= '1' after 7 ns, '0' after 12 ns;   
	wait for 20 ns; prove(intr_x => 0);                                                   --  100ns
    
--  ENI => Auslösen des gelatchten XMEMINTR (4) sobald PCWRITE ------------------------------------
	wait for  0 ns; eni <= '1', '0' after 40 ns;                                          --  100ns
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 0);			                          --  115ns
	wait for 10 ns; prove(intr_x => 1, curlvl_x => 0, selisra_x => 4);                    --  125ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 4);					                  --  145ns
    
-- neuer XMEMINTR (wird gelatcht bis RETI) --------------------------------------------------------
	wait for  0 ns; xmemintr <= '1' after 2 ns, '0' after 7 ns;                           --  145ns
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 4);                                    --  160ns
    
--  RETI => Auslösen des gelatchten XMEMINTR (4) sobald PCWRITE -----------------------------------
	wait for  0 ns; reti <= '1', '0' after 40 ns;                                         --  160ns
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 4);                                    --  175ns
	wait for 10 ns; prove(intr_x => 1, curlvl_x => 4, selisra_x => 4);                    --  185ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 4);                                    --  205ns
    
--  RETI => Auslösen des gelatchten XNAINTR (3) sobald PCWRITE ------------------------------------
	wait for 15 ns; reti <= '1', '0' after 40 ns;                                         --  220ns
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 4);                                    --  235ns
	wait for 10 ns; prove(intr_x => 1, curlvl_x => 4, selisra_x => 3);                    --  245ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 3);                                    --  265ns
    
--  RETI => Auslösen des gelatchten SWINTR (1) sobald PCWRITE -------------------------------------
	wait for 15 ns; reti <= '1', '0' after 40 ns;                                         --  280ns
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 3);                                    --  295ns
	wait for 10 ns; prove(intr_x => 1, curlvl_x => 3, selisra_x => 1);                    --  305ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 1);                                    --  325ns
    
--  RETI => Level 0 ohne Auslösen eines INTR ------------------------------------------------------
	wait for 15 ns; reti <= '1', '0' after 40 ns;                                         --  340ns
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 1);                                    --  355ns
	wait for 10 ns; prove(intr_x => 0, curlvl_x => 1);                                    --  365ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 0);                                    --  385ns
    
--  XNAINTR => Auslösen sobald PCWRITE ------------------------------------------------------------
	wait for 20 ns; xnaintr <= '1' after 2 ns, '0' after  7 ns;                           --  405ns
	wait for 10 ns; prove(intr_x => 0, curlvl_x => 0);                                    --  415ns
	wait for 10 ns; prove(intr_x => 1, curlvl_x => 0, selisra_x => 3);                    --  425ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 3);                                    --  445ns
    
--  RETI auf Level 3 => keine Änderung ------------------------------------------------------------
	wait for 15 ns; reti    <= '1'  , '0'   after 40 ns;                                  --  460ns
	                retilvl <= "011", "000" after 40 ns; 
	wait for 25 ns; prove(intr_x => 0, curlvl_x => 3);                                    --  485ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 3);                                    --  505ns
    
--  SWINTR (wird gelatcht) ------------------------------------------------------------------------
	wait for 20 ns; swintr <= '1' after 2 ns, '0' after  7 ns;                             --  525ns
	wait for 10 ns; prove(intr_x => 0, curlvl_x => 3);                                     --  535ns
	wait for 10 ns; prove(intr_x => 0, curlvl_x => 3);                                     --  545ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 3);                                     --  565ns
    
--  RETI => Auslösen des gelatchten SWINTR (1) sobald PCWRITE -------------------------------------
	wait for 15 ns; reti <= '1', '0' after 40 ns;                                          --  580ns
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 3);                                     --  595ns
	wait for 10 ns; prove(intr_x => 1, curlvl_x => 3, selisra_x => 1);                     --  605ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 1);                                     --  625ns
    
--  RETI => Level 0 ohne Auslösen eines INTR ------------------------------------------------------
	wait for 15 ns; reti <= '1', '0' after 40 ns;                                          --  640ns
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 1);                                     --  655ns
	wait for 10 ns; prove(intr_x => 0, curlvl_x => 1);                                     --  665ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 0);                                     --  685ns
    
--  SWINT => Auslösen sobald PCWRITE ------------------------------------------------------------
    wait for 20 ns; swintr <= '1' after 2 ns, '0' after  7 ns;                             --  705ns
    wait for 10 ns; prove(intr_x => 0, curlvl_x => 0);                                     --  715ns
    wait for 10 ns; prove(intr_x => 1, curlvl_x => 0, selisra_x => 1);                     --  725ns
    wait for 20 ns; prove(intr_x => 0, curlvl_x => 1);                                     --  745ns
        
--  XNAINT => Auslösen sobald PCWRITE -------------------------------------------------------------
    wait for 20 ns; xnaintr <= '1' after 2 ns, '0' after  7 ns;                            --  765ns
    wait for 10 ns; prove(intr_x => 0, curlvl_x => 1);                                     --  775ns
    wait for 10 ns; prove(intr_x => 1, curlvl_x => 1, selisra_x => 3);                     --  785ns
    wait for 20 ns; prove(intr_x => 0, curlvl_x => 3);                                     --  805ns

--  XMEMINT => Auslösen sobald PCWRITE ------------------------------------------------------------
    wait for 20 ns; xmemintr <= '1' after 2 ns, '0' after  7 ns;                           --  825ns
    wait for 10 ns; prove(intr_x => 0, curlvl_x => 3);                                     --  835ns
    wait for 10 ns; prove(intr_x => 1, curlvl_x => 3, selisra_x => 4);                     --  845ns
    wait for 20 ns; prove(intr_x => 0, curlvl_x => 4);                                     --  865ns
    
--  SWINT => (wird gelatched) ---------------------------------------------------------------------
    wait for 20 ns; swintr <= '1' after 2 ns, '0' after  7 ns;                             --  885ns
    wait for 10 ns; prove(intr_x => 0, curlvl_x => 4);                                     --  895ns
    wait for 10 ns; prove(intr_x => 0, curlvl_x => 4);                                     --  905ns
    wait for 20 ns; prove(intr_x => 0, curlvl_x => 4);                                     --  925ns

--  asynchrones RESET -----------------------------------------------------------------------------
    wait for  0 ns; reset <= '1', '0' after 5 ns;                                          --  925ns
    wait for  5 ns; prove(intr_x => 0, curlvl_x => 0);                                     --  930ns
	wait for  55 ns;

--  XPERINT => Auslösen sobald PCWRITE ------------------------------------------------------------
    wait for 20 ns; xperintr <= '1';
    wait for 10 ns; prove(intr_x => 0, curlvl_x => 0);                                     -- 1015ns
    wait for 10 ns; prove(intr_x => 1, curlvl_x => 0, selisra_x => 2);                     -- 1025ns
    wait for 20 ns; prove(intr_x => 0, curlvl_x => 2);                                     -- 1045ns
	
--  XMEMINT => Auslösen sobald PCWRITE ------------------------------------------------------------
    wait for 20 ns; xmemintr <= '1' after 2 ns, '0' after  7 ns;
    wait for 10 ns; prove(intr_x => 0, curlvl_x => 2);                                     -- 1075ns
    wait for 10 ns; prove(intr_x => 1, curlvl_x => 2, selisra_x => 4);                     -- 1085ns
    wait for 20 ns; prove(intr_x => 0, curlvl_x => 4);                                     -- 1105ns
    
--  RETI => Level 2 ohne Auslösen eines INTR ------------------------------------------------------
	wait for 15 ns; reti <= '1', '0' after 40 ns; 
	                retilvl <= "010", "000" after 40 ns;
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 4);                                     -- 1135ns
	wait for 10 ns; prove(intr_x => 0, curlvl_x => 4);                                     -- 1145ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 2);                                     -- 1165ns
	
--  RETI => erneutes Auslösen von XPERINTR (2) sobald PCWRITE -------------------------------------
	wait for 15 ns; reti <= '1', '0' after 40 ns;
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 2);                                     -- 1195ns
	wait for 10 ns; prove(intr_x => 1, curlvl_x => 2, selisra_x => 2);                     -- 1205ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 2);                                     -- 1225ns
	
--  RETI => Level 0 ohne Auslösen eines INTR ------------------------------------------------------
	wait for 15 ns; reti <= '1', '0' after 40 ns;
	                xperintr <= '0';
	wait for 15 ns; prove(intr_x => 0, curlvl_x => 2);                                     -- 1255ns
	wait for 10 ns; prove(intr_x => 0, curlvl_x => 2);                                     -- 1265ns
	wait for 20 ns; prove(intr_x => 0, curlvl_x => 0);                                     -- 1285ns
	
	report "!!!TEST DONE !!!"
		severity NOTE;
    wait;
  end process;                        
  
end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
