-------------------------------------------------------------------------------
-- xconsole_deglitch (deglitch input from switches/buttons) -------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;

entity xconsole_deglitch is
	generic (
		N       : natural;
		FREQ    : natural
	);
	port(
		-- common
		clk     : in  std_logic;
		reset   : in  std_logic;
		
		-- signals
		din	    : in  std_logic_vector(N-1 downto 0);
		dout    : out std_logic_vector(N-1 downto 0)
	);
end xconsole_deglitch;

architecture rtl of xconsole_deglitch is
	
	-- timing constants
	constant CYCLES_2ms : natural := FREQ / 500;
	
	-- internal types
	subtype cnt_t is unsigned(log2(CYCLES_2ms)-1 downto 0);
	type context_t is record
		ireg    : std_logic_vector(3 downto 0);
		status  : std_logic;
		active  : std_logic;
		counter : cnt_t;
	end record context_t;
	type context_array_t is array(natural range<>) of context_t;
	
	-- context
	signal ctx : context_array_t(N-1 downto 0);

begin
	
	-- update everything
	process(clk, reset)
	begin
		if reset='1' then
			ctx  <= (others=>(x"0",'0','0',(cnt_t'range=>'0')));
			dout <= (others=>'0');
		elsif rising_edge(clk) then
			for i in 0 to N-1 loop
				-- synchronize input
				ctx(i).ireg <= ctx(i).ireg(2 downto 0) & din(i);
				
				-- deglitch-logic
				if ctx(i).active='0' then
					if ctx(i).status/=ctx(i).ireg(3) then
						-- input has changed, start countdown to check if new input is stable
						ctx(i).active  <= '1';
						ctx(i).counter <= to_unsigned(CYCLES_2ms-1, ctx(i).counter'length);
					end if;
				else
					if ctx(i).status/=ctx(i).ireg(3) then
						-- input still changed
						ctx(i).counter <= ctx(i).counter-1;
						if ctx(i).counter=0 then
							--> stable to 2ms, accept new value
							ctx(i).status <= ctx(i).ireg(ctx(i).ireg'left);
							ctx(i).active <= '0';
						end if;
					else
						-- input changed back to old value, abort
						ctx(i).active <= '0';
					end if;
				end if;
				
				-- set output
				dout(i) <= ctx(i).status;
			end loop;
		end if;
	end process;
end rtl;

-------------------------------------------------------------------------------
-- XConsole                                                                  --
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
library work;
	use work.all;
	
entity xconsole is
	generic (
		FREQ		: natural
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
		intr		: out std_logic;
		
		-- external signals
		led_out		: out std_logic_vector(15 downto 0);
		btn_in		: in  std_logic_vector(3 downto 0);
		swt_in		: in  std_logic_vector(15 downto 0);
		rot_a       : in  std_logic;
		rot_b       : in  std_logic
	);
end xconsole;

architecture rtl of xconsole is		

	-- config
	constant BASE : natural := 64;
	constant REGS : natural := 5;
	
	-- register bank
	signal reg_data		: regbank(REGS-1 downto 0);
	signal reg_re		: std_logic_vector(REGS-1 downto 0);
	signal reg_we		: std_logic_vector(REGS-1 downto 0);
	
	-- LED status
	signal led_ena		: std_logic_vector(15 downto 0);
	signal led_blink	: std_logic_vector(15 downto 0);

	-- switch status
	signal swt_on	    : std_logic_vector(15 downto 0);
	signal swt_irq_set  : std_logic_vector(15 downto 0);
	
	-- button status
	signal btn_stat     : std_logic_vector(3 downto 0);
	signal btn_irq_set  : std_logic_vector(3 downto 0);
	
	-- IRQ status
	signal irq_ena	    : std_logic_vector(19 downto 0);
	signal irq_flg      : std_logic_vector(19 downto 0);
	
	-- blink status
	signal blink_cnt	: unsigned(log2(FREQ/2)-1 downto 0);
	signal blink_stat	: std_logic;
	
	-- button/switch edge detection
	signal swt_dg  : std_logic_vector(15 downto 0);
	signal swt_dgl : std_logic_vector(15 downto 0);
	signal btn_dg  : std_logic_vector(3 downto 0);
	signal btn_dgl : std_logic_vector(3 downto 0);
	
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
	reg_data(0) <= to_slv32(led_blink & led_ena);
	reg_data(1) <= to_slv32(swt_on);
	reg_data(2) <= to_slv32(btn_stat);
	reg_data(3) <= to_slv32(irq_ena);
	reg_data(4) <= to_slv32(irq_flg);
	
	-- handle requests
	process(clk, reset)
		variable irq_set : std_logic_vector(19 downto 0);
		variable irq_clr : std_logic_vector(19 downto 0);
		variable btn_clr : std_logic_vector(3 downto 0);
	begin
		if reset='1' then
			led_ena	  <= (others=>'0');
			led_blink <= (others=>'0');
			led_out   <= (others=>'0');
			swt_on    <= (others=>'0');
			btn_stat  <= (others=>'0');
			irq_ena   <= (others=>'0');
			irq_flg   <= (others=>'0');
			intr      <= '0';
		elsif rising_edge(clk) then
			
			-- handle LED register writes
			if reg_we(0)='1' then 
				led_ena   <= datain( 15 downto 0);
				led_blink <= datain(31 downto 16);
			end if;
			
			-- update LED output
			led_out <= led_ena and ((not led_blink) or (led_blink'range=>blink_stat));
			
			-- update switch-status
			swt_on <= swt_dg;
			
			-- update button-status
			if reg_we(2)='1' 
				then btn_clr := datain(3 downto 0);
				else btn_clr := (others=>'0');
			end if;
			btn_stat <= (btn_stat and (not btn_clr)) or btn_irq_set;
			
			-- update IRQ enable flags
			if reg_we(3)='1' then 
				irq_ena <= datain(19 downto 0);
			end if;
			
			-- update IRQ flags
			irq_set := btn_irq_set & swt_irq_set;
			irq_clr := (others => '0');
			if reg_we(4)='1' then 
				irq_clr := datain(19 downto 0);
			end if;
			irq_flg <= (irq_flg and (not irq_clr)) or irq_set;
			
			-- set final irq flag
			intr <= '0';
			if or_reduce(irq_ena and irq_flg)='1' then
				intr <= '1';
			end if;
		end if;
	end process;

	-- counter to create LED blink status
	process(clk, reset)
	begin
		if reset='1' then
			blink_cnt  <= to_unsigned(0, blink_cnt'length);
			blink_stat <= '0';
		elsif rising_edge(clk) then
			-- update blink-status
			if blink_cnt=0 then
				blink_cnt  <= to_unsigned(FREQ/2-1, blink_cnt'length);
				blink_stat <= not blink_stat;
			else
				blink_cnt  <= blink_cnt-1;
			end if;
		end if;
	end process;

	-- create button/switch IRQs
	process(clk, reset)
	begin
		if reset='1' then
			swt_dgl     <= (others=>'0');
			btn_dgl     <= (others=>'0');
			swt_irq_set <= (others=>'0');
			btn_irq_set <= (others=>'0');
		elsif rising_edge(clk) then
			-- delay input by one cycle for edge-detection
			swt_dgl <= swt_dg;
			btn_dgl <= btn_dg;
			
			-- trigger switch-irq on every edge
			swt_irq_set <= swt_dg xor swt_dgl;
			
			-- trigger button-irq in falling edge
			btn_irq_set <= btn_dg and (not btn_dgl);
		end if;
	end process;
	
	-- deglitch switch input
	dgswt: entity xconsole_deglitch
		generic map (
			N     => 16,
			FREQ  => FREQ
		)
		port map (
			clk   => clk,
			reset => reset,
			din	  => swt_in,
			dout  => swt_dg
		);
		
	-- deglitch button input
	dgbtn: entity xconsole_deglitch
		generic map (
			N     => 4,
			FREQ  => FREQ
		)
		port map (
			clk   => clk,
			reset => reset,
			din	  => btn_in,
			dout  => btn_dg
		);

end rtl;
