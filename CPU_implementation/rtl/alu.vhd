---------------------------------------------------------------------------------------------------
--
-- Titel: Arithmetic Logic Unit
-- Autor: David Mihola (12211951)
-- Datum: 18. 03. 2023   
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
	-- ALU operation codes (aopc)
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

	-- invalid ALU operation codes
	constant INVLD1_aopc : std_logic_vector(4 downto 0) := "00000";
	constant INVLD2_aopc : std_logic_vector(4 downto 0) := "01111";
	constant INVLD3_aopc : std_logic_vector(4 downto 0) := "10101";
	constant INVLD4_aopc : std_logic_vector(4 downto 0) := "10110";
	constant INVLD5_aopc : std_logic_vector(4 downto 0) := "10111";
	constant INVLD6_aopc : std_logic_vector(4 downto 0) := "11110";
	constant INVLD7_aopc : std_logic_vector(4 downto 0) := "11111";

	-- 3 MSBs of ALU operation codes, which signify the type of the operation (logic, arithmetic, shifts, ...)
	constant ANY_SHIFT_aopc : std_logic_vector(2 downto 0)  := "001";
	constant ANY_LOGIC_aopc : std_logic_vector(2 downto 0)  := "010";
	constant ANY_BRANCH_aopc : std_logic_vector(2 downto 0) := "011";
	constant ANY_COMP_aopc : std_logic_vector(2 downto 0)   := "111";

	-- constant used to set the 31 MSBs of the result to 0
	constant RESULT_CLEAR : std_logic_vector(30 downto 0) := (others => '0');

	-- register for storing the overflow flag
	signal ov_flag : std_logic;

	-- software interupt logic
	signal swi_achannel : std_logic_vector(31 downto 0) := (others => '0');
	signal swi_bchannel : std_logic_vector(31 downto 0) := (others => '0');
	signal getswi_res : std_logic_vector(31 downto 0)   := (others => '0');

	-- shift logic
	signal shift_res: std_logic_vector(31 downto 0) := (others => '0');
    signal shift_ov : std_logic := '0';
	signal shift_cyclic : std_logic := '0';
	signal shift_rl : std_logic := '0';

	-- bitwise logic
	signal bitwise_res: std_logic_vector(31 downto 0) := (others => '0');

	-- addition and subtraction logic
	signal add_sub_res : std_logic_vector(31 downto 0) := (others => '0');
	signal add_sub_sub : std_logic := '0';
	signal add_sub_ov : std_logic  := '0';

	-- multiplication logic
	signal mul_res : std_logic_vector(31 downto 0) := (others => '0');
	signal mul_ov : std_logic := '0';

	-- comparison results
	signal comp_eq : std_logic := '0';	
	signal comp_lt : std_logic := '0';
	signal comp_gt : std_logic := '0';

	-- overflow flag logic
	signal regwritten : std_logic := '0';
begin
	-- clocked logic
	process(clk, reset) is
	begin
		if reset = '1' then
			ov_flag <= '0';
			regwritten <= '0';
		elsif rising_edge(clk) then

			if regwritten = '1' then
				if opcode(4 downto 2) = ANY_SHIFT_aopc then
					ov_flag <= shift_ov;
				elsif opcode = SETOV_aopc then
					ov_flag <= bchannel(0);
				elsif opcode = ADD_aopc or opcode = SUB_aopc then
					ov_flag <= add_sub_ov;
				elsif opcode = MUL_aopc then
					ov_flag <= mul_ov;
				elsif opcode = GETOV_aopc then
					ov_flag <= ov_flag; -- GETOV does not change the overflow flag
				else
				    ov_flag <= '0'; -- for all other instructions overflow is '0'
				end if;
			end if;
			
			regwritten <= regwrite; -- delay of the regwrite signal

		end if;
	end process;

	overflow <= ov_flag;

	-- software interupt logic
	-- channels are cleared at reset and change only when SWI is executed and regwrite is set
	process(reset, clk) is
	begin
		if reset = '1' then
			swi_achannel  <= (others => '0');
		elsif rising_edge(clk) then

			if regwrite = '1' and opcode = SWI_aopc then
				swi_achannel <= achannel;
				swi_bchannel <= bchannel;
			end if;
			
		end if;	
	end process;

	getswi_res <= swi_bchannel when bchannel(0) = '0' else -- results is selected based on the LSB of the second operand
				  swi_achannel;
	
	-- shifts
	shift_cyclic <= '1' when opcode = CSHL_aopc or opcode = CSHR_aopc else '0'; -- cyclic or non cyclic shift
	shift_rl <= '1'     when opcode = SHR_aopc  or opcode = CSHR_aopc else '0'; -- right or left shift

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
	bitwise_res <= achannel AND  bchannel when opcode = AND_aopc  else
				   achannel OR   bchannel when opcode = OR_aopc   else
				   achannel XOR  bchannel when opcode = XOR_aopc  else
				   achannel XNOR bchannel when opcode = XNOR_aopc else
				   (others => '0'); 

	-- addition and subtraction
	add_sub_sub <= '1' when opcode = SUB_aopc else '0'; -- specifies whether the operation is subtraction or addition

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
	
	-- result logic
	result <= (others => '0') when opcode = INVLD1_aopc or opcode = INVLD2_aopc or opcode = INVLD3_aopc or 
								   opcode = INVLD4_aopc or opcode = INVLD5_aopc or opcode = INVLD6_aopc or 
								   opcode = INVLD7_aopc else -- clear the result at invalid opcode
	          getswi_res  when opcode = GETSWI_aopc else
			  shift_res   when opcode(4 downto 2) = ANY_SHIFT_aopc else 
			  bitwise_res when opcode(4 downto 2) = ANY_LOGIC_aopc else
			  add_sub_res when opcode = ADD_aopc or opcode = SUB_aopc else
			  mul_res     when opcode = MUL_aopc else
			  -- result of the get overflow instruction is stored as a LSB of the result, other bits are cleared
			  RESULT_CLEAR & ov_flag when opcode = GETOV_aopc else
			  -- result of the branch instructions is taken from the 16 LSBs of the second operand, other bits are cleared
			  x"0000" & bchannel(15 downto 0) when opcode(4 downto 2) = ANY_BRANCH_aopc else
			  -- result of the comparison instructions is stored as a LSB of the result, other bits are cleared
			  RESULT_CLEAR & comp_eq              when opcode = SEQ_aopc else
			  RESULT_CLEAR & not comp_eq          when opcode = SNE_aopc else
			  RESULT_CLEAR & comp_lt              when opcode = SLT_aopc else
			  RESULT_CLEAR & (comp_lt or comp_eq) when opcode = SLE_aopc else
			  RESULT_CLEAR & comp_gt              when opcode = SGT_aopc else
			  RESULT_CLEAR & (comp_gt or comp_eq) when opcode = SGE_aopc else
			  (others => '0'); -- result is cleared for other opcodes

	zero <= '1' when (opcode = BNEZ_aopc or opcode = BEQZ_aopc) and 
					 achannel = x"0000_0000" else -- zero flag is set for BNEZ and BEQZ if achannel is zero
			'0';
end rtl;
