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
	use work.all;
	use work.hadescomponents.all;
	
entity irqlogic is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- interrupt inputs
		xperintr	: in  std_logic;
		xnaintr		: in  std_logic;
		xmemintr	: in  std_logic;
		
		-- control input
		pcwrite		: in  std_logic;
		pccontr		: in  std_logic_vector(4 downto 0);
		pcnext		: in  std_logic_vector(11 downto 0);
		pcnew		: in  std_logic_vector(11 downto 0);
		sisalvl		: in  std_logic_vector(1 downto 0);
		
		-- control output
		intr		: out std_logic;
		isra		: out std_logic_vector(11 downto 0);
		isrr		: out std_logic_vector(11 downto 0)
	);
end irqlogic;

architecture rtl of irqlogic is
begin
end rtl;
