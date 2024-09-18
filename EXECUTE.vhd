--  Execute module (implements the data ALU and Branch Address Adder  
--  for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
--use ieee.numeric_std.all;

ENTITY  Execute IS
	PORT(	Read_data_1 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Read_data_2 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Shamt 			: IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			Sign_extend 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Zero_extend     : IN    STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Function_opcode : IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
			ALUOp 			: IN 	STD_LOGIC_VECTOR( 3 DOWNTO 0 );
			ALUSrc 			: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			Zero 			: OUT	STD_LOGIC;
			ALU_Result 		: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Add_Result 		: OUT	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			PC_plus_4 		: IN 	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			clock, reset	: IN 	STD_LOGIC );
END Execute;

ARCHITECTURE behavior OF Execute IS
	SIGNAL Ainput, Binput 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL ALU_output_mux, Shift_output		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Mul_output			: STD_LOGIC_VECTOR( 63 DOWNTO 0 );
	SIGNAL Branch_Add 			: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL ALU_ctl				: STD_LOGIC_VECTOR( 3 DOWNTO 0 );
	SIGNAL isSR					: STD_LOGIC;

	COMPONENT shifter IS
		GENERIC (n : INTEGER := 32;
				k : INTEGER := 5);
		PORT 
		(
			Y_i: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
			X_i: IN STD_LOGIC_VECTOR (k-1 DOWNTO 0);
			mode: IN STD_LOGIC;
			s: OUT STD_LOGIC_VECTOR(n-1 downto 0)
		);
	END COMPONENT;

BEGIN
	--isSR <= '1'  WHEN  (ALUOp = "1010")  ELSE '0';
	Shftr: shifter GENERIC MAP (32,5) port map(Binput,Shamt, isSR, Shift_output);
	Ainput <= Read_data_1;
						-- ALU input mux
	Binput <= Sign_extend( 31 DOWNTO 0 ) WHEN ( ALUSrc = "01" ) ELSE
			  Zero_extend( 31 DOWNTO 0 ) WHEN ( ALUSrc = "10" ) ELSE
		  	  Read_data_2;
						-- Generate ALU control bits
	-- ALU_ctl( 0 ) <= ( Function_opcode( 0 ) OR Function_opcode( 3 ) ) AND ALUOp(1 );
	-- ALU_ctl( 1 ) <= ( NOT Function_opcode( 2 ) ) OR (NOT ALUOp( 1 ) );
	-- ALU_ctl( 2 ) <= ( Function_opcode( 1 ) AND ALUOp( 1 )) OR ALUOp( 0 );
	
	PROCESS (ALUOp)
		BEGIN 
			if (ALUOp = "1010") then
				isSR <= '1';
			else 
				isSR <= '0';
			end if;
	end process;

	PROCESS (ALUOp, Function_opcode)
		BEGIN
		CASE ALUOp IS
			WHEN "0010" 	=> --R-type
				ALU_ctl( 0 ) <= ( Function_opcode( 0 ) OR Function_opcode( 3 ) ) AND ALUOp(1 );
				ALU_ctl( 1 ) <= ( NOT Function_opcode( 2 ) ) OR (NOT ALUOp( 1 ) );
				ALU_ctl( 2 ) <= ( Function_opcode( 1 ) AND ALUOp( 1 )) OR ALUOp( 0 );
			    ALU_ctl( 3 ) <= ALUOp( 3 );
			-- I-type:
			WHEN "0000" 	=> -- ADDI
				ALU_ctl <= "0010";
				
			WHEN "1111" 	=> -- ADDU (move)
				ALU_ctl <= "0010";	
			
			WHEN "0100"  => -- SUB (for branch equal)
				ALU_ctl <= "0110";

			WHEN "0011"  => -- ANDI
				ALU_ctl <= "0000";
			
			WHEN "1100"  => -- ORI
				ALU_ctl <= "0001";
			
			WHEN "0101"  => -- XORI
				ALU_ctl <= "0100";

			WHEN "1101"  => -- MUL
				ALU_ctl <= "0011";

			WHEN "1010"  => -- srl
				ALU_ctl <= "1000";

			WHEN "1011"  => -- sll
				ALU_ctl <= "1001";
			
			WHEN "0110"  => -- SLTI (set less than)
				ALU_ctl <= "0111";
			
			WHEN "1000" 	=> -- Lui
				ALU_ctl <= "1111";
				
			WHEN OTHERS	=>
				ALU_ctl <= "1010";
			
			END CASE;
	
	END PROCESS;

						-- Generate Zero Flag
	Zero <= '1' 
		WHEN ( ALU_output_mux( 31 DOWNTO 0 ) = X"00000000"  )
		ELSE '0';    
						-- Select ALU output        
	ALU_result <= X"0000000" & B"000"  & ALU_output_mux( 31 ) 
		WHEN    ALU_ctl = "0111" 
		ELSE  	ALU_output_mux( 31 DOWNTO 0 );
						-- Adder to compute Branch Address
	Branch_Add	<= PC_plus_4( 9 DOWNTO 2 ) +  Sign_extend( 7 DOWNTO 0 ) ;
		Add_result 	<= Branch_Add( 7 DOWNTO 0 );

	Mul_output <= Ainput *Binput;

PROCESS ( ALU_ctl, Ainput, Binput, Mul_output, Shamt, Shift_output)
	BEGIN
					-- Select ALU operation
 	CASE ALU_ctl IS
		
	    -- ALU performs ALUresult = A_input AND B_input
		WHEN "0000" 	=>	ALU_output_mux 	<= Ainput AND Binput; 
		
		-- ALU performs ALUresult = A_input OR B_input
		WHEN "0001" 	=>	ALU_output_mux 	<= Ainput OR Binput;
		
		-- ALU performs ALUresult = A_input + B_input
		WHEN "0010" 	=>	ALU_output_mux 	<= Ainput + Binput;
						
		-- ALU performs    Lui
		WHEN "1111" 	=>	ALU_output_mux <= Binput(15 DOWNTO 0) & X"0000";
		
		-- ALU performs ALUresult = A_input XOR B_input
 	 	WHEN "0100" 	=>	ALU_output_mux 	<= Ainput XOR Binput;
		
		-- ALU performs ALUresult = A_input * B_input
 	 	WHEN "0011" 	=>	
			ALU_output_mux 	<= Mul_output(31 downto 0);
		
		-- ALU performs ALUresult = A_input -B_input
 	 	WHEN "0110" 	=>	ALU_output_mux 	<= Ainput - Binput;
		
		-- ALU performs SLT
  	 	WHEN "0111" 	=>	ALU_output_mux 	<= Ainput - Binput ;

		-- ALU performs ALUresult = B_input >> shamt
		WHEN "1000" 	=>	ALU_output_mux 	<= Shift_output;

		-- ALU performs ALUresult = B_input << shamt
		WHEN "1001" 	=>	ALU_output_mux 	<= Shift_output;
 	
		WHEN OTHERS	=>	ALU_output_mux 	<= X"00000000" ;
  	END CASE;
  END PROCESS;
END behavior;

