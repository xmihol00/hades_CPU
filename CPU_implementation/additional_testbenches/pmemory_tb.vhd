---------------------------------------------------------------------------------------------------
--
-- titel:   Additional test bench for the pmemory component
-- autor:   David Mihola (12211951)
-- date:    12. 03. 2023
-- runtime: 670ns
--   
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.all;
	use work.hadescomponents.all;
  
entity pmemory_tb is
end pmemory_tb;

architecture tb_architecture of pmemory_tb is
	signal clk     : std_logic    := '0';
	signal reset   : std_logic    := '0';
	signal pwrite  : std_logic    := '0';
	signal loadir  : std_logic    := '0';
	signal raddr   : std_logic_vector(11 downto 0) := (others => '0');	
	signal waddr   : std_logic_vector(11 downto 0) := (others => '0');
	signal datain  : std_logic_vector(31 downto 0) := (others => '0');
	
	-- tested signals
	signal dataout : std_logic_vector(31 downto 0) := (others => '0');
begin
  	-- unit under test
	UUT: entity pmemory
    generic map ("../_testbench/pmemory_tb.hex")                            
		port map (
			CLK      => clk,
			RESET    => reset,
			RADR     => raddr,
			LOADIR   => loadir,
			DATAIN   => datain,
			WADR     => waddr,
			PWRITE   => pwrite,
			DATAOUT  => dataout
		);           

    -- CLK stimulus [50MHz]
    clk <= not clk after 10 ns;    	   
  
    -- assersion procedure
    test: process 
		procedure prove(ra, wa : integer; rd, wd: std_logic_vector(31 downto 0)) is
    		begin
			-- set input
			waddr   <= std_logic_vector(to_unsigned(wa, waddr'length));
			raddr   <= std_logic_vector(to_unsigned(ra, raddr'length));
			datain <= wd;
			
			-- wait some time
			wait for 10 ns;
			
			-- check output
			assert dataout = rd 
				report "wrong DATAOUT 0x" & to_hex(dataout) & "; expected 0x" & to_hex(rd)  
				severity error;

			-- wait reset of cycle
			wait for 10 ns;
		end;
	begin   
    	wait for 5 ns; 
				
		-- read-only
    	pwrite <= '0';
		loadir <= '1';
		prove( 0,  0, x"11111111", x"00000000"); --  15ns
		prove( 1,  0, x"22222222", x"00000000"); --  35ns
		prove( 2,  0, x"33333333", x"00000000"); --  55ns
		prove( 3,  0, x"44444444", x"00000000"); --  75ns

		pwrite <= '1';
		prove( 1,  0, x"22222222", x"00000000"); --  95ns

		pwrite <= '0';
		prove( 0,  1, x"00000000", x"12345678"); --  115ns
		prove( 1,  0, x"22222222", x"00000000"); --  135ns

		loadir <= '0';
		prove( 0,  0, x"22222222", x"00000000"); --  155ns
		prove( 1,  0, x"22222222", x"00000000"); --  175ns
		prove( 2,  0, x"22222222", x"00000000"); --  195ns

		reset <= '1';
		wait for 10 ns;
		reset <= '0';
		wait for 10 ns;
		prove( 0,  0, x"22222222", x"00000000"); --  235ns
		
		-- read/write from the same address
		loadir <= '1';
		pwrite <= '1';
		prove( 0,  0, x"00000000", x"11111111"); --  255ns
		prove( 0,  0, x"11111111", x"11111111"); --  275ns
		
		-- memcpy
		prove( 1,  4, x"22222222",     dataout); --  295ns
		prove( 2,  5, x"33333333",     dataout); --  315ns
		prove( 3,  6, x"44444444",     dataout); --  335ns
		prove( 4,  7, x"11111111",     dataout); --  355ns
		
		-- check of copied memory
		pwrite <= '0';
		prove( 4,  0, x"11111111", x"00000000"); --  375ns
		prove( 5,  0, x"22222222", x"00000000"); --  395ns
		prove( 6,  0, x"33333333", x"00000000"); --  415ns
		prove( 7,  0, x"44444444", x"00000000"); --  435ns

		reset <= '1';
		prove( 7,  0, x"44444444", x"00000000"); --  455ns
		reset <= '0';

		prove(1023, 0, x"00000000", x"00000000"); --  475ns
		pwrite <= '1';
		prove(1023, 1023, x"00000000", x"FFFFFFFF"); --  495ns
		prove(1023, 1023, x"FFFFFFFF", x"EEEEEEEE"); --  515ns
		prove(1023, 1023, x"EEEEEEEE", x"EEEEEEEE"); --  535ns
		prove(   0, 1024, x"11111111", x"FFFFFFFF"); --  555ns
		prove(   0, 1024, x"11111111", x"FFFFFFFF"); --  575ns
		prove(1024, 1024, x"FFFFFFFF", x"FFFFFFFF"); --  595ns
		prove(   0, 4096, x"11111111", x"FFFFFFFF"); --  615ns
		prove(   0,    0, x"FFFFFFFF", x"EEEEEEEE"); --  635ns
		prove(   0,    0, x"EEEEEEEE", x"EEEEEEEE"); --  655ns

		-- done
    	pwrite <= '0';
		loadir <= '0';
		report "Test completed."
			severity NOTE;
    	wait;
  	end process;  
end tb_architecture;
