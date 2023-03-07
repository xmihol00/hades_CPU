-------------------------------------------------------------------------------
-- reset_gen ------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;

entity reset_own is
	port (
		clk 	  	: in  std_logic;					-- some direct clock-input
		reset_in  : in std_logic;
		reset_sys	: out std_logic						-- global reset signal
	);
end reset_own;

architecture rtl of reset_own is
	
begin
	-- output reset-signal
	reset_sys <= reset_in;
end;
