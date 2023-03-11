---------------------------------------------------------------------------------------------------
--
-- Titel: Control Unit (using Mealy FSM)  
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
	type State_t is (IFETCH, IDECODE, ALU, IOREAD, IOWRITE, XBUSNAINTR, MEMREAD, MEMWRITE, WRITEBACK);
	signal mealy_current_state : State_t := IFETCH;
	signal mealy_next_state : State_t := IFETCH;
begin
	
	process (clk, reset) is -- change of current state of the Mealy FSM
    begin
	    if (reset = '1') then
		    mealy_current_state <= IFETCH;
	    elsif rising_edge(clk) then
		    mealy_current_state <= mealy_next_state;
	    end if;
    end process;

	process (mealy_current_state, inop, outop, loadop, storeop, dpma, epma, xack, xpresent, dmembusy) is -- Mealy FSM logic
	begin
		-- default values of the control signals
		loadir <= '0';
		regwrite <= '0';
		pcwrite <= '0';
		pwrite <= '0';
		xread <= '0';
		xwrite <= '0';
		xnaintr <= '0';

		-- next state and output logic
		case mealy_current_state is
			when IFETCH =>
				mealy_next_state <= IDECODE;
				loadir <= '1';

			when IDECODE =>
				mealy_next_state <= ALU;

			when ALU =>
				mealy_next_state <= WRITEBACK;
				if inop = '1' then
					mealy_next_state <= IOREAD;
				elsif outop = '1' then
					mealy_next_state <= IOWRITE;
				elsif loadop = '1' then
					mealy_next_state <= MEMREAD;
				elsif storeop = '1' then
					mealy_next_state <= MEMWRITE;
				end if;

			when IOREAD =>
				mealy_next_state <= IOREAD;
				xread <= '1';
				if xpresent = '0' then
					mealy_next_state <= XBUSNAINTR;
				elsif xack = '1' then
					mealy_next_state <= WRITEBACK;
				end if;
				
			when IOWRITE =>
				mealy_next_state <= IOWRITE;
				xwrite <= '1';
				if xpresent = '0' then
					mealy_next_state <= XBUSNAINTR;
				elsif xack = '1' then
					mealy_next_state <= WRITEBACK;
				end if;

			when XBUSNAINTR =>
				mealy_next_state <= IFETCH;
				xnaintr <= '1';
				pcwrite <= '1';

			when MEMREAD =>
				mealy_next_state <= MEMREAD;
				xread <= '1';
				if dmembusy = '0' then
					mealy_next_state <= WRITEBACK;
				end if;

			when MEMWRITE =>
				if epma = '1' then
					pwrite <= '1';
					mealy_next_state <= WRITEBACK;
				else
					xwrite <= '1';
				end if;
				
				if dmembusy = '0' then
					mealy_next_state <= WRITEBACK;
				elsif epma = '0' then
					mealy_next_state <= MEMWRITE;
				end if;

			when WRITEBACK =>
				mealy_next_state <= IFETCH;
				pcwrite <= '1';
				regwrite <= '1';

			when others =>
				mealy_next_state <= IFETCH;
		end case;
	end process;
end rtl;
