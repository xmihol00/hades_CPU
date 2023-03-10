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
	--type Instruction_t is (ALUi, ALUIi, NOPi, SWIi, GETSWIi, INi, OUTi, ENIi, DEIi, BNEZi, BEQZi, BOVi, LOADi, STOREi, JALi, 
	--					   JREGi, RETIi, SISAi, DPMAi, EPMAi);
	--type Instructions_t is array(Instruction_t) of std_logic_vector(3 downto 0);
	--constant Instructions : Instructions_t := (
	--	ALUi		=> "0000",
	--	ALUIi	=> "0000",
	--	NOPi	=> "0000",
	--	SWIi	=> "0000",
	--	GETSWIi	=> "0000",
	--	INi		=> "0010",
	--	OUTi	=> "0011",
	--	ENIi	=> "0001",
	--	DEIi	=> "0100",
	--	BNEZi	=> "0101",
	--	BEQZi	=> "0110",
	--	BOVi	=> "0111",
	--	LOADi	=> "1000",
	--	STOREi	=> "1001",
	--	JALi	=> "1010",
	--	JREGi	=> "1011",
	--	RETIi	=> "1100",
	--	SISAi	=> "1101",
	--	DPMAi	=> "1110",
	--	EPMAi	=> "1111"
	--);

	-- simple constants instead
	constant ALUi : std_logic_vector(3 downto 0) := "0000";
	constant ALUIi : std_logic_vector(3 downto 0) := "0000";
	constant SWIi : std_logic_vector(3 downto 0) := "0000";
	constant GETSWIi : std_logic_vector(3 downto 0) := "0000";
	constant INi : std_logic_vector(3 downto 0) := "0010";
	constant OUTi : std_logic_vector(3 downto 0) := "0011";
	constant ENIi : std_logic_vector(3 downto 0) := "0001";
	constant DEIi : std_logic_vector(3 downto 0) := "0100";
	constant BNEZi : std_logic_vector(3 downto 0) := "0101";
	constant BEQZi : std_logic_vector(3 downto 0) := "0110";
	constant BOVi : std_logic_vector(3 downto 0) := "0111";
	constant LOADi : std_logic_vector(3 downto 0) := "1000";
	constant STOREi : std_logic_vector(3 downto 0) := "1001";
	constant JALi : std_logic_vector(3 downto 0) := "1010";
	constant JREGi : std_logic_vector(3 downto 0) := "1011";
	constant RETIi : std_logic_vector(3 downto 0) := "1100";
	constant SISAi : std_logic_vector(3 downto 0) := "1101";
	constant DPMAi : std_logic_vector(3 downto 0) := "1110";
	constant EPMAi : std_logic_vector(3 downto 0) := "1111";
	
begin
	process(iword) is
	begin
		aopadr <= iword(19 downto 17);
		if iword(31 downto 28) = OUTi or iword(31 downto 28) = STOREi then -- OUT or STORE
			bopadr <= iword(22 downto 20);
			wopadr <= (others => '0');
		else -- other instructions, map directly from instruction word
			bopadr <= iword(15 downto 13);
			wopadr <= iword(22 downto 20);
		end if;

		ivalid <= iword(16);
		iop <= iword(15 downto 0);

		-- default values
		opc <= iword(27 downto 23);
		pccontr <= (others => '0');
		inop <= '0';
		outop <= '0';
		loadop <= '0';
		storeop <= '0';
		dmemop <= '0';
		selxres <= '0';
		dpma <= '0';
		epma <= '0';

		case iword(31 downto 28) is
			-- pccontr signal
			when SWIi => -- SWI
				if iword(27 downto 23) = "00010" then
				   pccontr <= "01" & "000000000";
				end if;
			when JALi => -- JAL
				pccontr <= "101" & "00000000";
			when JREGi => -- JREG
				pccontr <= "0001" & "0000000";
			when RETIi => -- RETI
				pccontr <= "00001" & "000000";
			when ENIi => -- ENI
				pccontr <= "000001" & "00000";
			when DEIi => -- DEI
				pccontr <= "0000001" & "0000";
			when SISAi => -- SISA
				pccontr <= "10000001" & "000";
			when BOVi => -- BOV
				pccontr <= "100000001" & "00";
			when BEQZi => -- BEQZ
				pccontr <= "1000000001" & "0";
			when BNEZi => -- BNEZ
				pccontr <= "10000000001";
			
			-- other yet unset signals
			when INi => -- IN
				inop <= '1';
				selxres <= '1';
			when OUTi => -- OUT
				outop <= '1';
				selxres <= '1';
			when LOADi => -- LOAD
				loadop <= '1';
				dmemop <= '1';
				selxres <= '1';
			when STOREi => -- STORE
				storeop <= '1';
				dmemop <= '1';
				selxres <= '1';
			when DPMAi => -- DPMA
				dpma <= '1';
			when EPMAi => -- EPMA
				epma <= '1';

			-- unnecessary, but recquired for compilation
			when others =>
				pccontr <= (others => '0');
		end case;
	end process;
end rtl;
