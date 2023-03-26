---------------------------------------------------------------------------------------------------
--
-- Titel: Check IRQ
-- Autor: David Mihola (12211951)
-- Datum: 26. 03. 2023
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
	signal intr_en_reg	        : std_logic;
	signal intr_lvl_reg	        : std_logic_vector(2 downto 0);

	signal req_lvl		        : std_logic_vector(2 downto 0);
	signal inner_intr			: std_logic;

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
			intr_en_reg <= '1'; -- enable interrupts by default
			intr_lvl_reg <= "000";
		elsif rising_edge(clk) then
			-- interrupt enable/disable logic
			if eni = '1' then
				intr_en_reg <= '1';
			elsif dei = '1' then
				intr_en_reg <= '0';
			end if;

			-- interrupt level logic based on req_lvl
			if inner_intr = '1' then
				intr_lvl_reg <= req_lvl;
			end if;
			
			-- interrupt level logic based on retilvl
			if reti = '1' and pcwrite = '1' then
				-- set the interrupt level to the higher of the requested level and the retilvl
				if unsigned(req_lvl) < unsigned(retilvl) then
					intr_lvl_reg <= retilvl;
				else
					intr_lvl_reg <= req_lvl;
				end if;
			end if;
		end if;
	end process;
	
	swi_clear <= '1' when (inner_intr = '1' and req_lvl = "001") else '0';
	SWINTR_BUFF: entity work.irqreceiver
	port map (
		clk => clk,
		reset => reset,

		isignal => swintr,
		iack => swi_clear,

		q => swi_detected
	);

	xnaintr_clear <= '1' when (inner_intr = '1' and req_lvl = "011") else '0';
	XNAINTR_BUFF: entity work.irqreceiver
	port map (
		clk => clk,
		reset => reset,

		isignal => xnaintr,
		iack => xnaintr_clear,

		q => xnaintr_detected
	);

					
	xmemintr_clear <= '1' when (inner_intr = '1' and req_lvl = "100") else '0';
	XMEMINTR_BUFF: entity work.irqreceiver
	port map (
		clk => clk,
		reset => reset,

		isignal => xmemintr,
		iack => xmemintr_clear,

		q => xmemintr_detected
	);

	-- determine the requested level immidiately and then hold it until the interrupt is cleared
	req_lvl <= "100" when xmemintr_detected = '1' or xmemintr = '1' else
			   "011" when xnaintr_detected = '1'  or xnaintr = '1' else
			   "010" when xperintr = '1' else	-- TODO: do peripheral interrupts get cleared by themself?
			   "001" when swi_detected = '1'      or swintr = '1' else
			   "000";
	
	inner_intr <= '1' when intr_en_reg = '1' and pcwrite = '1' and -- raise interrupts only when enabled and pcwrite is active and
						   (unsigned(req_lvl) > unsigned(intr_lvl_reg) or -- the requested level is higher than the current level or
						    (reti = '1' and unsigned(req_lvl) > unsigned(retilvl))) else -- the requested level is higher than the retilvl when RETI instruction is executed
				  '0';

	intr    <= inner_intr;
	selisra <= req_lvl;
	curlvl  <= intr_lvl_reg;
end rtl;
