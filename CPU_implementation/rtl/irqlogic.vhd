---------------------------------------------------------------------------------------------------
--
-- Titel: IRQ logic
-- Autor: David Mihola (12211951)
-- Datum: 26. 03. 2023 
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.all;
	use work.hadescomponents.all;
	
entity irqlogic is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- interrupt inputs
		xperintr	: in  std_logic;
		xnaintr		: in  std_logic;
		xmemintr	: in  std_logic;
		
		-- control input
		pcwrite		: in  std_logic;
		pccontr		: in  std_logic_vector(4 downto 0);
		pcnext		: in  std_logic_vector(11 downto 0);
		pcnew		: in  std_logic_vector(11 downto 0);
		sisalvl		: in  std_logic_vector(1 downto 0);
		
		-- control output
		intr		: out std_logic;
		isra		: out std_logic_vector(11 downto 0);
		isrr		: out std_logic_vector(11 downto 0)
	);
end irqlogic;

architecture rtl of irqlogic is
	signal inner_selisra   : std_logic_vector(2 downto 0);
	signal inner_retilvl   : std_logic_vector(2 downto 0);
	signal inner_curlvl	   : std_logic_vector(2 downto 0);
	signal inner_intr	   : std_logic;
	signal swi_and_pcwrite : std_logic;
begin
	-- instruction: SWI RETI ENI DEI SISA
    -- pccontr:       4    3   2   1    0

	swi_and_pcwrite <= pccontr(4) and pcwrite;

	ISRA_logic: entity work.isralogic
		port map (
			clk		=> clk,
			reset	=> reset,
			
			pcwrite => pcwrite,
			sisa    => pccontr(0),
			sisalvl => sisalvl,
			pcnew   => pcnew,
			selisra => inner_selisra,

			isra    => isra
		);
	
	ISRR_logic: entity work.isrrlogic
		port map (
			clk		=> clk,
			reset	=> reset,
			
			pcwrite => pcwrite,
			intr    => inner_intr,
			reti    => pccontr(3), 
			pcnext  => pcnext,
			curlvl  => inner_curlvl,

			retilvl => inner_retilvl,
			isrr    => isrr
		);
	
	check_IRQ: entity work.checkirq
		port map (
			clk		=> clk,
			reset	=> reset,
			
			xperintr => xperintr,
			xnaintr  => xnaintr,
			xmemintr => xmemintr,
			
			swintr   => swi_and_pcwrite,
            pcwrite  => pcwrite,
            eni      => pccontr(2),
            dei 	 => pccontr(1),
            reti	 => pccontr(3),
            retilvl  => inner_retilvl,

			curlvl   => inner_curlvl,
			selisra  => inner_selisra,
			intr     => inner_intr
		);

		intr <= inner_intr;
end rtl;
