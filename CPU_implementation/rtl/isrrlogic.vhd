---------------------------------------------------------------------------------------------------
--
-- Titel: ISRR logic
-- Autor: David Mihola (12211951)
-- Datum: 25. 03. 2023
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity isrrlogic is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- control & address input
		pcwrite		: in  std_logic;
		intr		: in  std_logic;
		reti		: in  std_logic;
		pcnext		: in  std_logic_vector(11 downto 0);
		curlvl		: in  std_logic_vector(2 downto 0);
		
		-- address output
		retilvl		: out std_logic_vector(2 downto 0);
		isrr		: out std_logic_vector(11 downto 0)
	);
end isrrlogic;

architecture rtl of isrrlogic is
	-- registers for the interrupt service routine return address and the return interrupt level
	signal issr1_reg	: std_logic_vector(14 downto 0);
	signal issr2_reg	: std_logic_vector(14 downto 0);
	signal issr3_reg	: std_logic_vector(14 downto 0);
	signal issr4_reg	: std_logic_vector(14 downto 0);

	signal issr1_mux 	: std_logic_vector(14 downto 0);
	signal issr2_mux 	: std_logic_vector(14 downto 0);
	signal issr3_mux 	: std_logic_vector(14 downto 0);
	signal issr4_mux 	: std_logic_vector(14 downto 0);

	signal shift	    : std_logic;
begin
	process(clk, reset) is
	begin
		if reset = '1' then
			-- reset the registers to adress 0xFFE, where there is an infinite loop
			issr1_reg <= "000" & x"FFE";
			issr2_reg <= "000" & x"FFE";
			issr3_reg <= "000" & x"FFE";
			issr4_reg <= "000" & x"FFE";
		elsif rising_edge(clk) then
			if shift = '1' then
				issr1_reg <= issr1_mux;
				issr2_reg <= issr2_mux;
				issr3_reg <= issr3_mux;
				issr4_reg <= issr4_mux;
			end if;
		end if;
	end process;

	-- shift the registers when an interrupt occures or RETI is executed but not both together
	shift <= '1' when pcwrite = '1' and (intr xor reti) = '1' else '0';

	issr1_mux <= curlvl & pcnext when reti = '0' else issr2_reg;
	issr2_mux <= issr1_reg when reti = '0' else issr3_reg;
	issr3_mux <= issr2_reg when reti = '0' else issr4_reg;
	issr4_mux <= issr3_reg when reti = '0' else "000" & x"FFE";

	isrr <= issr1_reg(11 downto 0);
	retilvl <= issr1_reg(14 downto 12);
end rtl;
