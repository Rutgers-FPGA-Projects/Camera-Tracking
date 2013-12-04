-- Camera Tracking

-- Goal:


-- Change Log:

-- Import the definitions for standard logic
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CameraTracking is 
	port(	VGA_R,VGA_G,VGA_B: out STD_logic_vector(7 downto 0);
			VGA_CLK,VGA_BLANK_N,VGA_HS,VGA_VS,VGA_SYNC_N: out STD_logic;
			SW: in STD_logic_vector(17 downto 0);
			CLOCK_50: in STD_logic;
			EXT_IO: out STD_lOGIC_VECTOR(6 downto 0);  -- this is how the pin mapping labels the external IOs
			LEDG: out STD_logic_vector(7 downto 0);
			KEY: in STD_logic_vector(3 downto 0);
			GPIO: out STD_logic_vector(4 downto 0);
			IRDA_RXD: in std_logic;
			HEX0, HEX1, HEX2, HEX3, HEX4, HEX5: OUT STD_LOGIC_VECTOR(0 TO 6));
end;

architecture behavior of CameraTracking is 

	-- used for the PLL
	component 
		clock1 PORT(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			c1		: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC);
	end component;	
	
	component TwoPortRam IS
	PORT(data		: IN STD_LOGIC_VECTOR (23 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (18 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (18 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (23 DOWNTO 0));
	END component;
		
	component servo is 
		port(clk: in STD_LOGIC;
			Angle: in integer := 100;   -- 1.5 ms
			servo_ctr: out STD_LOGIC
		);
	end component;
	
	component ir_receiver is 
		port ( 
			iIRDA: in std_logic;
			reset: in std_logic;
			clk_50: in std_logic;
			--Display the information about CUSTOM CODE bits __HEX7-HEX4
			--and KEY CODE bits __HEX3-HEX0
			oData: out std_logic_vector(31 downto 0)
			);
	end component;
	
	component hexDisplay is 
                port (S: in std_logic_vector(3 downto 0);  -- S is an intermediate signal (NOT A PHYSICAL INPUT)
                      H: out std_logic_vector(0 to 6));           -- Storage signal for result
	end component; 
	
	component
		vga_driver port(
			VertAddress,HorAddress: out STD_logic_vector(11 downto 0);
			DataValid: out STD_logic;
			VGA_CLK: out STD_logic;				-- used by VGA DAC
			VGA_BLANK_N: out STD_logic;		-- Sent to VGA DAC to indicate blanking
			VGA_HS: 	out STD_logic;				-- The Horizontial Syc  
			VGA_VS: 	out STD_logic;				-- Vertical Syc
			VGA_SYNC_N: out STD_logic;			
			CLOCK_IN: in STD_logic);			-- The clock used by the VGA driver; This must be the correct frequency for the resolution
	end component;

	-- used for PLL
	signal clock_106MHz: STD_logic; 
	signal clock_50MHz: STD_LOGIC;
	signal clock_25MHz: STD_LOGIC;
	
	signal locked: STD_logic;
	signal rst: STD_LOGIC := '0';
	
	
	-- used for the IR reciever and HEX displays
	signal display5, display4, display3, display2, display1, display0: std_logic_vector(0 to 6);
	signal iData: std_logic_vector(31 downto 0); 
	
	signal DataValid: STD_LOGIC;
	signal VGA_HorAddress,VGA_VertAddress: STD_LOGIC_VECTOR(11 downto 0);
	
	
	signal VGAMemReadAddress: STD_logic_vector(18 downto 0);
	signal VGAMemWriteAddress: STD_logic_vector(18 downto 0);
	signal VGAMemReadData: STD_logic_vector(23 downto 0);
	signal VGAMemWriteData: STD_logic_vector(23 downto 0);

begin
	
	-- implement the clock PLL to create a 106 MHz clock
	clock1_inst : clock1 PORT MAP(
		areset	 => rst,  -- active high to Reset PLL
		inclk0	 => CLOCK_50,
		c0	 => clock_50MHz,
		c1	 => clock_106MHz,
		locked	 => locked
	);
	
	
	process (clock_50MHz)
	begin
		if(rising_edge(clock_50MHz)) then
			clock_25MHz <= not clock_25MHz;
		end if;
	end process;
	
	LEDG(0) <= rst; --clock debuging 
	LEDG(1) <= locked;
	
	-- pan servo
	Servo_0 : servo port map (
		clk => clock_50MHz,
		Angle => 100,
		servo_ctr => EXT_IO(0)
	);
	
	-- vertical servo
	Servo_1 : servo port map (
		clk => clock_50MHz,
		Angle => 100,
		servo_ctr => EXT_IO(1)
	);
	
	
	vga_inst: vga_driver port map(
		VertAddress => VGA_VertAddress,
		HorAddress => VGA_HorAddress,
		DataValid => DataValid,
		VGA_CLK => VGA_CLK,
		VGA_BLANK_N => VGA_BLANK_N,
		VGA_HS => VGA_HS,
		VGA_VS => VGA_VS,
		VGA_SYNC_N => VGA_SYNC_N,
		CLOCK_IN => clock_25MHz
		);
	
	
	
	
	TwoPortRam_inst : TwoPortRam PORT MAP (
		data	 => VGAMemReadData,
		rdaddress	 => VGAMemReadAddress,
		rdclock	 => clock_25MHz,
		wraddress	 => VGAMemWriteAddress,
		wrclock	 => clock_25MHz,
		wren	 => '1',
		q	 => VGAMemWriteData
	);

	process (VGA_VertAddress,VGA_HorAddress)
	begin
		VGAMemWriteAddress <= "000000" & VGA_HorAddress & '1';
		--std_logic_vector(to_unsigned(unsigned(VGA_HorAddress) + 640 * unsigned(VGA_VertAddress),19)); 
		VGAMemWriteData <= "00000000" & VGA_HorAddress(7 downto 0) & VGA_VertAddress(7 downto 0);
		
	end process;
	
	process (VGA_VertAddress,VGA_HorAddress)
	begin
		VGAMemReadAddress <= "0000000" & VGA_HorAddress;
		VGA_R <= VGAMemReadData(23 downto 16); -- conect the data read from the	two port mem to the correct color 
		VGA_G <= VGAMemReadData(15 downto 8);
		VGA_B <= VGAMemReadData(7 downto 0);
		/*if(VGA_VertAddress > X"0F0") then   -- 0x10
			VGA_G <= B"11110000";
			VGA_B <= B"00001111";
		else
			VGA_B <= B"11110000";
			VGA_G <= B"00001111";
		end if;
		if(VGA_HorAddress > X"140") then  -- 0x18
			VGA_R <= B"11000000";
		else	
			VGA_R <= B"00000000";
		end if;
		*/
	end process;
	
	-- Hook up the IR conections 
	I_r: ir_receiver port map(IRDA_RXD,KEY(0),CLOCK_50,iData);
	
	h0: hexDisplay port map (VGA_VertAddress(3 downto 0), display0);
	h1: hexDisplay port map (VGA_VertAddress(7 downto 4), display1);
	h2: hexDisplay port map (VGA_HorAddress(3 downto 0), display2);
	h3: hexDisplay port map (VGA_HorAddress(7 downto 4), display3);
	h4: hexDisplay port map (iData(15 downto 12), display4);
	h5: hexDisplay port map (iData(11 downto 8), display5);
	

	
--	h0: hexDisplay port map (iData(31 downto 28), display0);
--	h1: hexDisplay port map (iData(27 downto 24), display1);
--	h2: hexDisplay port map (iData(23 downto 20), display2);
--	h3: hexDisplay port map (iData(19 downto 16), display3);
--	h4: hexDisplay port map (iData(15 downto 12), display4);
--	h5: hexDisplay port map (iData(11 downto 8), display5);
	
	HEX0<=display0;
	HEX1<=display1;
	HEX2<=display2;
	HEX3<=display3;
	HEX4<=display4;
	HEX5<=display5;
	
	
end behavior;
