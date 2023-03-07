-------------------------------------------------------------------------------
-- xtoolbox package -----------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
package xtoolbox is
	
	-- types
	type regbank is array (natural range <>) of std_logic_vector(31 downto 0); 
	
	-- helper functions
	function log2(x: natural) return positive;
	function or_reduce(arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
	function xor_reduce(arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
	function and_reduce(arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
	function reverse_vector(a: in std_logic_vector) return std_logic_vector;
	function to_slv32(x: std_logic) return std_logic_vector;
	function to_slv32(x: std_logic_vector) return std_logic_vector;
	function to_slv32(x: unsigned) return std_logic_vector;
	function to_slv32(x: signed) return std_logic_vector;
	
end xtoolbox;

package body xtoolbox is
	
	-- returns max(ceil(log2(x)),1)
	function log2(x: natural) return positive is
		variable x_tmp: natural;
		variable y: positive;
	begin
		x_tmp := x-1;
		y := 1;
		while x_tmp > 1 loop
			y := y+1;
			x_tmp := x_tmp/2;
		end loop;
		return y;
	end;

	-- bit-reverse given std_logic_vector
	function reverse_vector(a: in std_logic_vector) return std_logic_vector is
		variable result: std_logic_vector(a'reverse_range);
	begin
		for i in a'range loop
			result(i) := a(i);
		end loop;
		return result;
	end;	
	
	-- to_slv32 (pack basic types into "std_logic_vector(31 downto 0)")
	function to_slv32(x: std_logic) return std_logic_vector is
		variable res : std_logic_vector(31 downto 0);
	begin
		res := (0=>x,others=>'0');
		return res;
	end to_slv32;
	function to_slv32(x: std_logic_vector) return std_logic_vector is
		variable res : std_logic_vector(31 downto 0);
	begin
		res := (others=>'0');
		res(x'length-1 downto 0) := x;
		return res;
	end to_slv32;
	function to_slv32(x: unsigned) return std_logic_vector is
	begin
		return to_slv32(std_logic_vector(x));
	end to_slv32;
	function to_slv32(x: signed) return std_logic_vector is
	begin
		return to_slv32(std_logic_vector(x));
	end to_slv32;

	-- done in a recursively called function.
	function and_reduce (arg : std_logic_vector )
	return std_logic is
		variable Upper, Lower : std_logic;
		variable Half : integer;
		variable BUS_int : std_logic_vector ( arg'length - 1 downto 0 );
		variable Result : std_logic;
	begin
		if (arg'LENGTH < 1) then            -- In the case of a NULL range
			Result := '1';                    -- Change for version 1.3
		else
			BUS_int := to_ux01 (arg);
			if ( BUS_int'length = 1 ) then
				Result := BUS_int ( BUS_int'left );
			elsif ( BUS_int'length = 2 ) then
				Result := BUS_int ( BUS_int'right ) and BUS_int ( BUS_int'left );
			else
				Half := ( BUS_int'length + 1 ) / 2 + BUS_int'right;
				Upper := and_reduce ( BUS_int ( BUS_int'left downto Half ));
				Lower := and_reduce ( BUS_int ( Half - 1 downto BUS_int'right ));
				Result := Upper and Lower;
			end if;
		end if;
		return Result;
	end;

	function or_reduce (arg : std_logic_vector )
		return std_logic is
		variable Upper, Lower : std_logic;
		variable Half : integer;
		variable BUS_int : std_logic_vector ( arg'length - 1 downto 0 );
		variable Result : std_logic;
	begin
		if (arg'LENGTH < 1) then            -- In the case of a NULL range
			Result := '0';
		else
			BUS_int := to_ux01 (arg);
			if ( BUS_int'length = 1 ) then
				Result := BUS_int ( BUS_int'left );
			elsif ( BUS_int'length = 2 ) then
				Result := BUS_int ( BUS_int'right ) or BUS_int ( BUS_int'left );
			else
				Half := ( BUS_int'length + 1 ) / 2 + BUS_int'right;
				Upper := or_reduce ( BUS_int ( BUS_int'left downto Half ));
				Lower := or_reduce ( BUS_int ( Half - 1 downto BUS_int'right ));
				Result := Upper or Lower;
			end if;
		end if;
		return Result;
	end; 
	
	function xor_reduce (arg : std_logic_vector )
		return std_logic is
		variable Upper, Lower : std_logic;
		variable Half : integer;
		variable BUS_int : std_logic_vector ( arg'length - 1 downto 0 );
		variable Result : std_logic;
	begin
		if (arg'LENGTH < 1) then            -- In the case of a NULL range
			Result := '0';
		else
			BUS_int := to_ux01 (arg);
			if ( BUS_int'length = 1 ) then
				Result := BUS_int ( BUS_int'left );
			elsif ( BUS_int'length = 2 ) then
				Result := BUS_int ( BUS_int'right ) xor BUS_int ( BUS_int'left );
			else
				Half := ( BUS_int'length + 1 ) / 2 + BUS_int'right;
				Upper := xor_reduce ( BUS_int ( BUS_int'left downto Half ));
				Lower := xor_reduce ( BUS_int ( Half - 1 downto BUS_int'right ));
				Result := Upper xor Lower;
			end if;
		end if;
		return Result;
	end;


end xtoolbox;


-------------------------------------------------------------------------------
-- sync_dualff (dual flip-flop synchronizer) ----------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;

entity sync_dualff is
	port(
		-- input
		i_data	: in  std_logic;
		
		-- output
		o_clk	: in  std_logic;
		o_data	: out std_logic
	);
end sync_dualff;

architecture rtl of sync_dualff is
	signal idat	: std_logic;
	signal sreg	: std_logic := '0';
	signal oreg	: std_logic := '0';
begin
	idat <= i_data;
	process(o_clk)
	begin
		if rising_edge(o_clk) then
			sreg <= idat;
			oreg <= sreg;
		end if;
	end process;
	o_data <= oreg;
end rtl;

-------------------------------------------------------------------------------
-- sync_feedback (feedback synchronizer) --------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;

entity sync_feedback is
	port(
		-- input
		i_clk	: in  std_logic;
		i_data	: in  std_logic;
		
		-- output
		o_clk	: in  std_logic;
		o_data	: out std_logic
	);
end sync_feedback;

architecture rtl of sync_feedback is

	signal req_i : std_logic := '0';
	signal req_s : std_logic := '0';
	signal req_o : std_logic := '0';
	signal ack_i : std_logic := '0';
	signal ack_s : std_logic := '0';
	signal ack_o : std_logic := '0';
	signal oreg  : std_logic := '0';

begin
	
	process(i_clk)
	begin
		if rising_edge(i_clk) then
			-- create request-flag
			if i_data='1' then
				req_i <= '1';
			elsif ack_i='1' then
				req_i <= '0';
			end if;
			
			-- synchronize ack-flag
			ack_s <= ack_o;
			ack_i <= ack_s;
		end if;
	end process;
	
	process(o_clk)
	begin
		if rising_edge(o_clk) then
			-- synchronize request-flag
			req_s <= req_i;
			req_o <= req_s;
			
			-- create ack-flag
			if req_o='1' then
				ack_o <= '1';
			elsif req_o='0' then
				ack_o <= '0';
			end if;
		end if;
	end process;
	
	-- create output
	oreg <= req_o and not ack_o; 
	
	-- set output 
	o_data <= oreg;	
end rtl;


-------------------------------------------------------------------------------
-- reset_gen ------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;

entity reset_gen is
	port (
		clk 		: in  std_logic;					-- some direct clock-input
		dcm_locked	: in  std_logic_vector(3 downto 0);	-- DCMs locked?
		reset_dcm	: out std_logic;					-- reset signal for DCMs
		reset_sys	: out std_logic						-- global reset signal
	);
end reset_gen;

architecture rtl of reset_gen is

	-- reset generation
	signal rst_roc 		: std_logic := '1'; 			-- reset-on-configuratiobn signal
	signal rst_roc2dcm	: std_logic_vector(5 downto 0);	-- delay between rst_roc <-> rst_dcm
	signal rst_dcm2go	: std_logic_vector(5 downto 0); -- delay between rst_roc <-> reset_I
	signal reset_dcm_i	: std_logic;					-- inner version of 'reset_dcm'
	signal reset_sys_i	: std_logic;					-- inner version of 'reset_sys'
	
begin

	-- generate reset-on-configuration signal
	rst_roc <= '0';

	-- generate DCM-reset
	process(clk, rst_roc)
	begin
		if rst_roc = '1' then
			reset_dcm_i <= '1';
			rst_roc2dcm	<= (others=>'1');
		elsif rising_edge(clk) then
			rst_roc2dcm <= '0' & rst_roc2dcm(rst_roc2dcm'high downto 1);
			reset_dcm_i <= rst_roc2dcm(0);
		end if;
	end process;
	
	-- generate system-reset
	process(clk, reset_dcm_i)
	begin
		if reset_dcm_i = '1' then
			reset_sys_i <= '1';
			rst_dcm2go  <= (others=>'1');
		elsif rising_edge(clk) then
			if dcm_locked/="1111" then
				rst_dcm2go  <= (others=>'1');
				reset_sys_i <= '1';
			else
				rst_dcm2go  <= '0' & rst_dcm2go(rst_dcm2go'high downto 1);
				reset_sys_i <= rst_dcm2go(0);
			end if;
		end if;
	end process;
		
	-- output reset-signal
	reset_sys <= reset_sys_i;
		
	-- output DCM-reset
	reset_dcm <= reset_dcm_i;
	
end;


-------------------------------------------------------------------------------
-- reset_sync -----------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;

entity reset_sync is
	port (
		clk 	: in  std_logic;
		rst_in	: in  std_logic;
		rst_out	: out std_logic
	);
end reset_sync;

architecture rtl of reset_sync is
	signal taps : std_logic_vector(3 downto 0);
begin
	process(clk, rst_in)
	begin
		if rst_in='1' then
			taps    <= (others=>'1');
			rst_out <= '1';
		elsif rising_edge(clk) then
			taps    <= "0" & taps(taps'high downto 1);
			rst_out <= taps(0);
		end if;
	end process;
end;

-------------------------------------------------------------------------------
-- arbiter_prio_async ---------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;

entity arbiter_prio_async is
	generic (
		SIZE : natural											-- number of requestors
	);
	port(
		-- input
		req			: in  std_logic_vector(SIZE-1 downto 0);	-- request-lines
		
		-- output
		grant		: out std_logic_vector(SIZE-1 downto 0);	-- grant-lines
		nogrant		: out std_logic;							-- high when grant-lines are all zero
		
		-- special output
		hpri_mask	: out std_logic_vector(SIZE-1 downto 0)		-- #i: any req(x) set for x<i
	);
end arbiter_prio_async;

architecture rtl of arbiter_prio_async is
begin
	process(req)
		variable granted : std_logic;
	begin
		granted := '0';
		for i in 0 to SIZE-1 loop
			hpri_mask(i) <= granted;
			grant(i)     <= req(i) and not granted;
			granted      := req(i) or granted;
		end loop;
		nogrant <= not granted; 
	end process;
end rtl;


-------------------------------------------------------------------------------
-- arbiter_roundrobin ---------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity arbiter_roundrobin is
	generic (
		SIZE : natural := 4									-- number of requestors
	);
	port(
		-- common
		clk 	: in  std_logic;							-- system clock
		reset 	: in  std_logic;							-- reset signal
		
		-- special control
		norr	: in  std_logic := '0';						-- use priority-arbiter (disable round-robin)
		
		-- input
		req		: in  std_logic_vector(SIZE-1 downto 0);	-- request-lines
		ack		: in  std_logic;							-- ack-line (-> advance counter)
		
		-- output
		grant	: out std_logic_vector(SIZE-1 downto 0);	-- grant-lines
		nogrant	: out std_logic								-- high when grant-lines are all zero
	);
end arbiter_roundrobin;

architecture rtl of arbiter_roundrobin is

	-- control signals
	signal mask  			: std_logic_vector(SIZE-1 downto 0);
	signal nmask  			: std_logic_vector(SIZE-1 downto 0);
	
	-- ports of nomask-arbiter
	signal req_nomask		: std_logic_vector(SIZE-1 downto 0);
	signal grant_nomask		: std_logic_vector(SIZE-1 downto 0);
	signal nogrant_nomask	: std_logic;
	signal hpri_nomask		: std_logic_vector(SIZE-1 downto 0);
	
	-- ports of masked-arbiter
	signal req_masked		: std_logic_vector(SIZE-1 downto 0);
	signal grant_masked		: std_logic_vector(SIZE-1 downto 0);
	signal nogrant_masked	: std_logic;
	signal hpri_masked		: std_logic_vector(SIZE-1 downto 0);
		
begin
	
	-- update mask
	process(clk, reset)
	begin
		if reset = '1' then
			nmask <= (others=>'0');
			mask  <= (others=>'0');
		elsif rising_edge(clk) then
			-- get new mask
			if nogrant_masked='0' then 
				nmask <= hpri_masked;
			elsif nogrant_nomask='0' then 
				nmask <= hpri_nomask;
			else
				nmask <= mask;
			end if;
			
			-- save last mask if ACK-flag is set
			if ack='1' then
				mask <= nmask;
			end if;
		end if;
	end process;
	
	-- create arbiter inputs
	req_nomask <= req;
	req_masked <= req and mask;
	
	-- create output
	nogrant <= nogrant_nomask;
	grant   <= grant_nomask when (nogrant_masked='1' or norr='1') else
			   grant_masked;
	
	-- nomask-arbiter
	i_arbiter_nomask : entity work.arbiter_prio_async
		generic map (
			SIZE => SIZE
		)
		port map (
			req       => req_nomask,
			grant     => grant_nomask,
			nogrant   => nogrant_nomask,
			hpri_mask => hpri_nomask
		);
		
	-- masked-arbiter
	i_arbiter_masked : entity work.arbiter_prio_async
		generic map (
			SIZE => SIZE
		)
		port map (
			req       => req_masked,
			grant     => grant_masked,
			nogrant   => nogrant_masked,
			hpri_mask => hpri_masked
		);
end rtl;

-------------------------------------------------------------------------------
-- basic_fifo -----------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.xtoolbox.all;
	
entity basic_fifo is
	generic (
		STYLE     : string := "area";	-- ram style
		DWIDTH    : natural;			-- datawidth of entries
		DEPTH     : natural;			-- size of fifo
		FLEN      : natural 			-- log2(DEPTH+1)
	);
	port(
		-- common
		clk 		: in  std_logic;							-- system clock
		reset 		: in  std_logic;							-- reset signal
		
		-- status
		filled		: out unsigned(FLEN-1 downto 0);			-- number of entries in fifo
		full		: out std_logic;							-- fifo is full?
		empty		: out std_logic;							-- fifo is empty?
		
		-- control
		clear		: in  std_logic := '0';						-- reset fifo
		
		-- input
		in_we		: in  std_logic;							-- write enable
		in_data 	: in  std_logic_vector(DWIDTH-1 downto 0);	-- input data
		
		-- output
		out_re		: in  std_logic;							-- read enable
		out_data 	: out std_logic_vector(DWIDTH-1 downto 0);	-- output data
		out_valid 	: out std_logic								-- output data is valid?
	);
end basic_fifo;

architecture rtl of basic_fifo is

	-- calc constants
	constant ALEN : natural := log2(DEPTH);

	-- status
	signal filled_i			: unsigned(FLEN-1 downto 0);
	signal empty_i			: std_logic;
	signal full_i			: std_logic;
	
	-- RAM ports
	signal ram_raddr		: unsigned(ALEN-1 downto 0) := (others=>'0');
	signal ram_raddr_next	: unsigned(ALEN-1 downto 0);
	signal ram_raddr_reg	: unsigned(ALEN-1 downto 0);
	signal ram_waddr		: unsigned(ALEN-1 downto 0);
	signal ram_rdata		: std_logic_vector(DWIDTH-1 downto 0);
	signal ram_wdata		: std_logic_vector(DWIDTH-1 downto 0);
	signal ram_ren			: std_logic;
	signal ram_wen			: std_logic;
	
	-- create memory
	type mem_type is array (DEPTH-1 downto 0) of std_logic_vector(DWIDTH-1 downto 0);
	signal mem : mem_type := (others=>(others=>'0'));
	
	-- configure memory
	attribute syn_ramstyle : string;
	attribute syn_ramstyle of mem : signal is STYLE;
	
begin

	-- manage fifo pointers & filled counter
	process(clk, reset)
	begin
		if reset = '1' then
			ram_raddr <= (others=>'0');
			ram_waddr <= (others=>'0');
			filled_i  <= (others=>'0');
			empty_i   <= '1';
			full_i    <= '0';
		elsif rising_edge(clk) then
			if clear='1' then
				ram_raddr <= (others=>'0');
				ram_waddr <= (others=>'0');
				filled_i  <= (others=>'0');
				empty_i   <= '1';
				full_i    <= '0';
			else
				-- update filled-status
				if ram_ren='1' and ram_wen='0' then
					-- update counter
					filled_i <= filled_i-1;
					
					-- update flags
					full_i <= '0';
					if filled_i=1 
						then empty_i <= '1';
						else empty_i <= '0';
					end if;
				elsif ram_ren='0' and ram_wen='1' then
					-- update counter
					filled_i <= filled_i+1;
					
					-- update flags
					empty_i <= '0';
					if filled_i=(DEPTH-1)
						then full_i <= '1';
						else full_i <= '0';
					end if;
				end if;
				
				-- update read pointer
				ram_raddr <= ram_raddr_next;
				
				-- update write pointer
				if ram_wen='1' then
					if ram_waddr=(DEPTH-1)
						then ram_waddr <= to_unsigned(0, ram_waddr'length);
						else ram_waddr <= ram_waddr+1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- get next read address
	ram_raddr_next <= ram_raddr   	when ram_ren='0' else
					  ram_raddr+1 	when ram_raddr/=(DEPTH-1) else
					  to_unsigned(0, ALEN);
	
	-- connect ram-ports
	ram_wdata <= in_data;
	ram_wen	  <= in_we and not full_i;
	ram_ren	  <= out_re and not empty_i;
	
	-- connect output
	out_data  <= ram_rdata;
	out_valid <= not empty_i;
	filled    <= filled_i;
	full      <= full_i;
	empty     <= empty_i;
	
	-- dualport ram
	process(reset, clk)
	begin
		if reset='0' and rising_edge(clk) then
			-- handle read
			ram_raddr_reg <= ram_raddr_next;
			
			-- handle write
			if ram_wen='1' then
				mem(to_integer(ram_waddr)) <= ram_wdata;
			end if;
		end if;
	end process;
	ram_rdata <= mem(to_integer(ram_raddr_reg));
	
end rtl;