---------------------------------------------------------------------------------------------------
--
-- Titel: Instruction Decoder  
-- Autor: David Mihola (12211951)
-- Datum: 10. 03. 2023
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity indec is
	port (
		-- instruction word input
		iword		: in  std_logic_vector(31 downto 0);
		
		-- register addresses
		aopadr		: out std_logic_vector(2 downto 0);
		bopadr		: out std_logic_vector(2 downto 0);
		wopadr		: out std_logic_vector(2 downto 0);
		
		-- immediate value
		ivalid		: out std_logic;
		iop			: out std_logic_vector(15 downto 0);
		
		-- control flags
		opc		: out std_logic_vector(4 downto 0);
		pccontr	: out std_logic_vector(10 downto 0);
		inop		: out std_logic;
		outop		: out std_logic;
		loadop		: out std_logic;
		storeop		: out std_logic;
		dmemop		: out std_logic;
		selxres		: out std_logic;
		dpma		: out std_logic;
		epma		: out std_logic
	);
end indec;

architecture rtl of indec is
	-- This approach did not work because of the compilation error "choice must be locally static expression",
	-- this might be fixed with the 2008 VHDL standard according to the internet (--std=08 flag for GHDL).
	--type Instruction_opcodes_t is (ALU_opc, ALUI_opc, NOP_opc, SWI_opc, GETSWI_opc, IN_opc, OUT_opc, ENI_opc, DEI_opc, BNEZ_opc, BEQZ_opc, 
    --	 							 BOV_opc, LOAD_opc, STORE_opc, JAL_opc, JREG_opc, RETI_opc, SISA_opc, DPMA_opc, EPMA_opc);
	--type Instructions_t is array(Instruction_opcodes_t) of std_logic_vector(3 downto 0);
	--constant Instructions : Instructions_t := (
	--	ALU_opc		=> "0000",
	--	ALUI_opc	=> "0000",
	--	NOP_opc		=> "0000",
	--	SWI_opc		=> "0000",
	--	GETSWI_opc	=> "0000",
	--	IN_opc		=> "0010",
	--	OUT_opc		=> "0011",
	--	ENI_opc		=> "0001",
	--	DEI_opc		=> "0100",
	--	BNEZ_opc	=> "0101",
	--	BEQZ_opc	=> "0110",
	--	BOV_opc		=> "0111",
	--	LOAD_opc	=> "1000",
	--	STORE_opc	=> "1001",
	--	JAL_opc		=> "1010",
	--	JREG_opc	=> "1011",
	--	RETI_opc	=> "1100",
	--	SISA_opc	=> "1101",
	--	DPMA_opc	=> "1110",
	--	EPMA_opc	=> "1111"
	--);

	-- simple constants instead (instruction opcodes)
	constant ALU_opc    : std_logic_vector(3 downto 0) := "0000";
	constant ALUI_opc   : std_logic_vector(3 downto 0) := "0000";
	constant NOP_opc    : std_logic_vector(3 downto 0) := "0000";
	constant SWI_opc    : std_logic_vector(3 downto 0) := "0000";
	constant GETSWI_opc : std_logic_vector(3 downto 0) := "0000";
	constant IN_opc     : std_logic_vector(3 downto 0) := "0010";
	constant OUT_opc    : std_logic_vector(3 downto 0) := "0011";
	constant ENI_opc    : std_logic_vector(3 downto 0) := "0001";
	constant DEI_opc    : std_logic_vector(3 downto 0) := "0100";
	constant BNEZ_opc   : std_logic_vector(3 downto 0) := "0101";
	constant BEQZ_opc   : std_logic_vector(3 downto 0) := "0110";
	constant BOV_opc    : std_logic_vector(3 downto 0) := "0111";
	constant LOAD_opc   : std_logic_vector(3 downto 0) := "1000";
	constant STORE_opc  : std_logic_vector(3 downto 0) := "1001";
	constant JAL_opc    : std_logic_vector(3 downto 0) := "1010";
	constant JREG_opc   : std_logic_vector(3 downto 0) := "1011";
	constant RETI_opc   : std_logic_vector(3 downto 0) := "1100";
	constant SISA_opc   : std_logic_vector(3 downto 0) := "1101";
	constant DPMA_opc   : std_logic_vector(3 downto 0) := "1110";
	constant EPMA_opc   : std_logic_vector(3 downto 0) := "1111";
	
	constant SWI_aopc   : std_logic_vector(4 downto 0) := "00010";
begin
	process(iword) is
	begin
		aopadr <= iword(19 downto 17);
		if iword(31 downto 28) = OUT_opc or iword(31 downto 28) = STORE_opc then -- OUT or STORE
			bopadr <= iword(22 downto 20);
			wopadr <= (others => '0');
		else -- other instructions, map directly from instruction word
			bopadr <= iword(15 downto 13);
			wopadr <= iword(22 downto 20);
		end if;
		
		ivalid <= iword(16);
		iop <= iword(15 downto 0);

		-- default values
		opc     <= iword(27 downto 23);
		pccontr <= (others => '0');
		inop    <= '0';
		outop   <= '0';
		loadop  <= '0';
		storeop <= '0';
		dmemop  <= '0';
		selxres <= '0';
		dpma    <= '0';
		epma    <= '0';

		case iword(31 downto 28) is
			-- pccontr signal
			when SWI_opc => -- SWI
				if iword(27 downto 23) = SWI_aopc then
				   pccontr <= "01" & "000000000";
				end if;
			when JAL_opc =>  -- JAL
				pccontr <= "101" & "00000000";
			when JREG_opc => -- JREG
				pccontr <= "0001" & "0000000";
			when RETI_opc => -- RETI
				pccontr <= "00001" & "000000";
			when ENI_opc =>  -- ENI
				pccontr <= "000001" & "00000";
			when DEI_opc =>  -- DEI
				pccontr <= "0000001" & "0000";
			when SISA_opc => -- SISA
				pccontr <= "10000001" & "000";
			when BOV_opc =>  -- BOV
				pccontr <= "100000001" & "00";
			when BEQZ_opc => -- BEQZ
				pccontr <= "1000000001" & "0";
			when BNEZ_opc => -- BNEZ
				pccontr <= "10000000001";
			
			-- other yet unset signals
			when IN_opc =>    -- IN
				inop <= '1';
				selxres <= '1';
			when OUT_opc =>   -- OUT
				outop <= '1';
				selxres <= '1';
			when LOAD_opc =>  -- LOAD
				loadop <= '1';
				dmemop <= '1';
				selxres <= '1';
			when STORE_opc => -- STORE
				storeop <= '1';
				dmemop <= '1';
				selxres <= '1';
			when DPMA_opc =>  -- DPMA
				dpma <= '1';
			when EPMA_opc =>  -- EPMA
				epma <= '1';

			-- unnecessary, but recquired for compilation
			when others => null;
		end case;
	end process;
end rtl;
