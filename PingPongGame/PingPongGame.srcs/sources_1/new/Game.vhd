-- ===========================================================================
-- File Name: Game.vhd
-- Description: This file contains the top-level entity and architecture for your VHDL project.
-- Author: Khalid Abdelaziz
-- Date: 7th, May , 2023
-- Company: German University in Cairo
-- Version: 1.0
-- ===========================================================================

-- Library Declarations
LIBRARY IEEE; -- Standard IEEE library
USE IEEE.std_logic_1164.ALL; -- Package for standard logic types and operations
USE IEEE.NUMERIC_STD.ALL; -- Package for numeric types and operations
-- Entity Declaration

ENTITY Game IS
    PORT (
        Player1_up : IN STD_LOGIC; -- Input signal indicating whether Player 1 is moving up.
        Player1_down : IN STD_LOGIC; -- Input signal indicating whether Player 1 is moving down.
        Player2_up : IN STD_LOGIC; -- Input signal indicating whether Player 2 is moving up.
        Player2_down : IN STD_LOGIC; -- Input signal indicating whether Player 2 is moving down.
        reset : IN STD_LOGIC; -- Input signal for system reset.
        clk : IN STD_LOGIC; -- Input clock signal.

        R : OUT STD_LOGIC_VECTOR (3 DOWNTO 0); -- Output signal representing the Red component of the color.
        G : OUT STD_LOGIC_VECTOR (3 DOWNTO 0); -- Output signal representing the Green component of the color.
        B : OUT STD_LOGIC_VECTOR (3 DOWNTO 0); -- Output signal representing the Blue component of the color.

        Hsync, Vsync : OUT STD_LOGIC := '1'); -- Output signals for Horizontal and Vertical synchronization, initialized to logic 1.

END Game;

-- Architecture Definition
ARCHITECTURE Behavioral OF Game IS

    SIGNAL clk25 : STD_LOGIC := '0';
    SHARED VARIABLE counter : INTEGER := 0;
    SHARED VARIABLE horizontal, vertical : INTEGER := 0;

---------------------------------------- Paddles parameters -----------------------------------------------    
    -- This constant represents the length of the paddle, set to 120
    CONSTANT paddle_length : INTEGER := 80;

    -- This constant represents the width of the paddle, set to 20
    CONSTANT paddle_width : INTEGER := 5;

    -- This shared variable represents the top position of paddle 1, with a range from 0 to (479 - paddle_length) to ensure it stays within the visible area
    SHARED VARIABLE top_paddle1 : INTEGER RANGE 0 TO (479 - paddle_length) := 199;

    -- This shared variable represents the top position of paddle 2, with a range from 0 to (479 - paddle_length) to ensure it stays within the visible area
    SHARED VARIABLE top_paddle2 : INTEGER RANGE 0 TO (479 - paddle_length) := 199;

    -- This shared variable represents the bottom position of paddle 1, calculated as top_paddle1 + paddle_length
    SHARED VARIABLE bot_paddle1 : INTEGER := top_paddle1 + paddle_length;

    -- This shared variable represents the bottom position of paddle 2, calculated as top_paddle2 + paddle_length
    SHARED VARIABLE bot_paddle2 : INTEGER := top_paddle2 + paddle_length;

    -- This constant represents the left position of paddle 1 
    CONSTANT left_paddle1 : INTEGER := 6;

    -- This constant represents the left position of paddle 2, set to 620
    CONSTANT left_paddle2 : INTEGER := 629;

    -- This constant represents the right position of paddle 1, calculated as left_paddle1 + paddle_width
    CONSTANT right_paddle1 : INTEGER := left_paddle1 + paddle_width;

    -- This constant represents the right position of paddle 2, calculated as left_paddle2 + paddle_width
    CONSTANT right_paddle2 : INTEGER := left_paddle2 + paddle_width;

    -- This constant represents the speed of the paddles
    CONSTANT Paddle_speed : INTEGER := 3;

---------------------------------------------------- Ball Parameters --------------------------------------------------------------------------    
    -- This constant represents the parameter value for the ball, set to 20
    CONSTANT ball_Par : INTEGER := 10;

    -- This shared variable represents the top position of the ball, initially set to 235
    SHARED VARIABLE ball_top : INTEGER := 235;

    -- This shared variable represents the bottom position of the ball, calculated as ball_top + ball_Par
    SHARED VARIABLE ball_bot : INTEGER := ball_top + ball_Par;

    -- This shared variable represents the left position of the ball, initially set to 315
    SHARED VARIABLE ball_left : INTEGER := 315;

    -- This shared variable represents the right position of the ball, calculated as ball_left + ball_Par
    SHARED VARIABLE ball_right : INTEGER := ball_left + ball_Par;

    -- This constant represents the speed of the ball
    CONSTANT ball_speed : INTEGER := 4;
------------------------------------------------- GameFlow Parameters ------------------------------------------------------------------------    
    -- This shared variable represents the start flag, initially set to '1'
    SHARED VARIABLE start_flag : STD_LOGIC := '1';

    -- This shared variable represents the flag for upward movement of an object, initially set to '0'
    SHARED VARIABLE up_moving_flag : STD_LOGIC := '0';

    -- This shared variable represents the flag for leftward movement of an object, initially set to '0'
    SHARED VARIABLE left_moving_flag : STD_LOGIC := '0';

    -- This shared variable represents the game over flag, initially set to '0'
    SHARED VARIABLE GameOver : STD_LOGIC := '0';

------------------------------------------------- Score Calculations ------------------------------------------------------------------------        
    SHARED VARIABLE Player1_score : INTEGER := 0;
    SHARED VARIABLE Player2_score : INTEGER := 0;
---------------------------------------------------------------------------------------------------------------------------------------------- 

BEGIN

    -- to generate an appropriate clock (25MHz) from the board main clock (100MHz)
    clock_generation : PROCESS (clk)
    BEGIN
        -- Triggered on the rising edge of the "clk" signal
        IF (rising_edge(clk)) THEN
            -- Increment the counter by 1
            counter := counter + 1;

            -- Check the value of the counter
            IF (counter < 2) THEN
                -- If counter is less than 2, set "clk25" to '0'
                clk25 <= '0';
            ELSIF (counter < 4) THEN
                -- If counter is between 2 and 3, set "clk25" to '1'
                clk25 <= '1';
            ELSE
                -- If counter is 4 or greater, reset the counter to 0
                counter := 0;
                -- Set "clk25" to '0'
                clk25 <= '0';
            END IF;
        END IF;
    END PROCESS;
    main_process : PROCESS (clk25, reset)
    BEGIN

        IF (rising_edge(clk25)) THEN
            hsync <= '1';
            vsync <= '1';

            IF (horizontal <= 799) AND (vertical <= 524) THEN -- Screen area
------------------------------------- Drawing the figures of the paddles and the ball -------------------------------------------------------------------------                            
                IF (horizontal < 640) THEN -- Check if the current position is within the visible area
                    -- Check if the current position is within the range of paddle 1
                    IF ((horizontal >= left_paddle1) AND (horizontal <= right_paddle1) AND (vertical >= top_paddle1) AND (vertical <= bot_paddle1)) THEN
                        R <= "0000"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to maximum intensity
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)
                        -- Check if the current position is within the range of paddle 2
                    ELSIF ((horizontal >= left_paddle2) AND (horizontal <= right_paddle2) AND (vertical >= top_paddle2) AND (vertical <= bot_paddle2)) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "0000"; -- Set G (green) to maximum intensity
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)
                        -- Check if the current position is within the range of the ball
                    ELSIF ((horizontal >= ball_left AND horizontal <= ball_right) AND (vertical >= ball_top AND vertical <= (ball_top + ball_Par))) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)
                    ELSIF (horizontal = 0) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)
                    ELSIF (horizontal = 639) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)
                    ELSIF (horizontal >= 319 AND horizontal <= 321) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)
                    ELSIF ((horizontal >= 315 AND horizontal <= 325) AND (vertical >= 235 AND vertical <= 245)) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)

                    ELSIF ((horizontal >= 0 AND horizontal <= 639) AND vertical = 0) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)
                    ELSIF ((horizontal >= 0 AND horizontal <= 639) AND vertical = 478) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)
                    ELSIF ((horizontal >= 299 AND horizontal <= 341) AND vertical = 35) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)
                    ELSIF ((vertical >= 0 AND vertical <= 35) AND horizontal = 299) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)     
                    ELSIF ((vertical >= 0 AND vertical <= 35) AND horizontal = 341) THEN
                        R <= "1111"; -- Set R (red) to maximum intensity
                        G <= "1111"; -- Set G (green) to minimum intensity (off)
                        B <= "1111"; -- Set B (blue) to minimum intensity (off)

                    ELSE
                        R <= "0000"; -- Set R (red) to minimum intensity (off)
                        G <= "0000"; -- Set G (green) to minimum intensity (off)
                        B <= "0000"; -- Set B (blue) to minimum intensity (off)
                        IF (Player1_score = 0) THEN
                            IF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 5) THEN -- A1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 30) THEN -- D1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 303) THEN --F1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 303) THEN -- E1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 315) THEN -- B1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)             
                            END IF;
                        ELSIF (Player1_score = 1) THEN
                            IF ((vertical >= 6 AND vertical <= 17) AND horizontal = 315) THEN -- B1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)        
                            END IF;
                        ELSIF (Player1_score = 2) THEN
                            IF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 5) THEN -- A1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 18) THEN -- G1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 30) THEN -- D1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 303) THEN -- E1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 315) THEN -- B1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)   
                            END IF;
                        ELSIF (Player1_score = 3) THEN
                            IF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 5) THEN -- A1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 18) THEN -- G1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 30) THEN -- D1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 315) THEN -- B1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)      
                            END IF;
                        ELSIF (Player1_score = 4) THEN
                            IF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 18) THEN -- G1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 303) THEN --F1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 315) THEN -- B1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)               
                            END IF;
                        ELSIF (Player1_score = 5) THEN
                            IF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 5) THEN -- A1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)

                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 18) THEN -- G1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 30) THEN -- D1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 303) THEN --F1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)

                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)          
                            END IF;
                        ELSIF (Player1_score = 6) THEN
                            IF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 5) THEN -- A1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 18) THEN -- G1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 30) THEN -- D1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 303) THEN --F1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 303) THEN -- E1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)            
                            END IF;
                        ELSIF (Player1_score = 7) THEN
                            IF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 5) THEN -- A1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 315) THEN -- B1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)           
                            END IF;
                        ELSIF (Player1_score = 8) THEN
                            IF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 5) THEN -- A1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 18) THEN -- G1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 30) THEN -- D1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 303) THEN --F1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 303) THEN -- E1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 315) THEN -- B1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)        
                            END IF;
                        ELSIF (Player1_score = 9) THEN
                            IF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 5) THEN -- A1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 18) THEN -- G1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 303 AND horizontal <= 315) AND vertical = 30) THEN -- D1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 303) THEN --F1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 315) THEN -- B1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)     
                            END IF;
                        ELSE
                            IF ((vertical >= 19 AND vertical <= 30) AND horizontal = 315) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)     
                            END IF;
                        END IF;

                        IF (Player2_score = 0) THEN
                            IF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 5) THEN -- A1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 30) THEN -- D1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 325) THEN --F1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 325) THEN -- E1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 337) THEN -- B1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)             
                            END IF;
                        ELSIF (Player2_score = 1) THEN
                            IF ((vertical >= 6 AND vertical <= 17) AND horizontal = 337) THEN -- B1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)        
                            END IF;
                        ELSIF (Player2_score = 2) THEN
                            IF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 5) THEN -- A1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 18) THEN -- G1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 30) THEN -- D1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 325) THEN -- E1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 337) THEN -- B1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)   
                            END IF;
                        ELSIF (Player2_score = 3) THEN
                            IF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 5) THEN -- A1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 18) THEN -- G1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 30) THEN -- D1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 337) THEN -- B1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)      
                            END IF;
                        ELSIF (Player2_score = 4) THEN
                            IF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 18) THEN -- G1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 325) THEN --F1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 337) THEN -- B1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)               
                            END IF;
                        ELSIF (Player2_score = 5) THEN
                            IF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 5) THEN -- A1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)

                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 18) THEN -- G1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 30) THEN -- D1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 325) THEN --F1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)

                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)          
                            END IF;
                        ELSIF (Player2_score = 6) THEN
                            IF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 5) THEN -- A1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 18) THEN -- G1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 30) THEN -- D1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 325) THEN --F1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 325) THEN -- E1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)            
                            END IF;
                        ELSIF (Player2_score = 7) THEN
                            IF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 5) THEN -- A1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 337) THEN -- B1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)           
                            END IF;
                        ELSIF (Player2_score = 8) THEN
                            IF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 5) THEN -- A1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 18) THEN -- G1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 30) THEN -- D1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 325) THEN --F1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 325) THEN -- E1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 337) THEN -- B1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)        
                            END IF;
                        ELSIF (Player2_score = 9) THEN
                            IF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 5) THEN -- A1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 18) THEN -- G1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((horizontal >= 325 AND horizontal <= 337) AND vertical = 30) THEN -- D1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 325) THEN --F1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 6 AND vertical <= 17) AND horizontal = 337) THEN -- B1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)
                            ELSIF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "1111"; -- Set R (red) to maximum intensity
                                G <= "0000"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)     
                            END IF;
                        ELSE
                            IF ((vertical >= 19 AND vertical <= 30) AND horizontal = 337) THEN --C1
                                R <= "0000"; -- Set R (red) to maximum intensity
                                G <= "1111"; -- Set G (green) to minimum intensity (off)
                                B <= "1111"; -- Set B (blue) to minimum intensity (off)     
                            END IF;
                        END IF;
                    END IF;
                    horizontal := horizontal + 1; -- Increment the horizontal position

------------------------------------------------------------------------------------------------------------------------------------------------------                    
                ELSIF ((horizontal <= 655) AND (horizontal >= 640)) THEN
                    -- Condition: horizontal position is between 640 and 655
                    R <= "0000"; -- Set R to black (no red)
                    G <= "0000"; -- Set G to black (no green)
                    B <= "0000"; -- Set B to black (no blue)
                    horizontal := horizontal + 1; -- Increment the horizontal position
                ELSIF ((horizontal <= 751) AND (horizontal >= 656)) THEN
                    -- Condition: horizontal position is between 656 and 751
                    hsync <= '0'; -- Set hsync signal to '0'
                    R <= "0000"; -- Set R to black (no red)
                    G <= "0000"; -- Set G to black (no green)
                    B <= "0000"; -- Set B to black (no blue)
                    horizontal := horizontal + 1; -- Increment the horizontal position
                ELSIF ((horizontal < 799) AND (horizontal >= 752)) THEN
                    -- Condition: horizontal position is between 752 and 798
                    R <= "0000"; -- Set R to black (no red)
                    G <= "0000"; -- Set G to black (no green)
                    B <= "0000"; -- Set B to black (no blue)
                    horizontal := horizontal + 1; -- Increment the horizontal position
                ELSIF (horizontal >= 799) THEN
                    -- Condition: horizontal position is greater than or equal to 799
                    IF (vertical < 524) THEN
                        -- Check if the vertical position is less than 524
                        vertical := vertical + 1; -- Increment the vertical position
                        horizontal := 0; -- Reset the horizontal position to 0
                    ELSE
                        -- Vertical position is 524 or greater
                        vertical := 0; -- Reset the vertical position to 0
                        horizontal := 0; -- Reset the horizontal position to 0

---------------------------------------------- Paddles movement -------------------------------------------------------------------------------                        
                        -- This part is for the movement of the first paddle (paddle)
                        IF (Player1_up = '1' AND Player1_down = '0') THEN
                            -- If Player1 wants to move the first paddle upward
                            IF (top_paddle1 - paddle_speed >= 0) THEN
                                -- If the top position of the first paddle is greater than 0
                                -- Move the first paddle upward by reducing the top position by paddle_speed
                                top_paddle1 := top_paddle1 - paddle_speed;
                            ELSE
                                -- If the top position of the first paddle is already at 0
                                -- Keep the top position of the first paddle at 0 (cannot move further upward)
                                top_paddle1 := 0;
                            END IF;
                        ELSIF (Player1_up = '0' AND Player1_down = '1') THEN
                            -- If Player1 wants to move the first paddle downward
                            IF (top_paddle1 < (479 - paddle_length)) THEN
                                -- If the top position of the first paddle is less than (479 - paddle_length)
                                -- Move the first paddle downward by increasing the top position by paddle_speed
                                top_paddle1 := top_paddle1 + paddle_speed;
                            ELSE
                                -- If the top position of the first paddle is already at the maximum allowable position
                                -- Keep the top position of the first paddle at (479 - paddle_length) (cannot move further downward)
                                top_paddle1 := (479 - paddle_length);
                            END IF;
                        END IF;

                        -- This part is for the movement of the second paddle (paddle)
                        IF (Player2_up = '1' AND Player2_down = '0') THEN
                            -- If Player2 wants to move the second paddle upward
                            IF (top_paddle2 - paddle_speed >= 0) THEN
                                -- If the top position of the second paddle is greater than 0
                                -- Move the second paddle upward by reducing the top position by paddle_speed
                                top_paddle2 := top_paddle2 - paddle_speed;
                            ELSE
                                -- If the top position of the second paddle is already at 0
                                -- Keep the top position of the second paddle at 0 (cannot move further upward)
                                top_paddle2 := 0;
                            END IF;
                        ELSIF (Player2_up = '0' AND Player2_down = '1') THEN
                            -- If Player2 wants to move the second paddle downward
                            IF (top_paddle2 < (479 - paddle_length)) THEN
                                -- If the top position of the second paddle is less than (479 - paddle_length)
                                -- Move the second paddle downward by increasing the top position by paddle_speed
                                top_paddle2 := top_paddle2 + paddle_speed;
                            ELSE
                                -- If the top position of the second paddle is already at the maximum allowable position
                                -- Keep the top position of the second paddle at (479 - paddle_length) (cannot move further downward)
                                top_paddle2 := (479 - paddle_length);
                            END IF;
                        END IF;

--------------------------- The part responsible for resetting the ball postion at the middle --------------------------------------------------------------------                       

                        IF (reset = '0' AND start_flag = '1') THEN
                            -- Condition: If reset is '0' and start_flag is '1'

                            start_flag := '0';
                            -- Set start_flag to '0' (clear start_flag)

                            up_moving_flag := '1';
                            -- Set up_moving_flag to '1' (set up_moving_flag)

                            left_moving_flag := '0';
                            -- Set left_moving_flag to '0' (clear left_moving_flag)

                        ELSIF (reset = '1' OR GameOver = '1') THEN
                            -- Condition: If reset is '1' or GameOver is '1'

                            start_flag := '1';
                            -- Set start_flag to '1' (set start_flag)

                            GameOver := '0';
                            -- Set GameOver to '0' (clear GameOver)

                            ball_top := 235;
                            -- Set ball_top to 235 (reset ball_top to a specific value)

                            ball_left := 315;
                            -- Set ball_left to 315 (reset ball_left to a specific value)

                        END IF;
-------------------------------- The part responsible for tracing the ball movment -----------------------------------------------------------
                        IF (ball_top > (479 - ball_par)) THEN
                            -- Check if the top position of the ball is at the height where it would reflect from the bottom
                            -- If true, set the up_moving_flag to '1' indicating the ball is reflected from the bottom and moves upward
                            up_moving_flag := '1';
                        END IF;

                        IF (ball_top < ball_par) THEN
                            -- Check if the top position of the ball is at the height where it would reflect from the top
                            -- If true, set the up_moving_flag to '0' indicating the ball is reflected from the top and moves downward
                            up_moving_flag := '0';
                        END IF;

                        IF ((ball_left >= left_paddle2 - ball_Par) AND (ball_top <= bot_paddle2) AND (ball_bot > top_paddle2)) THEN
                            -- Check if the ball's left position is equal to the right position of paddle 2 minus ball_Par
                            -- and if the ball is within the vertical range of paddle 2
                            -- If true, set the left_moving_flag to '1' indicating the ball is reflected from the right paddle and moves left
                            left_moving_flag := '1';
                        END IF;

                        IF ((ball_left <= right_paddle1) AND (ball_top <= bot_paddle1) AND (ball_bot > top_paddle1)) THEN
                            -- Check if the ball's left position is equal to the right position of paddle 1
                            -- and if the ball is within the vertical range of paddle 1
                            -- If true, set the left_moving_flag to '0' indicating the ball is reflected from the left paddle and moves right
                            left_moving_flag := '0';
                        END IF;

                        IF (ball_left >= 639 - ball_Par) THEN
                            -- Check if the ball's left position reaches the maximum horizontal position (639 minus ball_Par)
                            -- If true, set the GameOver flag to '1' indicating that the game is over (the ball missed the second paddle)
                            GameOver := '1';
                            IF (Player1_score < 9) THEN
                                Player1_score := Player1_score + 1;
                            ELSE
                                Player1_score := 9;
                            END IF;

                        END IF;

                        IF (ball_left < ball_Par) THEN
                            -- Check if the ball's left position reaches the minimum horizontal position (0)
                            -- If true, set the GameOver flag to '1' indicating that the game is over (the ball missed the first paddle)
                            GameOver := '1';
                            IF (Player2_score < 9) THEN
                                Player2_score := Player2_score + 1;
                            ELSE
                                Player2_score := 9;
                            END IF;
                        END IF;

                        IF (up_moving_flag = '1') THEN
                            -- If the up_moving_flag is '1', indicating the ball is moving upward
                            -- Decrease the top position of the ball by ball speed
                            ball_top := ball_top - ball_speed;
                        ELSE
                            -- If the up_moving_flag is '0', indicating the ball is moving downward
                            -- Increase the top position of the ball by ball speed
                            ball_top := ball_top + ball_Speed;
                        END IF;

                        IF (left_moving_flag = '1') THEN
                            -- If the left_moving_flag is '1', indicating the ball is moving left
                            -- Decrease the left position of the ball by ball speed
                            ball_left := ball_left - ball_speed;
                        ELSE
                            -- If the left_moving_flag is '0', indicating the ball is moving right
                            -- Increase the left position of the ball by ball speed
                            ball_left := ball_left + ball_speed;
                        END IF;

                    END IF;

                END IF;
            END IF;
            IF (vertical >= 480 AND vertical <= 489) THEN
                -- Check if the vertical position is within the range of 480 to 489
                R <= "0000"; -- Set R (red) to minimum intensity (off)
                G <= "0000"; -- Set G (green) to minimum intensity (off)
                B <= "0000"; -- Set B (blue) to minimum intensity (off)
            ELSIF (vertical >= 490 AND vertical <= 491) THEN
                -- Check if the vertical position is within the range of 490 to 491
                R <= "0000"; -- Set R (red) to minimum intensity (off)
                G <= "0000"; -- Set G (green) to minimum intensity (off)
                B <= "0000"; -- Set B (blue) to minimum intensity (off)
                vsync <= '0'; -- Set vsync signal to '0' (vertical sync)
            ELSIF (vertical >= 492 AND vertical <= 524) THEN
                -- Check if the vertical position is within the range of 492 to 524
                R <= "0000"; -- Set R (red) to minimum intensity (off)
                G <= "0000"; -- Set G (green) to minimum intensity (off)
                B <= "0000"; -- Set B (blue) to minimum intensity (off)
            END IF;

        END IF;
    END PROCESS;
END Behavioral;