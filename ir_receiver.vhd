LIBRARY ieee; -- Import logic primitives
USE ieee.std_logic_1164.all;

entity ir_receiver is 
  port ( 
			iIRDA: in std_logic;
			reset: in std_logic;
			clk_50: in std_logic;
			--Display the information about CUSTOM CODE bits __HEX7-HEX4
			--and KEY CODE bits __HEX3-HEX0
			oData: out std_logic_vector(31 downto 0)
			);
end entity;

architecture behaviour of ir_receiver is
--All the constant I will use:
	constant data2idleThreshold: integer:=262143; --5.24ms
	constant idle2guidanceThreshold: integer:=230000; --4.6ms
	constant guidance2datareadThreshold: integer:=210000; --4.2ms
	constant data_high_duration: integer:=41500; --0.83ms
--All the signals I need to use:
	type count_state is (idle, guidance, dataread);--Once detect the LEAD CODE transfer idle to guidance, Detect the CUSTOM CODE transfer guidance to dataread.
	signal state : count_state;
	--The signals to determine the time to switch state
	signal idle_count_flag: std_logic;
	signal guidance_count_flag: std_logic;
	signal dataread_count_flag: std_logic;
	
	signal idle_count: integer;
	signal guidance_count: integer;
	signal dataread_count: integer;
----------------------------------------
	signal bitcount: integer range 0 to 34 := 0;
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
		elsif(rising_edge(clk_50) and state=idle and iIRDA='0') then 
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
		elsif(rising_edge(clk_50) and state=guidance and iIRDA='1') then 
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
		elsif(rising_edge(clk_50) and state=dataread and iIRDA='1') then 
			dataread_count_flag<='1';
		end if;
	end process;

--State changes between IDLE, GUIdance, DATaread	
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
					if (dataread_count>data2idleThreshold) then 
						state<=idle;
					end if;
			end case;
		end if;
	end process;
	
--The bitcount to get the info of the bit we have already handled.
	process(clk_50, reset)
	begin 
		if (reset='0') then 
			bitcount<=0;
		elsif (rising_edge(clk_50) and state= dataread) then 
			if (dataread_count=20000) then 
				bitcount<=bitcount+1;
			end if;
		end if;
	end process;
	
--In the dataread state, to distinguish whether the emitted signal is 0 or 1;
	process(clk_50, reset)
	begin
		if (reset='0') then 
			data<= X"00000000";
		elsif (rising_edge(clk_50) and state=dataread) then 
			if (dataread_count>=data_high_duration) then 
				data(bitcount-1)<='1';
			else data(bitcount-1)<='0';
			end if;
		end if;
	end process;
	 				
--Set the data_ready_flag 
	process(clk_50, reset)
	begin 
		if (reset='0') then 
			data_ready_flag<='0';
		elsif (rising_edge(clk_50) and bitcount=32) then
			if (data(31 downto 24)=not data(23 downto 16)) then 
				data_buffer<=data;
				data_ready_flag<='1';
			else data_ready_flag<='0';
			end if;
		end if;
	end process;
--Read data
	process(clk_50, reset)
	begin
		if (reset='0') then 
			odata<=X"00000000";
		elsif (rising_edge(clk_50) and data_ready_flag='1') then 
			odata<=data_buffer;
		end if;
	end process;
end behaviour;


		
