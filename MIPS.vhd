				-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY MIPS IS
	GENERIC ( sim : INTEGER := 0 );
	PORT(   reset, clock					: IN 	STD_LOGIC; 
			PC								: OUT  STD_LOGIC_VECTOR( 9 DOWNTO 0 );
     		Instruction_out					: OUT  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Memread_out, Memwrite_out		: OUT 	STD_LOGIC; 
			DataBUS							: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			address							: OUT STD_LOGIC_VECTOR( 11 DOWNTO 0 );
			GIE 							: OUT 	STD_LOGIC;
			INTA							: OUT STD_LOGIC;
			INTR							: IN STD_LOGIC;
			PC_ENABLE                       : IN    STD_LOGIC 
		);
END MIPS;

ARCHITECTURE structure OF MIPS IS 

	COMPONENT Ifetch
		GENERIC ( sim : INTEGER := 0 );
   	     PORT(	Instruction			: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		PC_plus_4_out 		: OUT  	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			    JumpR_PC 		    : IN    STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Jump_PC_se 			: IN  	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
				Jump   				: IN  	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
        		Add_result 			: IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
        		Branch 				: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
        		Zero 				: IN 	STD_LOGIC;
        		PC_out 				: OUT 	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
				Next_PC_out		    : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
				TYPEtoPC			: IN    STD_LOGIC;
			    read_data 		    : IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		clock,reset 		: IN 	STD_LOGIC;
				PC_ENABLE           : IN    STD_LOGIC
				);
	END COMPONENT; 

	COMPONENT Idecode
 	     PORT(	read_data_1 		: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		read_data_2 		: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Jump_PC_se 			: OUT   STD_LOGIC_VECTOR( 7 DOWNTO 0 );
        		Instruction 		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			    PC_plus_4   	    : IN	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
        		read_data 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		ALU_result 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		RegWrite, MemtoReg 	: IN 	STD_LOGIC;
        		RegDst 				: IN 	STD_LOGIC_VECTOR( 2 DOWNTO 0 );
        		Sign_extend 		: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Zero_extend         : OUT   STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Shamt 				: OUT 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
				GIE 				: OUT 	STD_LOGIC;
				Next_PC             : IN    STD_LOGIC_VECTOR( 7 DOWNTO 0 );
				clock, reset		: IN 	STD_LOGIC );
	END COMPONENT;

	COMPONENT control IS
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
 	END COMPONENT;
 

	COMPONENT  Execute
   	     PORT(	Read_data_1 		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
                Read_data_2 		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
               	Sign_Extend 		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			    Zero_extend  	    : IN    STD_LOGIC_VECTOR( 31 DOWNTO 0 );
				Shamt 				: IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
               	Function_opcode		: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
               	ALUOp 				: IN 	STD_LOGIC_VECTOR( 3 DOWNTO 0 );
		   	    ALUSrc 				: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
               	Zero 				: OUT	STD_LOGIC;
               	ALU_Result 			: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
               	Add_Result 			: OUT	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
               	PC_plus_4 			: IN 	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
               	clock, reset		: IN 	STD_LOGIC );
	END COMPONENT;


	COMPONENT dmemory
		GENERIC ( sim : INTEGER := 0 );
	     PORT(	read_data 			: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		address 			: IN 	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
        		write_data 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		MemRead, Memwrite 	: IN 	STD_LOGIC;
				TYPE_addr 			: IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
				TYPEtoPC			: IN    STD_LOGIC;
				Clock,reset			: IN 	STD_LOGIC );
	END COMPONENT;

	COMPONENT BidirPin
		GENERIC( WIDTH: INTEGER:=16 );
		PORT(   Dout: 	IN 		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
				en:		IN 		STD_LOGIC;
				Din:	OUT		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
				IOpin: 	INOUT 	STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)
		);
	END COMPONENT;

					-- declare signals used to connect VHDL components
	SIGNAL PC_plus_4 		: STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL read_data_1 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data_2 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Sign_Extend 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Zero_Extend 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Add_result 		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL ALU_result 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data_MEM 	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL ALUSrc 			: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL Branch 			: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL RegDst 			: STD_LOGIC_VECTOR( 2 DOWNTO 0 );
	SIGNAL Regwrite 		: STD_LOGIC;
	SIGNAL Zero 			: STD_LOGIC;
	SIGNAL MemWrite 		: STD_LOGIC;
	SIGNAL MemtoReg 		: STD_LOGIC;
	SIGNAL MemRead 			: STD_LOGIC;
	SIGNAL Jump 			: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL ALUop 			: STD_LOGIC_VECTOR( 3 DOWNTO 0 );
	SIGNAL Instruction		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Jump_PC_se 		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL Next_PC 		    : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	
	SIGNAL TYPEtoPC			: STD_LOGIC;
	SIGNAL Din				: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL en				: STD_LOGIC;


BEGIN
					-- copy important signals to output pins for easy 
					-- display in Simulator

	BiDirPin1: BidirPin
		GENERIC MAP ( 32 )
		PORT MAP (	Dout 		=> read_data_2,
					en			=> en,
					Din			=> Din,
					IOpin 		=> DataBUS);
				
	en	<= '1' WHEN MemWrite = '1' AND ALU_Result(11) = '1' ELSE '0';			
	
    Instruction_out 	<= Instruction;
   	Memread_out <= MemRead;
    MemWrite_out 	<= MemWrite;	
    address <= ALU_Result (11 DOWNTO 0);
	read_data <= read_data_MEM WHEN (ALU_Result(11) = '0') ELSE Din;
	 
					-- connect the 5 MIPS components   
  IFE : Ifetch
	GENERIC MAP (sim)
	PORT MAP (	Instruction 	=> Instruction,
    	    	PC_plus_4_out 	=> PC_plus_4,
				Jump_PC_se		=> Jump_PC_se,
				JumpR_PC        => read_data_1,
				Add_result 		=> Add_result,
				Branch 			=> Branch,
				Jump 			=> Jump,
				Zero 			=> Zero,
				PC_out 			=> PC,     
				Next_PC_out     => Next_PC, 
				TYPEtoPC	    => TYPEtoPC,
				read_data       => read_data_MEM,	
				clock 			=> clock,  
				reset 			=> reset, 
				PC_ENABLE       => PC_ENABLE              
				);

   ID : Idecode
   	PORT MAP (	read_data_1 	=> read_data_1,
        		read_data_2 	=> read_data_2,
				Jump_PC_se		=> Jump_PC_se, 
        		Instruction 	=> Instruction,
        	    PC_plus_4    	=> PC_plus_4,
				read_data 		=> read_data,
				ALU_result 		=> ALU_result,
				RegWrite 		=> RegWrite,
				MemtoReg 		=> MemtoReg,
				RegDst 			=> RegDst,
				Sign_extend 	=> Sign_extend,
				Zero_Extend     => Zero_Extend,
				GIE             => GIE,
				Next_PC         => Next_PC,
				clock 			=> clock,  
				reset 			=> reset );


   CTL:   control
	PORT MAP ( 	Opcode 			=> Instruction( 31 DOWNTO 26 ),
				INTR			=> INTR,
				INTA			=> INTA,
				Function_opcode	=> Instruction( 5 DOWNTO 0 ),
				RS              => Instruction( 25 DOWNTO 21),
				RegDst 			=> RegDst,
				ALUSrc 			=> ALUSrc,
				MemtoReg 		=> MemtoReg,
				RegWrite 		=> RegWrite,
				MemRead 		=> MemRead,
				MemWrite 		=> MemWrite,
				Jump 			=> Jump,
				Branch 			=> Branch,
				ALUop 			=> ALUop,
				TYPEtoPC	    => TYPEtoPC,
                clock 			=> clock,
				reset 			=> reset );

   EXE:  Execute
   	PORT MAP (	Read_data_1 	=> read_data_1,
             	Read_data_2 	=> read_data_2,
				Shamt			=> Instruction( 10 DOWNTO 6 ),
				Sign_extend 	=> Sign_extend,
				Zero_Extend     => Zero_Extend,
                Function_opcode	=> Instruction( 5 DOWNTO 0 ),
				ALUOp 			=> ALUop,
				ALUSrc 			=> ALUSrc,
				Zero 			=> Zero,
                ALU_Result		=> ALU_Result,
				Add_Result 		=> Add_Result,
				PC_plus_4		=> PC_plus_4,
                Clock			=> clock,
				Reset			=> reset );

   MEM:  dmemory
	GENERIC MAP (sim)
	PORT MAP (	read_data 		=> read_data_MEM,
				address 		=> ALU_Result (11 DOWNTO 2),--jump memory address by 4
				write_data 		=> read_data_2,
				MemRead 		=> MemRead, 
				Memwrite 		=> MemWrite, 
				TYPE_addr       => Din(7 DOWNTO 0),
				TYPEtoPC	    => TYPEtoPC,
                clock 			=> clock,  
				reset 			=> reset );
END structure;

