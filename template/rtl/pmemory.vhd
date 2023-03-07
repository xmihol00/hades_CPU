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

entity pmemory is
	generic (
		INIT		: string := "UNUSED"
	);
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- write port
		pwrite		: in  std_logic;
		wadr		: in  std_logic_vector(11 downto 0);
		datain		: in  std_logic_vector(31 downto 0);
		
		-- read port
		loadir		: in  std_logic;
		radr		: in  std_logic_vector(11 downto 0);
		dataout		: out std_logic_vector(31 downto 0)
	);
end pmemory;

architecture rtl of pmemory is	
begin
end rtl;
