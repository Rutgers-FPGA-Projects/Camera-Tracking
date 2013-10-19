-- Camera Tracking

-- Goal:


-- Change Log:


-- Import the definitions for standard logic
library ieee;
use ieee.std_logic_1164.all;

entity CameraTracking is 
	port(	VGA_R,VGA_G,VGA_B: out STD_logic_vector(7 downto 0);
			VGA_CLK,VGA_BLANK_N,VGA_HS,VGA_VS,VGA_SYNC_N: out STD_logic;
			SW: in STD_logic_vector(17 downto 0);
			CLOCK_50: in STD_logic;
			HEX0,HEX6,HEX7: out STD_logic_vector(6 downto 0);
			LEDG: out STD_logic_vector(7 downto 0);
			KEY: in STD_logic_vector(3 downto 0);
			GPIO: out STD_logic_vector(4 downto 0));
end;

architecture behavior of CameraTracking is 

	component 
		clock1 PORT(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			c1		: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC);
	end component;	

	-- used for PLL
	signal clock_106MHz: STD_logic; 
	signal clock_50MHz: STD_LOGIC;
	signal locked: STD_logic;
	signal rst: STD_LOGIC := '0';
	
begin
	
	-- implement the clock PLL to create a 106 MHz clock
	clock1_inst : clock1 PORT MAP(
		areset	 => rst,  -- active high to Reset PLL
		inclk0	 => CLOCK_50,
		c0	 => clock_50MHz,
		c1	 => clock_106MHz,
		locked	 => locked
	);
	
	
	
	
	
	
	
end behavior;
