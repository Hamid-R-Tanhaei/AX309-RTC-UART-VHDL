----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		Hamid Reza Tanhaei
-- 
-- Create Date:    2020 
-- Design Name: 	
-- Module Name:    Main - Behavioral 
-- Project Name: 	Alinx AX309 RTC UART Test
-- Target Devices: 	Xilinx FPGA SPARTAN6 XC6SLX9 (FTG256 package)
-- Tool versions: 
-- Description:A sample project for driving RTC (Real Time Clock) 
-- and UART for evaluation board Alinx-AX309 
-- Additional Comments: 
--	Xilinx ISE 14.7
----------------------------------------------------------------------------------
--------   Library and Packages   -----------
LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
--------   Interface or Entity   ------------
Entity Main is
  port (
		 Clock, hour_up, min_up, sec_rst  : in std_logic;
		 to_LED : out unsigned(6 downto 0);
		 Selected_digit : out unsigned(5 downto 0);
		 Dot : out std_logic;
		 RTC_io : inout std_logic;
		 RTC_En : out std_logic;
		 RTC_clk : out std_logic;
		 TXD : out std_logic
	   );
End Main;
--------   Architecture or Body  ------------
Architecture Behavioral of Main is
	signal	bcd_S1, bcd_S2, bcd_M1, bcd_M2, bcd_H1, bcd_H2 : unsigned(3 downto 0) := "0000";
	signal	RTC_Dout, rtc_din_test : std_logic;
	signal	RTC_we, RTC_En_int, RTC_clk_int	: std_logic := '0';
	signal	clk_50M, clk_5M, clk_7M : std_logic;
	--signal	data_ila : std_logic_vector(7 downto 0) := (others => '0');
	--signal	trig_ila : std_logic :='0';
	--signal	control_icon : std_logic_vector(35 downto 0);
	----------------------
-----------------------------------------
Begin

	-----------------
	DCM_inst : entity  work.DCM_CLOCK
	  port map
	   (-- Clock in ports
		CLK_IN_50M => Clock, 	-- input clock from osillator
		-- Clock out ports
		CLK_50M => CLK_50M,		-- output main clock
		CLK_7M => CLK_7M,		-- clock 7.143MHz for UART timing
		CLK_5M => CLK_5M);		-- clock for RTC interfacing
	---------------

--	icon_inst : entity work.chipscope_icon
--	port map (
--    CONTROL0 => control_icon);
--	-------------------
--	ila_inst : entity work.chipscope_ila
--	port map (
--    CONTROL => control_icon,
--    CLK => clk_5M,
--    DATA => data_ila,
--    TRIG0(0) => trig_ila);
	-----------------------
	uart_handler: entity work.UART
		port map
		(
			clock => clk_7M,
			bcd_hour2 => bcd_H2,
			bcd_hour1 => bcd_H1,
			bcd_min2 => bcd_M2,
			bcd_min1 => bcd_M1,
			bcd_sec2 => bcd_S2,
			bcd_sec1 => bcd_S1,
			TXD => TXD);
	----------------------------
	sevent_seg: entity work.Seven_segment
		port map
		(
			clock => clk_5M,
			bcd_S1 => bcd_S1,
			bcd_S2 => bcd_S2,
			bcd_M1 => bcd_M1,
			bcd_M2 => bcd_M2,
			bcd_H1 => bcd_H1,
			bcd_H2 => bcd_H2,
			to_LED => to_LED,
			Selected_digit => Selected_digit,
			Dot => Dot
		);
	----------------------------
	RTC_clk <= RTC_clk_int;
	RTC_En <= RTC_En_int;
	RTC_io <= RTC_Dout when RTC_we='1' else 'Z'; -- when RTC_we='0';
	--data_ila <= (RTC_En_int & RTC_clk_int & RTC_we & RTC_io & rtc_din_test & RTC_Dout & "00");
	--trig_ila <= RTC_En_int;
	------------------
	Inst_RTC_driver: entity work.RTC_driver PORT MAP(
		clk => clk_5M,
		RTC_Din => RTC_io,
		
		RtcEn => RTC_En_int,
		RtcClk => RTC_clk_int,
		RTC_Dout => RTC_Dout,
		RtcWE => RTC_we,
		hour_up => hour_up,
		min_up => min_up,
		sec_rst => sec_rst,
		
		BCD_S1 => BCD_S1,
		BCD_S2 => BCD_S2,
		BCD_M1 => BCD_M1,
		BCD_M2 => BCD_M2,
		BCD_H1 => BCD_H1,
		BCD_H2 => BCD_H2
	);

--  
end Behavioral;
-------------------------------------------------------------------------
-------------------------------------------------------------------------
