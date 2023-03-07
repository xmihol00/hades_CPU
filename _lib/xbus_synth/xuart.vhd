-------------------------------------------------------------------------------
-- xuart_clkgen ---------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity xuart_clkgen is
	port(
		-- common
		clk 		: in  std_logic;
		reset 		: in  std_logic;
		
		-- configuration & control
		incr		: in  unsigned(15 downto 0);	-- increment for clock accumulator
		startrx		: in  std_logic;				-- align rxclk to next base-clock-pulse
		
		-- generated clock
		baseclk		: out std_logic;				-- base-clock
		rxclk		: out std_logic;				-- RX-clock
		txclk		: out std_logic					-- TX-clock
	);
end xuart_clkgen;

architecture rtl of xuart_clkgen is
	
	-- clock generation
	signal clkgen_acc		: unsigned(15 downto 0);	-- accumulator-value
	signal clkgen_msbreg	: std_logic;				-- MSB of last value of 'clkgen_acc'
	signal rxphase			: unsigned(3 downto 0);		-- phase-counter for rx-clock
	signal txphase			: unsigned(3 downto 0);		-- phase-counter for tx-clock
	
begin

	--
	-- clock generation
	--
	process(clk, reset)
	begin
		if reset='1' then
			clkgen_acc    <= to_unsigned(0, clkgen_acc'length);
			clkgen_msbreg <= '0';
			rxphase       <= to_unsigned(0, rxphase'length);
			txphase       <= to_unsigned(0, txphase'length);
			baseclk       <= '0';
			rxclk         <= '0';
			txclk         <= '0';
		elsif rising_edge(clk) then
			-- update accumulator
			clkgen_acc    <= clkgen_acc + incr;
			clkgen_msbreg <= clkgen_acc(15);
			
			-- check for overflow
			if clkgen_msbreg='1' and clkgen_acc(15)='0' then
				-- update phase-counters
				txphase <= txphase + 1;
				rxphase <= rxphase + 1;
				
				-- update clock-signals
				baseclk <= '1';
				if txphase=0
					then txclk <= '1';
					else txclk <= '0';
				end if;
				if rxphase=0
					then rxclk <= '1';
					else rxclk <= '0';
				end if;
			else
				-- realign rx-phase if requested
				if startrx='1'then
					rxphase <= to_unsigned(0, rxphase'length);
				end if;
				
				-- update clock-signals
				baseclk <= '0';
				rxclk   <= '0';
				txclk   <= '0';
			end if;
		end if;
	end process;

end rtl;


-------------------------------------------------------------------------------
-- xuart_transmitter  ---------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.all;
	use xbus_common.xtoolbox.all;

entity xuart_transmitter is
	port(
		-- common
		clk 		: in  std_logic;
		reset 		: in  std_logic;
		
		-- status
		fill		: out unsigned(5 downto 0);				-- tx-fifo fill
		ready		: out std_logic;						-- tx-fifo ready for data
		empty		: out std_logic;						-- tx-fifo is empty
		err_ovl		: out std_logic;						-- overflow occured
		
		-- control
		enable		: in  std_logic;						-- enable
		txclk		: in  std_logic;						-- TX-clock
		we			: in  std_logic;						-- input-enable
		din			: in  std_logic_vector(7 downto 0);		-- input-data
		
		-- TS-connector pad
		pad_txd_o	: out std_logic							-- tx-data-pad
	);
end xuart_transmitter;

architecture rtl of xuart_transmitter is

	-- transmitter
	signal lreg_data	: std_logic_vector(7 downto 0);		-- load-register
	signal lreg_loaded	: std_logic;						-- load-register completly loaded?
	signal lreg_used	: std_logic;						-- load-register got consumed?
	signal sreg_data	: std_logic_vector(10 downto 0);	-- bits to send
	signal sreg_count	: unsigned(3 downto 0);				-- number of remaining bits in 'tx_shreg'
	signal sreg_empty	: std_logic;						-- transmitter empty?

	-- tx-fifo
	signal txfifo_fill	: unsigned(5 downto 0);
	signal txfifo_full	: std_logic;
	signal txfifo_empty	: std_logic;
	signal txfifo_we	: std_logic;
	signal txfifo_din 	: std_logic_vector(7 downto 0);
	signal txfifo_re	: std_logic;
	signal txfifo_dout 	: std_logic_vector(7 downto 0);
	
begin
	
	-- generate read-enable for fifo
	txfifo_re <= '1' when txfifo_empty='0' and							-- data available
						  (lreg_loaded='0' or lreg_used='1') else '0';	-- can overwrite load-regsiter
	
	-- update load-register
	process(clk, reset)
	begin
		if reset='1' then
			lreg_data   <= (others=>'0');
			lreg_loaded <= '0';
		elsif rising_edge(clk) then
			if txfifo_re='1' then
				--> read next byte
				lreg_data   <= txfifo_dout;
				lreg_loaded <= '1';
			elsif lreg_used='1' then
				--> load-regsister got consumed
				lreg_loaded <= '0';
			end if;
		end if;
	end process;
	
	-- transmitter logic
	process(clk, reset)
	begin
		if reset='1' then
			sreg_data  <= (others=>'1');
			sreg_count <= (others=>'0');
			lreg_used  <= '0';
			pad_txd_o  <= '1';
			sreg_empty <= '1';
		elsif rising_edge(clk) then	
			-- load-register is not used by default
			lreg_used <= '0';

			-- check if anything left in shift-buffer
			if sreg_empty='1' then
				-- nothing left, check for new data
				if enable='1' and lreg_loaded='1' then
					-- update status
					lreg_used  <= '1';
					sreg_empty <= '0';
					sreg_count <= to_unsigned(11, sreg_count'length);
					
					-- assemble uart-message
					sreg_data(0)           <= '1';										-- stop-bit
					sreg_data(8 downto 1)  <= reverse_vector(lreg_data(7 downto 0));	-- data
					sreg_data(10 downto 9) <= "10";										-- start bit
				end if;
			elsif txclk='1' then
				-- advance shift-register
				sreg_data(sreg_data'high downto 1) <= sreg_data(sreg_data'high-1 downto 0);
				sreg_data(0) <= '1';
				
				-- update counter
				sreg_count <= sreg_count - 1;
				if sreg_count=1 then
					sreg_empty <= '1';
				end if;
			end if;
			
			-- output next bit on write-pulse
			if txclk='1' then
				pad_txd_o <= sreg_data(sreg_data'high);
			end if;
		end if;
	end process;

	-- connect tx-fifo
	fill         <= txfifo_fill;
	ready        <= not txfifo_full;
	empty        <= txfifo_empty;
	err_ovl      <= txfifo_full and we;
	txfifo_we    <= we;
	txfifo_din   <= din;
	
	-- instantiate tx-fifo
	i_txfifo: entity xbus_common.basic_fifo
		generic map(
			DWIDTH => 8,
			DEPTH  => 32,
			FLEN   => 6
		)
		port map(
			clk       => clk,
			reset     => reset,
			filled    => txfifo_fill,
			full      => txfifo_full,
			empty     => txfifo_empty,
			clear     => '0',
			in_we     => txfifo_we,
			in_data   => txfifo_din,
			out_re    => txfifo_re,
			out_data  => txfifo_dout,
			out_valid => open
		);

end rtl;


-------------------------------------------------------------------------------
-- xuart_receiver  ------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.all;
	use xbus_common.xtoolbox.all;

entity xuart_receiver is
	port(
		-- common
		clk 		: in  std_logic;
		reset 		: in  std_logic;

		-- status
		startrx		: out std_logic;						-- realign 'rxclk'
		fill		: out unsigned(5 downto 0);				-- rx-fifo fill
		ready		: out std_logic;						-- rx-fifo has data ready
		err_ovl		: out std_logic;						-- overflow occured
		err_frame	: out std_logic;						-- framing error occured
		
		-- control
		enable		: in  std_logic;						-- enable
		rxclk		: in  std_logic;						-- RX-clock
		ovclk		: in  std_logic;						-- oversample-clock (16x rxclk)
		re			: in  std_logic;						-- output-enable
		dout		: out std_logic_vector(7 downto 0);		-- output-data
		
		-- TS-connector pad
		pad_rxd_i	: in  std_logic							-- rx-data-pad
	);
end xuart_receiver;

architecture rtl of xuart_receiver is

	-- start-bit detection (for uart)
	signal sbd_lowcnt		: unsigned(2 downto 0);
	signal sbd_start		: std_logic;

	-- shift-register
	signal sreg_data		: std_logic_vector(8 downto 0);		-- last received bits
	signal sreg_count 		: unsigned(3 downto 0);				-- position in incoming message
	
	-- status flags
	signal start     		: std_logic;
	signal done		 		: std_logic;
	signal ovr  			: std_logic;

	-- rx-fifo
	signal rxfifo_fill		: unsigned(5 downto 0);
	signal rxfifo_full		: std_logic;
	signal rxfifo_empty		: std_logic;
	signal rxfifo_we		: std_logic;
	signal rxfifo_din 		: std_logic_vector(7 downto 0);
	signal rxfifo_re		: std_logic;
	signal rxfifo_dout 		: std_logic_vector(7 downto 0);
	
begin
	
	-- start-bit detection
	process(clk, reset)
	begin
		if reset='1' then
			sbd_lowcnt <= to_unsigned(0, sbd_lowcnt'length);
			sbd_start  <= '0';
			startrx    <= '0';
		elsif rising_edge(clk) then
			if ovclk='1' then
				-- count consecutive low samples 
				if pad_rxd_i='0' 
					then sbd_lowcnt <= sbd_lowcnt+1;
					else sbd_lowcnt <= to_unsigned(0, sbd_lowcnt'length);
				end if;
				
				-- detect start-bit
				if sbd_lowcnt=7 and sreg_count=0 then
					sbd_start <= enable;
					startrx   <= enable;
				else
					sbd_start <= '0';
					startrx   <= '0';
				end if;
			else
				startrx <= '0';
			end if;
		end if;
	end process;
	
	-- map input-data into shift register
	sreg_data(0) <= pad_rxd_i;
	
	-- receiver logic
	process(clk, reset)
		variable data : std_logic_vector(7 downto 0);
		variable fre  : std_logic;
	begin
		if reset='1' then
			sreg_data(sreg_data'high downto 1) <= (others=>'1');
			sreg_count  <= (others=>'0');
			rxfifo_we   <= '0';
			rxfifo_din  <= (others=>'0');
			start		<= '0';
			done 		<= '0';
			ovr         <= '0';
			err_ovl		<= '0';
			err_frame	<= '0';
		elsif rising_edge(clk) then
			-- apply default values
			rxfifo_we <= '0';
			err_ovl   <= '0';
			err_frame <= '0';
						
			if rxclk='1' then
				-- advance shift register
				sreg_data(sreg_data'high downto 1) <= sreg_data(sreg_data'high-1 downto 0);
						
				if sreg_count=0 then
					-- waiting for a new message, check for start-bit
					if start='1' then
						--> start receiving message
						sreg_count <= sreg_count+1;
					end if;
				else
					-- update counter
					if done='1' 
						then sreg_count <= (others=>'0');
						else sreg_count <= sreg_count + 1;
					end if;
					
					-- check if byte was received
					if done='1' then
						if rxfifo_full='0' then
							-- collect data
							data := reverse_vector(sreg_data(8 downto 1));
							fre  := not sreg_data(0);

							-- write into fifo
							rxfifo_we  <= '1';
							rxfifo_din <= data;
							
							-- set error-flags
							err_ovl   <= ovr;
							err_frame <= fre;
							
							-- clear overrun-flag
							ovr <= '0';
						else
							-- set overrun-flag
							ovr <= '1';
						end if;
					end if;
				end if;
			else 
				case to_integer(sreg_count) is
					when 0 =>
						-- check for start-bit
						start <= (not sreg_data(0)) and sbd_start;
						done  <= '0';
					when 9 =>
						-- received a complete byte
						start <= '0';
						done  <= '1';
					when others =>
						-- normal data bit in message
						start <= '0';
						done  <= '0';
				end case;
			end if;
		end if;
	end process;
	
	-- connect rx-fifo
	fill      <= rxfifo_fill;
	ready     <= (not rxfifo_empty) and (not rxfifo_re);
	rxfifo_re <= re;
	dout      <= rxfifo_dout;
	
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
			filled    => rxfifo_fill,
			full      => rxfifo_full,
			empty     => rxfifo_empty,
			clear     => '0',
			in_we     => rxfifo_we,
			in_data   => rxfifo_din,
			out_re    => rxfifo_re,
			out_data  => rxfifo_dout,
			out_valid => open
		);

end rtl;


-------------------------------------------------------------------------------
-- xuart  ---------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
library work;
	use work.all;
	
entity xuart is
	generic (
		FREQ		: natural
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
		
		-- external signals
		pad_rxd_i	: in  std_logic;	-- rx-data-pad (input)
		pad_txd_o	: out std_logic		-- tx-data-pad (output)
	);
end xuart;

architecture rtl of xuart is

	-- config
	constant BASE : natural := 96;
	constant REGS : natural := 3;
	
	-- register bank
	signal reg_data		: regbank(REGS-1 downto 0);
	signal reg_re		: std_logic_vector(REGS-1 downto 0);
	signal reg_we		: std_logic_vector(REGS-1 downto 0);

	-- register values
	signal xbus_rxword 	: std_logic_vector(31 downto 0);
	signal xbus_rxready	: std_logic;
	signal xbus_txready	: std_logic;
	signal xbus_mode	: std_logic;
	signal xbus_rxirq	: std_logic;
	signal xbus_txirq	: std_logic;
	
	-- clocks
	signal clkincr		: unsigned(15 downto 0);
	signal baseclk		: std_logic;
	signal rxclk		: std_logic;
	signal txclk		: std_logic;
	
	-- transmitter
	signal tx_ready		: std_logic;
	signal tx_empty		: std_logic;
	signal tx_err_ovl	: std_logic;
	signal tx_fill 		: unsigned(5 downto 0);
	signal tx_we		: std_logic;
	signal tx_din 		: std_logic_vector(7 downto 0);
			
	-- receiver
	signal rx_startclk	: std_logic;
	signal rx_ready		: std_logic;
	signal rx_err_ovl	: std_logic;
	signal rx_err_frm	: std_logic;
	signal rx_fill 		: unsigned(5 downto 0);
	signal rx_re		: std_logic;
	signal rx_dout 		: std_logic_vector(7 downto 0);
	
	-- RX logic
	signal rxl_fill		: unsigned(2 downto 0);
	signal rxl_buf		: std_logic_vector(31 downto 0);
	
	-- TX logic
	signal txl_fill		: unsigned(2 downto 0);
	signal txl_buf		: std_logic_vector(31 downto 0);
	
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
	reg_data(0) <= xbus_rxword;
	reg_data(1) <= (0=>xbus_rxready,1=>xbus_txready,others=>'0');
	reg_data(2) <= (0=>xbus_rxirq,1=>xbus_txirq,2=>xbus_mode,others=>'0');
	
	-- create interrupt-flag
	intr <= (xbus_txready and xbus_txirq) or (xbus_rxready and xbus_rxirq);

	-- map internal status to external status flags
	xbus_rxword  <= rxl_buf;
	xbus_rxready <= '1' when ((xbus_mode='0' and rxl_fill>=1) or 
                              (xbus_mode='1' and rxl_fill>=4)) else '0';
	xbus_txready <= '1' when (txl_fill=0) else '0';
	
	-- handle bus-requests
	process(clk, reset)
	begin
		if reset='1' then
			xbus_txirq <= '0';
			xbus_rxirq <= '0';
			xbus_mode<= '0';
		elsif rising_edge(clk) then
			-- update config			
			if reg_we(2)='1' then 
				xbus_rxirq <= datain(0);
				xbus_txirq <= datain(1);
				xbus_mode <= datain(2);
			end if;
		end if;
	end process;
	
	-- TX logic
	process(clk, reset)
	begin
		if reset='1' then
			tx_we    <= '0';
			tx_din   <= x"00";
			txl_fill <= "000";
			txl_buf  <= x"00000000";
		elsif rising_edge(clk) then
			-- check for write-request
			if reg_we(0)='1' then
				--> write request from CPU, fill buffer
				if xbus_mode='1' then
					-- 4 bytes
					txl_fill <= to_unsigned(4,3);
					txl_buf  <= datain;
				else 
					-- 1 byte
					txl_fill <= to_unsigned(1,3);
					txl_buf  <= datain(7 downto 0) & x"000000";
				end if;
			end if;
			
			-- serve transmitter
			if tx_ready='1' and txl_fill/=0 then
				-- transfer byte into transmitter
				txl_fill <= txl_fill-1;
				txl_buf  <= txl_buf(23 downto 0) & x"00";
				tx_we    <= '1';
				tx_din   <= txl_buf(31 downto 24);
			else
				-- nothing to do
				tx_we <= '0';
			end if;
		end if;
	end process;
	
	-- RX logic
	process(clk, reset)
	begin
		if reset='1' then
			rx_re    <= '0';
			rxl_fill <= "000";
			rxl_buf  <= x"FFFFFFFF";
		elsif rising_edge(clk) then
			-- check for read-request
			if reg_re(0)='1' then
				-- clear buffer
				rxl_fill <= "000";
				rxl_buf  <= x"00000000";
			end if;
			
			-- serve receiver
			if rx_ready='1' and xbus_rxready='0' then
				-- transfer byte from receiver
				rxl_fill <= rxl_fill+1;
				rxl_buf  <= rxl_buf(23 downto 0) & rx_dout;
				rx_re    <= '1';
			else
				-- nothing to do
				rx_re <= '0';
			end if;
		end if;
	end process;
	
	-- set constant baudrate of 115200
	clkincr	<= to_unsigned(integer(16.0*115200.00/real(FREQ) * 65536.0), 16);
	
	
	--
	-- components
	--
	
	-- clock generator
	i_clkgen: entity xuart_clkgen
		port map (
			clk        => clk,
			reset      => reset,
			incr       => clkincr,
			startrx    => rx_startclk,
			baseclk    => baseclk,
			rxclk      => rxclk,
			txclk      => txclk
		);

	-- transmitter
	i_trans: entity xuart_transmitter
		port map (
			clk        => clk,
			reset      => reset,
			enable     => '1',
			ready      => tx_ready,
			empty      => tx_empty,
			err_ovl    => tx_err_ovl,
			fill       => tx_fill,
			txclk      => txclk,
			we         => tx_we,
			din        => tx_din,
			pad_txd_o  => pad_txd_o
		);
		
	-- receiver
	i_recv: entity xuart_receiver
		port map (
			clk        => clk,
			reset      => reset,
			enable     => '1',
			startrx    => rx_startclk,
			ready      => rx_ready,
			err_ovl    => rx_err_ovl,
			err_frame  => rx_err_frm,
			fill       => rx_fill,
			rxclk      => rxclk,
			ovclk      => baseclk,
			re         => rx_re,
			dout       => rx_dout,
			pad_rxd_i  => pad_rxd_i
		);

end rtl;