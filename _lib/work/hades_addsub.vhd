library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity hades_addsub is
	generic (
		N	: natural
	);
	port (
		-- control
		sub	: in  std_logic;
		
		-- input
		a	: in  std_logic_vector(N-1 downto 0);
		b	: in  std_logic_vector(N-1 downto 0);
		
		-- output
		r	: out std_logic_vector(N-1 downto 0);	
		ov	: out std_logic
	);
end hades_addsub;

architecture rtl of hades_addsub is

begin
	
	process(a,b,sub)
		variable aext : signed(N downto 0);
		variable bext : signed(N downto 0);
		variable rext : signed(N downto 0);
	begin
		-- expand input
		aext := resize(signed(a),N+1);
		bext := resize(signed(b),N+1);
		
		-- do addition/subtraction
		if sub='0'
			then rext := aext + bext;
			else rext := aext - bext;
		end if;
		
		-- set result
		r  <= std_logic_vector(rext(N-1 downto 0));
		ov <= rext(N) xor rext(N-1);
	end process;
	
end rtl;
