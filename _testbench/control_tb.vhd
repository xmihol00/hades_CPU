---------------------------------------------------------------------------------------------------
--
-- titel:    TestBench for the control
-- autor:    Andreas Engel
-- date:    27.07.07
-- runtime: 1650ns
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
entity control_tb is
end control_tb;
---------------------------------------------------------------------------------------------------


-- Architecture:
architecture TB_ARCHITECTURE of control_tb is

	-- Stimulie	
	signal clk, reset, 
         inop, outop, loadop, storeop, 
         dpma, epma, 
         xack, xpresent, dmembusy     : std_logic := '0';
	
	-- beobachtete Signale
	signal loadir, xread, xwrite, pwrite, xnaintr, pcwrite, regwrite : std_logic;
	
	-- Beobachtungsprozedur (inkusive 1 Takt Wartezeit)
	procedure prove(v : in std_logic_vector(6 downto 0)) is
	begin	
		wait for 20 ns;											
		assert v(6)=loadir   report "wrong LOADIR;   expected " & std_logic'image(v(6)) severity error;
		assert v(5)=xread    report "wrong XREAD;    expected " & std_logic'image(v(5)) severity error;
		assert v(4)=xwrite   report "wrong XWRITE;   expected " & std_logic'image(v(4)) severity error;
		assert v(3)=pwrite   report "wrong PWRITE;   expected " & std_logic'image(v(3)) severity error;
		assert v(2)=xnaintr  report "wrong XNAINT;   expected " & std_logic'image(v(2)) severity error;
		assert v(1)=pcwrite  report "wrong PCWRITE;  expected " & std_logic'image(v(1)) severity error;
		assert v(0)=regwrite report "wrong REGWRITE; expected " & std_logic'image(v(0)) severity error;
	end;
	
	-- Prozedur zum Rücksetzen von Signalen
		procedure clear(signal a: out std_logic) is 
			begin a <= '0';
		end procedure;  
		procedure clear(signal a, b: out std_logic) is 
			begin a <= '0'; b <= '0'; 
		end procedure;
		procedure clear(signal a, b, c: out std_logic) is 
			begin a <= '0'; b <= '0'; c <= '0';
		end procedure;
		 
begin
   
	-- Unit Under Test
	UUT: entity control
		port map (
			INOP     => inop,
			OUTOP    => outop,
			LOADOP   => loadop,
			STOREOP  => storeop,
			DPMA     => dpma,
			EPMA     => epma,
			XACK     => xack,
			XPRESENT => xpresent,
			DMEMBUSY => dmembusy,
			CLK      => clk,
			RESET    => reset,
			LOADIR   => loadir,
			REGWRITE => regwrite,
			PCWRITE  => pcwrite,
			PWRITE   => pwrite,
			XREAD    => xread,
			XWRITE   => xwrite,
			XNAINTR  => xnaintr
		);

	-- CLK Stimulus [50MHz]
	clk <= not clk after 10 ns;
	
	-- RESET Stimulus 
	reset <= '1', '0' after 15 ns;
	
	-- Beschaltung der Eingänge und Beobachtung der Ausgänge
	test: process
	begin
  
--   20- 80ns: DPMA (normaler ALU Zyklus) --------------------------------------------------------
-- Dieser Befehl mit Beispielwerten zum Überprüfen der Signalwerte der Ausgänge  
		prove("1000000");                                                                 -- IFETCH
		prove("0000000"); dpma <= '1';                                                    -- IDECODE
		prove("0000000");                                                                 -- ALU
		prove("0000011");                                                                 -- WRITEBACK
		clear(dpma);	
	  

--  100- 160ns: ALU -------------------------------------------------------------------------------
-- Ab hier sind die Signalwerte, auf die die Ausgänge überprüft werden sollen, entsprechend zu setzen
		prove("1000000");                                                                 -- IFETCH 	
		prove("0000000");                                                                 -- IDECODE	
		prove("0000000");                                                                 -- ALU      
		prove("0000011");                                                                 -- WRITEBACK
	
--  180- 280ns: STORE (ohne PMA mit DMEMBUSY) -----------------------------------------------------
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); storeop <= '1';                                                 -- IDECODE	
		prove("0000000");                                                                 -- ALU      
		prove("0010000"); dmembusy <= '1';                                                -- MEMWRITE 
		prove("0010000"); dmembusy <= '0';                                                -- MEMWRITE	
		prove("0000011");                                                                 -- WRITEBACK
		clear(storeop, dmembusy);
	  
--  300- 380ns: STORE (ohne PMA ohne DMEMBUSY) ----------------------------------------------------
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); storeop <= '1';                                                 -- IDECODE	
		prove("0000000");                                                                 -- ALU      
		prove("0010000");                                                                 -- MEMWRITE
		prove("0000011");                                                                 -- WRITEBACK
		clear(storeop);	  
	  
--  400- 460ns: EPMA ------------------------------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); epma <= '1';                                                    -- IDECODE	
		prove("0000000");                                                                 -- ALU    
		prove("0000011");                                                                 -- WRITEBACK
		clear(epma);	
	  
--  480-560ns: STORE (mit PMA ohne DMEMBUSY) ----------------------------------------------------- 
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); storeop <= '1';                                                 -- IDECODE
		prove("0000000");                                                                 -- ALU      
		prove("0001000");                                                                 -- MEMWRITE 
		prove("0000011");                                                                 -- WRITEBACK
		clear(storeop);	
	  
--  580-660ns: STORE (mit PMA mit DMEMBUSY) ------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); storeop <= '1';                                                 -- IDECODE
		prove("0000000");                                                                 -- ALU      
		prove("0001000"); dmembusy <= '1';                                                -- MEMWRITE 	
		prove("0000011");                                                                 -- WRITEBACK
		clear(storeop, dmembusy);
    
--  680-740ns: DPMA ------------------------------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH
		prove("0000000"); dpma <= '1';                                                    -- IDECODE
		prove("0000000");                                                                 -- ALU    
		prove("0000011");                                                                 -- WRITEBACK
		clear(dpma);	
	
	  
--  760-840ns: OUT (mit Interrupt) ---------------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); outop <= '1';                                                   -- IDECODE	
		prove("0000000");                                                                 -- ALU    
		prove("0010000");                                                                 -- IOWRITE
		prove("0000110");                                                                 -- XBUSNAINTR
		clear(outop);
	  
--  860-960ns: OUT (mit Wartezyklus) -------------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); outop <= '1';                                                   -- IDECODE
		prove("0000000");                                                                 -- ALU    	
		prove("0010000"); xpresent <='1';                                                 -- IOWRITE	
		prove("0010000"); xack <= '1';                                                    -- IOWRITE
		prove("0000011");                                                                 -- WRITEBACK
		clear(outop, xpresent, xack);
	  
--  980-1060ns: OUT (ohne Wartezyklus) ------------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); outop <= '1';                                                   -- IDECODE
		prove("0000000");                                                                 -- ALU    	
		prove("0010000"); xpresent <= '1'; xack <= '1';                                   -- IOWRITE
		prove("0000011");                                                                 -- WRITEBACK
		clear(outop, xpresent, xack);
	  
-- 1080-1160ns: IN (mit Interrupt) ----------------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH
		prove("0000000"); inop <= '1';                                                    -- IDECODE
		prove("0000000");                                                                 -- ALU
		prove("0100000");                                                                 -- IOREAD
		prove("0000110");                                                                 -- XBUSNAINTR
		clear(inop);
	  
-- 1180-1280ns: IN (mit Wartezyklus) --------------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH
		prove("0000000"); inop <= '1';                                                    -- IDECODE
		prove("0000000");                                                                 -- ALU    	
		prove("0100000"); xpresent <='1';                                                 -- IOREAD
		prove("0100000"); xack <= '1';                                                    -- IOREAD
		prove("0000011");                                                                 -- WRITEBACK
		clear(inop, xpresent, xack);
	  
-- 1300-1380ns: IN (ohne Wartezyklus) -------------------------------------------------------------	
		prove("1000000");                                                                 -- IFETCH
		prove("0000000"); inop <= '1';                                                    -- IDECODE
		prove("0000000");                                                                 -- ALU 	
		prove("0100000"); xpresent <='1'; xack <= '1';                                    -- IOREAD
		prove("0000011");                                                                 -- WRITEBACK
		clear(inop, xpresent, xack);
	  
-- 1400-1500ns: LOAD (mit DMEMBUSY) ---------------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); loadop <= '1';                                                  -- IDECODE	
		prove("0000000");                                                                 -- ALU    
		prove("0100000"); dmembusy <= '1';                                                -- MEMREAD
		prove("0100000"); dmembusy <= '0';                                                -- MEMREAD
		prove("0000011");                                                                 -- WRITEBACK
		clear(loadop, dmembusy);	  
	  
-- 1520-1600ns: LOAD (ohne DMEMBUSY) --------------------------------------------------------------
		prove("1000000");                                                                 -- IFETCH 
		prove("0000000"); loadop <= '1';                                                  -- IDECODE	
		prove("0000000");                                                                 -- ALU    
		prove("0100000");                                                                 -- MEMREAD
		prove("0000011");                                                                 -- WRITEBACK
		clear(loadop);	  

		report "!!!TEST DONE !!!"
			severity NOTE;
		wait;	
  end process;
	
end TB_ARCHITECTURE;
---------------------------------------------------------------------------------------------------
