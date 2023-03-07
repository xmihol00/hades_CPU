library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
entity xdmemory_sim is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- bus interface
		adr			: in  unsigned(11 downto 0);
		datain		: in  std_logic_vector(31 downto 0);
		dataout		: out std_logic_vector(31 downto 0);
		read		: in  std_logic;
		write		: in  std_logic;
		dmembusy	: out std_logic
	);
end xdmemory_sim;

architecture rtl of xdmemory_sim is	

	-- config
	constant DWIDTH : natural := 32;
	constant AWIDTH : natural := 10;
	constant SIZE   : natural := 2**AWIDTH;
	
	-- internal type
	subtype mem_word_t is std_logic_vector(31 downto 0);
	type mem_t is array(0 to SIZE-1) of mem_word_t;

	-- shortened address
	signal sadr : unsigned(AWIDTH-1 downto 0);
	
	-- memory
	signal mem : mem_t := (others=>(others=>'0'));
	
begin
	
	-- simulated memory is never busy
	dmembusy <= '0';
	
	-- shorten address
	sadr <= adr(sadr'range);
	
	-- check if address is in valid range
	process(clk)
	begin
		if rising_edge(clk) then
			if read='1' or write='1' then
				assert sadr=adr
					report "xdmemory_sim: memory access out of simulated range, increase AWIDTH"
					severity FAILURE;
			end if;
		end if;
	end process;
	
	-- handle writes
	process(clk)
	begin
		if rising_edge(clk) then
			if write='1' then
				mem(to_integer(sadr)) <= datain;
			end if;
		end if;
	end process;
	
	-- handle reads
	dataout <= mem(to_integer(sadr));
	
end rtl;
