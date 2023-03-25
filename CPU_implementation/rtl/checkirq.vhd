---------------------------------------------------------------------------------------------------
--
-- Titel:    
-- Autor:    
-- Datum:    
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity checkirq is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- interrupt inputs
		xperintr	: in  std_logic;
		xnaintr		: in  std_logic;
		xmemintr	: in  std_logic;
		
		-- control input
		swintr		: in  std_logic;
		pcwrite		: in  std_logic;
		eni			: in  std_logic;
		dei			: in  std_logic;
		reti		: in  std_logic;
		retilvl		: in  std_logic_vector(2 downto 0);
		
		-- control output
		curlvl		: out std_logic_vector(2 downto 0);
		selisra		: out std_logic_vector(2 downto 0);
		intr		: out std_logic
	);
end checkirq;

architecture rtl of checkirq is
	signal interrupt_enabled	: std_logic;
	signal interrupt_level		: std_logic_vector(2 downto 0);

	signal swi_detected	        : std_logic;
	signal xnaintr_detected	    : std_logic;
	signal xmemintr_detected	: std_logic;

	signal swi_clear	        : std_logic;
	signal xnaintr_clear	    : std_logic;
	signal xmemintr_clear	    : std_logic;
begin

	process (clk, reset) is
	begin
		if reset = '1' then
			interrupt_enabled <= '1';
			interrupt_level <= "000";
		elsif rising_edge(clk) then
			if pcwrite = '1' then
				if eni = '1' then
					interrupt_enabled <= '1';
				elsif dei = '1' then
					interrupt_enabled <= '0';
				end if;

				if reti = '1' then
					interrupt_level <= retilvl;
				end if;
			end if;
		end if;
	end process;
	
	swi_clear <= '1' when reti = '1' and retilvl = "001" else '0';
	SWINTR_BUFF: entity work.irqreceiver
	port map (
		clk => clk,
		reset => reset,

		isignal => swintr,
		iack => swi_clear,

		q => swi_detected
	);

	xnaintr_clear <= '1' when reti = '1' and retilvl = "011" else '0';
	XNAINTR_BUFF: entity work.irqreceiver
	port map (
		clk => clk,
		reset => reset,

		isignal => xnaintr,
		iack => xnaintr_clear,

		q => xnaintr_detected
	);

					
	xmemintr_clear <= '1' when reti = '1' and retilvl = "100" else '0';
	XMEMINTR_BUFF: entity work.irqreceiver
	port map (
		clk => clk,
		reset => reset,

		isignal => xmemintr,
		iack => xmemintr_clear,

		q => xmemintr_detected
	);
	
	intr <= '1' when interrupt_enabled = '1' and (swi_detected = '1' or xnaintr_detected = '1' or xmemintr_detected = '1' or xperintr = '1') else 
			'0';
	curlvl <= interrupt_level;
	
end rtl;
