library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
	
entity xvga_out is
	port (
		-- common
		clk 		: in  std_logic;
		reset 		: in  std_logic;
		
		-- data input
		in_vsync	: out std_logic;
		in_hsync	: out std_logic;
		in_enable	: out std_logic;
		in_data		: in  std_logic_vector(3 downto 0);
		
		-- VGA output
		vga_vsync	: out std_logic;
		vga_hsync	: out std_logic;
		vga_r		: out std_logic_vector(3 downto 0);
		vga_g		: out std_logic_vector(3 downto 0);
		vga_b		: out std_logic_vector(3 downto 0)
	);
end xvga_out;

architecture rtl of xvga_out is

	-- states
	type state_t is (
		sReset,		-- init state
		sSync,		-- sync pulse
		sFPorch,	-- front porch
		sVideo,		-- video data
		sBPorch		-- back porch
	);

	-- control
	signal enable	: std_logic;
	signal hstate	: state_t;
	signal vstate	: state_t;
	signal hcounter	: unsigned(9 downto 0);
	signal vcounter : unsigned(9 downto 0);
	signal vtick    : std_logic;


--eingefügt
--signal counter : unsigned(11 downto 0);
signal vga_r_int		: std_logic_vector(3 downto 0);
signal vga_g_int		: std_logic_vector(3 downto 0);
signal vga_b_int		: std_logic_vector(3 downto 0);
		
begin
	
	-- control logic
	process(reset, clk)
	begin
		if reset='1' then
			hstate    <= sReset;
			vstate    <= sReset;
			hcounter  <= (others=>'0');
			vcounter  <= (others=>'0');
			vtick     <= '0';
			in_vsync  <= '0';
			in_hsync  <= '0';
			in_enable <= '0';
			vga_vsync <= '0';
			vga_hsync <= '0';
			vga_r     <= (others=>'0');
			vga_g     <= (others=>'0');
			vga_b     <= (others=>'0');
			
			
		elsif rising_edge(clk) then
			-- set default-values
			in_vsync  <= '0';
			in_hsync  <= '0';
			in_enable <= '0';
			
            -- create 25mhz clock-enable
            enable <= not enable;
			if enable='1' then
				-- update horizontal status
				vtick    <= '0';
				hcounter <= hcounter-1;
				case hstate is
					when sReset => 
						hstate   <= sSync;
						hcounter <= to_unsigned(96-1, hcounter'length);
					when sSync => 
						if hcounter=0 then
							hstate   <= sFPorch;
							hcounter <= to_unsigned(16-1, hcounter'length);
						end if;
					when sFPorch => 
						if hcounter=0 then
							hstate   <= sVideo;
							hcounter <= to_unsigned(640-1, hcounter'length);                            
						end if;
					when sVideo => 
						if hcounter=0 then
							hstate   <= sBPorch;
							hcounter <= to_unsigned(48-1, hcounter'length);
						end if;
					when sBPorch => 
						if hcounter=1 then
							vtick <= '1';
						end if;
						if hcounter=0 then
							hstate   <= sSync;
							hcounter <= to_unsigned(96-1, hcounter'length);
						end if;
				end case;
				
				-- update vertical status
				if vtick='1' then
					vcounter <= vcounter-1;
					case vstate is
						when sReset => 
							vstate   <= sSync;
							vcounter <= to_unsigned(2-1, vcounter'length);
						when sSync => 
							if vcounter=0 then
								vstate   <= sFPorch;
								vcounter <= to_unsigned(10-1, vcounter'length);
							end if;
						when sFPorch => 
							if vcounter=0 then
								vstate   <= sVideo;
								vcounter <= to_unsigned(480-1, vcounter'length);
							end if;
						when sVideo => 
							if vcounter=0 then
								vstate   <= sBPorch;
								vcounter <= to_unsigned(29-1, vcounter'length);
							end if;
						when sBPorch => 
							if vcounter=0 then
								vstate   <= sSync;
								vcounter <= to_unsigned(2-1, vcounter'length);
								in_vsync <= '1';
							end if;
					end case;
				end if;
	
				-- set output
				if hstate=sSync
					then vga_hsync <= '0';
					else vga_hsync <= '1';
				end if;
				if vstate=sSync
					then vga_vsync <= '0';
					else vga_vsync <= '1';
				end if;

				if hstate=sVideo and vstate=sVideo then
					in_enable <= '1';
					-- https://de.wikipedia.org/wiki/Color_Graphics_Adapter
					if in_data="0110" then       -- dark yellow -> brown
                       vga_r <= (1 => '0', others => '1');                        -- 2/3
                       vga_g <= (1 => '1', others => '0');                        -- 1/3
                       vga_b <= (others => '0');                                  -- 0                    
					elsif in_data(3)='0' then
					   vga_r <= (1 => '0', others => in_data(2));                  -- 2/3
					   vga_g <= (1 => '0', others => in_data(1));                  -- 2/3
					   vga_b <= (1 => '0', others => in_data(0));                  -- 2/3
					else
                        vga_r <= (1 => '1', others => in_data(2));                 -- 1/3 + 2/3
                        vga_g <= (1 => '1', others => in_data(1));                 -- 1/3 + 2/3
                        vga_b <= (1 => '1', others => in_data(0));                 -- 1/3 + 2/3			
					end if;
				else
					vga_r <= "0000";
					vga_g <= "0000";
					vga_b <= "0000";
				end if;
			end if;
		end if;
	end process;
end rtl;
