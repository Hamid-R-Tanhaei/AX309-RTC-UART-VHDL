----------------------------------------------------------------------------------
-- Company: 
-- Engineer:   Hamid Reza Tanhaei
-- 
-- Create Date:     2020 
-- Design Name: 
-- Module Name:    UART - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
---------------------------
entity UART is
	port
	(
		clock		: in std_logic;
		bcd_hour2, bcd_hour1, bcd_min2, bcd_min1, bcd_sec2, bcd_sec1 : in unsigned(3 downto 0);
		TXD 		: out std_logic
	);

end UART;

architecture Behavioral of UART is

	signal time_interval 	: integer range 0 to 200000 := 0;
	signal uart_br 			: integer range 0 to 63 	:= 0;
	signal bit_cntr 		: integer range 0 to 10 	:= 0;
	signal byte_cntr 		: integer range 0 to 10 	:= 0;
	signal tx_en 			: std_logic := '0';
	--signal UART_TX_Byte 	: unsigned(7 downto 0) := (others => '0');
	signal UART_TX_Buffer 	: unsigned(9 downto 0) := (others => '0');

begin

process(clock)

begin
	if(rising_edge(Clock))then

		--- UART transmiting the time bytes of rtc
		uart_br <= uart_br + 1;
		if (uart_br = 62) then -- baudrate : 115200bps -> 62 * 140ns
			uart_br <= 0;
			time_interval <= time_interval + 1;
			if (time_interval = 200000) then
				time_interval 	<= 0;
				tx_en 			<= '1';
				bit_cntr 		<= 0;
				byte_cntr 		<= 0;
			end if;
		end if;
		-----------
		if (tx_en = '1' and uart_br = 0) then -- Baudrate tick @ 115200
			TXD	<=	UART_TX_Buffer(0);
			UART_TX_Buffer <= '0' & UART_TX_Buffer(9 downto 1);
			bit_cntr <= bit_cntr + 1;
			if (bit_cntr = 9) then
				case	byte_cntr is			-- (Stop-bit + Byte + start-bit)	
					when 0 =>	UART_TX_Buffer <= ("10011" & bcd_hour2 & '0'); -- Adding with "00110000" to convert number to ASCII
					when 1 =>	UART_TX_Buffer <= ("10011" & bcd_hour1 & '0');
					when 2 =>	UART_TX_Buffer <= ('1' & X"3A" & '0');	-- char ":"
					when 3 =>	UART_TX_Buffer <= ("10011" & bcd_min2 & '0');
					when 4 =>	UART_TX_Buffer <= ("10011" & bcd_min1 & '0');
					when 5 =>	UART_TX_Buffer <= ('1' & X"3A" & '0');	-- char ":"
					when 6 =>	UART_TX_Buffer <= ("10011" & bcd_sec2 & '0');
					when 7 =>	UART_TX_Buffer <= ("10011" & bcd_sec1 & '0');
					when 8 =>	UART_TX_Buffer <= ('1' & X"0A" & '0'); -- LF
					when 9 =>	UART_TX_Buffer <= ('1' & X"0D" & '0'); -- CR
					when others =>  UART_TX_Buffer <= ('1' & X"00" & '0'); -- 0
				end case;

				bit_cntr <= 0;
				byte_cntr <= byte_cntr + 1;
				if (byte_cntr = 9) then
					byte_cntr <= 0;
					tx_en <= '0';
				end if;
			end if;
		end if;
	end if;
end process;
end Behavioral;
-----------------------------------------------------------------------------------
