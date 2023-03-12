---------------------------------------------------------------------------------------------------
--
-- Titel: Register File (using 8:1 multiplexer and 1:8 demultiplexer)
-- Autor: David Mihola (12211951)
-- Datum: 12. 03. 2023
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;

entity multiplexer_8to1 is 
	port(	
		-- input signals
		sig1    : in std_logic_vector(31 downto 0);
		sig2    : in std_logic_vector(31 downto 0);
		sig3    : in std_logic_vector(31 downto 0);
		sig4    : in std_logic_vector(31 downto 0);
		sig5    : in std_logic_vector(31 downto 0);
		sig6    : in std_logic_vector(31 downto 0);
		sig7    : in std_logic_vector(31 downto 0);
		
		-- selector
		sel		: in std_logic_vector(2 downto 0);

		-- output signal
		wout	: out std_logic_vector(31 downto 0)
	);
end multiplexer_8to1;

architecture rtl of multiplexer_8to1 is
begin
	process(sig1, sig2, sig3, sig4, sig5, sig6, sig7, sel) is
	begin
		case sel is
			when "001" => wout <= sig1;
			when "010" => wout <= sig2;
			when "011" => wout <= sig3;
			when "100" => wout <= sig4;
			when "101" => wout <= sig5;
			when "110" => wout <= sig6;
			when "111" => wout <= sig7;
			when others => wout <= (others => '0');
		end case;
	end process;
end rtl;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;

entity demultiplexer_1to8 is 
	port(
		-- enables output signal to be written
		enable	: in std_logic;
		reset	: in std_logic;

		-- input signal
		rin		: in std_logic_vector(31 downto 0);
		
		-- selector
		sel		: in std_logic_vector(2 downto 0);

		-- output signals
		sig1    : out std_logic_vector(31 downto 0);
		sig2    : out std_logic_vector(31 downto 0);
		sig3    : out std_logic_vector(31 downto 0);
		sig4    : out std_logic_vector(31 downto 0);
		sig5    : out std_logic_vector(31 downto 0);
		sig6    : out std_logic_vector(31 downto 0);
		sig7    : out std_logic_vector(31 downto 0)
	);
end demultiplexer_1to8;

architecture rtl of demultiplexer_1to8 is
begin
	process(reset, rin, sel, enable) is
	begin
		if reset = '1' then
			sig1 <= (others => '0');
			sig2 <= (others => '0');
			sig3 <= (others => '0');
			sig4 <= (others => '0');
			sig5 <= (others => '0');
			sig6 <= (others => '0');
			sig7 <= (others => '0');
		elsif enable = '1' then
			case sel is
				when "001" => sig1 <= rin;
				when "010" => sig2 <= rin;
				when "011" => sig3 <= rin;
				when "100" => sig4 <= rin;
				when "101" => sig5 <= rin;
				when "110" => sig6 <= rin;
				when "111" => sig7 <= rin;
				when others => null;
			end case;
		end if;
	end process;
end rtl;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity haregs is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- write port
		regwrite	: in  std_logic;
		wopadr		: in  std_logic_vector(2 downto 0);
		wop			: in  std_logic_vector(31 downto 0);
		
		-- read port A
		aopadr		: in  std_logic_vector(2 downto 0);
		aop			: out std_logic_vector(31 downto 0);
		
		-- read port B
		bopadr		: in  std_logic_vector(2 downto 0);
		bop			: out std_logic_vector(31 downto 0)
	);
end haregs;

architecture rtl of haregs is 
	component multiplexer_8to1 is
		port(
			-- input signals
			sig1    : in std_logic_vector(31 downto 0);
			sig2    : in std_logic_vector(31 downto 0);
			sig3    : in std_logic_vector(31 downto 0);
			sig4    : in std_logic_vector(31 downto 0);
			sig5    : in std_logic_vector(31 downto 0);
			sig6    : in std_logic_vector(31 downto 0);
			sig7    : in std_logic_vector(31 downto 0);

			-- selector
			sel		: in std_logic_vector(2 downto 0);

			-- output signal
			wout	: out std_logic_vector(31 downto 0)
		);
	end component;

	component demultiplexer_1to8 is 
		port(
			-- enables output signal to be written
			enable	: in std_logic;
			reset	: in std_logic;

			-- input signal
			rin		: in std_logic_vector(31 downto 0);

			-- selector
			sel		: in std_logic_vector(2 downto 0);

			-- output signals
			sig1    : out std_logic_vector(31 downto 0);
			sig2    : out std_logic_vector(31 downto 0);
			sig3    : out std_logic_vector(31 downto 0);
			sig4    : out std_logic_vector(31 downto 0);
			sig5    : out std_logic_vector(31 downto 0);
			sig6    : out std_logic_vector(31 downto 0);
			sig7    : out std_logic_vector(31 downto 0)
		);
	end component;

	signal reg1 : std_logic_vector(31 downto 0);
	signal reg2 : std_logic_vector(31 downto 0);
	signal reg3 : std_logic_vector(31 downto 0);
	signal reg4 : std_logic_vector(31 downto 0);
	signal reg5 : std_logic_vector(31 downto 0);
	signal reg6 : std_logic_vector(31 downto 0);
	signal reg7 : std_logic_vector(31 downto 0);

	signal enable : std_logic := '0';
begin
	-- All writes to registers must be in a single process, otherwise the value inside registers will be undefined.
	process(clk, regwrite) is
	begin
		if rising_edge(clk) and regwrite = '1' then -- synchronously write a supplied value to a given valid register
			enable <= '1';
		else
			enable <= '0';
		end if;
	end process;
	
	-- input
	WRITE: demultiplexer_1to8 port map(
		sig1 => reg1,
		sig2 => reg2,
		sig3 => reg3,
		sig4 => reg4,
		sig5 => reg5,
		sig6 => reg6,
		sig7 => reg7,
		sel  => wopadr,
		rin  => wop,
		enable => enable,
		reset => reset
	);

	-- output A
	outA: multiplexer_8to1 port map(
		sig1 => reg1,
		sig2 => reg2,
		sig3 => reg3,
		sig4 => reg4,
		sig5 => reg5,
		sig6 => reg6,
		sig7 => reg7,
		sel  => aopadr,
		wout => aop
	);
	
	-- output B
	outB: multiplexer_8to1 port map(
		sig1 => reg1,
		sig2 => reg2,
		sig3 => reg3,
		sig4 => reg4,
		sig5 => reg5,
		sig6 => reg6,
		sig7 => reg7,
		sel  => bopadr,
		wout => bop
	);
end rtl;
