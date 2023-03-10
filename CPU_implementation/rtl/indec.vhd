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
begin
	process(iword) is
	begin
		aopadr <= iword(19 downto 17);
		if iword(31 downto 28) = "0011" or iword(31 downto 28) = "1001" then -- OUT or STORE
			bopadr <= iword(22 downto 20);
			wopadr <= (others => '0');
		else
			bopadr <= iword(15 downto 13);
			wopadr <= iword(22 downto 20);
		end if;

		ivalid <= iword(16);
		iop <= iword(15 downto 0);

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
			when "0000" => -- SWI
				if iword(27 downto 23) = "00010" then
				   pccontr <= "01" & "000000000";
				end if;
			when "1010" => -- JAL
				pccontr <= "101" & "00000000";
			when "1011" => -- JREG
				pccontr <= "0001" & "0000000";
			when "1100" => -- RETI
				pccontr <= "00001" & "000000";
			when "0001" => -- ENI
				pccontr <= "000001" & "00000";
			when "0100" => -- DEI
				pccontr <= "0000001" & "0000";
			when "1101" => -- SISA
				pccontr <= "10000001" & "000";
			when "0111" => -- BOV
				pccontr <= "100000001" & "00";
			when "0110" => -- BEQZ
				pccontr <= "1000000001" & "0";
			when "0101" => -- BNEZ
				pccontr <= "10000000001";
			
			when "0010" => -- IN
				inop <= '1';
				selxres <= '1';
			when "0011" => -- OUT
				outop <= '1';
				selxres <= '1';
			when "1000" => -- LOAD
				loadop <= '1';
				dmemop <= '1';
				selxres <= '1';
			when "1001" => -- STORE
				storeop <= '1';
				dmemop <= '1';
				selxres <= '1';
			when "1110" => -- DPMA
				dpma <= '1';
			when "1111" => -- EPMA
				epma <= '1';

			when others =>
				pccontr <= (others => '0');
		end case;
	end process;
end rtl;
