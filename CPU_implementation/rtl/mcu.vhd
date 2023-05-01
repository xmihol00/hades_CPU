library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.all;
library xbus_synth;
	use xbus_synth.all;
library work;
	use work.all;
	
entity mcu is
	generic (
		INIT		: string := "UNUSED"
	);
	port (
		-- clock input
		clk_in		: in  std_logic;
--  	-- reset input
		reset_in  : in std_logic;
		
		-- console
		led_out		: out std_logic_vector(15 downto 0);
		swt_in		: in  std_logic_vector(15 downto 0);
		btn_in		: in  std_logic_vector(3 downto 0);
		rot_a       : in  std_logic;
		rot_b       : in  std_logic;
		
		-- UART
		uart_rx		: in  std_logic;
		uart_tx		: out std_logic;
		
		-- PS/2 ports
		ps2_clk     : inout std_logic;
		ps2_data	: inout std_logic;
		
		-- VGA
		vga_vsync	: out std_logic;
		vga_hsync	: out std_logic;
		vga_r		: out std_logic_vector(3 downto 0);
		vga_g		: out std_logic_vector(3 downto 0);
		vga_b		: out std_logic_vector(3 downto 0);
		
		-- 7SEG
		seg			: out std_logic_vector(6 downto 0); -- cathodes
		dp			: out std_logic; 					-- point
		an			: out std_logic_vector(3 downto 0) -- anodes
		
	);
end mcu;

architecture rtl of mcu is

	-- reset signal
	signal reset	: std_logic;
	signal clk		: std_logic;

	-- interconnect
	signal xread	: std_logic;
	signal xwrite	: std_logic;
	signal xadr		: std_logic_vector(12 downto 0);
	signal xdatain	: std_logic_vector(31 downto 0);
	signal xdataout	: std_logic_vector(31 downto 0);
	signal xpresent	: std_logic;
	signal xack		: std_logic;
	signal dmemop	: std_logic;
	signal dmembusy	: std_logic;
	signal xperintr	: std_logic;
	signal xmemintr	: std_logic;
begin

  process(reset, clk_in)
  begin
	if reset='1' then
	   clk <= '0';
	elsif rising_edge(clk_in) then
	   clk <= not clk;
	end if;
  end process;

	-- reset generation
  i_rstgen: entity xbus_common.reset_own
    port map (
      clk => clk,
      reset_in => reset_in,
      reset_sys => reset
   ); 
	-- CPU
	i_cpu: entity work.cpu
		generic map (INIT=>INIT)
		port map (
			-- common
			clk 		=> clk,
			reset		=> reset,
			
			-- XBus
			xread		=> xread,
			xwrite		=> xwrite,
			xadr		=> xadr,
			xdatain		=> xdatain,
			xdataout	=> xdataout,
			xpresent	=> xpresent,
			xack		=> xack,
			dmemop		=> dmemop,
			dmembusy	=> dmembusy,
			xperintr	=> xperintr,
			xmemintr	=> xmemintr
		);
	
	-- peripherie
	i_xbus: entity xbus_synth.xbus_syn
		port map (
			-- common
			clk 		=> clk,
			reset		=> reset,
			
			-- common bus inteface
			adr			=> xadr,
			datain		=> xdataout,
			dataout		=> xdatain,
			read		=> xread,
			write		=> xwrite,
			
			-- peripherie bus signals
			ack			=> xack,
			xpresent	=> xpresent,
			perintr		=> xperintr,
			
			-- memory bus signals
			dmemop		=> dmemop,
			dmembusy	=> dmembusy,
			memintr		=> xmemintr,
			
			-- external signals
			led_out     => led_out,
			btn_in		=> btn_in,
			swt_in		=> swt_in,
			rot_a       => rot_a,
			rot_b       => rot_b,
			uart_rx		=> uart_rx,
			uart_tx		=> uart_tx,
			vga_vsync	=> vga_vsync,
			vga_hsync	=> vga_hsync,
			vga_r		=> vga_r,
			vga_g		=> vga_g,
			vga_b		=> vga_b,
			ps2_clk		=> ps2_clk,
			ps2_data	=> ps2_data,
			an          => an,
			seg         => seg,
			dp          => dp
		);
	
end rtl;
