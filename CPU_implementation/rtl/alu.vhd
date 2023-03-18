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
	constant NOP_aopc    : std_logic_vector(4 downto 0) := "00000";

	constant INVLD1_aopc : std_logic_vector(4 downto 0) := "00000";
	constant INVLD2_aopc : std_logic_vector(4 downto 0) := "01111";
	constant INVLD3_aopc : std_logic_vector(4 downto 0) := "10101";
	constant INVLD4_aopc : std_logic_vector(4 downto 0) := "10110";
	constant INVLD5_aopc : std_logic_vector(4 downto 0) := "10111";
	constant INVLD6_aopc : std_logic_vector(4 downto 0) := "11110";
	constant INVLD7_aopc : std_logic_vector(4 downto 0) := "11111";

	constant ANY_SHIFT_aopc : std_logic_vector(2 downto 0) := "001";
	constant ANY_LOGIC_aopc : std_logic_vector(2 downto 0) := "010";
	constant ANY_BRANCH_aopc : std_logic_vector(2 downto 0) := "011";
	constant ANY_COMP_aopc : std_logic_vector(2 downto 0) := "111";

	constant RESULT_CLEAR : std_logic_vector(30 downto 0) := (others => '0');

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

	signal mul_res : std_logic_vector(31 downto 0);
	signal mul_ov : std_logic;

	signal comp_eq : std_logic;	
	signal comp_lt : std_logic;
	signal comp_gt : std_logic;

	signal regwritten : std_logic;
begin
	-- clocked logic
	process (clk, reset) is
	begin
		if reset = '1' then
			ovfflag <= '0';
			overflow <= '0';
			regwritten <= '0'; -- TODO
		elsif rising_edge(clk) then
			if regwrite = '1' then
				regwritten <= '1'; -- TODO
				if opcode(4 downto 2) = ANY_SHIFT_aopc then
					ovfflag <= shift_ov;
				elsif opcode = SETOV_aopc then
					ovfflag <= bchannel(0);
				elsif opcode = ADD_aopc or opcode = SUB_aopc then
					ovfflag <= add_sub_ov;
				elsif opcode = NOP_aopc then
					ovfflag <= '0';
				end if;
			end if;
			
			if regwritten = '1' then -- TODO
				if opcode = MUL_aopc then
					overflow <= mul_ov;
				else
					overflow <= ovfflag;
				end if;
			end if;
		end if;
	end process;

	-- swi/getswi
	swi_achannel <= (others => '0') when reset = '1' else
					achannel when opcode = SWI_aopc and regwrite = '1' else
					swi_achannel;
	swi_bchannel <= (others => '0') when reset = '1' else
					bchannel when opcode = SWI_aopc and regwrite = '1' else
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

	-- bitwise logic
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

	-- multiplication
	MUL: entity work.hades_mul
	generic map (
		N => 32
	)
	port map (
		a => achannel,
		b => bchannel,

		clk => clk,

		r => mul_res,
		ov => mul_ov
	);

	-- compare logic
	COMP: entity work.hades_compare
	generic map (
		N => 32
	)
	port map (
		a => achannel,
		b => bchannel,

		eq => comp_eq,
		lt => comp_lt,
		gt => comp_gt
	);
 
	result <= (others => '0') when reset = '1' or opcode = INVLD1_aopc or opcode = INVLD2_aopc or opcode = INVLD3_aopc or opcode = INVLD4_aopc or opcode = INVLD5_aopc or opcode = INVLD6_aopc or opcode = INVLD7_aopc else
	          getswi_res when opcode = GETSWI_aopc else
			  shift_res when opcode(4 downto 2) = ANY_SHIFT_aopc else 
			  logic_res when opcode(4 downto 2) = ANY_LOGIC_aopc else
			  add_sub_res when opcode = ADD_aopc or opcode = SUB_aopc else
			  mul_res when opcode = MUL_aopc else
			  RESULT_CLEAR & ovfflag when opcode = GETOV_aopc else
			  b"0000_0000_0000_0000" & bchannel(15 downto 0) when opcode(4 downto 2) = ANY_BRANCH_aopc else
			  RESULT_CLEAR & comp_eq when opcode = SEQ_aopc else
			  RESULT_CLEAR & not comp_eq when opcode = SNE_aopc else
			  RESULT_CLEAR & comp_lt when opcode = SLT_aopc else
			  RESULT_CLEAR & (comp_lt or comp_eq) when opcode = SLE_aopc else
			  RESULT_CLEAR & comp_gt when opcode = SGT_aopc else
			  RESULT_CLEAR & (comp_gt or comp_eq) when opcode = SGE_aopc else
			  (others => '0');

	zero <= '1' when (opcode = BNEZ_aopc or opcode = BEQZ_aopc) and achannel = x"0000_0000" else
			'0';
end rtl;
