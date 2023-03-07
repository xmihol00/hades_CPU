library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity hades_mul is
	generic (
		N	: natural
	);
	port (
		-- common
		clk : in  std_logic;
		
		-- input
		a	: in  std_logic_vector(N-1 downto 0);
		b	: in  std_logic_vector(N-1 downto 0);
		
		-- output
		r	: out std_logic_vector(N-1 downto 0);	
		ov	: out std_logic
	);
end hades_mul;

architecture rtl of hades_mul is

	signal mfull : signed(2*N-1 downto 0);
	signal high  : signed(N downto 0);

begin
	
	-- do multiplication
	mfull <= signed(a) * signed(b);
		
	-- output lower bits as result
	r <= std_logic_vector(mfull(N-1 downto 0));
	
	-- set overflow-flag if higher bits are not all equal
	ov <= '1' when high /= (high'range=>'0') and 
                   high /= (high'range=>'1') else '0';
	
	-- register high bits of result for timing reasons
	process(clk)
	begin
		if rising_edge(clk) then
			high <= mfull(2*N-1 downto N-1);
		end if;
	end process;
	
end rtl;
