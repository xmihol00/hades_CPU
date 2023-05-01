---------------------------------------------------------------------------------------------------
--
-- Titel: Register File (implementation from 'haregs_8regs.vhd')
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
	type RegisterFile_t is array(7 downto 1) of std_logic_vector(31 downto 0); -- register file of 8 32-bit registers
	signal registers : RegisterFile_t;
begin
	-- All writes to registers must be in a single process, otherwise the value inside registers will be undefined.
	process(clk, reset) is
	begin
		if reset = '1' then -- reset values of registers to 0
			for i in registers'range loop
				registers(i) <= (others => '0');
			end loop;
		elsif rising_edge(clk) then
			if regwrite = '1' and wopadr /= "000" then -- synchronously write a supplied value to a given valid register, separate if for synthesis
				registers(to_integer(unsigned(wopadr))) <= wop;
			end if;
		end if;
	end process;

	-- output A
	aop <= (others => '0') when to_integer(unsigned(aopadr)) = 0 else registers(to_integer(unsigned(aopadr)));

	-- output B
	bop <= (others => '0') when to_integer(unsigned(aopadr)) = 0 else registers(to_integer(unsigned(bopadr)));
end rtl;
