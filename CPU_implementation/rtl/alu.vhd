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
	use work.all;
	use work.hadescomponents.all;
	
entity alu is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- control inputs
		opcode		: in  std_logic_vector(4 downto 0);
		regwrite	: in  std_logic;
		
		-- data input
		achannel	: in  std_logic_vector(31 downto 0);
		bchannel	: in  std_logic_vector(31 downto 0);
		
		-- result
		result		: out std_logic_vector(31 downto 0);
		zero		: out std_logic;
		overflow	: out std_logic
	);
end alu;

architecture rtl of alu is
	constant SWI_aopc    : std_logic_vector(4 downto 0) := "00010";
	constant GETSWI_aopc : std_logic_vector(4 downto 0) := "00011";
	constant SHL_aopc    : std_logic_vector(4 downto 0) := "00100";
	constant SHR_aopc    : std_logic_vector(4 downto 0) := "00101";
	constant CSHL_aopc   : std_logic_vector(4 downto 0) := "00110";
	constant CSHR_aopc   : std_logic_vector(4 downto 0) := "00111";
	constant AND_aopc    : std_logic_vector(4 downto 0) := "01000";
	constant OR_aopc     : std_logic_vector(4 downto 0) := "01001";
	constant XOR_aopc    : std_logic_vector(4 downto 0) := "01010";
	constant XNOR_aopc   : std_logic_vector(4 downto 0) := "01011";
	constant BNEZ_aopc   : std_logic_vector(4 downto 0) := "01100";
	constant BEQZ_aopc   : std_logic_vector(4 downto 0) := "01101";
	constant PASS_aopc   : std_logic_vector(4 downto 0) := "01110";
	constant SUB_aopc    : std_logic_vector(4 downto 0) := "10000";
	constant ADD_aopc    : std_logic_vector(4 downto 0) := "10001";
	constant SETOV_aopc  : std_logic_vector(4 downto 0) := "10010";
	constant GETOV_aopc  : std_logic_vector(4 downto 0) := "10011";
	constant MUL_aopc    : std_logic_vector(4 downto 0) := "10100";
	constant SNE_aopc    : std_logic_vector(4 downto 0) := "11000";
	constant SEQ_aopc    : std_logic_vector(4 downto 0) := "11001";
	constant SGT_aopc    : std_logic_vector(4 downto 0) := "11010";
	constant SGE_aopc    : std_logic_vector(4 downto 0) := "11011";
	constant SLT_aopc    : std_logic_vector(4 downto 0) := "11100";
	constant SLE_aopc    : std_logic_vector(4 downto 0) := "11101";
	constant IN_aopc     : std_logic_vector(4 downto 0) := "01110";
	constant OUT_aopc    : std_logic_vector(4 downto 0) := "01110";
	constant BOV_aopc    : std_logic_vector(4 downto 0) := "01110";
	constant LOAD_aopc   : std_logic_vector(4 downto 0) := "10001";
	constant STORE_aopc  : std_logic_vector(4 downto 0) := "10001";
	constant JAL_aopc    : std_logic_vector(4 downto 0) := "01110";
	constant JREG_aopc   : std_logic_vector(4 downto 0) := "00110";
	constant SISA_aopc   : std_logic_vector(4 downto 0) := "01110";

	constant ANY_SHIFT_aopc : std_logic_vector(1 downto 0) := "00";
	constant ANY_LOGIC_aopc : std_logic_vector(1 downto 0) := "01";

	signal ovfflag : std_logic;

	signal swi_achannel : std_logic_vector(31 downto 0);
	signal swi_bchannel : std_logic_vector(31 downto 0);
	signal getswi_res : std_logic_vector(31 downto 0);

	signal shift_res: std_logic_vector(31 downto 0);
    signal shift_ov : std_logic;
	signal shift_cyclic : std_logic;
	signal shift_rl : std_logic;

	signal logic_res: std_logic_vector(31 downto 0);

	signal add_sub_res : std_logic_vector(31 downto 0);
	signal add_sub_sub : std_logic;
	signal add_sub_ov : std_logic;
begin
	-- clocked logic
	process (clk, reset) is
	begin
		if rising_edge(clk) then
			if regwrite = '1' then
				if opcode = ADD_aopc or opcode = SUB_aopc then
					ovfflag <= add_sub_ov;
				elsif opcode(4 downto 3) = ANY_SHIFT_aopc then
					ovfflag <= shift_ov;
				end if;
			end if;
			overflow <= ovfflag;
		end if;
	end process;

	-- swi/getswi
	swi_achannel <= achannel when opcode = SWI_aopc and regwrite = '1' else
					swi_achannel;
	swi_bchannel <= bchannel when opcode = SWI_aopc and regwrite = '1' else
					swi_bchannel;

	getswi_res <= swi_bchannel when bchannel(0) = '0' else
				  swi_achannel;
	
	-- shifts
	shift_cyclic <= '1' when opcode = CSHL_aopc or opcode = CSHR_aopc else '0';
	shift_rl <= '1' when opcode = SHR_aopc or opcode = CSHR_aopc else '0';

	SHIFT: entity work.hades_shift
	generic map (
		N => 32
	)
	port map (
		A => achannel,
		B => bchannel(4 downto 0),

		cyclic => shift_cyclic,
		right => shift_rl,

		R => shift_res,
		OV => shift_ov
	);

	-- logic
	logic_res <= achannel AND bchannel when opcode = AND_aopc else
				 achannel OR bchannel when opcode = OR_aopc else
				 achannel XOR bchannel when opcode = XOR_aopc else
				 achannel XNOR bchannel when opcode = XNOR_aopc else
				 (others => '0');

	-- add/sub
	add_sub_sub <= '1' when opcode = SUB_aopc else '0';

	ADD_SUB: entity work.hades_addsub
	generic map (
		N => 32
	)
	port map (
		a => achannel,
		b => bchannel,

		sub => add_sub_sub,

		r => add_sub_res,
		ov => add_sub_ov
	);

	result <= (others => '0') when reset = '1' else
	          getswi_res when opcode = GETSWI_aopc else
			  shift_res when opcode(4 downto 3) = ANY_SHIFT_aopc else 
			  logic_res when opcode(4 downto 3) = ANY_LOGIC_aopc else
			  add_sub_res when opcode = ADD_aopc or opcode = SUB_aopc else
			  (others => '0');

	zero <= '1' when reset = '1' or
					 (shift_res = x"0000_0000" and opcode(4 downto 3) = ANY_SHIFT_aopc) or 
					 (logic_res = x"0000_0000" and opcode(4 downto 3) = ANY_LOGIC_aopc) or 
					 (getswi_res = x"0000_0000" and opcode(4 downto 3) = GETSWI_aopc) 
				else '0';
	
	--process (regwrite) is 
	--begin
	--	if regwrite = '1' and opcode = SWI_aopc then
	--		swi_achannel <= achannel;
	--		swi_bchannel <= bchannel;
	--	end if;
	--end process;
end rtl;
