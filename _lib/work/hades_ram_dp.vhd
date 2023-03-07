library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library std;
	use std.textio.all;
library work;
	use work.hadescomponents.all;
	
entity hades_ram32_dp is
	generic (
		WIDTH_ADDR  : natural;
		INIT_FILE	: string     := "UNUSED";
		INIT_DATA   : mem_init_t := (0=>x"00000000")
	);
	port (
		-- common
		clk 		: in  std_logic;
		reset 		: in  std_logic;
		
		-- write port
		wena		: in  std_logic;
		waddr		: in  std_logic_vector(WIDTH_ADDR-1 downto 0);
		wdata		: in  std_logic_vector(31 downto 0);
		
		-- read port
		rena		: in  std_logic;
		raddr		: in  std_logic_vector(WIDTH_ADDR-1 downto 0);
		rdata		: out std_logic_vector(31 downto 0)
	);
end hades_ram32_dp;

architecture rtl of hades_ram32_dp is

	-- internal types
	subtype mem_t is mem_init_t(0 to 2**WIDTH_ADDR-1);
	
	-- helper function to get inital data
	impure function getInitData return mem_t is
		variable tmp : mem_t;
	begin
		if INIT_FILE/="UNUSED" then 
			return hades_read_hex(INIT_FILE,WIDTH_ADDR);
		else 
			tmp := (others=>x"00000000");
			for i in INIT_DATA'range loop
				tmp(i) := INIT_DATA(i);
			end loop;
			return tmp;
		end if;
	end getInitData;

	-- memory
	signal mem : mem_t :=  getInitData;

begin
	
	-- infer ram
	process(clk)
	begin
		if rising_edge(clk) then
			-- handle writes
			if reset='0' and wena='1' then
				mem(to_integer(unsigned(waddr))) <= wdata;
			end if;
			
			-- handle reads
			if reset='0' and rena='1' then
				rdata <= mem(to_integer(unsigned(raddr)));
			end if;
		end if;
	end process;
	
end rtl;
