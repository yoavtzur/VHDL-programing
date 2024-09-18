LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--USE work.aux_package.all;
-------------------------------------
ENTITY shifter IS
	GENERIC (n : INTEGER := 32;
			 k : INTEGER := 5);
	PORT 
	(
		Y_i: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		X_i: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		mode: IN STD_LOGIC;

		s: OUT STD_LOGIC_VECTOR(31 downto 0)
	);
END shifter;

-------------------------------------

ARCHITECTURE shifter_arch OF shifter IS 
	SUBTYPE vector is STD_LOGIC_VECTOR(n-1 DOWNTO 0);
	TYPE matrix IS ARRAY (k DOWNTO 0) OF vector;
	SIGNAL row: matrix;
BEGIN
	G1: FOR j in 0 TO n-1 GENERATE
		WITH mode SELECT
			row(0)(j) <= Y_i(j) WHEN '0',
							Y_i(n-1-j) WHEN '1',
							'0' WHEN OTHERS;
	END GENERATE;
	
	G3: FOR i in 1 TO k GENERATE
		G4: FOR j in 0 TO n-1 GENERATE
			C1: IF (j<2**(i-1)) GENERATE
				row(i)(j) <= row(i-1)(j) AND NOT X_i(i-1);
			END GENERATE;
			
			C2: IF (j>=2**(i-1)) GENERATE
				row(i)(j) <= (row(i-1)(j) AND NOT X_i(i-1)) OR (row(i-1)(j-2**(i-1)) AND X_i(i-1));
			END GENERATE;
		END GENERATE;
	END GENERATE;
	
	G5: FOR j in 0 TO n-1 GENERATE
		WITH mode SELECT
			s(j) <= row(k)(j) WHEN '0',
					row(k)(n-1-j) WHEN OTHERS;
	END GENERATE;

	
END shifter_arch;