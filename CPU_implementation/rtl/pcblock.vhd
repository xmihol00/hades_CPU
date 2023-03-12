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
	
entity pcblock is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- interrupt inputs
		xperintr	: in  std_logic;
		xnaintr		: in  std_logic;
		xmemintr	: in  std_logic;
		
		-- ALU flags
		ov			: in  std_logic;
		zero		: in  std_logic;
		
		-- control input
		pcwrite		: in  std_logic;
		pccontr		: in  std_logic_vector(10 downto 0);
		pcnew		: in  std_logic_vector(11 downto 0);
		sisalvl     : in  std_logic_vector(1 downto 0);

		-- control output
		pcakt		: out std_logic_vector(11 downto 0);
		pcinc		: out std_logic_vector(11 downto 0)
	);
end pcblock;

architecture rtl of pcblock is
begin
end rtl;
