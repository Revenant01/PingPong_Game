-- ===========================================================================
-- File Name: Game.vhd
-- Description: This file contains the top-level entity and architecture for your VHDL project.
-- Author: Khalid Abdelaziz
-- Date: 7th, May , 2023
-- Company: German University in Cairo
-- Version: 1.0
-- ===========================================================================

-- Library Declarations
library IEEE; -- Standard IEEE library
use IEEE.std_logic_1164.all; -- Package for standard logic types and operations
use IEEE.NUMERIC_STD.all;   -- Package for numeric types and operations


-- Entity Declaration

entity Game is
 Port (     Player1_up: in std_logic;     -- Input signal indicating whether Player 1 is moving up.
            Player1_down: in std_logic;   -- Input signal indicating whether Player 1 is moving down.
            Player2_up: in std_logic;     -- Input signal indicating whether Player 2 is moving up.
            Player2_down: in std_logic;   -- Input signal indicating whether Player 2 is moving down.
            reset : in std_logic;         -- Input signal for system reset.
            clk : in STD_LOGIC;           -- Input clock signal.
            
            R : out STD_LOGIC_VECTOR (3 downto 0);   -- Output signal representing the Red component of the color.
            G : out STD_LOGIC_VECTOR (3 downto 0);   -- Output signal representing the Green component of the color.
            B : out STD_LOGIC_VECTOR (3 downto 0);   -- Output signal representing the Blue component of the color.
            
            Hsync,Vsync : out std_logic := '1');    -- Output signals for Horizontal and Vertical synchronization, initialized to logic 1.
            
end Game;

-- Architecture Definition
architecture Behavioral of Game is

    signal  clk25 : std_logic := '0';
    shared variable counter : integer := 0;
    shared variable horizontal, vertical : integer := 0;
    
---------------------------------------- Paddles parameters -----------------------------------------------    
    -- This constant represents the length of the paddle, set to 120
    constant paddle_length : integer := 80;
    
    -- This constant represents the width of the paddle, set to 20
    constant paddle_width : integer := 5;
    
    -- This shared variable represents the top position of paddle 1, with a range from 0 to (479 - paddle_length) to ensure it stays within the visible area
    shared variable top_paddle1 : integer range 0 to (479 - paddle_length) := 199;
    
    -- This shared variable represents the top position of paddle 2, with a range from 0 to (479 - paddle_length) to ensure it stays within the visible area
    shared variable top_paddle2 : integer range 0 to (479 - paddle_length) := 199;
    
    -- This shared variable represents the bottom position of paddle 1, calculated as top_paddle1 + paddle_length
    shared variable bot_paddle1 : integer := top_paddle1 + paddle_length;
    
    -- This shared variable represents the bottom position of paddle 2, calculated as top_paddle2 + paddle_length
    shared variable bot_paddle2 : integer := top_paddle2 + paddle_length;
    
    -- This constant represents the left position of paddle 1 
    constant left_paddle1 : integer := 6;
    
    -- This constant represents the left position of paddle 2, set to 620
    constant left_paddle2 : integer := 629;
    
    -- This constant represents the right position of paddle 1, calculated as left_paddle1 + paddle_width
    constant right_paddle1 : integer := left_paddle1 + paddle_width;
    
    -- This constant represents the right position of paddle 2, calculated as left_paddle2 + paddle_width
    constant right_paddle2 : integer := left_paddle2 + paddle_width;
    
    -- This constant represents the speed of the paddles
    constant Paddle_speed : integer := 3;

---------------------------------------------------- Ball Parameters --------------------------------------------------------------------------    
    -- This constant represents the parameter value for the ball, set to 20
    constant ball_Par : integer := 10;
    
    -- This shared variable represents the top position of the ball, initially set to 235
    shared variable ball_top : integer := 235;
    
    -- This shared variable represents the bottom position of the ball, calculated as ball_top + ball_Par
    shared variable ball_bot : integer := ball_top + ball_Par;
    
    -- This shared variable represents the left position of the ball, initially set to 315
    shared variable ball_left : integer := 315;
    
    -- This shared variable represents the right position of the ball, calculated as ball_left + ball_Par
    shared variable ball_right : integer := ball_left + ball_Par;
    
    -- This constant represents the speed of the ball
    constant ball_speed : integer := 4;

 
------------------------------------------------- GameFlow Parameters ------------------------------------------------------------------------    
    -- This shared variable represents the start flag, initially set to '1'
    shared variable start_flag : std_logic := '1';
    
    -- This shared variable represents the flag for upward movement of an object, initially set to '0'
    shared variable up_moving_flag : std_logic := '0';
    
    -- This shared variable represents the flag for leftward movement of an object, initially set to '0'
    shared variable left_moving_flag : std_logic := '0';
    
    -- This shared variable represents the game over flag, initially set to '0'
    shared variable GameOver : std_logic := '0';

------------------------------------------------- Score Calculations ------------------------------------------------------------------------        
    shared variable Player1_score : integer := 0;
    shared variable Player2_score : integer := 0;
---------------------------------------------------------------------------------------------------------------------------------------------- 

begin

-- to generate an appropriate clock (25MHz) from the board main clock (100MHz)
clock_generation: process (clk)
begin
    -- Triggered on the rising edge of the "clk" signal
    if (rising_edge(clk)) then 
        -- Increment the counter by 1
        counter := counter + 1; 
        
        -- Check the value of the counter
        if (counter < 2) then
            -- If counter is less than 2, set "clk25" to '0'
            clk25 <= '0';
        elsif (counter < 4) then
            -- If counter is between 2 and 3, set "clk25" to '1'
            clk25 <= '1';
        else 
            -- If counter is 4 or greater, reset the counter to 0
            counter := 0;
            -- Set "clk25" to '0'
            clk25 <= '0';
        end if;
    end if;
end process;


main_process: process (clk25,reset)
    begin

        if (rising_edge(clk25)) then
            hsync <= '1';
            vsync <= '1';
           
            if (horizontal <= 799) and (vertical<= 524 )  then -- Screen area
------------------------------------- Drawing the figures of the paddles and the ball -------------------------------------------------------------------------                            
                if (horizontal < 640) then -- Check if the current position is within the visible area
                    -- Check if the current position is within the range of paddle 1
                    if ( (horizontal >= left_paddle1) and (horizontal <= right_paddle1) and (vertical >= top_paddle1) and (vertical <= bot_paddle1) ) then 
                        R <= "0000";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to maximum intensity
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
                    -- Check if the current position is within the range of paddle 2
                    elsif ((horizontal >= left_paddle2) and (horizontal <= right_paddle2) and (vertical >= top_paddle2) and (vertical <= bot_paddle2)) then 
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "0000";  -- Set G (green) to maximum intensity
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
                    -- Check if the current position is within the range of the ball
                    elsif ( (horizontal >= ball_left and horizontal <= ball_right) and (vertical >= ball_top and vertical <= (ball_top + ball_Par)) ) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
                    elsif (horizontal=0) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
                    elsif (horizontal= 639) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
                    elsif (horizontal>=319 and horizontal <= 321) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
                   elsif ( (horizontal >= 315 and horizontal <= 325) and (vertical >= 235 and vertical <= 245) ) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
  
                   elsif ( (horizontal >= 0 and horizontal <= 639) and vertical =0 ) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
                   elsif ( (horizontal >= 0 and horizontal <= 639) and vertical = 478  ) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
                   elsif ( (horizontal >= 299 and horizontal <= 341) and vertical = 35  ) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)
                   elsif ( (vertical >= 0 and vertical <= 35) and horizontal = 299  ) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off)     
                   elsif ( (vertical >= 0 and vertical <= 35) and horizontal = 341  ) then
                        R <= "1111";  -- Set R (red) to maximum intensity
                        G <= "1111";  -- Set G (green) to minimum intensity (off)
                        B <= "1111";  -- Set B (blue) to minimum intensity (off        
     
                    else
                        R <= "0000";  -- Set R (red) to minimum intensity (off)
                        G <= "0000";  -- Set G (green) to minimum intensity (off)
                        B <= "0000";  -- Set B (blue) to minimum intensity (off)
                    end if;
                    horizontal := horizontal + 1;  -- Increment the horizontal position

------------------------------------------------------------------------------------------------------------------------------------------------------                    
                elsif ( (horizontal <= 655) and (horizontal >= 640) ) then
                    -- Condition: horizontal position is between 640 and 655
                    R <= "0000";  -- Set R to black (no red)
                    G <= "0000";  -- Set G to black (no green)
                    B <= "0000";  -- Set B to black (no blue)
                    horizontal := horizontal + 1;  -- Increment the horizontal position
                elsif ( (horizontal <= 751) and (horizontal >= 656) ) then
                    -- Condition: horizontal position is between 656 and 751
                    hsync <= '0';  -- Set hsync signal to '0'
                    R <= "0000";  -- Set R to black (no red)
                    G <= "0000";  -- Set G to black (no green)
                    B <= "0000";  -- Set B to black (no blue)
                    horizontal := horizontal + 1;  -- Increment the horizontal position
                elsif ( (horizontal < 799) and (horizontal >= 752) ) then
                    -- Condition: horizontal position is between 752 and 798
                    R <= "0000";  -- Set R to black (no red)
                    G <= "0000";  -- Set G to black (no green)
                    B <= "0000";  -- Set B to black (no blue)
                    horizontal := horizontal + 1;  -- Increment the horizontal position
                elsif (horizontal >= 799) then 
                    -- Condition: horizontal position is greater than or equal to 799
                    if (vertical < 524) then
                        -- Check if the vertical position is less than 524
                        vertical := vertical + 1;  -- Increment the vertical position
                        horizontal := 0;  -- Reset the horizontal position to 0
                    else 
                        -- Vertical position is 524 or greater
                        vertical := 0;  -- Reset the vertical position to 0
                        horizontal := 0;  -- Reset the horizontal position to 0
                
---------------------------------------------- Paddles movement -------------------------------------------------------------------------------                        
                        -- This part is for the movement of the first paddle (paddle)
                        if (Player1_up = '1' and Player1_down = '0') then
                            -- If Player1 wants to move the first paddle upward
                            if (top_paddle1 - paddle_speed >= 0) then
                                -- If the top position of the first paddle is greater than 0
                                -- Move the first paddle upward by reducing the top position by paddle_speed
                                top_paddle1 := top_paddle1 - paddle_speed;
                            else 
                                -- If the top position of the first paddle is already at 0
                                -- Keep the top position of the first paddle at 0 (cannot move further upward)
                                top_paddle1 := 0;
                            end if;
                        elsif (Player1_up = '0' and Player1_down = '1') then
                            -- If Player1 wants to move the first paddle downward
                            if (top_paddle1 < (479 - paddle_length) ) then
                                -- If the top position of the first paddle is less than (479 - paddle_length)
                                -- Move the first paddle downward by increasing the top position by paddle_speed
                                top_paddle1 := top_paddle1 + paddle_speed;
                            else
                                -- If the top position of the first paddle is already at the maximum allowable position
                                -- Keep the top position of the first paddle at (479 - paddle_length) (cannot move further downward)
                                top_paddle1 := (479 - paddle_length);
                            end if;
                        end if;
                        
                        -- This part is for the movement of the second paddle (paddle)
                        if (Player2_up = '1' and Player2_down = '0') then
                            -- If Player2 wants to move the second paddle upward
                            if (top_paddle2 - paddle_speed >= 0) then
                                -- If the top position of the second paddle is greater than 0
                                -- Move the second paddle upward by reducing the top position by paddle_speed
                                top_paddle2 := top_paddle2 - paddle_speed;
                            else 
                                -- If the top position of the second paddle is already at 0
                                -- Keep the top position of the second paddle at 0 (cannot move further upward)
                                top_paddle2 := 0;
                            end if;
                        elsif (Player2_up = '0' and Player2_down = '1') then
                            -- If Player2 wants to move the second paddle downward
                            if (top_paddle2 < (479 - paddle_length) ) then
                                -- If the top position of the second paddle is less than (479 - paddle_length)
                                -- Move the second paddle downward by increasing the top position by paddle_speed
                                top_paddle2 := top_paddle2 + paddle_speed;
                            else
                                -- If the top position of the second paddle is already at the maximum allowable position
                                -- Keep the top position of the second paddle at (479 - paddle_length) (cannot move further downward)
                                top_paddle2 := (479 - paddle_length);
                            end if;
                        end if;
 
 --------------------------- The part responsible for resetting the ball postion at the middle --------------------------------------------------------------------                       
            
               if (reset = '0' and start_flag = '1') then
    			-- Condition: If reset is '0' and start_flag is '1'

    start_flag := '0';
    -- Set start_flag to '0' (clear start_flag)

    up_moving_flag := '1';
    -- Set up_moving_flag to '1' (set up_moving_flag)

    left_moving_flag := '0';
    -- Set left_moving_flag to '0' (clear left_moving_flag)

elsif (reset = '1' or GameOver = '1') then
    -- Condition: If reset is '1' or GameOver is '1'

    start_flag := '1';
    -- Set start_flag to '1' (set start_flag)

    GameOver := '0';
    -- Set GameOver to '0' (clear GameOver)

    ball_top := 235;
    -- Set ball_top to 235 (reset ball_top to a specific value)

    ball_left := 315;
    -- Set ball_left to 315 (reset ball_left to a specific value)

end if;

                
-------------------------------- The part responsible for tracing the ball movment -----------------------------------------------------------
                        if (ball_top > (479 - ball_par) ) then 
                            -- Check if the top position of the ball is at the height where it would reflect from the bottom
                            -- If true, set the up_moving_flag to '1' indicating the ball is reflected from the bottom and moves upward
                            up_moving_flag := '1';
                        end if;
                        
                        if (ball_top  < ball_par ) then 
                            -- Check if the top position of the ball is at the height where it would reflect from the top
                            -- If true, set the up_moving_flag to '0' indicating the ball is reflected from the top and moves downward
                            up_moving_flag := '0';
                        end if;
                        
                        if ( (ball_left >= left_paddle2 - ball_Par) and (ball_top <= bot_paddle2) and (ball_bot > top_paddle2) ) then 
                            -- Check if the ball's left position is equal to the right position of paddle 2 minus ball_Par
                            -- and if the ball is within the vertical range of paddle 2
                            -- If true, set the left_moving_flag to '1' indicating the ball is reflected from the right paddle and moves left
                            left_moving_flag := '1';
                        end if;
                        
                        if ( (ball_left <= right_paddle1) and (ball_top <= bot_paddle1) and (ball_bot > top_paddle1) ) then 
                            -- Check if the ball's left position is equal to the right position of paddle 1
                            -- and if the ball is within the vertical range of paddle 1
                            -- If true, set the left_moving_flag to '0' indicating the ball is reflected from the left paddle and moves right
                            left_moving_flag := '0';
                        end if;
                        
                        if (ball_left >= 639 - ball_Par) then 
                            -- Check if the ball's left position reaches the maximum horizontal position (639 minus ball_Par)
                            -- If true, set the GameOver flag to '1' indicating that the game is over (the ball missed the second paddle)
                            GameOver := '1';
                            Player2_score := Player2_score +1;
                        end if;
                        
                        if (ball_left < ball_Par) then 
                            -- Check if the ball's left position reaches the minimum horizontal position (0)
                            -- If true, set the GameOver flag to '1' indicating that the game is over (the ball missed the first paddle)
                            GameOver := '1';
                            Player1_score := Player1_score +1;
                        end if;
                        
                        if (up_moving_flag = '1') then 
                            -- If the up_moving_flag is '1', indicating the ball is moving upward
                            -- Decrease the top position of the ball by ball speed
                            ball_top := ball_top - ball_speed;
                        else
                            -- If the up_moving_flag is '0', indicating the ball is moving downward
                            -- Increase the top position of the ball by ball speed
                            ball_top := ball_top + ball_Speed;
                        end if;
                        
                        if (left_moving_flag = '1') then 
                            -- If the left_moving_flag is '1', indicating the ball is moving left
                            -- Decrease the left position of the ball by ball speed
                            ball_left := ball_left - ball_speed;
                        else 
                            -- If the left_moving_flag is '0', indicating the ball is moving right
                            -- Increase the left position of the ball by ball speed
                            ball_left := ball_left + ball_speed;
                        end if;

                    end if ;
                     
                end if;
            end if;    
          if (vertical >= 480 and vertical <= 489) then
                -- Check if the vertical position is within the range of 480 to 489
                R <= "0000";  -- Set R (red) to minimum intensity (off)
                G <= "0000";  -- Set G (green) to minimum intensity (off)
                B <= "0000";  -- Set B (blue) to minimum intensity (off)
            elsif (vertical >= 490 and vertical <= 491) then 
                -- Check if the vertical position is within the range of 490 to 491
                R <= "0000";  -- Set R (red) to minimum intensity (off)
                G <= "0000";  -- Set G (green) to minimum intensity (off)
                B <= "0000";  -- Set B (blue) to minimum intensity (off)
                vsync <= '0';  -- Set vsync signal to '0' (vertical sync)
            elsif (vertical >= 492 and vertical <= 524) then
                -- Check if the vertical position is within the range of 492 to 524
                R <= "0000";  -- Set R (red) to minimum intensity (off)
                G <= "0000";  -- Set G (green) to minimum intensity (off)
                B <= "0000";  -- Set B (blue) to minimum intensity (off)
            end if;

        end if;
    end process;
end Behavioral;
