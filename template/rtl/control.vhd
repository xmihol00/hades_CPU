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
	
entity control is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- control inputs
		inop		: in  std_logic;
		outop		: in  std_logic;
		loadop		: in  std_logic;
		storeop		: in  std_logic;
		dpma		: in  std_logic;
		epma		: in  std_logic;
		xack		: in  std_logic;
		xpresent	: in  std_logic;
		dmembusy	: in  std_logic;
		
		-- control outputs
		loadir		: out std_logic;
		regwrite	: out std_logic;
		pcwrite		: out std_logic;
		pwrite		: out std_logic;
		xread		: out std_logic;
		xwrite		: out std_logic;
		xnaintr		: out std_logic
	);
end control;

architecture rtl of control is	
begin
end rtl;
