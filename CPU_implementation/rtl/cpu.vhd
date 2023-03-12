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
	
entity cpu is
	generic (
		INIT		: string := "UNUSED"
	);
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- XBus
		xread		: out std_logic;
		xwrite		: out std_logic;
		xadr		: out std_logic_vector(12 downto 0);
		xdatain		: in  std_logic_vector(31 downto 0);
		xdataout	: out std_logic_vector(31 downto 0);
		xpresent	: in  std_logic;
		xack		: in  std_logic;
		dmemop		: out std_logic;
		dmembusy	: in  std_logic;
		xperintr	: in  std_logic;
		xmemintr	: in  std_logic
	);
end cpu;

architecture rtl of cpu is
begin
end rtl;
