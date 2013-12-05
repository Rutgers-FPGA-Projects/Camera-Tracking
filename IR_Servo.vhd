LIBRARY ieee; -- Import logic primitives
USE ieee.std_logic_1164.all;

entity IR_Servo is
	port(
		IRDA_RXD: in std_logic;
		key: in std_logic_vector(0 downto 0);
		CLOCK_50	:IN STD_LOGIC;
		ready : out std_logic;
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5: OUT STD_LOGIC_VECTOR(0 TO 6);	
		EX_IO: out std_LOGIC_VECTOR(2 downto 0)
		);
end IR_Servo;

architecture behav of IR_Servo is 
	component servo is 
		port(clk: in STD_LOGIC;
			Angle: in integer := 100;   -- 1.5 ms
			servo_ctr: out STD_LOGIC
		);
	end component;
	
	component IR is 
		port(
			IRDA_RXD: in std_logic;
			key: in std_logic_vector(0 downto 0);
			CLOCK_50	:IN STD_LOGIC;
			ready : out std_logic  ;
			HEX0, HEX1, HEX2, HEX3, HEX4, HEX5: OUT STD_LOGIC_VECTOR(0 TO 6);
			irData: out std_logic_vector(31 downto 0)
			);
	end component;
	
	signal irData: std_logic_vector(31 downto 0);
	signal controlAngle: integer range 0 to 200:= 100;
begin 
	II: IR port map(IRDA_RXD, key(0),CLOCK_50,ready,HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,irData);
	 
	process (irData(23 downto 16))
      begin 
        CASE irData(23 downto 16) IS                                
          when "00011010"=>
					controlAngle<=controlAngle+5;
			 when "00011110"=>
					controlAngle<=controlAngle-5;
        END CASE;
   end process;
	
	irservo: servo port map(CLOCK_50, controlAngle, EX_IO(0));
	
end architecture;