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
	type RegisterFile_t is array(0 to 7) of std_logic_vector(31 downto 0); -- register file of 8 32-bit registers
	signal registers : RegisterFile_t;
	signal written : std_logic := '0'; -- Ensure processes that read reagisters are notified when any register changes.
	constant r0_idx : integer := 0;    -- Index of the fisrt register that cannot be written and always returns 0.
begin
	-- All writes to registers must be in a single process, otherwise the value inside registers will be undefined.
	process(clk, reset, regwrite, wopadr) is
	begin
		if reset = '1' then -- reset values of registers to 0
			for i in registers'range loop
				registers(i) <= (others => '0');
			end loop;
			written <= not written; -- notify processes about a change in the register file
		elsif rising_edge(clk) and regwrite = '1' then -- synchronously write a supplied value to a given valid register
			registers(to_integer(unsigned(wopadr))) <= wop;
			registers(r0_idx) <= (others => '0'); -- make sure r0 is always 0
			written <= not written; -- notify processes about a change in the register file
		end if;
	end process;

	-- output A
	process(written, aopadr) is
	begin
		aop <= registers(to_integer(unsigned(aopadr)));
	end process;
	
	-- output B
	process(written, bopadr) is
	begin
		bop <= registers(to_integer(unsigned(bopadr)));
	end process;
end rtl;
