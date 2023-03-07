library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
	
entity xtimerxt is
	generic (
		FREQ		: natural;
		SIM         : boolean
	);
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- bus interface
		adr			: in  unsigned(7 downto 0);
		datain		: in  std_logic_vector(31 downto 0);
		dataout		: out std_logic_vector(31 downto 0);
		read		: in  std_logic;
		write		: in  std_logic;
		present		: out std_logic;
		ack			: out std_logic;
		intr		: out std_logic
	);
end xtimerxt;

architecture rtl of xtimerxt is		

	-- helper function to choose constant depeding on SIM-flag
	function simMux(a,b:natural) return natural is
	begin
		if SIM 
			then return b;
			else return a;
		end if;
	end function;

	-- config
	constant BASE : natural := 16;
	constant REGS : natural := 2;
	constant LOAD : natural := simMux(FREQ/1000, FREQ/1000/1000); -- 1ms normally, 1us when simulating
	
	-- register bank
	signal reg_data	: regbank(REGS-1 downto 0);
	signal reg_re	: std_logic_vector(REGS-1 downto 0);
	signal reg_we	: std_logic_vector(REGS-1 downto 0);
	
	-- config
	signal cfg_load	: unsigned(15 downto 0);
	signal cfg_ien  : std_logic;
	
	-- status
	signal active   : std_logic;
	signal fired    : std_logic;
	signal counter  : unsigned(15 downto 0);
	signal icounter : unsigned(log2(LOAD)-1 downto 0);
	
begin
	
	-- connect register bank
	process(adr, read, write, reg_data)
		variable sel : integer;
	begin
		-- set default output
		present <= '0';
		ack     <= '0';
		reg_re  <= (others=>'0');
		reg_we  <= (others=>'0');
		dataout <= (others=>'0');
		
		-- get selection
		sel := to_integer(unsigned(adr)) - BASE;
		if (sel>=0) and (sel<REGS) then
			present     <= '1';
			ack         <= read or write;
			dataout     <= reg_data(sel);
			reg_re(sel) <= read;
			reg_we(sel) <= write;
		end if;
	end process;
	
	-- set output
	reg_data(0) <= "0000000000000000" & std_logic_vector(cfg_load);
	reg_data(1) <= (1=>cfg_ien,2=>fired,others=>'0');
	
	-- output irq flag
	intr <= fired and cfg_ien;
	
	-- handle requests
	process(clk, reset)
	begin
		if reset='1' then
			cfg_load <= (others=>'0');
			cfg_ien  <= '0';
			active   <= '0';
			fired    <= '0';
			counter  <= (others=>'0');
			icounter <= (others=>'0');
		elsif rising_edge(clk) then
			-- update load-value
			if reg_we(0)='1' then 
				cfg_load <= unsigned(datain(15 downto 0));
			end if;
			
			-- update timer
			if reg_we(1)='1' then
				if datain(0)='1' then
					-- start timer
					active   <= '1';
					counter  <= cfg_load;
					icounter <= to_unsigned(LOAD-1, icounter'length);
					fired    <= '0';
				else
					-- stop timer
					active   <= '0';
				end if;
				if datain(2)='1' then
					-- reset fired-flag
					fired <= '0';
				end if;
				
				-- update irq status
				cfg_ien <= datain(1);
			elsif active='1' then
				if icounter=0 then
					-- 1us timer ellapsed
					if counter<=1 then
						-- timer ellapsed
						active   <= '0';
						fired    <= '1';
					else
						-- update counter
						icounter <= to_unsigned(LOAD-1, icounter'length);
						counter  <= counter-1;
					end if;
				else
					-- update inner counter
					icounter <= icounter - 1;
				end if;
			end if;
		end if;
	end process;
end rtl;
