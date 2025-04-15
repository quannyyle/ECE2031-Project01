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
    CLOCK	: IN  STD_LOGIC;
    LEDs        : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    IO_DATA     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END LEDController;

ARCHITECTURE a OF LEDController IS

	SIGNAL brightness_level : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL count				: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL duty_cycle			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL pulse				: STD_LOGIC;

BEGIN
    PROCESS (RESETN, CS)
    BEGIN
        IF (RESETN = '0') THEN
            -- Turn off LEDs at reset (a nice usability feature)
            brightness_level <= "0001";
        ELSIF (RISING_EDGE(CS)) THEN
            IF WRITE_EN = '1' THEN
                brightness_level <= IO_DATA(3 DOWNTO 0);
            END IF;
        END IF;
    END PROCESS;
	 
	 PROCESS (brightness_level)
	 BEGIN
		CASE brightness_level IS
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
	 
	 PROCESS (RESETN, CLOCK)
	 BEGIN
		IF (RESETN = '0') THEN
			count <= "00000000";
			pulse <= '0';
		ELSIF (RISING_EDGE(CLOCK)) THEN
			count <= count + 1;
			
			IF count < duty_cycle THEN
				pulse <= '1'; --FIX THIS SECTION
			ELSE
				pulse <= '0';
			END IF;
		END IF;
	END PROCESS;
	
	LEDs(0) <= '1';
	LEDs(1) <= '1';
	LEDs(2) <= '1';
	LEDs(3) <= '1';
	LEDs(4) <= '1';
	LEDs(5) <= '1';
	LEDs(6) <= '1';
	LEDs(7) <= '1';
	LEDs(8) <= '1';
	LEDs(9) <= '1'; 
	 
	 
END a;