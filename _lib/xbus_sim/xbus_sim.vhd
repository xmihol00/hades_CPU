library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
	use xbus_common.all;
library work;
	use work.all;
	
entity xbus_sim is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- common bus inteface
		adr			: in  std_logic_vector(12 downto 0);
		datain		: in  std_logic_vector(31 downto 0);
		dataout		: out std_logic_vector(31 downto 0);
		read		: in  std_logic;
		write		: in  std_logic;
		
		-- peripherie bus signals
		ack			: out std_logic;
		xpresent	: out std_logic;
		perintr		: out std_logic;
		
		-- memory bus signals
		dmemop		: in  std_logic;
		dmembusy	: out std_logic;
		memintr		: out std_logic
	);
end xbus_sim;

architecture rtl of xbus_sim is	

	-- config
	constant FREQ : natural := 50000000;	-- bus frequency
	constant N    : natural := 1; 			-- number of peripherals on bus
	
	-- internal types
	subtype data_t is std_logic_vector(31 downto 0); 
	type data_array_t is array(natural range<>) of data_t;
	
	-- data memory ports
	signal dmem_adr     : unsigned(11 downto 0);
	signal dmem_dout    : data_t;
	signal dmem_read    : std_logic;
	signal dmem_write   : std_logic;

	-- perpherie ports
	signal perp_adr     : unsigned(7 downto 0);
	signal perp_dout    : data_array_t(N-1 downto 0);
	signal perp_read    : std_logic;
	signal perp_write   : std_logic;
	signal perp_present : std_logic_vector(N-1 downto 0);
	signal perp_ack     : std_logic_vector(N-1 downto 0);
	signal perp_intr    : std_logic_vector(N-1 downto 0);
	
begin
	
	--
	-- bus multiplexer
	--
	
	-- create special signals for data-memory
	dmem_adr   <= unsigned(adr(11 downto 0));
	dmem_read  <= dmemop and read;
	dmem_write <= dmemop and write;
	memintr    <= dmemop and adr(12) and (read or write);
	
	-- create special signals for peripherals
	perp_adr   <= unsigned(adr(7 downto 0));
	perp_read  <= (not dmemop) and read;
	perp_write <= (not dmemop) and write;
	
	-- output multiplexer
	process(dmemop, dmem_dout, perp_present, perp_ack, perp_dout, perp_intr)
	begin
		-- apply default values
		ack      <= '0';
		xpresent <= '0';
		perintr  <= '0';
		dataout  <= (others=>'0');
	
		-- check if memory or peripheral access
		if dmemop='1' then
			--> memory access
			dataout <= dmem_dout;
		else
			--> peripheral access
			
			-- get output from active peripheral
			for i in 0 to N-1 loop
				if perp_present(i)='1' then
					xpresent <= '1';
					ack      <= perp_ack(i);
					dataout  <= perp_dout(i);
				end if;
			end loop;
			
			-- assert IRQ if any peripheral wants it
			perintr <= or_reduce(perp_intr);
		end if;
	end process;
	
	
	--
	-- peripheral components
	--
	
	-- data-memory
	i_dmem: entity work.xdmemory_sim
		port map (
			clk 		=> clk,
			reset		=> reset,
			adr			=> dmem_adr,
			datain		=> datain,
			dataout		=> dmem_dout,
			read		=> dmem_read,
			write		=> dmem_write,
			dmembusy	=> dmembusy
		);
	
	-- timer
	i_timer: entity xbus_common.xtimerxt
		generic map (
			FREQ		=> FREQ,
			SIM			=> true
		)
		port map (
			-- common
			clk 		=> clk,
			reset		=> reset,
			
			-- bus interface
			adr			=> perp_adr,
			datain		=> datain,
			dataout		=> perp_dout(0),
			read		=> perp_read,
			write		=> perp_write,
			present		=> perp_present(0),
			ack			=> perp_ack(0),
			intr		=> perp_intr(0)
		);

end rtl;
