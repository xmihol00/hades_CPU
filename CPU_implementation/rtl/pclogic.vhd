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
	signal pcmux	: std_logic_vector(11 downto 0);
	signal irqmux	: std_logic_vector(11 downto 0);
	signal pc_reg 	: std_logic_vector(11 downto 0);
	signal inner_pcinc 	: std_logic_vector(11 downto 0);
begin

	process (clk, reset) is
	begin
		if reset = '1' then
			pc_reg <= (others => '0');
		elsif rising_edge(clk) then
			if pcwrite = '1' then
				pc_reg <= irqmux;
			end if;
		end if;
	end process;

	inner_pcinc <= std_logic_vector(unsigned(pc_reg) + 1);

	pcmux <= isrr when pccontr(3) = '1' else
	         pcnew when 
			 			(pccontr(0) = '1' and zero = '0') or
			 			(pccontr(1) = '1' and zero = '1') or
			 			(pccontr(2) = '1' and ov = '1') or
	                    (pccontr(4) = '1') or
	                    (pccontr(5) = '1') else
			 inner_pcinc;
	
	irqmux <= isra when intr = '1' else
	          pcmux;
	
	pcakt <= pc_reg;
	pcinc <= inner_pcinc;
	pcnext <= pcmux;

end rtl;
