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
	
entity alu is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- control inputs
		opcode		: in  std_logic_vector(4 downto 0);
		regwrite	: in  std_logic;
		
		-- data input
		achannel	: in  std_logic_vector(31 downto 0);
		bchannel	: in  std_logic_vector(31 downto 0);
		
		-- result
		result		: out std_logic_vector(31 downto 0);
		zero		: out std_logic;
		overflow	: out std_logic
	);
end alu;

architecture rtl of alu is
begin
end rtl;
