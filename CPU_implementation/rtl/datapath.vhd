---------------------------------------------------------------------------------------------------
--
-- Titel: Data Path
-- Autor: David Mihola (12211951)
-- Datum: 19. 03. 2023   
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
library work;
	use work.all;
	use work.hadescomponents.all;
	
entity datapath is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- control
		opc			: in  std_logic_vector(4 downto 0);
		regwrite	: in  std_logic;
		
		-- input data
		aop			: in  std_logic_vector(31 downto 0);
		bop			: in  std_logic_vector(31 downto 0);
		iop			: in  std_logic_vector(15 downto 0);
		ivalid		: in  std_logic;
		
		-- output data
		wop			: out std_logic_vector(31 downto 0);
		
		-- XBus
		selxres		: in  std_logic;
		xdatain		: in  std_logic_vector(31 downto 0);
		xdataout	: out std_logic_vector(31 downto 0);
		xadr		: out std_logic_vector(12 downto 0);
		
		-- status flags
		zero		: out std_logic;
		ov			: out std_logic;
		
		-- program counter
		jal			: in  std_logic;
		rela		: in  std_logic;
		pcinc		: in  std_logic_vector(11 downto 0);
		pcnew		: out std_logic_vector(11 downto 0);
		sisalvl     : out std_logic_vector(1 downto 0)
	);
end datapath;

architecture rtl of datapath is
	constant ANY_ARITHMETIC_aopc : std_logic_vector(1 downto 0) := "10";    -- 2 MSBs of ALU opcode, which signify an arithmetic instruction
	constant PASS_IMMED_aopc     : std_logic_vector(4 downto 0) := "01110"; -- ALU opcode for a PassImmed instruction

	signal jal_selxres : std_logic_vector(1 downto 0) := "00"; -- variable to make the 'wop' logic simpler

	-- registers for storing the ALU opcode and the value of the first operand
	signal opcode_reg : std_logic_vector(4 downto 0)  := (others => '0');
	signal aop_reg    : std_logic_vector(31 downto 0) := (others => '0');

	-- result of the second operand selection logic
	signal bop_reg : std_logic_vector(31 downto 0) := (others => '0');

	-- registers for storing the result and zero flag of the ALU
	signal result_reg : std_logic_vector(31 downto 0) := (others => '0');
	signal zero_reg   : std_logic;

	-- registers for input output data
	signal xdatain_reg  : std_logic_vector(31 downto 0) := (others => '0');
	signal xdataout_reg : std_logic_vector(31 downto 0) := (others => '0');
begin
	jal_selxres <= jal & selxres; -- vector from the 'jal' and 'selxres' bits used for further calculations lower
	
	-- clocked logic
	process(clk, reset) is
	begin
		if reset = '1' then
			-- clear of all the registers on reset
			opcode_reg   <= (others => '0');
			aop_reg      <= (others => '0');
			xdatain_reg  <= (others => '0');
			xdataout_reg <= (others => '0');
		elsif rising_edge(clk) then
			xdataout <= xdataout_reg;
			zero     <= zero_reg;
			sisalvl  <= result_reg(15 downto 14);

			-- memory address logic, MSB is set, when invalid address is encountered, i.e. 20 MSBs of the result are not 0
			if result_reg(31 downto 12) = x"0000_0" then
				xadr <= result_reg(12 downto 0);
			else
				xadr <= '1' & result_reg(11 downto 0);
			end if;
	
			-- 'wop' logic base on the JAL and SELXRES signals
			case jal_selxres is
				when "00" =>   wop <= result_reg;			-- result from the ALU
				when "10" =>   wop <= x"0000_0" & pcinc;    -- the value of the next PC
				when others => wop <= xdatain_reg;			-- the value read from the data memory
			end case;
			
			-- program counter logic based on the RELA signal
			if rela = '0' then
				pcnew <= result_reg(11 downto 0);
			else
				pcnew <= std_logic_vector(unsigned(result_reg(11 downto 0)) + unsigned(pcinc)); -- sum of the result with the next PC (PC + 1)
			end if;
			
			-- asignment of the internal registers
			opcode_reg   <= opc;
			aop_reg      <= aop;
			xdatain_reg  <= xdatain;
			xdataout_reg <= bop;
			if ivalid = '0' then
				bop_reg <= bop;
			elsif iop(15) = '1' and (opcode_reg(4 downto 3) = ANY_ARITHMETIC_aopc or opcode_reg = PASS_IMMED_aopc) then
				bop_reg <= x"FFFF" & iop;
			else
				bop_reg <= x"0000" & iop;
			end if;		
		end if;
	end process;
	
    -- ALU instantiation
	ALU: entity work.alu
	port map(
		clk => clk,
		reset => reset,

		opcode => opcode_reg,
		regwrite => regwrite,

		achannel => aop_reg,
		bchannel => bop_reg,

		result => result_reg,
		overflow => ov,
		zero => zero_reg
	);
end rtl;
