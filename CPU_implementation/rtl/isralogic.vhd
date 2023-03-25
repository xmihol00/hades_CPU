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
	
entity isralogic is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- address input
		pcwrite		: in  std_logic;
		sisa		: in  std_logic;
		sisalvl		: in  std_logic_vector(1 downto 0);
		pcnew		: in  std_logic_vector(11 downto 0);
		
		selisra		: in  std_logic_vector(2 downto 0);
		
		-- address output
		isra		: out std_logic_vector(11 downto 0)
	);
end isralogic;

architecture rtl of isralogic is
	signal isra1_reg	: std_logic_vector(11 downto 0);
	signal isra2_reg	: std_logic_vector(11 downto 0);
	signal isra3_reg	: std_logic_vector(11 downto 0);
	signal isra4_reg	: std_logic_vector(11 downto 0);

	signal isra1_write	: std_logic;
	signal isra2_write	: std_logic;
	signal isra3_write	: std_logic;
	signal isra4_write	: std_logic;
begin
	process(clk, reset) is
	begin
		if reset = '1' then
			isra1_reg <= x"FFF";
			isra2_reg <= x"FFF";
			isra3_reg <= x"FFF";
			isra4_reg <= x"FFF";
		elsif rising_edge(clk) then
			if isra1_write = '1' then
				isra1_reg <= pcnew;
			end if;
			
			if isra2_write = '1' then
				isra2_reg <= pcnew;
			end if;
			
			if isra3_write = '1' then
				isra3_reg <= pcnew;
			end if;
			
			if isra4_write = '1' then
				isra4_reg <= pcnew;
			end if;
		end if;
	end process;

	isra1_write <= '1' when pcwrite = '1' and sisa = '1' and (sisalvl = "00") else 
				   '0';
	isra2_write <= '1' when pcwrite = '1' and sisa = '1' and (sisalvl = "01") else 
				   '0';
	isra3_write <= '1' when pcwrite = '1' and sisa = '1' and (sisalvl = "10") else 
				   '0';
	isra4_write <= '1' when pcwrite = '1' and sisa = '1' and (sisalvl = "11") else 
				   '0';

	isra <= isra1_reg when selisra = "001" else
			isra2_reg when selisra = "010" else
			isra3_reg when selisra = "011" else
			isra4_reg when selisra = "100" else
			(others => '0');
end rtl;
