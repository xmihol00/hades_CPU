library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.all;
	use xbus_common.xtoolbox.all;
library work;
	use work.all;
	
entity xbus_syn is
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
		memintr		: out std_logic;
		
		-- periphery
		led_out		: out std_logic_vector(15 downto 0);
		seg         : out std_logic_vector(6 downto 0);
		dp          : out std_logic;
		an          : out std_logic_vector(3 downto 0);
		swt_in		: in  std_logic_vector(15 downto 0);
		btn_in		: in  std_logic_vector(3 downto 0);
		rot_a       : in  std_logic;
		rot_b       : in  std_logic;
		uart_rx		: in  std_logic;
		uart_tx		: out std_logic;
		vga_vsync	: out std_logic;
		vga_hsync	: out std_logic;
		vga_r		: out std_logic_vector(3 downto 0);
		vga_g		: out std_logic_vector(3 downto 0);
		vga_b		: out std_logic_vector(3 downto 0);
		ps2_clk		: inout std_logic;
		ps2_data	: inout std_logic
	);
end xbus_syn;

architecture rtl of xbus_syn is	

	-- config
	constant FREQ		: natural := 50000000;	-- bus frequency
	constant N          : natural := 6;			-- number of peripherals on bus
	
	-- internal types
	subtype data_t is std_logic_vector(31 downto 0); 
	type data_array_t is array(natural range<>) of data_t;
	
	-- status
	signal ractive      : std_logic;
	signal wactive      : std_logic;
	
	-- data memory ports
	signal dmem_adr     : unsigned(11 downto 0);
	signal dmem_dout    : data_t;
	signal dmem_read    : std_logic;
	signal dmem_write   : std_logic;

	-- peripherie ports
	signal perp_adr     : unsigned(7 downto 0);
	signal perp_dout    : data_array_t(N-1 downto 0);
	signal perp_sel     : data_t;
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
	perp_read  <= (not dmemop) and (read and (not ractive));
	perp_write <= (not dmemop) and (write and (not wactive));
	
	process(clk, reset)
	begin
		if reset='1' then
			ractive  <= '0';
			wactive  <= '0';
			ack      <= '0';
			perintr  <= '0';
			perp_sel <= (others=>'0');
		elsif rising_edge(clk) then
			-- apply default values
			ack      <= '0';
			perintr  <= '0';
			perp_sel <= (others=>'0');
			
			-- register request-flags (needed to generate RE/WE-pulses)
			ractive <= read;
			wactive <= write;
				
			-- check for peripheral access
			if (dmemop='0' and (read='1' or write='1')) then
				-- check if any peripheral feels responsible
				for i in 0 to N-1 loop
					if perp_present(i)='1' then
						--> peripheral found
						if perp_ack(i)='1' then
							--> peripheral acked request, latch result
							ack      <= '1';
							perp_sel <= perp_dout(i);
						end if;
					end if;
				end loop;
			end if;

			-- assert IRQ if any peripheral wants it
			perintr <= or_reduce(perp_intr);
		end if;
	end process;
	
	-- create xpresent-signal (needs to be updated instantaneous)
	xpresent <= (not dmemop) and or_reduce(perp_present);
	
	-- output multiplexer between memory & peripheral-bus
	dataout <= dmem_dout when dmemop='1' else perp_sel;

	
	--
	-- peripheral components
	--
	
	-- data-memory
	i_dmem: entity work.xdmemory_dcache
		generic map (
			BASE_ADDR	=> 16#00000#
		)
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
			SIM			=> false
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

	-- console
	i_cons: entity work.xconsole
		generic map (
			FREQ		=> FREQ
		)
		port map (
			-- common
			clk 		=> clk,
			reset		=> reset,
			
			-- bus interface
			adr			=> perp_adr,
			datain		=> datain,
			dataout		=> perp_dout(1),
			read		=> perp_read,
			write		=> perp_write,
			present		=> perp_present(1),
			ack			=> perp_ack(1),
			intr		=> perp_intr(1),
			
			-- external signals
			led_out		=> led_out,
			swt_in		=> swt_in,
			btn_in		=> btn_in,
			rot_a       => rot_a,
			rot_b       => rot_b
		);
		
	
	-- XUart (UART communication port)
	i_uart: entity work.xuart
		generic map (
			FREQ		=> FREQ
		)
		port map (
			-- common
			clk 		=> clk,
			reset		=> reset,
			
			-- bus interface
			adr			=> perp_adr,
			datain		=> datain,
			dataout		=> perp_dout(2),
			read		=> perp_read,
			write		=> perp_write,
			present		=> perp_present(2),
			ack			=> perp_ack(2),
			intr		=> perp_intr(2),
			
			-- external signals
			pad_rxd_i	=> uart_rx,
			pad_txd_o	=> uart_tx
		);
		
	-- XVGA (VGA component)
	i_vga: entity work.xvga
		generic map (
			BASE_ADDR	=> 16#40000#,
			FREQ		=> FREQ
		)
		port map (
			-- common
			clk 		=> clk,
			reset		=> reset,
			
			-- bus interface
			adr			=> perp_adr,
			datain		=> datain,
			dataout		=> perp_dout(3),
			read		=> perp_read,
			write		=> perp_write,
			present		=> perp_present(3),
			ack			=> perp_ack(3),
			intr		=> perp_intr(3),
			
			-- external signals
			vga_vsync	=> vga_vsync,
			vga_hsync	=> vga_hsync,
			vga_r		=> vga_r,
			vga_g		=> vga_g,
			vga_b		=> vga_b
		);
	
	-- Xps2 (PS/2 interface)
	i_ps2: entity work.xps2
		generic map (
			FREQ		=> FREQ
		)
		port map (
			-- common
			clk 		=> clk,
			reset		=> reset,
			
			-- bus interface
			adr			=> perp_adr,
			datain		=> datain,
			dataout		=> perp_dout(4),
			read		=> perp_read,
			write		=> perp_write,
			present		=> perp_present(4),
			ack			=> perp_ack(4),
			intr		=> perp_intr(4),
			
			-- external signals
			ps2_clk		=> ps2_clk,
			ps2_data	=> ps2_data
		);
		
	-- sevensegment
    i_sevenseg: entity work.xsevenseg
        generic map (
            FREQ        => FREQ
        )
        port map (
            -- common
            clk         => clk,
            reset        => reset,
            
            -- bus interface
            adr            => perp_adr,
            datain        => datain,
            dataout        => perp_dout(5),
            read        => perp_read,
            write        => perp_write,
            present        => perp_present(5),
            ack            => perp_ack(5),
            intr        => perp_intr(5),
            
            -- external signals
            seg => seg,
            dp => dp,
            an => an
        );
		
end rtl;
