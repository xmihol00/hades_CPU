---------------------------------------------------------------------------------------------------
--
-- Titel: Control Unit (using Moore FSM)
-- Autor: David Mihola (12211951)
-- Datum: 11. 03. 2023   
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.hadescomponents.all;
	
entity control is
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- control inputs
		inop		: in  std_logic;
		outop		: in  std_logic;
		loadop		: in  std_logic;
		storeop		: in  std_logic;
		dpma		: in  std_logic;
		epma		: in  std_logic;
		xack		: in  std_logic;
		xpresent	: in  std_logic;
		dmembusy	: in  std_logic;
		
		-- control outputs
		loadir		: out std_logic;
		regwrite	: out std_logic;
		pcwrite		: out std_logic;
		pwrite		: out std_logic;
		xread		: out std_logic;
		xwrite		: out std_logic;
		xnaintr		: out std_logic
	);
end control;

architecture rtl of control is
	type State_t is (IFETCH, IDECODE, ALU, IOREAD, IOWRITE, XBUSNAINTR, MEMREAD, MEMWRITE_PMA, MEMWRITE_DMA, WRITEBACK);
	signal moore_current_state : State_t := IFETCH;
	signal moore_next_state : State_t := IFETCH;
	signal epma_set : std_logic; -- remember if program or data memory is written
begin
	-- EPMA/DPMA logic
	process (clk, reset) is
	begin
		if reset = '1' then
			epma_set <= '1';
		elsif rising_edge(clk) then
			if dpma = '1' then
				epma_set <= '0';
			elsif epma = '1' then
				epma_set <= '1';
			end if;
		end if;
	end process;
	
	-- current state logic
	process (clk, reset) is
    begin
	    if (reset = '1') then
		    moore_current_state <= IFETCH;
	    elsif rising_edge(clk) then
		    moore_current_state <= moore_next_state;
	    end if;
    end process;
	
	-- Moore FSM next state logic
	process (moore_current_state, inop, outop, loadop, storeop, dpma, epma, xack, xpresent, dmembusy, epma_set) is
	begin
		case moore_current_state is
			when IFETCH =>
				moore_next_state <= IDECODE;

			when IDECODE =>
				moore_next_state <= ALU;

			when ALU =>
				moore_next_state <= WRITEBACK;
				if inop = '1' then
					moore_next_state <= IOREAD;
				elsif outop = '1' then
					moore_next_state <= IOWRITE;
				elsif loadop = '1' then
					moore_next_state <= MEMREAD;
				elsif storeop = '1' then
					if epma_set = '1' then
						moore_next_state <= MEMWRITE_PMA;
					else
						moore_next_state <= MEMWRITE_DMA;
					end if;
				end if;

			when IOREAD =>
				moore_next_state <= IOREAD;
				if xpresent = '0' then
					moore_next_state <= XBUSNAINTR;
				elsif xack = '1' then
					moore_next_state <= WRITEBACK;
				end if;
				
			when IOWRITE =>
				moore_next_state <= IOWRITE;
				if xpresent = '0' then
					moore_next_state <= XBUSNAINTR;
				elsif xack = '1' then
					moore_next_state <= WRITEBACK;
				end if;

			when XBUSNAINTR =>
				moore_next_state <= IFETCH;

			when MEMREAD =>
				moore_next_state <= MEMREAD;
				if dmembusy = '0' then
					moore_next_state <= WRITEBACK;
				end if;
							
			when MEMWRITE_PMA =>				
				moore_next_state <= WRITEBACK;
			
			when MEMWRITE_DMA =>
				moore_next_state <= MEMWRITE_DMA;
				if dmembusy = '0' then
					moore_next_state <= WRITEBACK;
				end if;

			when WRITEBACK =>
				moore_next_state <= IFETCH;

			when others =>
				moore_next_state <= IFETCH;
		end case;
	end process;
	
	-- Moore FSM output logic
	process (moore_current_state) is
	begin
		-- default values of the control signals
		loadir <= '0';
		regwrite <= '0';
		pcwrite <= '0';
		pwrite <= '0';
		xread <= '0';
		xwrite <= '0';
		xnaintr <= '0';

		case moore_current_state is
			when IFETCH =>
				loadir <= '1';

			when IOREAD =>
				xread <= '1';
				
			when IOWRITE =>
				xwrite <= '1';

			when XBUSNAINTR =>
				xnaintr <= '1';
				pcwrite <= '1';

			when MEMREAD =>
				xread <= '1';
			
			when MEMWRITE_PMA =>
				pwrite <= '1';
			
			when MEMWRITE_DMA =>
				xwrite <= '1';

			when WRITEBACK =>
				pcwrite <= '1';
				regwrite <= '1';

			when others =>
				NULL;
		end case;
	end process;
end rtl;
