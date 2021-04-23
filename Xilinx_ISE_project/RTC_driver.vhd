----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		Hamid Reza Tanhaei
-- 
-- Create Date:    2020 
-- Design Name: 
-- Module Name:    RTC_driver - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity RTC_driver is
    Port ( clk, RTC_Din : in  STD_LOGIC;
           RtcEn, RtcClk, RTC_Dout, RtcWE : out  STD_LOGIC;
		   hour_up, min_up, sec_rst  : in std_logic;
		   BCD_S1 : out unsigned(3 downto 0);
		   BCD_S2 : out unsigned(3 downto 0);
		   BCD_M1 : out unsigned(3 downto 0);
		   BCD_M2 : out unsigned(3 downto 0);
		   BCD_H1 : out unsigned(3 downto 0);
		   BCD_H2 : out unsigned(3 downto 0));
end RTC_driver;

architecture Behavioral of RTC_driver is
	signal cntr : unsigned(20 downto 0) := (others => '0');
	signal cntr_del : std_logic := '0';
	signal clkEn  : std_logic := '0';
	signal RtcEn_int : std_logic := '0';
	signal time_changed : std_logic := '0';

	signal RTC_cmd : unsigned(15 downto 0) := (others => '0');
	signal RTC_dat : unsigned(23 downto 0):= (others => '0');
	signal addr, value : unsigned(7 downto 0) := (others => '0');
	signal bcd_hour1, bcd_hour2, bcd_min1, bcd_min2, bcd_sec1, bcd_sec2 : unsigned(3 downto 0) := (others=>'0');
	signal bcd_hour1_draft, bcd_hour2_draft, bcd_min1_draft, bcd_min2_draft : unsigned(3 downto 0) := (others=>'0');
	signal min_chng_cntdown, hour_chng_cntdown : integer range 0 to 2000000 := 0;

begin
	
	BCD_S1 <= bcd_sec1;
	BCD_S2 <= bcd_sec2;
	BCD_M1 <= bcd_min1;
	BCD_M2 <= bcd_min2;
	BCD_H1 <= bcd_hour1;
	BCD_H2 <= bcd_hour2;
	
	RtcEn <= RtcEn_int;
	clkEn <= RtcEn_int and (not cntr_del) AND cntr(3) and (not cntr(4));
	RtcClk <= RtcEn_int AND cntr(4);
	process(clk)
	
	begin
		if rising_edge(clk) then
			
			if (clkEn = '1') then
				RTC_Dout <= RTC_cmd(0);
				RTC_cmd <= '0' & RTC_cmd(15 downto 1);
				RTC_dat <= RTC_Din & RTC_dat(23 downto 1);
				--rtc_din_test <= RTC_Din;
			end if;
			
			cntr_del <= cntr(3);
			cntr <= cntr + 1;
			
			case cntr is
				when "100000000000000000000" =>	-- Reading/writing start
					RtcEn_int <= '1';
					RtcWE <= '1';
					if (time_changed = '0') then -- reading
						RTC_cmd <= "0000000010111111"; -- burst read 3 bytes sec/min/hour
					else
						RTC_cmd <= value & addr;  -- writing
					end if;
				when "100000000000100000000" =>	-- Command end / getting Data start
					if (time_changed = '0') then -- when reading
						RtcWE <= '0';
					end if;
				when "100000000001000000000" => -- Writing stop
					if (time_changed = '1') then
						RtcEn_int <= '0';
						RtcWE <= '0';
						time_changed <= '0';
						cntr <= (others => '0');
					end if;
				when "100000000010000000000" =>	-- Reading stop
					RtcEn_int <= '0';
					cntr <= (others => '0');
					bcd_sec1 <= RTC_dat(3 downto 0);
					bcd_sec2 <= RTC_dat(7 downto 4);
					bcd_min1 <= RTC_dat(11 downto 8);
					bcd_min2 <= RTC_dat(15 downto 12);
					bcd_hour1 <= RTC_dat(19 downto 16);
					bcd_hour2 <= RTC_dat(23 downto 20);
				
				when others =>
			
			end case;

			--------
			if (sec_rst = '0') then
				addr 	<= "10000000";
				value 	<= "00000000";
				time_changed <= '1';
			end if;
			---------
			if ((hour_chng_cntdown = 0) and (hour_up = '0')) then -- Key1
				bcd_hour1_draft <= bcd_hour1 + 1;
				bcd_hour2_draft <= bcd_hour2;
				hour_chng_cntdown <= 2000000;
			end if;
			if (bcd_hour1_draft > 9) then
				bcd_hour1_draft <= "0000";
				bcd_hour2_draft <= bcd_hour2_draft + 1;
			end if;
			if (bcd_hour2_draft = 2 and bcd_hour1_draft > 3) then
				bcd_hour1_draft <= "0000";
				bcd_hour2_draft <= "0000";
			end if;
			if (hour_chng_cntdown = 10) then
				addr <= "10000100";
				value <= bcd_hour2_draft & bcd_hour1_draft;
				time_changed <= '1';
			end if;
			if (hour_chng_cntdown /= 0) then
				hour_chng_cntdown <= hour_chng_cntdown - 1;
			end if;
			-------
			if ((min_chng_cntdown = 0) and (min_up = '0')) then -- Key2
				bcd_min1_draft <= bcd_min1 + 1;
				bcd_min2_draft <= bcd_min2;
				min_chng_cntdown <= 2000000;
			end if;	
			if (bcd_min1_draft > 9) then
				bcd_min1_draft <= "0000";
				bcd_min2_draft <= bcd_min2_draft + 1;
			end if;
			if (bcd_min2_draft > 5) then
				bcd_min1_draft <= "0000";
				bcd_min2_draft <= "0000";
			end if;
			if (min_chng_cntdown = 10) then
				addr <= "10000010";
				value <= bcd_min2_draft & bcd_min1_draft;
				time_changed <= '1';
			end if;
			if (min_chng_cntdown /= 0) then
				min_chng_cntdown <= min_chng_cntdown - 1;
			end if;
			-----
		end if;
	end process;

end Behavioral;

---------------------------------------------------------------------------------
