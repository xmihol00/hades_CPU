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
library xbus_common;
	use xbus_common.xtoolbox.all;
library work;
	use work.all;
	use work.hadescomponents.all;
	
entity datapath is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- control
		opc			: in  std_logic_vector(4 downto 0);
		regwrite	: in  std_logic;
		
		-- input data
		aop			: in  std_logic_vector(31 downto 0);
		bop			: in  std_logic_vector(31 downto 0);
		iop			: in  std_logic_vector(15 downto 0);
		ivalid		: in  std_logic;
		
		-- output data
		wop			: out std_logic_vector(31 downto 0);
		
		-- XBus
		selxres		: in  std_logic;
		xdatain		: in  std_logic_vector(31 downto 0);
		xdataout	: out std_logic_vector(31 downto 0);
		xadr		: out std_logic_vector(12 downto 0);
		
		-- status flags
		zero		: out std_logic;
		ov			: out std_logic;
		
		-- program counter
		jal			: in  std_logic;
		rela		: in  std_logic;
		pcinc		: in  std_logic_vector(11 downto 0);
		pcnew		: out std_logic_vector(11 downto 0);
		sisalvl     : out std_logic_vector(1 downto 0)
	);
end datapath;

architecture rtl of datapath is			
begin
end rtl;
