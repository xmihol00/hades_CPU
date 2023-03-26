---------------------------------------------------------------------------------------------------
--
-- Titel: Program Counter Block
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
	
entity pcblock is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- interrupt inputs
		xperintr	: in  std_logic;
		xnaintr		: in  std_logic;
		xmemintr	: in  std_logic;
		
		-- ALU flags
		ov			: in  std_logic;
		zero		: in  std_logic;
		
		-- control input
		pcwrite		: in  std_logic;
		pccontr		: in  std_logic_vector(10 downto 0);
		pcnew		: in  std_logic_vector(11 downto 0);
		sisalvl     : in  std_logic_vector(1 downto 0);

		-- control output
		pcakt		: out std_logic_vector(11 downto 0);
		pcinc		: out std_logic_vector(11 downto 0)
	);
end pcblock;

architecture rtl of pcblock is
	signal inner_pcnext	: std_logic_vector(11 downto 0);
	signal inner_issr   : std_logic_vector(11 downto 0);
	signal inner_isra   : std_logic_vector(11 downto 0);
	signal inner_intr   : std_logic;

	signal irq_pccontr  : std_logic_vector(4 downto 0);
	signal pc_pccontr   : std_logic_vector(5 downto 0);
begin
	irq_pccontr <= pccontr(9) & pccontr(6 downto 3); -- SWI, RETI, ENI, DEI, SISA
	IRQ_logic: entity work.irqlogic
		port map (
			clk			=> clk,
			reset		=> reset,

			xperintr	=> xperintr,
			xnaintr		=> xnaintr,
			xmemintr	=> xmemintr,

			pcwrite     => pcwrite,
			pccontr     => irq_pccontr,
			pcnext      => inner_pcnext,
			pcnew       => pcnew,
			sisalvl     => sisalvl,

			intr => inner_intr,
			isra => inner_isra,
			isrr => inner_issr
		);

	pc_pccontr <= pccontr(8 downto 6) & pccontr(2 downto 0); -- JAL, JREG, RETI, BOV, BEQZ, BNEZ
    PC_logic: entity work.pclogic
		port map (
			clk			=> clk,
			reset		=> reset,

			pcwrite     => pcwrite,
			pccontr     => pc_pccontr,
			ov          => ov,
			zero        => zero,
			intr        => inner_intr,
			pcnew	    => pcnew,
			isra        => inner_isra,
			isrr        => inner_issr,

			pcakt       => pcakt,
			pcinc       => pcinc,
			pcnext      => inner_pcnext
		);
end rtl;
