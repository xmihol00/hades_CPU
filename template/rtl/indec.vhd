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
	
entity indec is
	port (
		-- instruction word input
		iword		: in  std_logic_vector(31 downto 0);
		
		-- register addresses
		aopadr		: out std_logic_vector(2 downto 0);
		bopadr		: out std_logic_vector(2 downto 0);
		wopadr		: out std_logic_vector(2 downto 0);
		
		-- immediate value
		ivalid		: out std_logic;
		iop			: out std_logic_vector(15 downto 0);
		
		-- control flags
		opc			: out std_logic_vector(4 downto 0);
		pccontr		: out std_logic_vector(10 downto 0);
		inop		: out std_logic;
		outop		: out std_logic;
		loadop		: out std_logic;
		storeop		: out std_logic;
		dmemop		: out std_logic;
		selxres		: out std_logic;
		dpma		: out std_logic;
		epma		: out std_logic
	);
end indec;

architecture rtl of indec is
begin
end rtl;
