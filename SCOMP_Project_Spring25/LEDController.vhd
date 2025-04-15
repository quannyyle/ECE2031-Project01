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
    CLOCK	    : IN  STD_LOGIC;
    LEDs        : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    IO_DATA     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END LEDController;

ARCHITECTURE a OF LEDController IS
	
	--Brightness Control Signals
	SIGNAL brightness_Level 	: STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
	SIGNAL count				: STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL duty_cycle			: STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL pulse				: STD_LOGIC := '0';
	SIGNAL data 				: STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0'); 
	--Breathing Signals: 
	SIGNAL breathing_Level 		: STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL increasingBrightness	: STD_LOGIC := '1';
	SIGNAL breathing_Counter	: STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL man_Brightness 		: STD_LOGIC_VECTOR(7 DOWNTO 0); --Manual Brightness Control 
	
	--Chasing Signals: 
	SIGNAL chase_Pos 			:integer Range 0 to 9 := 0; 
	SIGNAL chase_Dir			:STD_LOGIC := '1'; --Direction of chase, '1' right, '0' left
	SIGNAL chase_Counter		:STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL chase_LEDs 			:STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
	
	--CLOCK DIVIDER 
	--This is to reduce the clock speeds to actually see the effects. 
	SIGNAL clk_divider 			:STD_LOGIC_VECTOR(17 DOWNTO 0) := (others => '0'); 
	signal slow_clk 			:STD_LOGIC := '0'; 
BEGIN
	--Clock Division 
	PROCESS (cs)
	BEGIN 
		IF RISING_EDGE(cs) THEN 
			clk_divider <= clk_divider + 1; 
			slow_clk <= clk_divider(2); 
		END IF; 
	END PROCESS; 
	
    PROCESS (RESETN, CS)
    BEGIN
        IF (RESETN = '0') THEN
            -- Turn off LEDs at reset (a nice usability feature)
            brightness_level <= "0001";
			data <= (others => '0');
        ELSIF (RISING_EDGE(CS)) THEN
            IF WRITE_EN = '1' THEN
                brightness_level <= IO_DATA(3 DOWNTO 0);
				data <= IO_DATA;
            END IF;
        END IF;
    END PROCESS;
	
	 --Mapping brightness_level to duty cycle
	 PROCESS (brightness_level)
	 BEGIN
	 CASE brightness_Level IS
		WHEN "0000" => man_Brightness <= "00000000";
		WHEN "0001" => man_Brightness <= "00011001"; 
		WHEN "0010" => man_Brightness <= "00110011"; 
		WHEN "0011" => man_Brightness <= "01001101";
		WHEN "0100" => man_Brightness <= "01100110"; 
		WHEN "0101" => man_Brightness <= "10000000"; 
		WHEN "0110" => man_Brightness <= "10011001";
		WHEN "0111" => man_Brightness <= "10110011"; 
		WHEN "1000" => man_Brightness <= "11001100";
		WHEN "1001" => man_Brightness <= "11100110"; 
		WHEN OTHERS => man_Brightness <= "11111111";
    END CASE;
  END PROCESS;
  
	 --Duty cycle source 
	 PROCESS(brightness_Level, data) 
	 BEGIN 
		IF data(9) = '1' THEN 
			duty_cycle <= breathing_Level; 
		ELSE 
			duty_cycle <= man_Brightness; 
		END IF; 
	END PROCESS; 
	
	--Breathing Effect: 
	 PROCESS (slow_clk)
	 BEGIN
		IF rising_edge(slow_clk) THEN
			IF breathing_Counter = "00000001" THEN
				breathing_Counter <= (others => '0'); 
				IF increasingBrightness ='1' THEN 
					IF breathing_Level = "11111111" THEN
						increasingBrightness <= '0'; 
					ELSE 
						breathing_Level <= breathing_Level + 2;
					END IF;
				ELSE
					IF breathing_Level = "00000000" THEN 
						increasingBrightness <= '1';
					ELSE 
						breathing_Level <= breathing_Level - 2;
					END IF;
				END IF;
			ELSE 
				breathing_Counter <= breathing_Counter + 1;
			END IF;
		END IF;
	END PROCESS;
	-- Bouncing LED: 
	process(slow_clk) 
	BEGIN 
		IF RISING_EDGE(slow_clk) THEN 
			IF chase_Counter = "00000001" THEN 
				chase_Counter <= (others => '0'); 
				IF chase_Dir = '1' THEN	
					IF chase_Pos = 9 THEN 
						chase_Dir <= '0'; 
						chase_Pos <= 8; 
					ELSE
					 chase_Pos <= chase_Pos + 1; 
					END IF; 
				ELSE 
					IF chase_Pos = 0 THEN 
						chase_Dir <= '1'; 
						chase_Pos <= 1;
					ELSE 
						chase_Pos <= chase_Pos - 1; 
					END IF; 
				END IF;
			ELSE 
				chase_Counter <= chase_Counter + 1; 
			END IF; 
		END IF;
	END PROCESS;
	
	--LED OUTPUT for chasing effect
	PROCESS(chase_Pos)
	BEGIN	
		chase_LEDs <= (others => '0'); 
		chase_LEDs(chase_Pos) <= '1'; 
	END PROCESS;
	
	
	
	
	
	--PWM GENERATOR
	PROCESS(CS)
	BEGIN
		IF rising_edge(CS) THEN	
			count <= count + 1; 
			IF count < duty_cycle THEN
				pulse <= '1';
			ELSE
				pulse <= '0'; 
			END IF;
		END IF; 
	END PROCESS; 
	--Final LED output logic
	 LEDs <= chase_LEDs WHEN data(8) = '1' ELSE (OTHERS => pulse); 
	 
END a;