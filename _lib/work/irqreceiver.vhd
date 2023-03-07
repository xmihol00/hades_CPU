---------------------------------------------------------------------------------------------------
--
-- Title       : irqreceiver
-- Design      : hades4cpu
-- Author      : Holger Englert
-- Company     : Universität Würzburg / Lehrstuhl für Informatik V
--
---------------------------------------------------------------------------------------------------
--
-- File        : irqreceiver.vhd
-- Generated   : Tue Jul 23 12:00:21 2002
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.20
--
---------------------------------------------------------------------------------------------------
--
-- Description : Receives asynchronous IRQ-Signal and stores until served
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity irqreceiver is
	 port(
		 CLK : in std_logic;
		 RESET : in std_logic;
		 IACK : in std_logic;
		 ISIGNAL : in std_logic;
		 Q : out std_logic
	     );
end irqreceiver;


architecture fsm of irqreceiver is

type state_type is (READY,TRIGGERED, WAITING, SERVED);

signal state: state_type;

begin
  process (CLK, RESET)
  begin
	if RESET = '1' then state <= READY;
	elsif (CLK'event AND CLK = '1') then
    
	  case state is
		when READY =>
      if ISIGNAL ='1' then
        if IACK='0' then 
          state <= TRIGGERED;
		else
		   state <= SERVED;
        end if;			   
	  else
		if IACK='1' then
		  state <= SERVED;
		end if;
      end if;
		when TRIGGERED =>
      if  ISIGNAL = '0' then
        if IACK = '1' then
			    state <= READY;
        else
          state <= WAITING;
        end if;
			else 
        if IACK = '1' then
				  state <= SERVED;
        end if;
		  end if;
		when WAITING =>
		  if ISIGNAL = '1' then
			  state <= TRIGGERED;
		  else
			  if IACK = '1' then
				  state <= READY;
			  end if;
			end if;
		when SERVED =>
		  if ISIGNAL = '0' then
			  state <= READY;
			end if;
	  end case;
	end if;
  end process;
  
  -- Output Control for State Machine
  Q <= '1' when (state = TRIGGERED or state = WAITING) else '0';
  
end fsm;
