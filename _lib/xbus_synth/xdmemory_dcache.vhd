library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

	
entity xdmemory_dcache is
	generic (
		BASE_ADDR	: natural
	);
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
end xdmemory_dcache;

architecture rtl of xdmemory_dcache is
    -- internal types
	type mem_t is array(4095 downto 0) of std_logic_vector(31 downto 0);
	
	--memory
	signal mem : mem_t := (others => x"00000000");
begin
	
	
	
	-- infer ram
  process(reset, clk)
  begin
      if reset = '1' then
          dmembusy <= '1';
      elsif rising_edge(clk) then
		  dmembusy <= '1';
          -- handle writes
          if write='1' then
		  	  dmembusy <= '0';
              mem(to_integer(unsigned(adr))) <= datain;
          end if;
		  
		 -- handle read 
		 if read = '1' then
 		    dmembusy <= '0';
			dataout <= mem(to_integer(unsigned(adr)));
		 end if;
 
      end if;
  end process;
    
 
	
end rtl;
