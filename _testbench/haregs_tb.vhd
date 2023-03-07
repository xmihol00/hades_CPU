---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the register file
-- autor:    Andreas Engel
-- date:    25.07.07
-- runtime: 400ns
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
entity haregs_tb is
end haregs_tb;
---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of haregs_tb is
	
	-- Stimulie
	signal clk, reset, regwrite   : std_logic   :=  '0';
	signal aopadr, bopadr, wopadr : t_haregsAdr :=  "000";
	signal wop                    : t_word      := x"00000000";
	
	-- beobachtete Signale
	signal aop, bop : t_word;	
	
	-- Beobachtungsprozedur
	procedure prove(a, b: t_word := (others => 'U')) is
	begin
		if a(a'left)/='U' then
      assert aop = a 
      report "wrong AOP 0x" & to_hex(aop) & "; expected 0x" & to_hex(a)  
      severity error;
    end if;
    
    if b(b'left)/='U' then
      assert bop = b 
      report "wrong BOP 0x" & to_hex(bop) & "; expected 0x" & to_hex(b)  
      severity error;
    end if;    
  end;

begin

	-- Unit Under Test
	UUT: entity haregs
		port map (
			CLK      => clk,
			RESET    => reset,
			AOPADR   => std_logic_vector(aopadr),
			BOPADR   => std_logic_vector(bopadr),
			WOPADR   => std_logic_vector(wopadr),
			WOP      => wop,
			REGWRITE => regwrite,
			AOP      => aop,
			BOP      => bop
		);

  -- CLK Stimulus [50MHz]
  clk      <= not clk after  10 ns;
  
   -- RESET Stimulus
  reset    <= '1',
              '0'     after  5 ns,
              '1'     after 355 ns,
              '0'     after 370 ns;          
  
  -- REGWRITE Stimulus              
  regwrite <= '0',
              '1'     after   5 ns,
              '0'     after  185 ns;
    
  -- Beschaltung der Eingänge und Beobachtung der Ausgänge
  test: process
  begin       
  
    wait for  7 ns; aopadr <= "001"; bopadr <= "011"; wopadr <= "000"; wop <= x"A0000000"; --   7ns
    wait for  2 ns; prove(x"00000000", x"00000000");                                       --   9ns
    wait for  6 ns; prove(x"00000000", x"00000000");                                       --  15ns  
         
    wait for 10 ns; aopadr <= "001"; bopadr <= "011"; wopadr <= "001"; wop <= x"0B000000"; --  25ns
    wait for  3 ns; prove(a => x"00000000");                                               --  28ns
    wait for  7 ns; prove(x"0B000000", x"00000000");                                       --  35ns
    
    wait for 10 ns; aopadr <= "001"; bopadr <= "010"; wopadr <= "010"; wop <= x"00C00000"; --  45ns
    wait for  3 ns; prove(b => x"00000000");                                               --  48ns
    wait for  5 ns; prove(x"0B000000", x"00C00000");                                       --  53ns
    wait for  2 ns; aopadr <= "011"; bopadr <= "111";                                      --  55ns 
    wait for  3 ns; prove(x"00000000", x"00000000");                                       --  58ns   
     
    wait for  7 ns; aopadr <= "001"; bopadr <= "011"; wopadr <= "011"; wop <= x"000D0000"; --  65ns
    wait for  3 ns; prove(b => x"00000000");                                               --  68ns
    wait for  7 ns; prove(x"0B000000", x"000D0000");                                       --  75ns
     
    wait for 10 ns; aopadr <= "010"; bopadr <= "100"; wopadr <= "100"; wop <= x"0000E000"; --  85ns
    wait for  3 ns; prove(b => x"00000000");                                               --  88ns
    wait for  7 ns; prove(x"00C00000", x"0000E000");                                       --  95ns
     
    wait for 10 ns; aopadr <= "101"; bopadr <= "001"; wopadr <= "101"; wop <= x"00000F00"; -- 105ns
    wait for  3 ns; prove(a => x"00000000");                                               -- 108ns
    wait for  5 ns; prove(x"00000F00", x"0B000000");                                       -- 113ns
    wait for  2 ns; aopadr <= "010"; bopadr <= "011";                                      -- 115ns
    wait for  3 ns; prove(x"00C00000", x"000D0000");                                       -- 118ns
     
    wait for  7 ns; aopadr <= "100"; bopadr <= "110"; wopadr <= "110"; wop <= x"00000090"; -- 125ns
    wait for  3 ns; prove(b => x"00000000");                                               -- 128ns
    wait for  7 ns; prove(x"0000E000", x"00000090");                                       -- 135ns
                                                                                             
    wait for 10 ns; aopadr <= "111"; bopadr <= "010"; wopadr <= "111"; wop <= x"00000005"; -- 145ns
    wait for  3 ns; prove(a => x"00000000");                                               -- 148ns
    wait for  7 ns; prove(x"00000005", x"00C00000");                                       -- 155ns
     
    wait for 10 ns; aopadr <= "001"; bopadr <= "001"; wopadr <= "001"; wop <= x"00000005"; -- 165ns
    wait for  3 ns; prove(x"0B000000", x"0B000000");                                       -- 168ns
    wait for  7 ns; prove(x"00000005", x"00000005");                                       -- 175ns
                                                                                           
                                                                                          
    -- 185ns Regwrite <= 0
                                                                                           
    wait for 12 ns; aopadr <= "001"; bopadr <= "001"; wopadr <= "001"; wop <= x"12345678"; -- 187ns
    wait for  5 ns; prove(x"00000005", x"00000005");                                       -- 192ns
    wait for 10 ns; prove(x"00000005", x"00000005");                                       -- 202ns
     
    wait for  3 ns; aopadr <= "001"; bopadr <= "010"; wopadr <= "010"; wop <= x"12345678"; -- 205ns
    wait for  7 ns; prove(x"00000005", x"00C00000");                                       -- 212ns
    wait for 10 ns; prove(x"00000005", x"00C00000");                                       -- 222ns
    wait for  2 ns; aopadr <= "010"; bopadr <= "011";                                      -- 224ns
    wait for  2 ns; prove(x"00C00000", x"000D0000");                                       -- 226ns
          
    wait for  2 ns; aopadr <= "001"; bopadr <= "011"; wopadr <= "011"; wop <= x"12345678"; -- 228ns
    wait for  4 ns; prove(x"00000005", x"000D0000");                                       -- 232ns
    wait for 10 ns; prove(x"00000005", x"000D0000");                                       -- 242ns
     
    wait for  3 ns; aopadr <= "100"; bopadr <= "010"; wopadr <= "100"; wop <= x"12345678"; -- 245ns
    wait for  7 ns; prove(x"0000E000", x"00C00000");                                       -- 252ns
    wait for 10 ns; prove(x"0000E000", x"00C00000");                                       -- 262ns
     
    wait for  3 ns; aopadr <= "110"; bopadr <= "101"; wopadr <= "101"; wop <= x"12345678"; -- 265ns
    wait for  7 ns; prove(x"00000090", x"00000F00");                                       -- 272ns
    wait for 10 ns; prove(x"00000090", x"00000F00");                                       -- 282ns
       
    wait for  3 ns; aopadr <= "111"; bopadr <= "110"; wopadr <= "110"; wop <= x"12345678"; -- 285ns
    wait for  7 ns; prove(x"00000005", x"00000090");                                       -- 292ns
    wait for 10 ns; prove(x"00000005", x"00000090");                                       -- 302ns
    wait for  2 ns; aopadr <= "101"; bopadr <= "010";                                      -- 304ns
    wait for  2 ns; prove(x"00000F00", x"00C00000");                                       -- 306ns 
    
    wait for  2 ns; aopadr <= "000"; bopadr <= "000"; wopadr <= "000"; wop <= x"12345678"; -- 308ns
    wait for  4 ns; prove(x"00000000", x"00000000");                                       -- 312ns
    wait for 10 ns; prove(x"00000000", x"00000000");                                       -- 322ns
     
    wait for  3 ns; aopadr <= "010"; bopadr <= "111"; wopadr <= "111"; wop <= x"12345678"; -- 325ns
    wait for  7 ns; prove(x"00C00000", x"00000005");                                       -- 332ns
    wait for 10 ns; prove(x"00C00000", x"00000005");                                       -- 342ns
    
    
    wait for 10 ns; prove(x"00C00000", x"00000005");                                       -- 352ns
    
     -- 355ns Reset <= 1
    
    wait for  10 ns; prove(x"00000000", x"00000000");                                      -- 362ns
	
	report "!!!TEST DONE !!!"
		severity NOTE;
	
    wait;
  end process;
             
end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
