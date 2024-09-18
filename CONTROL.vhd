		-- control module (implements MIPS control unit)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY control IS
   PORT( 	
	Opcode 	    	: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	INTR			: IN 	STD_LOGIC;
	INTA			: OUT 	STD_LOGIC;
	Function_opcode	: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	RS              : IN    STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	RegDst 		    : OUT 	STD_LOGIC_VECTOR( 2 DOWNTO 0 );
	ALUSrc 			: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	MemtoReg 	    : OUT 	STD_LOGIC;
	RegWrite     	: OUT 	STD_LOGIC;
	MemRead 		: OUT 	STD_LOGIC;
	MemWrite 	    : OUT 	STD_LOGIC;
	Branch 	    	: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	Jump   			: OUT   STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	ALUop 		    : OUT 	STD_LOGIC_VECTOR( 3 DOWNTO 0 );
	TYPEtoPC		: OUT   STD_LOGIC;
	clock, reset	: IN 	STD_LOGIC );

END control;

ARCHITECTURE behavior OF control IS

	SIGNAL  R_format, Lw, Sw, Addi, Andi, Xori , Slti, Ori, Bne, Beq, Mul, ShiftLL, ShiftRL, JmpO, move , Lui, jmpR, Jal, Reti 	: STD_LOGIC;
	SIGNAL 	dis, INT_cyc1, INT_cyc2, prev_INTR 	: STD_LOGIC;
	SIGNAL 	INT_counter 				: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
    --SIGNAL       : STD_LOGIC_VECTOR( 1 DOWNTO 0 );

BEGIN           
				-- Code to generate control signals using opcode bits
	R_format 	<=  '1'  WHEN  Opcode = "000000"  ELSE '0';
	Lw          <=  '1'  WHEN  Opcode = "100011"  ELSE '0';
	move        <=  '1'  WHEN  Opcode = "000000" AND Function_opcode = "100001"  ELSE '0';
    Lui         <=  '1'  WHEN  Opcode = "001111"  ELSE '0';
 	Sw          <=  '1'  WHEN  Opcode = "101011"  ELSE '0';
   	Beq         <=  '1'  WHEN  Opcode = "000100"  ELSE '0';
	Bne         <=  '1'  WHEN  Opcode = "000101"  ELSE '0';
	Addi        <=  '1'  WHEN  Opcode = "001000"  ELSE '0';
	Xori        <=  '1'  WHEN  Opcode = "001110"  ELSE '0';
	Andi        <=  '1'  WHEN  Opcode = "001100"  ELSE '0';
	Ori         <=  '1'  WHEN  Opcode = "001101"  ELSE '0';
	Slti        <=  '1'  WHEN  Opcode = "001010"  ELSE '0';
	Mul 		<=  '1'  WHEN  Opcode = "011100"  ELSE '0';
	JmpO 		<=  '1'  WHEN  Opcode = "000010"  ELSE '0';
	jmpR		<=  '1'  WHEN  Opcode = "000000" AND Function_opcode = "001000"  ELSE '0';
	Jal         <=  '1'  WHEN  Opcode = "000011"  ELSE '0';
	ShiftRL		<=  '1'  WHEN  Opcode = "000000" AND Function_opcode = "000010"  ELSE '0';
	ShiftLL		<=  '1'  WHEN  Opcode = "000000" AND Function_opcode = "000000" ELSE '0';
	Reti		<=  '1'  WHEN  (Opcode = "000000" AND Function_opcode = "001000" AND Rs = "11011") ELSE '0';

	
	RegDst(2)   <=  (Reti AND NOT dis) OR INT_cyc2;
	RegDst(1)   <=  (Jal AND NOT dis) OR INT_cyc1;
  	RegDst(0)   <=  ((R_format OR Mul OR ShiftRL OR ShiftLL OR move OR Reti) AND NOT dis) or INT_cyc1;
 	ALUSrc(0)  	<=  ((Lw OR Sw OR Addi OR Slti OR Lui) AND NOT dis);
 	ALUSrc(1)  	<=  ((Andi OR Ori OR Xori) AND NOT dis);
	MemtoReg 	<=  (Lw AND NOT dis);
  	RegWrite 	<=  ((R_format OR Mul OR Lw OR Addi OR Xori OR Ori OR Slti OR Andi OR ShiftRL OR ShiftLL OR move OR Lui OR Jal) AND NOT dis) or INT_cyc1 OR INT_cyc2 ;
  	MemRead 	<=  (Lw AND NOT dis);
   	MemWrite 	<=  (Sw AND NOT dis); 
	Jump(0)  	<=  (JmpO OR Jal) and not INT_cyc2;
	Jump(1)  	<=  (JmpR OR Reti)and not INT_cyc2;
 	Branch(0)   <=  (Beq AND NOT dis);
 	Branch(1)   <=  (Bne AND NOT dis);
    ALUOp( 3 )  <=  ((Ori OR Mul OR ShiftRL OR ShiftLL OR move OR Lui) AND NOT dis);
	ALUOp( 2 )  <=  ((Xori OR Ori OR Slti OR Beq or Bne or Mul OR move) AND NOT dis);
	ALUOp( 1 ) 	<=  ((R_format OR Andi OR Slti) AND NOT dis);
	ALUOp( 0 ) 	<=  ((Xori OR Andi or Mul OR ShiftLL OR move) AND NOT dis); 
	TYPEtoPC 	<=	INT_cyc2;
 
	process(reset, clock,INTR)
	begin 
		if (clock'EVENT) AND (clock = '1') then
			prev_INTR <= INTR;
		END IF;
	END PROCESS;
	
	
	process(reset, clock, prev_INTR, INTR)
	begin 
		if (clock'EVENT) AND (clock = '1') then
				IF (prev_INTR = '0' AND INTR = '1') then
					INT_counter <= "10";
            ELSIF (INT_counter /= "00") THEN
					INT_counter <= INT_counter - 1;
				END IF;
		END IF;
	END PROCESS;

	INTA <= '0' WHEN INT_counter = "01" ELSE '1';
	dis  <= '1' WHEN INT_counter = "10" OR INT_counter = "01" ELSE '0';
	INT_cyc1 <= '1' WHEN INT_counter = "10" ELSE '0';
	INT_cyc2 <= '1' WHEN INT_counter = "01" ELSE '0';

   END behavior;


