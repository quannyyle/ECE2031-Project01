-- LEDController.VHD
-- 2025.03.09
--
-- This SCOMP peripheral drives ten outputs high or low based on
-- a value from SCOMP.

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY LEDController IS
PORT(
    CS          : IN  STD_LOGIC;
    WRITE_EN    : IN  STD_LOGIC;
    RESETN      : IN  STD_LOGIC;
    CLOCK		 : IN  STD_LOGIC;
    LEDs        : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    IO_DATA     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END LEDController;

ARCHITECTURE a OF LEDController IS

	SIGNAL brightness_level : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL count				: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL duty_cycle			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL pulse				: STD_LOGIC;

	--BREATHING IMPLEMENTATION
	SIGNAL breathing_mode			: STD_LOGIC; 
	SIGNAL breathing_lvl 			: STD_LOGIC_VECTOR(3 DOWNTO 0); -- Stages of Breathing Cycle
	SIGNAL breathing_dir		      : STD_LOGIC; -- '0' = Dimmer, '1' Brighter, Breathing Direction
	SIGNAL breathing_counter		: STD_LOGIC_VECTOR(21 DOWNTO 0) := (OTHERS => '0'); 
	
BEGIN
    PROCESS (RESETN, CS)
    BEGIN
        IF (RESETN = '0') THEN
            -- Turn off LEDs at reset (a nice usability feature)
            brightness_level <= "0001";
	    breathing_mode <= '0';
        ELSIF (RISING_EDGE(CS)) THEN
            IF WRITE_EN = '1' THEN
                brightness_level <= IO_DATA(3 DOWNTO 0);
		breathing_mode <= IO_DATA(4); --Should be changed later for demonstration purposes/implementation
            END IF;
        END IF;
    END PROCESS;

	 --Duty Cycle 
	 PROCESS (brightness_level, breathing_lvl, breathing_mode)
		VARIABLE level: STD_LOGIC_VECTOR(3 DOWNTO 0); 
	 BEGIN
		IF breathing_mode = '0' THEN 
			level := brightness_level; 
		ELSE 
			level := breathing_lvl; 
		END IF;
		CASE level IS
			WHEN "0001" => duty_cycle <= "00000000";  -- 0% 
			WHEN "0010" => duty_cycle <= "00011011";  -- 10%
			WHEN "0011" => duty_cycle <= "00110110";  -- 20%
			WHEN "0100" => duty_cycle <= "01010001";  -- 30%
			WHEN "0101" => duty_cycle <= "01101010";  -- 40%
			WHEN "0110" => duty_cycle <= "10000101";  -- 50%
			WHEN "0111" => duty_cycle <= "10100000";  -- 60%
			WHEN "1000" => duty_cycle <= "10111011";  -- 70%
			WHEN "1001" => duty_cycle <= "11010110";  -- 80%
			WHEN "1010" => duty_cycle <= "11111111";  -- 100%
			WHEN OTHERS => duty_cycle <= "00000000";
		END CASE;
    END PROCESS;

	-- BREATHING IMPLEMENTATION:
	PROCESS  (RESETN, CLOCK) 
	BEGIN 
		IF (RESETN = '0') THEN 
			breathing_counter <= (OTHERS => '0'); --USED TO MAKE THINGS VISIBLE ON HUMAN TIMESCALE
			breathing_lvl <= "0000"; 
			breathing_dir <= '1'; 
		ELSIF (RISING_EDGE(CLOCK)) THEN 
			breathing_counter <= breathing_counter + 1; 
			IF breathing_counter = ("0000001111111111111111") THEN 
				breathing_counter <= (OTHERS => '0'); 
			
			IF breathing_dir = '1' THEN 
				IF breathing_lvl  = "1010" THEN 
					breathing_dir <= '0'; 
					breathing_lvl <= breathing_lvl - 1; 
				ELSE 
					breathing_lvl <= breathing_lvl + 1;
				END IF; 
			ELSE 
				IF breathing_lvl = "0001" THEN 
					breathing_dir <= '1'; 
					breathing_lvl <= breathing_lvl + 1; 
				ELSE 
					breathing_lvl <= breathing_lvl - 1;
				END IF; 
			END IF; 
		END IF; 
	END IF; 
	END PROCESS;


	 --PWM Implementation:  
	 PROCESS (RESETN, CLOCK)
	 BEGIN
		IF (RESETN = '0') THEN
			count <= "00000000";
			pulse <= '0';
		ELSIF (RISING_EDGE(CLOCK)) THEN
			count <= count + 1;
			IF count < duty_cycle THEN
				pulse <= '1'; 
			ELSE
				pulse <= '0';
			END IF;
		END IF;
	END PROCESS;
	
	LEDs <= (OTHERS => pulse); 
	 
END a;
