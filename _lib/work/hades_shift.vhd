library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
library work;
	use work.hadescomponents.all;
	
entity hades_shift is
	generic (
		N			: natural
	);
	port (
		-- control
		cyclic		: in  std_logic;
		right		: in  std_logic;
		
		-- input
		a			: in  std_logic_vector(N-1 downto 0);
		b			: in  std_logic_vector(log2(N)-1 downto 0);
		
		-- output
		r			: out std_logic_vector(N-1 downto 0);
		ov			: out std_logic
	);
end hades_shift;

architecture rtl of hades_shift is
begin
	
	process(a,b,cyclic,right)
		variable cnt : unsigned(log2(N+1)-1 downto 0);
		variable msk : unsigned(N-1 downto 0);
		variable res : unsigned(N-1 downto 0);
		variable ovf : std_logic;
	begin
		-- get number of bits to rotate 
		if right='0'
			then cnt := resize(unsigned(b), cnt'length);
			else cnt := N - resize(unsigned(b), cnt'length);
		end if;
		
		-- create mask for bits which will be shifted out
		for i in msk'range loop
			if (N-i-1)<cnt
				then msk(i) := (not cyclic) and (not right);
				else msk(i) := (not cyclic) and right;
			end if;
		end loop;
		
		-- mask out bits which will be shifted out
		res := unsigned(a) and (not msk);
		
		-- set overflow-flag if any of the masked out bits was set
		ovf := or_reduce(a and std_logic_vector(msk));
		
		-- do rotate input
		for i in log2(N)-1 downto 0 loop
			if cnt(i)='1' then
				res := res rol 2**i;
			end if;
		end loop;
		
		-- output result
		r  <= std_logic_vector(res);
		ov <= ovf;
	end process;
	
end rtl;
