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
	
entity isralogic is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- address input
		pcwrite		: in  std_logic;
		sisa		: in  std_logic;
		sisalvl		: in  std_logic_vector(1 downto 0);
		pcnew		: in  std_logic_vector(11 downto 0);
		
		selisra		: in  std_logic_vector(2 downto 0);
		
		-- address output
		isra		: out std_logic_vector(11 downto 0)
	);
end isralogic;

architecture rtl of isralogic is
begin
end rtl;
