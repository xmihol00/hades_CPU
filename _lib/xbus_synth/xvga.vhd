library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
library work;
	use work.all;
	
	
entity xvga is
	generic (
		BASE_ADDR	: natural;
		FREQ        : natural
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
		vga_vsync	: out std_logic;
		vga_hsync	: out std_logic;
		vga_r		: out std_logic_vector(3 downto 0);
		vga_g		: out std_logic_vector(3 downto 0);
		vga_b		: out std_logic_vector(3 downto 0)
	);
end xvga;

architecture rtl of xvga is		

	-- config
	constant BASE : natural := 160;
	constant REGS : natural := 3;
	
	-- register bank
	signal reg_data	  : regbank(REGS-1 downto 0);
	signal reg_re	  : std_logic_vector(REGS-1 downto 0);
	signal reg_we	  : std_logic_vector(REGS-1 downto 0);

	-- write cache 
	signal wc_addr	   : unsigned(18 downto 0);
	signal wc_mem_adr  : unsigned(16 downto 0);
	signal wc_pxl_idx  : natural;
	
	signal w_cache     : std_logic_vector(15 downto 0);
	signal w_cache0    : std_logic_vector(15 downto 0);
	signal w_cache1    : std_logic_vector(15 downto 0);
	signal w_cache2    : std_logic_vector(15 downto 0);
	signal w_cache3    : std_logic_vector(15 downto 0);
	signal w_cache4    : std_logic_vector(15 downto 0);

	-- read cache	
	signal rc_addr     : unsigned(18 downto 0);
	signal rc_addr_reg : unsigned(18 downto 0);
    signal rc_mem_adr  : unsigned(16 downto 0);
    signal rc_pxl_idx  : natural;
    
    signal r_cache     : std_logic_vector(15 downto 0);
    signal r_cache0    : std_logic_vector(15 downto 0);
    signal r_cache1    : std_logic_vector(15 downto 0);
    signal r_cache2    : std_logic_vector(15 downto 0);
    signal r_cache3    : std_logic_vector(15 downto 0);
    signal r_cache4    : std_logic_vector(15 downto 0);    	
    
    signal rc_vsync	   : std_logic;
    signal rc_hsync    : std_logic;
    signal rc_enable   : std_logic;
    signal rc_data	   : std_logic_vector(3 downto 0); 
	
	
    -- internal types
    
    -- uses 4 times a 16kx4 block ram -> memory for     262144 bit
    -- uses 4 times a 16kx4 block ram -> memory for     262144 bit
    -- uses 4 times a 16kx4 block ram -> memory for     262144 bit
    -- uses 4 times a 16kx4 block ram -> memory for     262144 bit
    -- uses 4 times a 16kx4 block ram -> memory for     262144 bit                
    -- 640x480x4bit =                                  -1228800 bit
    --                                                  ___________
    --                                                    81920 bit = 20480 pixel free
	type mem_t is array(16383 downto 0) of std_logic_vector(15 downto 0);
    
    
	--memory
	signal mem0 : mem_t := (others => x"0000");
	signal mem1 : mem_t := (others => x"0000");
	signal mem2 : mem_t := (others => x"0000");
	signal mem3 : mem_t := (others => x"0000");
	signal mem4 : mem_t := (others => x"0000");
begin
	
	-- no interrupts
	intr <= '0';
	
	-- connect register bank
	process(adr, read, write, reg_data)
		variable sel : integer;
	begin
		-- set default output
		present <= '0';
		ack <= '0';
		dataout <= (others=>'0');
		reg_re <= (others =>'0');
		reg_we <= (others =>'0');
		
		-- get selection
		sel := to_integer(unsigned(adr)) - BASE;
		if (sel>=0) and (sel<REGS) then
			present     <= '1';
			ack         <= '1';
			dataout     <= reg_data(sel);
			reg_re(sel) <= read;
			reg_we(sel) <= write;
		end if;
	end process;
	
	-- set output
	reg_data(0) <= std_logic_vector(resize(wc_addr,32));
	reg_data(1) <= (31 downto 4 => '0') & w_cache((wc_pxl_idx+3) downto wc_pxl_idx);
	reg_data(2) <= (31 downto 16 => '0') & w_cache;
	
	
	
	wc_pxl_idx <= to_integer(wc_addr(1 downto 0) & "00");
    wc_mem_adr <= wc_addr(18 downto 2);
	
	-- update reg address
	process(clk, reset)
	begin
		if reset='1' then
			wc_addr <= (others=>'0');
		elsif rising_edge(clk) then
			-- handle direct address-update
			if reg_we(0)='1' then 
				wc_addr <= unsigned(datain(18 downto 0));
			-- auto-increment address
			elsif reg_we(1)='1' or reg_re(1)='1' then
				wc_addr <= wc_addr + 1;
			elsif reg_we(2)='1' or reg_re(2)='1' then
				wc_addr <= wc_addr + 4;
			end if;
		end if;
	end process;
	
	
	process(reset, clk)
	begin
	  if reset='1' then
	    w_cache0 <= (others => '0');
	    w_cache1 <= (others => '0');
	    w_cache2 <= (others => '0');
	    w_cache3 <= (others => '0');
	    w_cache4 <= (others => '0');
	  elsif rising_edge(clk) then
	    w_cache0 <= mem0(to_integer(wc_mem_adr(13 downto 0)));
	    w_cache1 <= mem1(to_integer(wc_mem_adr(13 downto 0)));
        w_cache2 <= mem2(to_integer(wc_mem_adr(13 downto 0)));	  
        w_cache3 <= mem3(to_integer(wc_mem_adr(13 downto 0)));	  
        w_cache4 <= mem4(to_integer(wc_mem_adr(13 downto 0)));	   
      end if;
	end process;
	
with wc_mem_adr(16 downto 14) select
    w_cache <= w_cache0 when "000",
             w_cache1 when "001",
             w_cache2 when "010",
             w_cache3 when "011",
             w_cache4 when "100",
             (w_cache'range => '0') when others;
	
	-- infer ram
    process(reset, clk)
        constant MASK : unsigned(15 downto 0) := "0000000000001111";
        variable value : std_logic_vector(15 downto 0);
    begin
        if rising_edge(clk) then
            if reg_we(1)='1' then
                value := (w_cache and not std_logic_vector(MASK sll wc_pxl_idx)) 
                            or std_logic_vector(resize(unsigned(datain(3 downto 0)), 16) sll wc_pxl_idx);
            elsif reg_we(2)='1' then
                value := datain(15 downto 0);
            end if;
            
            if (reg_we(1)='1' or reg_we(2)='1') then
                case wc_mem_adr(16 downto 14) is
                 when "000"  => mem0(to_integer(wc_mem_adr(13 downto 0))) <= value;
                 when "001"  => mem1(to_integer(wc_mem_adr(13 downto 0))) <= value;
                 when "010"  => mem2(to_integer(wc_mem_adr(13 downto 0))) <= value;
                 when "011"  => mem3(to_integer(wc_mem_adr(13 downto 0))) <= value;
                 when others => mem4(to_integer(wc_mem_adr(13 downto 0))) <= value;
                end case;
            end if;
          
        end if;
    end process;	
    

    process(rc_vsync, rc_enable, rc_addr_reg)
        variable rc_addr_new : unsigned(18 downto 0);
    begin
        rc_addr_new := rc_addr_reg;
        if rc_vsync='1' then 
            rc_addr_new := to_unsigned(0, rc_addr'length);
        elsif rc_enable='1' then
            rc_addr_new := rc_addr_new + 1;
        end if;
        rc_addr <= rc_addr_new;
    end process;  
    
    process(reset, clk)
    begin
        if reset='1' then
            rc_addr_reg <= (others => '0');
        elsif rising_edge(clk) then 
            rc_addr_reg <= rc_addr;
        end if;
    end process;    
    
    
    process(reset, clk)
    begin
        if reset='1' then
            r_cache0 <= (others => '0');
            r_cache1 <= (others => '0');
            r_cache2 <= (others => '0');
            r_cache3 <= (others => '0');
            r_cache4 <= (others => '0');
        elsif rising_edge(clk) then
            --if rc_enable='1' then
                r_cache0 <= mem0(to_integer(rc_mem_adr(13 downto 0)));
                r_cache1 <= mem1(to_integer(rc_mem_adr(13 downto 0)));
                r_cache2 <= mem2(to_integer(rc_mem_adr(13 downto 0)));
                r_cache3 <= mem3(to_integer(rc_mem_adr(13 downto 0)));
                r_cache4 <= mem4(to_integer(rc_mem_adr(13 downto 0)));
            --end if;
        end if;
    end process;
	
	rc_mem_adr <= rc_addr(18 downto 2);
	rc_pxl_idx <= to_integer(rc_addr(1 downto 0) & "00");
	
	
	with rc_mem_adr(16 downto 14) select
        r_cache <= r_cache0 when "000",
                 r_cache1 when "001",
                 r_cache2 when "010",
                 r_cache3 when "011",
                 r_cache4 when "100",
                 (r_cache'range => '0') when others;
	rc_data <= r_cache((rc_pxl_idx + 3) downto rc_pxl_idx);
	
	
	
	-- output formater
	vga: entity xvga_out
		port map (
			-- common
			clk 		=> clk,
			reset 		=> reset,
			
			-- data input
			in_vsync	=> rc_vsync,
			in_hsync	=> rc_hsync,
			in_enable	=> rc_enable,
			in_data		=> rc_data,
			
			-- VGA output
			vga_vsync	=> vga_vsync,
			vga_hsync	=> vga_hsync,
			vga_r		=> vga_r,
			vga_g		=> vga_g,
			vga_b		=> vga_b
		);

end rtl;
