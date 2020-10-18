----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		Hamid Reza Tanhaei
-- 
-- Create Date:    01/01/2020 
-- Design Name: 	
-- Module Name:    Main - Behavioral 
-- Project Name: 	Alinx AX309 RTC UART Test
-- Target Devices: 	Xilinx FPGA SPARTAN6 XC6SLX9 (FTG256 package)
-- Tool versions: 
-- Description:A sample project for driving RTC (Real Time Clock) 
-- and UART for evaluation board Alinx-AX309 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--	Xilinx ISE 14.7
----------------------------------------------------------------------------------

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--------   Library and Packages   -----------
LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
--use ieee.numeric_std.all;
--------   Interface or Entity   ------------
Entity Main is
  port (
    reset, clk, hour_up, min_up, sec_rst  : in std_logic;
	 to_LED : out std_logic_vector(6 downto 0);
	 Selected_digit : buffer std_logic_vector(5 downto 0);
	 Dot : out std_logic;
	 RTC_io : inout std_logic;
	 RTC_En : buffer std_logic;
	 RTC_clk : out std_logic;
	 TXD : out std_logic
	 );
	 
End Main;
--------   Architecture or Body  ------------
Architecture Behavioral of Main is
		signal	BCD_input, bcd_S1, bcd_S2, bcd_M1, bcd_M2, bcd_H1, bcd_H2 : std_logic_vector(3 downto 0) := "0000";
		signal	RTC_Dout : std_logic;
		signal	RTC_we	: std_logic := '0';
Begin

	RTC_io <= RTC_Dout when RTC_we='1' else 'Z'; -- when RTC_we='0';
 with Selected_digit select
	Dot <= 	'1'	when "111110",
			'1'	when "111101",
			'0'	when "111011",
			'1'	when "110111",
			'0'	when "101111",
			'1'	when "011111",
			'1' when others;
	----------
  with BCD_input select
	to_LED <= 	"0000001" when "0000",  -- 0
				"1001111" when "0001",  -- 1
				"0010010" when "0010",	-- 2			 
				"0000110" when "0011",	-- 3			 
				"1001100" when "0100",	-- 4			 
				"0100100" when "0101",	-- 5			 
				"0100000" when "0110",	-- 6			 
				"0001111" when "0111",	-- 7			 
				"0000000" when "1000",	-- 8			 
				"0000100" when "1001",	-- 9			 
				--	"0000010" when "1010",	-- A			 
				--	"1100000" when "1011",	-- B			 
				--	"0110001" when "1100",	-- C			 
				--	"1000010" when "1101",	-- D			 
				--	"0110000" when "1110",	-- E			 
				--	"0111000" when "1111",	-- F
				"1111110" when others; -- dash	
-----------------------------------
  with Selected_digit select
	BCD_input <= bcd_S1	when "111110",
				 bcd_S2	when "111101",
				 bcd_M1	when "111011",
				 bcd_M2	when "110111",
				 bcd_H1	when "101111",
				 bcd_H2	when "011111",
				 "0000" when others;
--------------------------------------------------------------------------
process(clk)
	variable temp1 		: integer range 0 to 10000001 := 0;
	variable temp2 		: integer range 0 to 100001 := 0;
	variable temp3 		: integer range 0 to 400 := 0;
	variable uart_br 	: integer range 0 to 1000 := 0; -- for 57600 => 868clk
	variable uart_bit_cntr 	: integer range 0 to 15 := 0;
	variable uart_byte_cntr 	: integer range 0 to 63 := 0;
	variable uart_timeout 	: integer range 0 to 200000000 := 0;
	variable uart_tx_en 	: std_logic;
	variable UART_TX_Buff 	: std_logic_vector(7 downto 0) := "00000000";
	
	variable sweeper 	: std_logic_vector(5 downto 0):= "111110";
	variable bcd_sec1 	: std_logic_vector(3 downto 0) := "0000";
	variable bcd_sec2 	: std_logic_vector(3 downto 0) := "0000";
	variable bcd_min1 	: std_logic_vector(3 downto 0) := "0000";
	variable bcd_min2 	: std_logic_vector(3 downto 0) := "0000";
	variable bcd_hour1 	: std_logic_vector(3 downto 0) := "0000";
	variable bcd_hour2 	: std_logic_vector(3 downto 0) := "0000";
	variable RTC_cmd 	: std_logic_vector(7 downto 0) := "00000000";
	variable RTC_dat 	: std_logic_vector(7 downto 0) := "00000000";
	variable byte_cntr	: integer range 0 to 100 :=0;
	variable time_changed : std_logic;
	variable addr, value : std_logic_vector(7 downto 0); 
  begin
	if(rising_edge(clk))then
		--
		
		if (reset = '0') then
			temp1 := 0;
			temp2 := 0;
			temp3 := 0;
			uart_br := 0;
			--temp4 := 0;
			--temp5 := 0;
			RTC_we <= '0';
			RTC_clk <= '0';
			RTC_En <= '0';
		end if;
		----------------------------------
		--- UART transmiting the time result of rtc
		uart_timeout := uart_timeout + 1;
		if (uart_timeout > 100000000) then -- uart transmiting every 2sec -> 100000000 * 20ns(5MHz)
			uart_timeout := 0;
			uart_tx_en := '1';
		end if;
		if (uart_tx_en = '1') then
			uart_br := uart_br + 1;
			if (uart_br > 868) then -- baudrate : 57600bps -> 868 * 20ns
				uart_br := 0;
				uart_bit_cntr := uart_bit_cntr + 1;
				if (uart_bit_cntr > 10) then
					uart_bit_cntr := 0;
					if (uart_byte_cntr >= 10) then
						uart_byte_cntr := 0;
						uart_tx_en := '0';
					end if;
					uart_byte_cntr := uart_byte_cntr + 1;
					
				end if;
				if (uart_bit_cntr = 0) then
					TXD <= '1'; -- stop bit
					if 	  (uart_byte_cntr = 1) then
						UART_TX_Buff := ("0000" & bcd_hour2) + "00110000"; -- convert number to ASCII
					elsif (uart_byte_cntr = 2) then
						UART_TX_Buff := ("0000" & bcd_hour1) + "00110000";
					elsif (uart_byte_cntr = 3) then
						UART_TX_Buff := "00111010"; -- char ":"
					elsif (uart_byte_cntr = 4) then
						UART_TX_Buff := ("0000" & bcd_min2) + "00110000";
					elsif (uart_byte_cntr = 5) then
						UART_TX_Buff := ("0000" & bcd_min1) + "00110000";
					elsif (uart_byte_cntr = 6) then
						UART_TX_Buff := "00111010"; -- char ":"
					elsif (uart_byte_cntr = 7) then
						UART_TX_Buff := ("0000" & bcd_sec2) + "00110000";
					elsif (uart_byte_cntr = 8) then
						UART_TX_Buff := ("0000" & bcd_sec1) + "00110000";
					elsif (uart_byte_cntr = 9) then
						UART_TX_Buff := "00001010"; -- LF
					elsif (uart_byte_cntr = 10) then
						UART_TX_Buff := "00001101"; -- CR
					end if;
					------	
				elsif (uart_bit_cntr = 1) then
					TXD <= '0'; -- start bit
				elsif (uart_bit_cntr = 10) then
					TXD <= '1'; -- stop bit
				elsif (uart_bit_cntr > 1 and uart_bit_cntr < 10) then
					TXD <= UART_TX_Buff(0);
					UART_TX_Buff := '0' & UART_TX_Buff(7 downto 1);
				end if;
				
			end if;
		end if;
		-------------------
		temp1 := temp1 + 1;
		temp2 := temp2 + 1;
		temp3 := temp3 + 1;
		------
		-- sweep between 6 7segments:
		if (temp2 >= 100000) then -- every 2msec
			temp2 := 0;
			sweeper := sweeper(0) & sweeper(5 downto 1);
			Selected_digit <= sweeper;
				BCD_S1 <= bcd_sec1;
				BCD_S2 <= bcd_sec2;
				BCD_M1 <= bcd_min1;
				BCD_M2 <= bcd_min2;
				BCD_H1 <= bcd_hour1;
				BCD_H2 <= bcd_hour2;
		end if;
		--------
		-- RTC:
		if (temp1 >= 10000000) then -- sampling the rtc time every 200msec
			----- changing the time using buttons:
			if (hour_up = '0') then -- Key1
				bcd_hour1 := bcd_hour1 + 1;
				if (bcd_hour1 > 9) then
					bcd_hour1 := "0000";
					bcd_hour2 := bcd_hour2 + 1;
				end if;
				if (bcd_hour2 = 2 and bcd_hour1 > 3) then
					bcd_hour1 := "0000";
					bcd_hour2 := "0000";
				end if;
				addr := "10000100";
				value := bcd_hour2 & bcd_hour1;
				time_changed := '1';
			end if;
			------ 
			if (min_up = '0') then -- Key2
				bcd_min1 := bcd_min1 + 1;
				if (bcd_min1 > 9) then
					bcd_min1 := "0000";
					bcd_min2 := bcd_min2 + 1;
					if (bcd_min2 > 5) then
						bcd_min1 := "0000";
						bcd_min2 := "0000";
					end if;
					
				end if;
				addr := "10000010";
				value := bcd_min2 & bcd_min1;
				time_changed := '1';
			end if;
			-------
			if (sec_rst = '0') then -- Key3
				bcd_sec1 := "0000";
				bcd_sec2 := "0000";
				addr  := "10000000";
				value := "00000000";
				time_changed := '1';
			end if;
			-------
			temp1 := 0;
			temp3 := 0;
			RTC_En <= '1';
			byte_cntr := 0;
			RTC_we <= '1';
		end if;
		------
		--- Appling the changed time into RTC:
			if (temp3 = 100 and RTC_En = '1' and time_changed = '1') then -- 500KHz RTC clock
			byte_cntr := byte_cntr + 1;
			if (byte_cntr = 1) then
				RTC_cmd := addr;
			end if;
			RTC_clk <= '0';
			if (byte_cntr = 9) then
				RTC_cmd := value; -- "00000000";
			end if;
			RTC_Dout <= RTC_cmd(0);
			if (byte_cntr > 16) then
				RTC_clk <= '0';
				byte_cntr := 0;
				RTC_En <= '0';
				time_changed := '0';
			end if;
			RTC_cmd := '0' & RTC_cmd(7 downto 1);
		end if;
		if (temp3 = 200 and RTC_En = '1' and time_changed = '1') then
			RTC_clk <= '1';
			temp3 := 0;
		end if;
		
		---- Reading the time out of RTC DS1302
		if (temp3 = 100 and RTC_En = '1' and time_changed = '0') then -- 500KHz RTC clock
			RTC_clk <= '0';
			byte_cntr := byte_cntr + 1;
			if (byte_cntr = 1) then
				RTC_cmd := "10111111"; -- burst read 3 bytes sec/min/hour
			end if;
			if (byte_cntr > 8) then
				RTC_we <= '0';
			end if;
			RTC_Dout <= RTC_cmd(0);
		end if;
		-------
		if (temp3 = 200 and RTC_En = '1' and time_changed = '0') then
			RTC_clk <= '1';
			RTC_dat := RTC_io & RTC_dat(7 downto 1);
			RTC_cmd := '0' & RTC_cmd(7 downto 1);
			temp3 := 0;
			if (byte_cntr = 16) then
				bcd_sec1 := RTC_dat(3 downto 0);
				bcd_sec2 := RTC_dat(7 downto 4);
			end if;
			if (byte_cntr = 24) then
				bcd_min1 := RTC_dat(3 downto 0);
				bcd_min2 := '0' & RTC_dat(6 downto 4);
			end if;
			if (byte_cntr = 32) then
				RTC_clk <= '0';
				byte_cntr := 0;
				RTC_En <= '0';
				bcd_hour1 := RTC_dat(3 downto 0);
				bcd_hour2 := "00" & RTC_dat(5 downto 4);
			end if;
			
		end if;
		-------
	end if;
  
  end process;

--------------------------------------------------------------------------  
end Behavioral;




