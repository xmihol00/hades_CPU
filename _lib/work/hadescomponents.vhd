library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library xbus_common;
	use xbus_common.xtoolbox.all;
library std;
	use std.textio.all;
	
package hadescomponents is	
	
	--
	-- types & helper functions
	--
	
	-- memory type
	type mem_init_t is array(natural range<>) of std_logic_vector(31 downto 0);

	--
	-- components (provided)
	--

	component hades_ram32_dp is
		generic (
			WIDTH_ADDR  : natural;
			INIT_FILE	: string     := "UNUSED";
			INIT_DATA   : mem_init_t := (0=>x"00000000")
		);
		port (
			-- common
			clk 		: in  std_logic;
			reset 		: in  std_logic;
			
			-- write port
			wena		: in  std_logic;
			waddr		: in  std_logic_vector(WIDTH_ADDR-1 downto 0);
			wdata		: in  std_logic_vector(31 downto 0);
			
			-- read port
			rena		: in  std_logic;
			raddr		: in  std_logic_vector(WIDTH_ADDR-1 downto 0);
			rdata		: out std_logic_vector(31 downto 0)
		);
	end component;	
	
	component hades_shift is
		generic (
			N			: natural
		);
		port (
			-- control
			cyclic		: in  std_logic;
			right		: in  std_logic;
			
			-- input
			a			: in  std_logic_vector(N-1 downto 0);
			b			: in  std_logic_vector(log2(N)-1 downto 0);
			
			-- output
			r			: out std_logic_vector(N-1 downto 0);
			ov			: out std_logic
		);
	end component;
	
	component hades_addsub is
		generic (
			N	: natural
		);
		port (
			-- control
			sub	: in  std_logic;
			
			-- input
			a	: in  std_logic_vector(N-1 downto 0);
			b	: in  std_logic_vector(N-1 downto 0);
			
			-- output
			r	: out std_logic_vector(N-1 downto 0);	
			ov	: out std_logic
		);
	end component;

	component hades_mul is
		generic (
			N	: natural
		);
		port (
			-- common
			clk : in  std_logic;
			
			-- input
			a	: in  std_logic_vector(N-1 downto 0);
			b	: in  std_logic_vector(N-1 downto 0);
			
			-- output
			r	: out std_logic_vector(N-1 downto 0);	
			ov	: out std_logic
		);
	end component;
	

	component hades_compare is
		generic (
			N	: natural
		);
		port (
			-- input
			a	: in  std_logic_vector(N-1 downto 0);
			b	: in  std_logic_vector(N-1 downto 0);
			
			-- output
			lt	: out std_logic;
			eq	: out std_logic;
			gt  : out std_logic
		);
	end component;


	component irqreceiver is
		port(
			CLK : in std_logic;
			RESET : in std_logic;
			IACK : in std_logic;
			ISIGNAL : in std_logic;
			Q : out std_logic
		);
	end component;


	--
	-- program memory helper
	--
	
	-- return program memory from MIF file
	impure function hades_read_hex(fname : in string; WA : in natural) return mem_init_t;
	
	-- return default program memory (==> bootloader)
	function hades_bootloader return mem_init_t;
	
	--
	-- testbench helper
	--
	
	-- types used in testbenches
	subtype t_word  is std_logic_vector(31 downto 0);
	subtype t_short is std_logic_vector(15 downto 0);
	subtype t_pmemoryAdr is unsigned(11 downto 0);
	subtype t_haregsAdr is unsigned(2 downto 0);
	subtype t_opcode is std_logic_vector(4 downto 0);
	subtype t_irqLvl is unsigned(2 downto 0);
	subtype t_sisaLvl is unsigned(1 downto 0);
	subtype t_xbusAdr is std_logic_vector(12 downto 0);
	
	
	-- ALU opcodes
	constant opc_NOP    : t_opcode := "00000";
	constant opc_SWI    : t_opcode := "00010";
	constant opc_GETSWI : t_opcode := "00011";
	constant opc_SHL    : t_opcode := "00100";
	constant opc_SHR    : t_opcode := "00101";
	constant opc_CSHL   : t_opcode := "00110";
	constant opc_CSHR   : t_opcode := "00111";
	constant opc_AND    : t_opcode := "01000";
	constant opc_OR     : t_opcode := "01001";
	constant opc_XOR    : t_opcode := "01010";
	constant opc_XNOR   : t_opcode := "01011";
	constant opc_BNEZ   : t_opcode := "01100";
	constant opc_BEQZ   : t_opcode := "01101";
	constant opc_PASS   : t_opcode := "01110";
	constant opc_SUB    : t_opcode := "10000";
	constant opc_ADD    : t_opcode := "10001";
	constant opc_SETOV  : t_opcode := "10010";
	constant opc_GETOV  : t_opcode := "10011";
	constant opc_MUL    : t_opcode := "10100";
	constant opc_SNE    : t_opcode := "11000";
	constant opc_SEQ    : t_opcode := "11001";
	constant opc_SGT    : t_opcode := "11010";
	constant opc_SGE    : t_opcode := "11011";
	constant opc_SLT    : t_opcode := "11100";
	constant opc_SLE    : t_opcode := "11101";
  
	-- functions used in testbech
	function to_bin(x : std_logic_vector) return string;
	function to_bin(x : unsigned) return string;
	function to_bin(x : signed) return string;
	function to_hex(x : std_logic_vector) return string;
	function to_hex(x : unsigned) return string;
	function to_hex(x : signed) return string;
end hadescomponents;

package body hadescomponents is
	
	---------------------------------------------------------------------------
	-- general helper                                                        --
	---------------------------------------------------------------------------
	
	-- convert 'std_logic_vector' to binary-string
	function to_bin(x: std_logic_vector) return string is
		variable res: string(x'length downto 1);
		variable tmp: string(3 downto 1);
		variable x2 : std_logic_vector(x'length-1 downto 0);
	begin
		x2 := x;
		for j in 0 to x2'length-1 loop
			tmp := std_logic'image(x2(j));
			res(1+j) := tmp(2);
		end loop;
		return res;
	end to_bin;
	
	-- convert 'unsigned' to binary-string
	function to_bin(x : unsigned) return string is
	begin
		return to_bin(std_logic_vector(x));
	end;
	
	-- convert 'signed' to binary-string
	function to_bin(x : signed) return string is
	begin
		return to_bin(std_logic_vector(x));
	end;
	
	-- convert 'std_logic_vector' to hex-string
	function to_hex(x: std_logic_vector) return string is
		type hex_lut is array (0 to 15) of character;
		constant hextable:hex_lut :=
			('0', '1', '2', '3', '4', '5', '6', '7',
			'8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
		constant str_len:natural:=(x'length+3)/4;
		variable temp:integer;
		variable inva:boolean;
		variable ret_string: string(str_len downto 1);
		variable x2 : std_logic_vector(x'length-1 downto 0);
	begin
		x2   := to_X01Z(x);
		temp := 0;
		inva := false;
		for j in 0 to x'length-1 loop
			if x2(j)='1' then
				temp := temp + 2**(j mod 4);
			elsif x2(j)/='0' then
				inva := true;
			end if;
			if (j mod 4)=3 or j=x'length-1 then
				if inva 
					then ret_string(j/4+1):= 'X';
					else ret_string(j/4+1):= hextable(temp);
				end if;
				temp := 0;
				inva := false;
			end if;
		end loop;
		return ret_string;
	end to_hex;

	-- convert 'unsigned' to hex-string
	function to_hex(x : unsigned) return string is
	begin
		return to_hex(std_logic_vector(x));
	end;
	
	-- convert 'signed' to hex-string
	function to_hex(x : signed) return string is
	begin
		return to_hex(std_logic_vector(x));
	end;

	
	---------------------------------------------------------------------------
	-- MIF parser ('borrowed' from altera simulation models)                 --
	---------------------------------------------------------------------------
	
	-- converts uppercase parameter values (e.g. "AUTO") to lowercase ("auto")
	function ALPHA_TOLOWER (given_string : in string) return string is
	    -- VARIABLE DECLARATION
	    variable result_string : string(given_string'low to given_string'high);
	begin
	    for i in given_string'low to given_string'high loop
	        case given_string(i) is
	            when 'A' => result_string(i) := 'a';
	            when 'B' => result_string(i) := 'b';
	            when 'C' => result_string(i) := 'c';
	            when 'D' => result_string(i) := 'd';
	            when 'E' => result_string(i) := 'e';
	            when 'F' => result_string(i) := 'f';
	            when 'G' => result_string(i) := 'g';
	            when 'H' => result_string(i) := 'h';
	            when 'I' => result_string(i) := 'i';
	            when 'J' => result_string(i) := 'j';
	            when 'K' => result_string(i) := 'k';
	            when 'L' => result_string(i) := 'l';
	            when 'M' => result_string(i) := 'm';
	            when 'N' => result_string(i) := 'n';
	            when 'O' => result_string(i) := 'o';
	            when 'P' => result_string(i) := 'p';
	            when 'Q' => result_string(i) := 'q';
	            when 'R' => result_string(i) := 'r';
	            when 'S' => result_string(i) := 's';
	            when 'T' => result_string(i) := 't';
	            when 'U' => result_string(i) := 'u';
	            when 'V' => result_string(i) := 'v';
	            when 'W' => result_string(i) := 'w';
	            when 'X' => result_string(i) := 'x';
	            when 'Y' => result_string(i) := 'y';
	            when 'Z' => result_string(i) := 'z';
	            when others => result_string(i) := given_string(i);
	        end case;
	    end loop;
	
	    return (result_string(given_string'low to given_string'high));
	end;

	-- This function converts a integer string to an integer
	function INT_STR_TO_INT (str : in string) return integer is
	variable len : integer := str'length;
	variable newdigit : integer := 0;
	variable sign : integer := 1;
	variable digit : integer := 0;
	begin
	    for i in 1 to len loop
	        case str(i) is
	            when '-' =>
	                if i = 1 then
	                    sign := -1;
	                else
	                    ASSERT FALSE
	                    REPORT "Illegal Character "&  str(i) & "i n string parameter! "
	                    SEVERITY ERROR;
	                end if;
	            when '0' =>
	                digit := 0;
	            when '1' =>
	                digit := 1;
	            when '2' =>
	                digit := 2;
	            when '3' =>
	                digit := 3;
	            when '4' =>
	                digit := 4;
	            when '5' =>
	                digit := 5;
	            when '6' =>
	                digit := 6;
	            when '7' =>
	                digit := 7;
	            when '8' =>
	                digit := 8;
	            when '9' =>
	                digit := 9;
	            when others =>
	                ASSERT FALSE
	                REPORT "Illegal Character "&  str(i) & "in string parameter! "
	                SEVERITY ERROR;
	        end case;
	        newdigit := newdigit * 10 + digit;
	    end loop;
	
	    return (sign*newdigit);
	end;

	-- This procedure "cuts" the str_line into desired length
	procedure SHRINK_LINE (str_line : inout line; pos : in integer) is
	subtype nstring is string(1 to pos);
	variable str : nstring;
	begin
	    if (pos >= 1) then
	        read(str_line, str);
	    end if;
	end;
	
	-- This function converts an integer to a string
	function INT_TO_STR (value : in integer) return string is
	variable ivalue : integer := 0;
	variable index  : integer := 0;
	variable digit : integer := 0;
	variable line_no: string(8 downto 1) := "        ";  
	begin
	    ivalue := value;
	    index := 1;
	    
	    while (ivalue > 0) loop
	        digit := ivalue MOD 10;
	        ivalue := ivalue/10;
	        case digit is
	            when 0 => line_no(index) := '0';
	            when 1 => line_no(index) := '1';
	            when 2 => line_no(index) := '2';
	            when 3 => line_no(index) := '3';
	            when 4 => line_no(index) := '4';
	            when 5 => line_no(index) := '5';
	            when 6 => line_no(index) := '6';
	            when 7 => line_no(index) := '7';
	            when 8 => line_no(index) := '8';
	            when 9 => line_no(index) := '9';
	            when others =>
	                ASSERT FALSE
	                REPORT "Illegal number!"
	                SEVERITY ERROR;
	        end case;
	        index := index + 1;
	    end loop;
	    
	    return line_no;
	end INT_TO_STR;
	
	-- This function converts a binary number to an integer
	function BIN_STR_TO_INT (str : in string) return integer is
	variable len : integer := str'length;
	variable ivalue : integer := 0;
	variable digit : integer := 0;
	begin
	    for i in len downto 1 loop
	        case str(i) is
	            when '0' => digit := 0;
	            when '1' => digit := 1;
	            when others =>
	                ASSERT FALSE
	                REPORT "Illegal bin character "&  str(i) & "! "
	                SEVERITY ERROR;
	        end case;
	        ivalue := ivalue * 2 + digit;
	    end loop;
	    return ivalue;
	end BIN_STR_TO_INT;

	-- This function converts a octadecimal number to an integer
	function OCT_STR_TO_INT (str : in string) return integer is
	variable len : integer := str'length;
	variable ivalue : integer := 0;
	variable digit : integer := 0;
	begin
	    for i in len downto 1 loop
	        case str(i) is
	            when '0' => digit := 0;
	            when '1' => digit := 1;
	            when '2' => digit := 2;
	            when '3' => digit := 3;
	            when '4' => digit := 4;
	            when '5' => digit := 5;
	            when '6' => digit := 6;
	            when '7' => digit := 7;
	            when others =>
	                ASSERT FALSE
	                REPORT "Illegal octadecimal character "&  str(i) & "! "
	                SEVERITY ERROR;
	        end case;
	        ivalue := ivalue * 8 + digit;
	    end loop;
	    return ivalue;
	end OCT_STR_TO_INT;

	-- This function converts a hexadecimal number to an integer
	function HEX_STR_TO_INT (str : in string) return integer is
	variable len : integer := str'length;
	variable ivalue : integer := 0;
	variable digit : integer := 0;
	begin
	    for i in len downto 1 loop
	        case str(i) is
	            when '0' => digit := 0;
	            when '1' => digit := 1;
	            when '2' => digit := 2;
	            when '3' => digit := 3;
	            when '4' => digit := 4;
	            when '5' => digit := 5;
	            when '6' => digit := 6;
	            when '7' => digit := 7;
	            when '8' => digit := 8;
	            when '9' => digit := 9;
	            when 'A' => digit := 10;
	            when 'a' => digit := 10;
	            when 'B' => digit := 11;
	            when 'b' => digit := 11;
	            when 'C' => digit := 12;
	            when 'c' => digit := 12;
	            when 'D' => digit := 13;
	            when 'd' => digit := 13;
	            when 'E' => digit := 14;
	            when 'e' => digit := 14;
	            when 'F' => digit := 15;
	            when 'f' => digit := 15;
	            when others =>
	                ASSERT FALSE
	                REPORT "Illegal hex character "&  str(i) & "! "
	                SEVERITY ERROR;
	        end case;
	        ivalue := ivalue * 16 + digit;
	    end loop;
	    return ivalue;
	end HEX_STR_TO_INT;
	
	impure function hades_read_hex (fname : in string; WA : in natural) return mem_init_t is
	
		constant lpm_width   : natural := 32;
		constant lpm_widthad : natural := WA;
	
	    variable mem_data : mem_init_t(0 to (2**lpm_widthad)-1);
	    variable mem_data_word : std_logic_vector(lpm_width-1 downto 0);
	    variable mem_init: boolean := false;
	    variable i, j, k, n, m, lineno: integer := 0;
	    variable buf: line ;
	    variable booval: boolean ;
	    FILE mem_data_file: TEXT;
	    variable char : string(1 downto 1) := " ";
	    variable base, byte, rec_type, datain, addr, checksum: string(2 downto 1);
	    variable startadd: string(4 downto 1);
	    variable ibase: integer := 0;
	    variable ibyte: integer := 0;
	    variable istartadd: integer := 0;
	    variable check_sum_vec, check_sum_vec_tmp: unsigned(7 downto 0);
	    variable m_string : string(1 to 15);
	    variable m_data_radix : string(1 to 3);
	    variable m_address_radix : string(1 to 3);
	    variable m_width : integer;
	    variable m_depth : integer;
	    variable m_start_address_int : integer := 0;
	    variable m_end_address_int : integer := 0;
	    variable m_address_int : integer := 0;
	    variable m_data_int : unsigned(lpm_width+4 downto 0) := (OTHERS => '0');
	    variable found_keyword_content : boolean := false;
	    variable get_memory_content : boolean := false;
	    variable get_start_Address : boolean := false;
	    variable get_end_Address : boolean := false;
    begin

-- synopsys translate_off

        -- Initialize
        if not (mem_init) then
            -- Initialize to 0
            for i in mem_data'range(1) loop
               	mem_data(i) := x"00000000";
            end loop;

            if (fname /= "UNUSED") then
                FILE_OPEN(mem_data_file, fname, READ_MODE);
                if (ALPHA_TOLOWER(fname(fname'length -3 to fname'length)) = ".hex") then
                    while not ENDFILE(mem_data_file) loop
                        booval := true;
                        READLINE(mem_data_file, buf);
                        lineno := lineno + 1;
                        check_sum_vec := (OTHERS => '0');
--                        if (buf(buf'low) = ':') then
                        if (true) then
                            i := 1;
                            SHRINK_LINE(buf, i);
                            READ(L=>buf, VALUE=>byte, good=>booval);
                            if not (booval) then
                                ASSERT FALSE
                                REPORT "[Line "& INT_TO_STR(lineno) & "]:Illegal Intel Hex Format!"
                                SEVERITY ERROR;
                            end if;
                            ibyte := HEX_STR_TO_INT(byte);
                            check_sum_vec :=    check_sum_vec + 
                                                to_unsigned(ibyte, 8);
                            READ(L=>buf, VALUE=>startadd, good=>booval);
                            if not (booval) then
                                ASSERT FALSE
                                REPORT "[Line "& INT_TO_STR(lineno) & "]:Illegal Intel Hex Format! "
                                SEVERITY ERROR;
                            end if;
                            istartadd := HEX_STR_TO_INT(startadd);
                            addr(2) := startadd(4);
                            addr(1) := startadd(3);
                            check_sum_vec :=    check_sum_vec + 
                                                to_unsigned(HEX_STR_TO_INT(addr), 8);
                            addr(2) := startadd(2);
                            addr(1) := startadd(1);
                            check_sum_vec :=    check_sum_vec + 
                                                to_unsigned(HEX_STR_TO_INT(addr), 8);
                            READ(L=>buf, VALUE=>rec_type, good=>booval);
                            if not (booval) then
                                ASSERT FALSE
                                REPORT "[Line "& INT_TO_STR(lineno) & "]:Illegal Intel Hex Format! "
                                SEVERITY ERROR;
                            end if;
                            check_sum_vec :=    check_sum_vec + 
                                                to_unsigned(HEX_STR_TO_INT(rec_type), 8);
                        else
                            ASSERT FALSE
                            REPORT "[Line "& INT_TO_STR(lineno) & "]:Illegal Intel Hex Format! "
                            SEVERITY ERROR;
                        end if;
                        case rec_type is
                            when "00"=>     -- data record
                                i := 0;
                                k := lpm_width / 8;
                                if ((lpm_width mod 8) /= 0) then
                                    k := k + 1; 
                                end if;
                                -- k = no. of bytes per CAM entry.
                                while (i < ibyte) loop
                                    mem_data_word := (others => '0');
                                    n := (k - 1)*8;
                                    m := lpm_width - 1;
                                    
                                    for j in 1 to k loop
                                        READ(L=>buf, VALUE=>datain,good=>booval); -- read in data a byte (2 hex chars) at a time.
                                        if not (booval) then
                                            ASSERT FALSE
                                            REPORT "[Line "& INT_TO_STR(lineno) & "]:Illegal Intel Hex Format! "
                                            SEVERITY ERROR;
                                        end if;
                                        check_sum_vec :=    check_sum_vec + 
                                                            to_unsigned(HEX_STR_TO_INT(datain), 8);
                                        mem_data_word(m downto n) := std_logic_vector(to_unsigned(HEX_STR_TO_INT(datain), m-n+1));
                                        m := n - 1;
                                        n := n - 8;
                                    end loop;
                                    i := i + k;
                                    mem_data(ibase + istartadd) := mem_data_word;
                                    istartadd := istartadd + 1;
                                end loop;
                            when "01"=>
                                exit;
                            when "02"=>
                                ibase := 0;
                                if (ibyte /= 2) then
                                    ASSERT FALSE
                                    REPORT "[Line "& INT_TO_STR(lineno) & "]:Illegal Intel Hex Format for record type 02! "
                                    SEVERITY ERROR;
                                end if;
                                for i in 0 to (ibyte-1) loop
                                    READ(L=>buf, VALUE=>base,good=>booval);
                                    ibase := (ibase * 256) + HEX_STR_TO_INT(base);
                                    if not (booval) then
                                        ASSERT FALSE
                                        REPORT "[Line "& INT_TO_STR(lineno) & "]:Illegal Intel Hex Format! "
                                        SEVERITY ERROR;
                                    end if;
                                    check_sum_vec :=   check_sum_vec + 
                                                       to_unsigned(HEX_STR_TO_INT(base), 8);
                                end loop;
                                ibase := ibase * 16;
                            when "03"=>
                        
                                if (ibyte /= 4) then
                                    ASSERT FALSE
                                    REPORT  "[Line "& INT_TO_STR(lineno) & 
                                            "]:Illegal Intel Hex Format for record type 03! "
                                    SEVERITY ERROR;
                                end if;
                                
                                for i in 0 to (ibyte-1) loop
                                    READ(L=>buf, VALUE=>base,good=>booval);
                                    
                                    if not (booval) then
                                        ASSERT FALSE
                                        REPORT  "[Line "& INT_TO_STR(lineno) & 
                                                "]:Illegal Intel Hex Format! "
                                        SEVERITY ERROR;
                                    end if;
                                    
                                    check_sum_vec := check_sum_vec + to_unsigned(HEX_STR_TO_INT(base), 8);
                                end loop;
                            when "04"=>
                                ibase := 0;
                        
                                if (ibyte /= 2) then
                                    ASSERT FALSE
                                    REPORT  "[Line "& INT_TO_STR(lineno) & 
                                            "]:Illegal Intel Hex Format for record type 04! "
                                    SEVERITY ERROR;
                                end if;
                                
                                for i in 0 to (ibyte-1) loop
                                    READ(L=>buf, VALUE=>base,good=>booval);
                                    ibase := (ibase * 256) + HEX_STR_TO_INT(base);
                                    
                                    if not (booval) then
                                        ASSERT FALSE
                                        REPORT  "[Line "& INT_TO_STR(lineno) & 
                                                "]:Illegal Intel Hex Format! "
                                        SEVERITY ERROR;
                                    end if;
                                    
                                    check_sum_vec := check_sum_vec + to_unsigned(HEX_STR_TO_INT(base), 8);
                                end loop;
                                ibase := ibase * 65536;
                            when "05"=>
                        
                                if (ibyte /= 4) then
                                    ASSERT FALSE
                                    REPORT  "[Line "& INT_TO_STR(lineno) & 
                                            "]:Illegal Intel Hex Format for record type 05! "
                                    SEVERITY ERROR;
                                end if;
                                
                                for i in 0 to (ibyte-1) loop
                                    READ(L=>buf, VALUE=>base,good=>booval);
                                    
                                    if not (booval) then
                                        ASSERT FALSE
                                        REPORT  "[Line "& INT_TO_STR(lineno) & 
                                                "]:Illegal Intel Hex Format! "
                                        SEVERITY ERROR;
                                    end if;
                                    
                                    check_sum_vec := check_sum_vec + to_unsigned(HEX_STR_TO_INT(base), 8);
                                end loop;
                            when OTHERS =>
                                ASSERT FALSE
                                REPORT "[Line "& INT_TO_STR(lineno) & "]:Illegal record type in Intel Hex File! "
                                SEVERITY ERROR;
                        end case;
                        READ(L=>buf, VALUE=>checksum,good=>booval);
                        if not (booval) then
                            ASSERT FALSE
                            REPORT "[Line "& INT_TO_STR(lineno) & "]:Checksum is missing! "
                            SEVERITY ERROR;
                        end if;
    
                        check_sum_vec := unsigned(not (check_sum_vec)) + 1 ;
                        check_sum_vec_tmp := to_unsigned(HEX_STR_TO_INT(checksum),8);
    
                        if (unsigned(check_sum_vec) /= unsigned(check_sum_vec_tmp)) then
                            ASSERT FALSE
                            REPORT "[Line "& INT_TO_STR(lineno) & "]:Incorrect checksum!"
                            SEVERITY ERROR;
                        end if;
                    end loop;
                elsif (ALPHA_TOLOWER(fname(fname'length -3 to fname'length)) = ".mif") then
                    -- ************************************************
                    -- Read in RAM initialization file (mif)
                    -- ************************************************
                    while not endfile(mem_data_file) loop
                        booval := true;
                        readline(mem_data_file, buf);
                        lineno := lineno + 1;
                        LOOP2 : while (buf'length > 0) loop
                            if (buf(buf'low) = '-') then
                                if (buf(buf'low) = '-') then
                                    -- ignore comment started with --.
                                    exit LOOP2;
                                end if;
                            elsif (buf(buf'low) = '%') then
                                i := 1;
          
                                -- zum Debuggen eingefügt                    
                                --  ASSERT FALSE
                                --  REPORT "buffy!" & INT_TO_STR(buf'high) & " low " & INT_TO_STR(buf'low) & " ! "
                                --  SEVERITY ERROR;
                                
                                -- ignore comment which begin with % and end with another %.
                                
                                -- old hat Fehler, bound error, wenn buf'low schon high ist gibts buf(buf_low + i) nicht!!!
                                -- konnte passieren
                                --while ((i < (buf'high)) and (buf(buf'low + i) /= '%')) loop
                                --        i := i+1;
                                --end loop;
                                
                                -- ersetzt durch
                                -- ignore comment which begin with % and end with another %.
                                LOOP3 : while (i < (buf'high)) loop
                                           if ((buf'low + i) <= buf'high) then
                                            if(buf(buf'low + i) = '%') then
                                              exit LOOP3;
                                            end if;
                                           end if;
                                            i:=i+1;
                                        end loop;
                                
                                if (i >= buf'high) then
                                    exit LOOP2;
                                else
                                    SHRINK_LINE(buf, i+1);
                                end if;
                            elsif ((buf(buf'low) = ' ') or (buf(buf'low) = HT)) then
                                i := 1;
                                -- ignore space or tab character.
                                while ((i < buf'high-1) and ((buf(buf'low +i) = ' ') or
                                        (buf(buf'low+i) = HT))) loop
                                    i := i+1;
                                end loop;
                                
                                if (i >= buf'high) then
                                    exit LOOP2;
                                else
                                    SHRINK_LINE(buf, i);
                                end if;
                            elsif (get_memory_content = true) then
                            
                                if ((buf(buf'low to buf'low +2) = "end") or
                                    (buf(buf'low to buf'low +2) = "END") or
                                    (buf(buf'low to buf'low +2) = "End")) then
                                    get_memory_content := false;
                                    exit LOOP2;
                                else
                                    get_start_address := false;
                                    get_end_address := false;
                                    m_start_address_int := 0;
                                    m_end_address_int := 0;
                                    m_address_int := 0;
                                    m_data_int := (others => '0');
                                    if (buf(buf'low) = '[') then
                                        get_start_Address := true;
                                        SHRINK_LINE(buf, 1);
                                    end if;
        
                                    case m_address_radix is
                                        when "hex" =>
                                            while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                    (buf(buf'low) /= ':') and (buf(buf'low) /= '.')) loop
                                                read(l => buf, value => char, good => booval);
                                                m_address_int := m_address_int *16 +  HEX_STR_TO_INT(char);
                                            end loop;
                                        when "bin" =>
                                            while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                    (buf(buf'low) /= ':') and (buf(buf'low) /= '.')) loop
                                                read(l => buf, value => char, good => booval);
                                                m_address_int := m_address_int *2 +  BIN_STR_TO_INT(char);
                                            end loop;
                                        when "dec" =>
                                            while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                    (buf(buf'low) /= ':') and (buf(buf'low) /= '.')) loop
                                                read(l => buf, value => char, good => booval);
                                                m_address_int := m_address_int *10 +  INT_STR_TO_INT(char);
                                            end loop;
                                        when "uns" =>
                                            while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                    (buf(buf'low) /= ':') and (buf(buf'low) /= '.')) loop
                                                read(l => buf, value => char, good => booval);
                                                m_address_int := m_address_int *10 +  INT_STR_TO_INT(char);
                                            end loop;
                                        when "oct" =>
                                            while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                    (buf(buf'low) /= ':') and (buf(buf'low) /= '.')) loop
                                                read(l => buf, value => char, good => booval);
                                                m_address_int := m_address_int *8 + OCT_STR_TO_INT(char);
                                            end loop;
                                        when others =>
                                            assert false
                                            report "Unsupported address_radix!"
                                            severity error;
                                    end case;
        
                                    if (get_start_Address = true) then
                                    
                                        i := 0;
                                        -- ignore space or tab character.
                                        while ((i < buf'high-1) and ((buf(buf'low +i) = ' ') or
                                            (buf(buf'low+i) = HT))) loop
                                            i := i+1;
                                        end loop;
                                    
                                        if (i > 0) then
                                            SHRINK_LINE(buf, i);
                                        end if;
            
                                        if ((buf(buf'low) = '.') and (buf(buf'low+1) = '.')) then
                                            get_start_Address := false;
                                            get_end_Address := true;
                                            m_start_address_int := m_address_int;
                                            SHRINK_LINE(buf, 2);    
                                        end if;
                                    end if;
        
                                    if (get_end_address = true) then
                                        i := 0;
                                        -- ignore space or tab character.
                                        while ((i < buf'high-1) and ((buf(buf'low +i) = ' ') or
                                            (buf(buf'low+i) = HT))) loop
                                            i := i+1;
                                        end loop;
                                    
                                        if (i > 0) then
                                            SHRINK_LINE(buf, i);
                                        end if;                                
                                        
                                        m_address_int := 0;
                                        case m_address_radix is
                                            when "hex" =>
                                                while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                        (buf(buf'low) /= ']')) loop
                                                    read(l => buf, value => char, good => booval);
                                                    m_address_int := m_address_int *16 +  HEX_STR_TO_INT(char);
                                                end loop;
                                            when "bin" =>
                                                while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                        (buf(buf'low) /= ']')) loop
                                                    read(l => buf, value => char, good => booval);
                                                    m_address_int := m_address_int *2 +  BIN_STR_TO_INT(char);
                                                end loop;
                                            when "dec" =>
                                                while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                        (buf(buf'low) /= ']')) loop
                                                    read(l => buf, value => char, good => booval);
                                                    m_address_int := m_address_int *10 +  INT_STR_TO_INT(char);
                                                end loop;
                                            when "uns" =>
                                                while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                        (buf(buf'low) /= ']')) loop
                                                    read(l => buf, value => char, good => booval);
                                                    m_address_int := m_address_int *10 +  INT_STR_TO_INT(char);
                                                end loop;
                                            when "oct" =>
                                                while ((buf(buf'low) /= ' ') and (buf(buf'low) /= HT) and
                                                        (buf(buf'low) /= ']')) loop
                                                    read(l => buf, value => char, good => booval);
                                                    m_address_int := m_address_int *8 + OCT_STR_TO_INT(char);
                                                end loop;
                                            when others =>
                                                assert false
                                                report "Unsupported address_radix!"
                                                severity error;
                                        end case;
        
                                        if (buf(buf'low) = ']') then
                                            get_end_address := false;
                                            m_end_address_int := m_address_int;
                                            SHRINK_LINE(buf, 1);    
                                        end if;
                                    end if;
                                        
                                    i := 0;
                                    -- ignore space or tab character.
                                    while ((i < buf'high-1) and ((buf(buf'low +i) = ' ') or
                                        (buf(buf'low+i) = HT))) loop
                                        i := i+1;
                                    end loop;
                                    
                                    if (i > 0) then
                                        SHRINK_LINE(buf, i);
                                    end if;                                
                                    
                                    if (buf(buf'low) = ':') then
                                        SHRINK_LINE(buf, 1);    
                                    end if;
                                    
                                    i := 0;
                                    -- ignore space or tab character.
                                    while ((i < buf'high-1) and ((buf(buf'low +i) = ' ') or
                                        (buf(buf'low+i) = HT))) loop
                                        i := i+1;
                                    end loop;
                                    
                                    if (i > 0) then
                                        SHRINK_LINE(buf, i);
                                    end if;
            
                                    case m_data_radix is
                                        when "hex" =>
                                            while ((buf(buf'low) /= ';') and (buf(buf'low) /= ' ') and
                                                    (buf(buf'low) /= HT)) loop
                                                read(l => buf, value => char, good => booval);
                                                m_data_int(lpm_width+4 downto 0) := m_data_int(lpm_width-1 downto 0) * "10000" + to_unsigned(HEX_STR_TO_INT(char), 4);
                                            end loop;
                                        when "bin" =>
                                            while ((buf(buf'low) /= ';') and (buf(buf'low) /= ' ') and
                                                    (buf(buf'low) /= HT)) loop
                                                read(l => buf, value => char, good => booval);
                                                m_data_int(lpm_width+1 downto 0) := m_data_int(lpm_width-1 downto 0) * "10" + to_unsigned(BIN_STR_TO_INT(char), 4);
                                            end loop;
                                        when "dec" =>
                                            while ((buf(buf'low) /= ';') and (buf(buf'low) /= ' ') and
                                                    (buf(buf'low) /= HT)) loop
                                                read(l => buf, value => char, good => booval);
                                                m_data_int(lpm_width+3 downto 0) := m_data_int(lpm_width-1 downto 0) * "1010" + to_unsigned(INT_STR_TO_INT(char), 4);
                                            end loop;
                                        when "uns" =>
                                            while ((buf(buf'low) /= ';') and (buf(buf'low) /= ' ') and
                                                    (buf(buf'low) /= HT)) loop
                                                read(l => buf, value => char, good => booval);
                                                m_data_int(lpm_width+3 downto 0) := m_data_int(lpm_width-1 downto 0) * "1010" + to_unsigned(INT_STR_TO_INT(char), 4);
                                            end loop;
                                        when "oct" =>
                                            while ((buf(buf'low) /= ';') and (buf(buf'low) /= ' ') and
                                                    (buf(buf'low) /= HT)) loop
                                                read(l => buf, value => char, good => booval);
                                                m_data_int(lpm_width+3 downto 0) := m_data_int(lpm_width-1 downto 0) * "1000" + to_unsigned(OCT_STR_TO_INT(char), 4);
                                            end loop;
                                        when others =>
                                            assert false
                                            report "Unsupported data_radix!"
                                            severity error;
                                        end case;                           
        
                                        if (m_start_address_int /= m_end_address_int) then
                                            for i in m_start_address_int to m_end_address_int loop
			                                    mem_data(i) := std_logic_vector(m_data_int(31 downto 0));
                                            end loop;
                                        else
		                                    mem_data(m_address_int) := std_logic_vector(m_data_int(31 downto 0));
                                        end if;
                                    exit LOOP2;
                                end if;                                
                            elsif ((buf(buf'low) = 'W') or (buf(buf'low) = 'w')) then
                                read(l=>buf, value=>m_string(1 to 5));
        
                                if (ALPHA_TOLOWER(m_string(1 to 5))  = "width") then
                                    i := 0;
        
                                    while ((buf(buf'low+i) = ' ') or (buf(buf'low+i) = HT)) loop
                                        i := i+1;
                                    end loop;
                                   
                                    if (buf(buf'low + i) = '=') then
                                        i := i+1;
                                    end if;
        
                                    while ((buf(buf'low +i) = ' ') or (buf(buf'low +i) = HT)) loop
                                        i := i+1;
                                    end loop;
                                                                   
                                    SHRINK_LINE(buf, i);
        
                                    i := 0;
                                    while (buf(buf'low + i) /= ';') loop
                                        i := i+1;
                                    end loop;
                                    
                                    read(l=>buf, value=>m_string(1 to i));
                                    
                                    m_width := INT_STR_TO_INT(m_string(1 to i));
                                end if;
                                exit LOOP2;
                            elsif (((buf(buf'low) = 'D') or (buf(buf'low) = 'd')) and
                                    ((buf(buf'low+1) = 'E') or (buf(buf'low+1) = 'e'))) then
                                read(l=>buf, value=>m_string(1 to 5));
        
                                if (ALPHA_TOLOWER(m_string(1 to 5))  = "depth") then
                                    i := 0;
        
                                    while ((buf(buf'low+i) = ' ') or (buf(buf'low+i) = HT)) loop
                                        i := i+1;
                                    end loop;
                                   
                                    if (buf(buf'low + i) = '=') then
                                        i := i+1;
                                    end if;
        
                                    while ((buf(buf'low +i) = ' ') or (buf(buf'low +i) = HT)) loop
                                        i := i+1;
                                    end loop;
                                                                   
                                    SHRINK_LINE(buf, i);
        
                                    i := 0;
                                    while (buf(buf'low + i) /= ';') loop
                                        i := i+1;
                                    end loop;
                                    
                                    read(l=>buf, value=>m_string(1 to i));
                                    
                                    m_depth := INT_STR_TO_INT(m_string(1 to i));
                                end if;
                                exit LOOP2;
                            elsif ((buf(buf'low) = 'D') or (buf(buf'low) = 'd')) then
                                read(l=>buf, value=>m_string(1 to 10));
        
                                if (ALPHA_TOLOWER(m_string(1 to 10))  = "data_radix") then
                                    i := 0;
        
                                    while ((buf(buf'low+i) = ' ') or (buf(buf'low+i) = HT)) loop
                                        i := i+1;
                                    end loop;
                                   
                                    if (buf(buf'low + i) = '=') then
                                        i := i+1;
                                    end if;
        
                                    while ((buf(buf'low+i) = ' ') or (buf(buf'low+i) = HT)) loop
                                        i := i+1;
                                    end loop;
                                                                   
                                    SHRINK_LINE(buf, i);
        
                                    i := 0;
                                    while (buf(buf'low + i) /= ';') loop
                                        i := i+1;
                                    end loop;
                                    
                                    read(l=>buf, value=>m_string(1 to 3));
                                    
                                    m_data_radix := ALPHA_TOLOWER(m_string(1 to 3));
                                end if;
                                exit LOOP2;
                            elsif ((buf(buf'low) = 'A') or (buf(buf'low) = 'a')) then
                                read(l=>buf, value=>m_string(1 to 13));
        
                                if (ALPHA_TOLOWER(m_string(1 to 13))  = "address_radix") then
                                    i := 0;
        
                                    while ((buf(buf'low+i) = ' ') or (buf(buf'low+i) = HT)) loop
                                        i := i+1;
                                    end loop;
                                   
                                    if (buf(buf'low + i) = '=') then
                                        i := i+1;
                                    end if;
        
                                    while ((buf(buf'low+i) = ' ') or (buf(buf'low+i) = HT)) loop
                                        i := i+1;
                                    end loop;
                                                                   
                                    SHRINK_LINE(buf, i);
        
                                    i := 0;
                                    while (buf(buf'low + i) /= ';') loop
                                        i := i+1;
                                    end loop;
                                    
                                    read(l=>buf, value=>m_string(1 to 3));
                                    
                                    m_address_radix := ALPHA_TOLOWER(m_string(1 to 3));
                                end if;
                                exit LOOP2;
                            elsif ((buf(buf'low) = 'C') or (buf(buf'low) = 'c')) then
                                read(l=>buf, value=>m_string(1 to 7));
                                
                                if (ALPHA_TOLOWER(m_string(1 to 7))  = "content") then
                                    found_keyword_content := true;
                                end if;
                            elsif ((buf(buf'low) = 'B') or (buf(buf'low) = 'b')) then
                                read(l=>buf, value=>m_string(1 to 5));
                                
                                if (ALPHA_TOLOWER(m_string(1 to 5))  = "begin") then
                                    if (found_keyword_content = true) then
                                        get_memory_content := true;
                                    end if;
                                end if;
                            end if;
                        end loop;
                    end loop;
                
                else
                    assert false
                    report "Unsupported memory initialization file type (" & fname(fname'length -3 to fname'length) & ")!"
                    severity error;
                end if;
                FILE_CLOSE(mem_data_file);
            end if;
            mem_init := TRUE;
        end if;
		
-- synopsys translate_on

		return mem_data;
    end hades_read_hex;
	
	---------------------------------------------------------------------------
	-- default program memory                                                --
	---------------------------------------------------------------------------
	function hades_bootloader return mem_init_t is
        -- default program (=bootloader)	
		constant prom_def : mem_init_t(0 to 4095) := (
			x"66810F7F",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",
			x"40000000",x"A7110053",x"04F10001",x"37710040",x"04F10004",x"37710062",x"08A50001",x"27710061",
			x"047F0001",x"668FFFFC",x"E0000000",x"98A10000",x"F0000000",x"A7110064",x"08B50000",x"0D750F80",
			x"560F0030",x"0E740000",x"560F002E",x"04F10003",x"37710040",x"66870006",x"A711005B",x"08EC4000",
			x"98A90000",x"08C90001",x"08370001",x"6681FFF9",x"04F10007",x"37710040",x"A7110053",x"0CF4C000",
			x"668F0025",x"04F1000F",x"37710040",x"E0000000",x"08E10000",x"08C10000",x"A711004B",x"08B50000",
			x"04F107FF",x"0D74E000",x"560F0020",x"0E740000",x"560F001E",x"04F1001F",x"37710040",x"66870006",
			x"A7110041",x"08EC4000",x"98A90000",x"08C90001",x"08370001",x"6681FFF9",x"04F1003F",x"37710040",
			x"A7110039",x"0CF4C000",x"668F0015",x"04F1007F",x"37710040",x"A7110017",x"08910000",x"10000000",
			x"6681F03F",x"04F10100",x"027F0010",x"04FF0100",x"37710040",x"6681FFFB",x"04F10200",x"027F0010",
			x"04FF0200",x"37710040",x"6681FFFB",x"04F10400",x"027F0010",x"04FF0400",x"37710040",x"6681FFFB",
			x"04F10800",x"027F0010",x"04FF0800",x"37710040",x"6681FFFB",x"40000000",x"08F30000",x"05900000",
			x"37010010",x"37110011",x"37010011",x"37010040",x"37110042",x"37010043",x"37110044",x"37010061",
			x"27010060",x"37010081",x"37010082",x"370100A0",x"04A1004B",x"0225000A",x"370100A2",x"08250001",
			x"5605FFFD",x"370100A0",x"089F0000",x"08A10000",x"08B10000",x"08C10000",x"08D10000",x"08E10000",
			x"08F10000",x"B3020000",x"27710061",x"047F0001",x"668FFFFD",x"27210060",x"B3020000",x"00000000",
			x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"00000000",x"6681FFFF",x"C0000000"
		);




  begin
		return prom_def;
	end hades_bootloader;
end hadescomponents;
