---------------------------------------------------------------------------------------------------
--
-- Titel: Program Memory   
-- Autor: David Mihola (12211951)
-- Datum: 07. 03. 2023
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	use work.all;

entity pmemory is
	generic (
		INIT		: string := "UNUSED"
	);
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- write port
		pwrite		: in  std_logic;
		wadr		: in  std_logic_vector(11 downto 0);
		datain		: in  std_logic_vector(31 downto 0);
		
		-- read port
		loadir		: in  std_logic;
		radr		: in  std_logic_vector(11 downto 0);
		dataout	: out std_logic_vector(31 downto 0)
	);
end pmemory;

architecture rtl of pmemory is
begin
    MEM : entity work.hades_ram32_dp
    generic map (
    	INIT_FILE => INIT,
    	WIDTH_ADDR => 12,
    	INIT_DATA => hades_bootloader
    )
    port map (
      clk => clk,
      reset => reset,
      
      wena => pwrite,
      waddr => wadr,
      wdata => datain,
      
      rena => loadir,
      raddr => radr,
      rdata => dataout
    );
end rtl;
