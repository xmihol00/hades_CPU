---------------------------------------------------------------------------------------------------
--
-- Titel: Program Counter logic
-- Autor: David Mihola (12211951)
-- Datum: 26. 03. 2023
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
	-- instruction: JREG JAL RETI BOV BEQZ BNEZ
    -- pccontr:        5   4    3   2    1    0

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

	inner_pcinc <= std_logic_vector(unsigned(pc_reg) + 1); -- increment PC by 1

	pcmux <= isrr when pccontr(3) = '1' else -- RETI - return from subroutine
	         pcnew when -- jump in the program happens
			 			(pccontr(0) = '1' and zero = '0') or -- branch when not zero
			 			(pccontr(1) = '1' and zero = '1') or -- branch when zero
			 			(pccontr(2) = '1' and ov = '1') or   -- branch when overflow
	                    (pccontr(4) = '1') or				 -- JAL  - subroutine call
	                    (pccontr(5) = '1') else				 -- JREG - jump to absolute address
			 inner_pcinc;									 -- other intructions, increment PC by 1
	
	irqmux <= isra when intr = '1' else
	          pcmux;
	
	pcakt  <= pc_reg;
	pcinc  <= inner_pcinc;
	pcnext <= pcmux;
end rtl;
