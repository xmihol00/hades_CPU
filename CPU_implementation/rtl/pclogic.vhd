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
	
entity pclogic is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- control flags
		pcwrite		: in  std_logic;
		pccontr		: in  std_logic_vector(5 downto 0);
		ov			: in  std_logic;
		zero		: in  std_logic;
		intr		: in  std_logic;
		
		-- program counter inputs
		pcnew		: in  std_logic_vector(11 downto 0);
		isra		: in  std_logic_vector(11 downto 0);
		isrr		: in  std_logic_vector(11 downto 0);

		-- program counter outputs
		pcakt		: out std_logic_vector(11 downto 0);
		pcinc		: out std_logic_vector(11 downto 0);
		pcnext		: out std_logic_vector(11 downto 0)
	);
end pclogic;

architecture rtl of pclogic is
begin
end rtl;
