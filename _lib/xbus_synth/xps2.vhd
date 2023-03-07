-------------------------------------------------------------------------------
-- xps2_deglitch (input filter) -----------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity xps2_deglitch is
	port(
		clk	: in  std_logic;
		rst	: in  std_logic;
		di	: in  std_logic;
		do	: out std_logic
	);
end xps2_deglitch;

architecture rtl of xps2_deglitch is

	-- get number on high bits in 'a'
	function count_ones(a: std_logic_vector) return integer is
		variable c : integer := 0;
	begin
		for i in a'range loop
			if a(i)='1' then
				c := c+1;
			end if;
		end loop;
		return c;
	end count_ones;
	
	-- status
	signal sreg : std_logic_vector(19 downto 0);
	signal dout : std_logic;
	signal ones : unsigned(4 downto 0);

begin
	
	-- control logic
	process(clk, rst)
	begin
		if rst='1' then
			sreg <= (others=>'1');
			dout <= '1';
		elsif rising_edge(clk) then
			-- update shift-regsiter
			sreg <= sreg(sreg'high-1 downto 0) & di;
			
			-- count high bits
			ones <= to_unsigned(count_ones(sreg),ones'length);
			
			-- update output
			   if dout='1' and ones<4  then dout <= '0';
			elsif dout='0' and ones>17 then dout <= '1';
			end if;
		end if;
	end process;
	
	-- set output
	do <= dout;
end rtl;


-------------------------------------------------------------------------------
-- xps2_lowlevel --------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
library work;
	use work.all;

entity xps2_lowlevel is
	generic (
		FREQ		: natural := 50000000
	);
	port(
		-- common
		clk 		: in  std_logic;
		reset 		: in  std_logic;

		-- transmitter
		tx_ready	: out std_logic;
		tx_error	: out std_logic;
		tx_start	: in  std_logic;
		tx_data		: in  std_logic_vector(7 downto 0);
		
		-- receiver
		rx_valid	: out std_logic;
		rx_error	: out std_logic;
		rx_data		: out std_logic_vector(7 downto 0);
			
		-- PS/2 signals
		ps2_clk_i	: in  std_logic;
		ps2_data_i	: in  std_logic;
		ps2_clk_o	: out std_logic;
		ps2_data_o	: out std_logic
	);
end xps2_lowlevel;

architecture rtl of xps2_lowlevel is

	-- timing constants
	constant CYCLES_50us  : natural := FREQ / 20000;
	constant CYCLES_100us : natural := FREQ / 10000;
	constant CYCLES_2ms   : natural := FREQ / 500;
	constant CYCLES_10ms  : natural := FREQ / 100;

	-- state types
	type txstate_t is (TXIDLE,RTS1,RTS2,RTS3,RTS4,TXACTIVE,TXACK);
	
	-- deglitched inputs
	signal dg_clk	: std_logic;
	signal dg_data	: std_logic;
		
	-- idle detection
	signal idle_cnt : unsigned(log2(CYCLES_100us)-1 downto 0);
	signal idle     : std_logic;
	
	-- edge detection
	signal last_clk : std_logic;
	
	-- receiver logic
	signal rx_active : std_logic;
	signal rx_remain : unsigned(3 downto 0);
	signal rx_sreg   : std_logic_vector(8 downto 0);
	
	-- transmitter logic
	signal tx_sreg   : std_logic_vector(8 downto 0);
	signal tx_state  : txstate_t;
	signal tx_timer  : unsigned(log2(CYCLES_10ms)-1 downto 0);
	signal tx_remain : unsigned(3 downto 0);
	
begin
	
	-- deglitch inputs
	dgc: entity xps2_deglitch
		port map (
			clk	=> clk,
			rst	=> reset,
			di	=> ps2_clk_i,
			do	=> dg_clk
		);
	dgd: entity xps2_deglitch
		port map (
			clk	=> clk,
			rst	=> reset,
			di	=> ps2_data_i,
			do	=> dg_data
		);
	
	process(clk, reset)
	begin
		if reset='1' then
			idle_cnt   <= (others=>'0');
			idle       <= '1';
			last_clk   <= '0';
			rx_active  <= '0';
			rx_remain  <= (others=>'0');
			rx_sreg    <= (others=>'0');
			rx_valid   <= '0';
			rx_error   <= '0';
			rx_data    <= (others=>'0');
			tx_ready   <= '0';
			tx_state   <= TXIDLE;
			tx_sreg    <= (others=>'0');
			tx_timer   <= (others=>'0');
			tx_remain  <= (others=>'0');
			tx_error <= '0';
			ps2_clk_o  <= '1';
			ps2_data_o <= '1';
		elsif rising_edge(clk) then
			-- set default values
			rx_valid <= '0';
			rx_error <= '0';
			tx_error <= '0';
			tx_timer <= tx_timer-1;
			
			-- detect idle bus (clock high for >100us)
			if dg_clk='0' then
				idle_cnt <= to_unsigned(CYCLES_100us-1, idle_cnt'length);
				idle     <= '0';
			elsif idle='0' then
				idle_cnt <= idle_cnt-1;
				if idle_cnt=0 then
					idle <= '1';
				end if;
			end if;
			
			-- reset receiver when idle-contition is detected or transmitter is active
			if idle='1' or tx_state/=TXIDLE then
				rx_active <= '0';
			end if;
			
			-- receiver logic
			last_clk <= dg_clk;
			if dg_clk='1' and last_clk='0' then
				--> rising clock edge
				
				if rx_active='0' then
					if dg_data='0' then
						--> valid start bit detected, start receiver
						rx_active <= '1';
						rx_remain <= to_unsigned(10,rx_remain'length);
						rx_sreg   <= (others=>'0');
					end if;
				else
					-- shift bit into shift-register
					rx_sreg   <= dg_data & rx_sreg(rx_sreg'left downto 1);
					rx_remain <= rx_remain-1;
					
					-- check if this was the last bit
					if rx_remain=1 then
						-- done
						rx_active <= '0';
						
						-- do error-checks
						if dg_data='0' then
							-- framing-error
							rx_error <= '1';
						elsif xor_reduce(rx_sreg)='0' then
							-- parity-error
							rx_error <= '1';
						else
							-- ok
							rx_valid <= '1';
							rx_data  <= rx_sreg(7 downto 0);
						end if;
					end if;
				end if;
			end if;		
			
			-- transmitter start logic
			if tx_state=TXIDLE and idle='1'
				then tx_ready <= '1';
				else tx_ready <= '0';
			end if;
			
			-- transmitter logic
			case tx_state is
				when TXIDLE =>
					-- start transmitter if requested
					if tx_start='1' then
						-- prepare data to transmit
						tx_sreg    <= (not xor_reduce(tx_data)) & tx_data;
						
						-- bring clock down for 100us
						tx_state   <= RTS1;
						tx_timer   <= to_unsigned(CYCLES_100us,tx_timer'length);
						ps2_clk_o  <= '0';
					else
						-- release bus
						ps2_clk_o  <= '1';
						ps2_data_o <= '1';
					end if;
					
				when RTS1 =>
					if tx_timer=0 then
						-- bring data low for some us
						tx_state   <= RTS2;
						tx_timer   <= to_unsigned(CYCLES_50us,tx_timer'length);
						ps2_data_o <= '0';
					end if;
					
				when RTS2 =>
					if tx_timer=0 then
						-- release clock and wait until clock is really high
						tx_state  <= RTS3;
						tx_timer  <= to_unsigned(CYCLES_50us,tx_timer'length);
						ps2_clk_o <= '1';
					end if;
					
				when RTS3 =>
					-- wait for high clock
					if dg_clk='1' then
						-- no wait until device pulls clock low
						tx_state  <= RTS4;
						tx_timer  <= to_unsigned(CYCLES_10ms,tx_timer'length);
						ps2_clk_o <= '1';
					elsif tx_timer=0 then
						-- timeout
						tx_state <= TXIDLE;
						tx_error <= '1';
					end if;
					
				when RTS4 =>
					-- wait for low clock
					if dg_clk='0' then
						-- start transmitting data, init timout-timer
						tx_state <= TXACTIVE;
						tx_timer <= to_unsigned(CYCLES_2ms,tx_timer'length);
						
						-- output first bit
						ps2_data_o <= tx_sreg(0);
						tx_sreg    <= '1' & tx_sreg(tx_sreg'left downto 1);
						tx_remain  <= to_unsigned(9, tx_remain'length);
					elsif tx_timer=0 then
						-- timeout
						tx_state <= TXIDLE;
						tx_error <= '1';
					end if;
					
				when TXACTIVE =>
					if dg_clk='0' and last_clk='1' then
						--> falling clock-edge, output next bit
						ps2_data_o <= tx_sreg(0);
						tx_sreg    <= '1' & tx_sreg(tx_sreg'left downto 1);
						tx_remain  <= tx_remain-1;
						if tx_remain=0 then
							tx_state <= TXACK;
						end if;
					elsif tx_timer=0 then
						-- timeout
						tx_state <= TXIDLE;
						tx_error <= '1';
					end if;
					
				when TXACK =>
					if dg_clk='1' and last_clk='0' then
						--> rising clock-edge, check for ack
						if dg_data='1' then
							--> NAK
							tx_error <= '1';
						end if;
						
						-- done
						tx_state <= TXIDLE;
					elsif tx_timer=0 then
						-- timeout
						tx_state <= TXIDLE;
						tx_error <= '1';
					end if;
			end case;
		end if;
	end process;
end rtl;



-------------------------------------------------------------------------------
-- xps2_lowlevel --------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.all;
	use xbus_common.xtoolbox.all;
library work;
	use work.all;

entity xps2 is
	generic (
		FREQ		: natural := 50000000
	);
	port(
		-- common
		clk 		: in  std_logic;
		reset 		: in  std_logic;

		-- bus interface
		adr			: in  unsigned(7 downto 0);
		datain		: in  std_logic_vector(31 downto 0);
		dataout		: out std_logic_vector(31 downto 0);
		read		: in  std_logic;
		write		: in  std_logic;
		present		: out std_logic;
		ack			: out std_logic;
		intr		: out std_logic;
			
		-- PS/2 signals
		ps2_clk		: inout std_logic;
		ps2_data	: inout std_logic
	);
end xps2;

architecture rtl of xps2 is

	-- config
	constant BASE : natural := 128;
	constant REGS : natural := 3;
	
	-- timing constants
	constant CYCLES_50ms : natural := FREQ/20;
	constant CYCLES_1s   : natural := FREQ;
	
	-- state types
	type state_t is (
		S_RESET,
		S_IDLE,
		S_WAIT_ACK1,
		S_WAIT_BAT,
		S_WAIT_ID,
		S_REQ_ID,
		S_WAIT_ACK2,
		S_ACT_MOUSE,
		S_ACT_KEYBOARD
		);
	
	-- register bank
	signal reg_data   : regbank(REGS-1 downto 0);
	signal reg_re     : std_logic_vector(REGS-1 downto 0);
	signal reg_we     : std_logic_vector(REGS-1 downto 0);
	
	-- register values
	signal xbus_rxirq	 : std_logic;
	signal xbus_txirq	 : std_logic;
	signal xbus_rxready	 : std_logic;
	signal xbus_txready	 : std_logic;
	signal xbus_rstdone	 : std_logic;
	signal xbus_devfnd   : std_logic;
	signal xbus_keyboard : std_logic;
	
	-- status
	signal state      : state_t;
	signal timer      : unsigned(log2(CYCLES_1s)-1 downto 0);
	signal rstreq     : std_logic;
	
	-- lowlevel control
	signal tx_ready	  : std_logic;
	signal tx_error	  : std_logic;
	signal tx_start	  : std_logic;
	signal tx_data	  : std_logic_vector(7 downto 0);
	signal rx_valid	  : std_logic;
	signal rx_error	  : std_logic;
	signal rx_data	  : std_logic_vector(7 downto 0);
		
	-- PS/2 signals
	signal ps2_clk_i  : std_logic;
	signal ps2_data_i : std_logic;
	signal ps2_clk_o  : std_logic;
	signal ps2_data_o : std_logic;
	
	-- tx-fifo
	signal txfifo_clear	: std_logic;
	signal txfifo_full	: std_logic;
	signal txfifo_empty	: std_logic;
	signal txfifo_we	: std_logic;
	signal txfifo_din 	: std_logic_vector(7 downto 0);
	signal txfifo_re	: std_logic;
	signal txfifo_dout 	: std_logic_vector(7 downto 0);
	
	-- rx-fifo
	signal rxfifo_clear	: std_logic;
	signal rxfifo_full	: std_logic;
	signal rxfifo_empty	: std_logic;
	signal rxfifo_we	: std_logic;
	signal rxfifo_din 	: std_logic_vector(7 downto 0);
	signal rxfifo_re	: std_logic;
	signal rxfifo_dout 	: std_logic_vector(7 downto 0);
	
	
begin
	
	--
	-- register bank
	--
	
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
	reg_data(0) <= x"000000" & rxfifo_dout;
	reg_data(1) <= (0=>xbus_rxready,1=>xbus_txready,2=>xbus_rstdone,
	                3=>xbus_devfnd,4=>xbus_keyboard, others=>'0');
	reg_data(2) <= (0=>xbus_rxirq,1=>xbus_txirq,others=>'0');
	
	-- create interrupt-flag
	intr <= (xbus_txready and xbus_txirq) or (xbus_rxready and xbus_rxirq);

	-- connect register interface with fifos
	xbus_rxready <= not rxfifo_empty;
	xbus_txready <= not txfifo_full;
	txfifo_we    <= reg_we(0) and (not txfifo_full);
	rxfifo_re    <= reg_re(0) and (not rxfifo_empty);
	txfifo_din   <= datain(7 downto 0);
	txfifo_clear <= rstreq;
	rxfifo_clear <= rstreq;
	
	-- map internal status to external status flags
	xbus_rstdone  <= '1' when (state=S_ACT_KEYBOARD or state=S_ACT_MOUSE or state=S_IDLE) else '0';
	xbus_devfnd   <= '1' when (state=S_ACT_KEYBOARD or state=S_ACT_MOUSE) else '0';
	xbus_keyboard <= '1' when (state=S_ACT_KEYBOARD) else '0';
	
	-- handle bus-requests
	process(clk, reset)
	begin
		if reset='1' then
			rstreq     <= '0';
			xbus_txirq <= '0';
			xbus_rxirq <= '0';
		elsif rising_edge(clk) then
			-- update config
			if reg_we(2)='1' then 
				xbus_rxirq <= datain(0);
				xbus_txirq <= datain(1);
			end if;
			
			-- check for reset-command
			rstreq <= '0';
			if reg_we(1)='1' then 
				if datain(5)='1' then
					rstreq <= '1';
				end if;
			end if;
		end if;
	end process;

	
	--
	-- PS/2 control logic
	--
	
	-- infer tristate pads
	ps2_clk_i  <= to_X01(ps2_clk);
	ps2_data_i <= to_X01(ps2_data);
	ps2_clk    <= '0' when ps2_clk_o='0'  else 'Z';
	ps2_data   <= '0' when ps2_data_o='0' else 'Z';
		
	-- control logic
	process(clk, reset)
	begin
		if reset='1' then
			state       <= S_RESET;
			timer       <= (others=>'0');
			tx_start    <= '0';
			tx_data     <= (others=>'0');
			txfifo_re   <= '0';
			rxfifo_we   <= '0';
			rxfifo_din  <= (others=>'0');
		elsif rising_edge(clk) then
			-- set default values
			tx_start  <= '0';
			txfifo_re <= '0';
			rxfifo_we <= '0';
			timer     <= timer-1;
			
			-- update status
			case state is
				when S_IDLE =>
					-- handle reset-request
					if rstreq='1' then
						state <= S_RESET;
					end if;
					
				when S_RESET =>
					if tx_ready='1' then 
						-- set reset command
						tx_start <= '1';
						tx_data  <= x"FF";
						
						-- now wait for ACK
						state <= S_WAIT_ACK1;
						timer <= to_unsigned(CYCLES_50ms, timer'length);
					end if;
					
				when S_WAIT_ACK1 =>
					if rx_valid='1' and rx_data=x"FA" then
						-- now wait for self-test-passed
						state <= S_WAIT_BAT;
						timer <= to_unsigned(CYCLES_1s, timer'length);
					elsif tx_error='1' or timer=0 then
						-- abort
						state <= S_IDLE;
					end if;
					
				when S_WAIT_BAT =>
					if rx_valid='1' and rx_data=x"AA" then
						-- now wait for device-id
						state <= S_WAIT_ID;
						timer <= to_unsigned(CYCLES_50ms, timer'length);
					elsif timer=0 then
						-- abort
						state <= S_IDLE;
					end if;
					
				when S_WAIT_ID =>
					if rx_valid='1'  then
						if rx_data=x"00" then
							-- mouse
							state <= S_ACT_MOUSE;
						elsif rx_data=x"AB" then
							-- keyboard
							state <= S_ACT_KEYBOARD;
						end if;
					end if;
					if timer=0 then
						-- timeout, explictly request id
						state <= S_REQ_ID;
					end if;
					
				when S_REQ_ID =>
					if tx_ready='1' then 
						-- send 'read id' command
						tx_start <= '1';
						tx_data  <= x"F2";
						
						-- now wait for ACK
						state <= S_WAIT_ACK2;
						timer <= to_unsigned(CYCLES_50ms, timer'length);
					end if;
					
				when S_WAIT_ACK2 =>
					if rx_valid='1' and rx_data=x"FA" then
						-- now wait for id
						state <= S_WAIT_ID;
						timer <= to_unsigned(CYCLES_50ms, timer'length);
					elsif tx_error='1' or timer=0 then
						-- abort
						state <= S_IDLE;
					end if;

				when S_ACT_MOUSE | S_ACT_KEYBOARD =>
					-- handle incoming data
					if rx_valid='1' and rxfifo_full='0' then
						rxfifo_we  <= '1';
						rxfifo_din <= rx_data;
					end if;
					
					-- transmit pending data
					if tx_ready='1' and txfifo_empty='0' then 
						tx_start  <= '1';
						tx_data   <= txfifo_dout;
						txfifo_re <= '1';
					end if;
					
					-- handle reset-request
					if rstreq='1' then
						state <= S_RESET;
					end if;
			end case;
		end if;
	end process;
	
	-- low-level logic
	ll: entity xps2_lowlevel
		generic map (
			FREQ		=> FREQ
		)
		port map (
			-- common
			clk 		=> clk,
			reset 		=> reset,
	
			-- tranmitter
			tx_ready	=> tx_ready,
			tx_error	=> tx_error,
			tx_start	=> tx_start,
			tx_data		=> tx_data,
			
			-- receiver
			rx_valid	=> rx_valid,
			rx_error	=> rx_error,
			rx_data		=> rx_data,
				
			-- PS/2 signals
			ps2_clk_i	=> ps2_clk_i,
			ps2_data_i	=> ps2_data_i,
			ps2_clk_o	=> ps2_clk_o,
			ps2_data_o	=> ps2_data_o
		);

	-- tx-fifo
	i_txfifo: entity xbus_common.basic_fifo
		generic map(
			DWIDTH => 8,
			DEPTH  => 32,
			FLEN   => 6
		)
		port map(
			clk       => clk,
			reset     => reset,
			filled    => open,
			full      => txfifo_full,
			empty     => txfifo_empty,
			clear     => txfifo_clear,
			in_we     => txfifo_we,
			in_data   => txfifo_din,
			out_re    => txfifo_re,
			out_data  => txfifo_dout,
			out_valid => open
		);
		
	-- rx-fifo
	i_rxfifo: entity xbus_common.basic_fifo
		generic map(
			DWIDTH => 8,
			DEPTH  => 32,
			FLEN   => 6
		)
		port map(
			clk       => clk,
			reset     => reset,
			filled    => open,
			full      => rxfifo_full,
			empty     => rxfifo_empty,
			clear     => rxfifo_clear,
			in_we     => rxfifo_we,
			in_data   => rxfifo_din,
			out_re    => rxfifo_re,
			out_data  => rxfifo_dout,
			out_valid => open
		);
	
end rtl;