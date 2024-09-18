LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
-----------------------------------------------------------------
ENTITY BidirPin IS
	GENERIC( WIDTH: INTEGER:=16 );
	PORT(   Dout: 	IN 		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
			en:		IN 		STD_LOGIC;
			Din:	OUT		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
			IOpin: 	INOUT 	STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)
	);
END BidirPin;

ARCHITECTURE comb OF BidirPin IS
BEGIN 

	Din   <= IOpin;
	IOpin <= Dout WHEN(en='1') ELSE (OTHERS => 'Z');
	
END comb;