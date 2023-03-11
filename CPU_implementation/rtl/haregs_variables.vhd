---------------------------------------------------------------------------------------------------
--
-- Titel: Register File   
-- Autor: David Mihola (12211951)
-- Datum: 11. 03. 2023
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity haregs is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- write port
		regwrite	: in  std_logic;
		wopadr		: in  std_logic_vector(2 downto 0);
		wop			: in  std_logic_vector(31 downto 0);
		
		-- read port A
		aopadr		: in  std_logic_vector(2 downto 0);
		aop			: out std_logic_vector(31 downto 0);
		
		-- read port B
		bopadr		: in  std_logic_vector(2 downto 0);
		bop			: out std_logic_vector(31 downto 0)
	);
end haregs;

architecture rtl of haregs is
	constant r0_idx : integer := 0; -- Index of the fisrt register that cannot be written and always returns 0.
begin
	-- Single process enables use of variables as registers.
	process(clk, reset, regwrite, wopadr, aopadr, bopadr) is
		type RegisterFile_t is array(0 to 7) of std_logic_vector(31 downto 0); -- register file of 8 32-bit registers
		variable registers : RegisterFile_t;
	begin
		if reset = '1' then -- reset values of registers to 0
			for i in registers'range loop
				registers(i) := (others => '0');
			end loop;
		elsif rising_edge(clk) and regwrite = '1' then -- synchronously write a supplied value to a given valid register
			registers(to_integer(unsigned(wopadr))) := wop;
			registers(r0_idx) := (others => '0'); -- make sure r0 is always 0
		end if;

		aop <= registers(to_integer(unsigned(aopadr))); -- output A
		bop <= registers(to_integer(unsigned(bopadr))); -- output B
	end process;
end rtl;

