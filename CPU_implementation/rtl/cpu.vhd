---------------------------------------------------------------------------------------------------
--
-- Titel: Control Processing Unit
-- Autor: David Mihola (12211951)
-- Datum: 28. 03. 2023    
--
---------------------------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
library work;
	use work.all;
	use work.hadescomponents.all;
	
entity cpu is
	generic (
		INIT		: string := "UNUSED"
	);
	port (
		-- common
		clk 		: in  std_logic;
		reset		: in  std_logic;
		
		-- XBus
		xread		: out std_logic;
		xwrite		: out std_logic;
		xadr		: out std_logic_vector(12 downto 0);
		xdatain		: in  std_logic_vector(31 downto 0);
		xdataout	: out std_logic_vector(31 downto 0);
		xpresent	: in  std_logic;
		xack		: in  std_logic;
		dmemop		: out std_logic;
		dmembusy	: in  std_logic;
		xperintr	: in  std_logic;
		xmemintr	: in  std_logic
	);
end cpu;

architecture rtl of cpu is
	signal inner_dataout_iword     : std_logic_vector(31 downto 0) := (others => '0');
	signal inner_pwrite            : std_logic := '0';
	signal inner_datain_bop        : std_logic_vector(31 downto 0) := (others => '0');
	signal inner_loadir            : std_logic := '0';
	signal inner_radr_pcakt        : std_logic_vector(11 downto 0) := (others => '0');
	signal inner_wadr_xaddr        : std_logic_vector(12 downto 0) := (others => '0');
	signal inner_aopaddr           : std_logic_vector(2 downto 0)  := (others => '0');
	signal inner_bopaddr           : std_logic_vector(2 downto 0)  := (others => '0');
	signal inner_wopaddr           : std_logic_vector(2 downto 0)  := (others => '0');
	signal inner_ivalid            : std_logic := '0';
	signal inner_iop 			   : std_logic_vector(15 downto 0) := (others => '0');
	signal inner_opc               : std_logic_vector(4 downto 0)  := (others => '0');
	signal inner_pccontr		   : std_logic_vector(10 downto 0) := (others => '0');
	signal inner_inop              : std_logic := '0';
	signal inner_outop             : std_logic := '0';
	signal inner_loadop            : std_logic := '0';
	signal inner_storeop           : std_logic := '0';
	signal inner_selxres           : std_logic := '0';
	signal inner_dpma              : std_logic := '0';
	signal inner_epma              : std_logic := '0';
	signal inner_aop			   : std_logic_vector(31 downto 0) := (others => '0');
	signal inner_wop			   : std_logic_vector(31 downto 0) := (others => '0');
	signal inner_regwrite          : std_logic := '0';
	signal inner_pcwrite           : std_logic := '0';
	signal inner_xnaintr           : std_logic := '0';
	signal inner_ov                : std_logic := '0';
	signal inner_zero              : std_logic := '0';
	signal inner_pcnew             : std_logic_vector(11 downto 0) := (others => '0');
	signal inner_sisalvl           : std_logic_vector(1 downto 0)  := (others => '0');
	signal inner_pcinc             : std_logic_vector(11 downto 0) := (others => '0');
begin
	PMEMORY: entity work.pmemory
	generic map (
		INIT => INIT
	)
	port map (
		clk    => clk,
		reset  => reset,
		
		pwrite => inner_pwrite,	
		wadr   => inner_wadr_xaddr(11 downto 0),
		datain => inner_datain_bop,	
	
		loadir	=> inner_loadir,
		radr	=> inner_radr_pcakt,
		dataout	=> inner_dataout_iword
	);

	INDEC: entity work.indec
	port map (
		iword => inner_dataout_iword,

        aopadr => inner_aopaddr,
        bopadr => inner_bopaddr,
        wopadr => inner_wopaddr, 
        
        ivalid => inner_ivalid,
        iop    => inner_iop,
        
        opc      => inner_opc,
        pccontr  => inner_pccontr,
        inop     => inner_inop,
        outop    => inner_outop,
        loadop   => inner_loadop,
        storeop  => inner_storeop,
        dmemop   => dmemop,
        selxres  => inner_selxres,
        dpma     => inner_dpma,
        epma     => inner_epma
	);

	HAREGS: entity work.haregs
	port map (
		clk   => clk,
		reset => reset,

		regwrite => inner_regwrite,
		wopadr   => inner_wopaddr,
		wop      => inner_wop,
		aopadr   => inner_aopaddr,
		bopadr   => inner_bopaddr,

		aop      => inner_aop,
		bop      => inner_datain_bop
	);

	CONTROL: entity work.control
	port map (
		clk   => clk,
		reset => reset,

		inop     => inner_inop,
		outop    => inner_outop,
		loadop   => inner_loadop,
		storeop  => inner_storeop,
		dpma     => inner_dpma,
		epma     => inner_epma,
		xack     => xack,
		xpresent => xpresent,
		dmembusy => dmembusy,

		loadir   => inner_loadir,
		regwrite => inner_regwrite,
		pcwrite  => inner_pcwrite,
		pwrite   => inner_pwrite,
		xread    => xread,
		xwrite   => xwrite,
		xnaintr  => inner_xnaintr
	);

	PCBLOCK: entity work.pcblock
	port map (
		clk   => clk,
		reset => reset,

		xperintr => xperintr,
		xnaintr  => inner_xnaintr,
		xmemintr => xmemintr,
		ov       => inner_ov,
		zero     => inner_zero,
		pcwrite  => inner_pcwrite,
		pccontr  => inner_pccontr,
		pcnew    => inner_pcnew,
		sisalvl  => inner_sisalvl,

		pcakt => inner_radr_pcakt,
		pcinc => inner_pcinc
	);

	DATAPATH: entity work.datapath
	port map (
		clk   => clk,
		reset => reset,
		
		opc      => inner_opc,
		regwrite => inner_regwrite,		
		aop      => inner_aop,
		bop      => inner_datain_bop,
		iop      => inner_iop,
		ivalid   => inner_ivalid,
		selxres  => inner_selxres,
		xdatain  => xdatain,
		jal      => inner_pccontr(8),
		rela     => inner_pccontr(10),
		pcinc    => inner_pcinc,
		
		ov       => inner_ov,
		zero     => inner_zero,
		pcnew    => inner_pcnew,
		sisalvl  => inner_sisalvl,
		xdataout => xdataout,
		xadr     => inner_wadr_xaddr,
		wop      => inner_wop
	);

	xadr <= inner_wadr_xaddr;
end rtl;
