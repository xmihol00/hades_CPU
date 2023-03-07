---------------------------------------------------------------------------------------------------
--
-- Titel:    
-- Autor:    
-- Datum:    
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity isrrlogic is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- control & address input
		pcwrite		: in  std_logic;
		intr		: in  std_logic;
		reti		: in  std_logic;
		pcnext		: in  std_logic_vector(11 downto 0);
		curlvl		: in  std_logic_vector(2 downto 0);
		
		-- address output
		retilvl		: out std_logic_vector(2 downto 0);
		isrr		: out std_logic_vector(11 downto 0)
	);
end isrrlogic;

architecture rtl of isrrlogic is
begin
end rtl;
