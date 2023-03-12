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
	
entity checkirq is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- interrupt inputs
		xperintr	: in  std_logic;
		xnaintr		: in  std_logic;
		xmemintr	: in  std_logic;
		
		-- control input
		swintr		: in  std_logic;
		pcwrite		: in  std_logic;
		eni			: in  std_logic;
		dei			: in  std_logic;
		reti		: in  std_logic;
		retilvl		: in  std_logic_vector(2 downto 0);
		
		-- control output
		curlvl		: out std_logic_vector(2 downto 0);
		selisra		: out std_logic_vector(2 downto 0);
		intr		: out std_logic
	);
end checkirq;

architecture rtl of checkirq is
begin
end rtl;
