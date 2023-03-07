-------------------------------------------------------------------------------
-- bcd decoder  -----------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity bcd_decoder is
	port(
	    en : in std_logic;
		bcd_in : in std_logic_vector(3 downto 0);
		bcd_out : out std_logic_vector(6 downto 0)
	);
end bcd_decoder;

architecture rtl of bcd_decoder is
begin
    bcd_out <= "1111111" when en = '0' else
               "1000000" when bcd_in = "0000" else
               "1111001" when bcd_in = "0001" else
               "0100100" when bcd_in = "0010" else
               "0110000" when bcd_in = "0011" else
               "0011001" when bcd_in = "0100" else
               "0010010" when bcd_in = "0101" else
               "0000010" when bcd_in = "0110" else
               "1111000" when bcd_in = "0111" else
               "0000000" when bcd_in = "1000" else
               "0010000" when bcd_in = "1001" else
               "1111111";
end rtl;

-------------------------------------------------------------------------------
-- XSevenSeg                                                                 --
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.all;
	use xbus_common.xtoolbox.all;
library work;
	use work.all;
	
entity xsevenseg is
	generic (
		FREQ		: natural
	);
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- bus interface
		adr			: in  unsigned(7 downto 0);
		datain		: in  std_logic_vector(31 downto 0);
		dataout		: out std_logic_vector(31 downto 0);
		read		: in  std_logic;
		write		: in  std_logic;
		present		: out std_logic;
		ack			: out std_logic;
		intr		: out std_logic;
		
		-- external signals
		seg			: out std_logic_vector(6 downto 0);
		dp			: out std_logic;
		an			: out  std_logic_vector(3 downto 0)
	);
end xsevenseg;

architecture rtl of xsevenseg is		

	-- config
	constant BASE : natural := 224;
	constant REGS : natural := 1;
	
	-- register bank
	signal reg_data		: regbank(REGS-1 downto 0);
	signal reg_re		: std_logic_vector(REGS-1 downto 0);
	signal reg_we		: std_logic_vector(REGS-1 downto 0);
	
	signal bcd_in : std_logic_vector(3 downto 0);
	
    signal timer    : unsigned(log2(FREQ/2)-1 downto 0);
	
	signal bcd1, bcd2, bcd3, bcd4 : std_logic_vector(3 downto 0);
	signal dp1, dp2, dp3, dp4 : std_logic;
	signal seg_en : std_logic;
	signal index : unsigned(1 downto 0);	
begin	
	intr <= '0';
	-- connect register bank
	process(adr, read, write, reg_data)
		variable sel : integer;
	begin
		-- set default output
		present <= '0';
		ack     <= '0';
		reg_re  <= (others=>'0');
		reg_we  <= (others=>'0');
		dataout <= (others=>'0');
		
		-- get selection
		sel := to_integer(unsigned(adr)) - BASE;
		if (sel>=0) and (sel<REGS) then
			present     <= '1';
			ack         <= read or write;
			dataout     <= reg_data(sel);
			reg_re(sel) <= read;
			reg_we(sel) <= write;
		end if;
	end process;	
	
    bcd1 <= reg_data(0)(3 downto 0);
    bcd2 <= reg_data(0)(7 downto 4);
    bcd3 <= reg_data(0)(11 downto 8);
    bcd4 <= reg_data(0)(15 downto 12);
    dp1 <= not reg_data(0)(16);
    dp2 <= not reg_data(0)(17);
    dp3 <= not reg_data(0)(18);
    dp4 <= not reg_data(0)(19);
    seg_en <= reg_data(0)(31);
	-- handle requests
	process(clk, reset)
	begin
		if reset='1' then
            dp <= '1';
            an <= (others=>'1');
            index <= to_unsigned(0, index'length);
            timer  <= to_unsigned(0, timer'length);
            bcd_in <= "1111";
		elsif rising_edge(clk) then
		  
            if reg_we(0)='1' then 
                reg_data(0) <= datain;
            end if;
		
		    if timer=0 then
                timer  <= to_unsigned(100000, timer'length);
                case index is
                    when "00" => an <= "1110"; bcd_in <= bcd1; dp <= dp1;
                    when "01" => an <= "1101"; bcd_in <= bcd2; dp <= dp2;
                    when "10" => an <= "1011"; bcd_in <= bcd3; dp <= dp3;
                    when "11" => an <= "0111"; bcd_in <= bcd4; dp <= dp4;
                    when others => an <= "1111"; bcd_in <= "0000"; dp <= '1';
                end case;
                if index = x"3" then
                    index <= to_unsigned(0, index'length);
                else
                    index <= index + 1;
                end if;
            else
                timer  <= timer-1;
            end if;
		    
		end if;
	end process;
	
	decoder : entity bcd_decoder 
	   port map(
	       en => seg_en,
	       bcd_in => bcd_in,
	       bcd_out => seg
	   );


end rtl;
