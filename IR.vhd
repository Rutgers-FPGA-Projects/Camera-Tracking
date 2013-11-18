library ieee;
use ieee.std_logic_1164;

entity ir_receiver is 
  port ( IRDA_RXD: in std_logic;
			reset: in std_logic;
			clk_50: in std_logic;
			--When the IR receiver on the FPGA board receive the signal, LEDR will light
			LEDR: out std_logic_vector(1 downto 0);
			--Display the information about CUSTOM CODE bits __HEX7-HEX4
			--and KEY CODE bits __HEX3-HEX0
			oData_Ready: out std_logic;
			oData: out std_logic_vector(31 downto 0)
			);
end entity;

architecture behaviour of ir_receiver is
--All the constant I will use:
	constant data2idleThreshold: integer:=262143; --5.24ms
	constant idle2guidanceThreshold: integer:=230000; --4.6ms
	constant guidance2datareadThreshold: integer:=210000; --4.2ms
--All the signals I need to use:
	type count_state is (idle, guidance, dataread);--Once detect the LEAD CODE transfer idle to guidance, Detect the CUSTOM CODE transfer guidance to dataread.
	signal state : count_state;
	--The signals to determine the time to switch from present_state to next_state
	signal idle_count_flag: std_logic;
	signal guidance_count_flag: std_logic;
	signal dataread_count_flag: std_logic;
	
	signal idle_count: integer;
	signal guidance_count: integer;
	signal dataread_count: integer;
----------------------------------------
	signal data_ready_flag: std_logic;
	signal data: std_logic_vector(31 downto 0);
	signal data_buffer: std_logic_vector(31 downto 0);
	
begin 
--Count the idle_count preparing for state changes from idle to guidance
	process(clk_50, reset)
	begin
		if (reset='0') then 
			idle_count<=0;
		elsif(rising_edge(clk_50) and idle_count_flag='1') then 
			idle_count<=idle_count+1;
		end if;
	end process;
	
	process(clk_50, reset)
	begin
		if (reset='0') then 
			idle_count_flag<='0';
		elsif(rising_edge(clk_50) and state=idle and IRDA_RXD='0') then 
			idle_count_flag<='1';
		end if;
	end process;
	
--Count the guidance_count preparing for state changes from guidance to dataread
	process(clk_50, reset)
	begin
		if (reset='0') then 
			guidance_count<=0;
		elsif(rising_edge(clk_50) and guidance_count_flag='1') then 
			guidance_count<=guidance_count+1;
		end if;
	end process;
	
	process(clk_50, reset)
	begin
		if (reset='0') then 
			guidance_count_flag<='0';
		elsif(rising_edge(clk_50) and state=guidance and IRDA_RXD='1') then 
			guidance_count_flag<='1';
		end if;
	end process;
	
--Count the dataread_count preparing for state changes from dataread to idle
	process(clk_50, reset)
	begin
		if (reset='0') then 
			dataread_count<=0;
		elsif(rising_edge(clk_50) and guidance_count_flag='1') then 
			dataread_count<=dataread_count+1;
		end if;
	end process;
	
	process(clk_50, reset)
	begin
		if (reset='0') then 
			dataread_count_flag<='0';
		elsif(rising_edge(clk_50) and state=dataread and IRDA_RXD='1') then 
			dataread_count_flag<='1';
		end if;
	end process;
	
	process(state, reset, clk_50)
	begin 
		if (reset='0') then 
			state<=idle;
		elsif (rising_edge(clk_50)) then
			case state is
			when 
				idle=>
					if (idle_count>idle2guidanceThreshold) then 
						state<=guidance;
					end if;
			when 
				guidance=>
					if (guidance_count>guidance2datareadThreshold) then
						state<=dataread;
					end if;
			when 
				dataread=>
					if (dataread>data2idleThreshold) then 
						state<=idle;
					end if;
			end case;
		end if;
	end process;
		
	
	
end behaviour;


		
