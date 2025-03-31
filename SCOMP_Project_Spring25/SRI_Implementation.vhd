LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY DIG_OUT IS
  PORT(
    CLK       : IN  STD_LOGIC;  -- Clock for PWM
    RESETN    : IN  STD_LOGIC;  -- Active-low Reset
    IO_DATA   : IN  STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16-bit input (10 switches)
    LEDS      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)   -- 10 LEDs
  );
END DIG_OUT;

ARCHITECTURE a OF DIG_OUT IS
  SIGNAL PWM_COUNTER   : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'); -- 4-bit PWM counter (0-10)
  SIGNAL BRIGHTNESS    : INTEGER RANGE 0 TO 10 := 0;  -- The brightness level based on switch input (0-10)
  
  -- Gamma correction lookup table for brightness levels (0 to 10)
  TYPE gamma_table IS ARRAY(0 TO 10) OF STD_LOGIC_VECTOR(3 DOWNTO 0);
  CONSTANT GAMMA_LUT : gamma_table := (
    "0000", -- 0% brightness (0)
    "0001", -- 2% brightness (0.2)
    "0010", -- 6% brightness (0.6)
    "0011", -- 13% brightness (1.3)
    "0100", -- 25% brightness (2.5)
    "0101", -- 41% brightness (4.1)
    "0110", -- 62% brightness (6.2)
    "0111", -- 82% brightness (8.2)
    "1000", -- 94% brightness (9.4)
    "1001", -- 99% brightness (9.9)
    "1010"  -- 100% brightness (10)
  );
BEGIN

  -- PWM Counter: Increments on every clock cycle
  PROCESS (CLK)
  BEGIN
    IF RISING_EDGE(CLK) THEN
      IF PWM_COUNTER < "1010" THEN  -- Max brightness level = 10
        PWM_COUNTER <= PWM_COUNTER + 1;
      ELSE
        PWM_COUNTER <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  -- Count the number of HIGH bits in IO_DATA[9:0] (Number of active switches)
  PROCESS (IO_DATA)
    VARIABLE COUNT : INTEGER RANGE 0 TO 10 := 0;
  BEGIN
    COUNT := 0;
    FOR i IN 0 TO 9 LOOP
      IF IO_DATA(i) = '1' THEN
        COUNT := COUNT + 1;
      END IF;
    END LOOP;
    BRIGHTNESS := COUNT;  -- Number of active switches defines brightness level (0-10)
  END PROCESS;

  -- Gamma correction: Apply the LUT to get the corrected PWM value
  PROCESS (BRIGHTNESS)
  BEGIN
    -- Apply gamma correction by using the LUT to map BRIGHTNESS to a corrected value
    PWM_BRIGHTNESS <= GAMMA_LUT(BRIGHTNESS);
  END PROCESS;

  -- PWM Brightness Control for all LEDs
  PROCESS (PWM_COUNTER, PWM_BRIGHTNESS)
  BEGIN
    -- Loop through all LEDs and apply brightness control
    FOR i IN 0 TO 9 LOOP
      IF PWM_BRIGHTNESS > PWM_COUNTER THEN
        LEDS(i) <= '1';  -- Turn ON LED i based on brightness
      ELSE
        LEDS(i) <= '0';  -- Turn OFF LED i
      END IF;
    END LOOP;
  END PROCESS;

END a;
