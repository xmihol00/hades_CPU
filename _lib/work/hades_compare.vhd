library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity hades_compare is
	generic (
		N	: natural := 32
	);
	port (
		-- input
		a	: in  std_logic_vector(N-1 downto 0);
		b	: in  std_logic_vector(N-1 downto 0);
		
		-- output
		lt	: out std_logic;
		eq	: out std_logic;
		gt  : out std_logic
	);
end hades_compare;

architecture rtl of hades_compare is
begin
	process(a,b)
		variable aext : signed(N downto 0);
		variable bext : signed(N downto 0);
		variable rext : signed(N downto 0);
		variable zero : std_logic;
	begin
		-- expand input
		aext := resize(signed(a),N+1);
		bext := resize(signed(b),N+1);
		
		-- do subtraction
		rext := aext - bext;
		
		-- check if result is zero
		if rext=0
			then zero := '1';
			else zero := '0';
		end if;
		
		-- set result flags
		eq <= zero;
		lt <= (not zero) and rext(rext'left);
		gt <= (not zero) and (not rext(rext'left));
	end process;
	
end rtl;
