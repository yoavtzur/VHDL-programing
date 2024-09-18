-- Ifetch module (provides the PC and instruction 
--memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY Ifetch IS
	GENERIC ( sim : INTEGER := 0 );
	PORT(	SIGNAL Instruction 		: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	SIGNAL PC_plus_4_out 	: OUT	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			SIGNAL Jump_PC_se 		: IN   STD_LOGIC_VECTOR( 7 DOWNTO 0 );
        	SIGNAL Add_result 		: IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
        	SIGNAL Branch 			: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			SIGNAL Jump   			: IN   STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			SIGNAL JumpR_PC 		: IN	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	SIGNAL Zero 			: IN 	STD_LOGIC;
      		SIGNAL PC_out 			: OUT	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			SIGNAL Next_PC_out		: OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			SIGNAL TYPEtoPC			: IN    STD_LOGIC;
        	SIGNAL read_data 		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			SIGNAL clock, reset 	: IN 	STD_LOGIC;
			SIGNAL PC_ENABLE        : IN    STD_LOGIC

			);
END Ifetch;

ARCHITECTURE behavior OF Ifetch IS
	SIGNAL PC, PC_plus_4 	 : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL next_PC, Mem_Addr, branch_PC : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL Mem_Addr_quartus : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
BEGIN
						--ROM for Instruction Memory

	modelsim: IF sim = 1 GENERATE
		inst_memory: altsyncram
		GENERIC MAP (
			operation_mode => "ROM",
			width_a => 32,
			widthad_a => 8,
			lpm_type => "altsyncram",
			outdata_reg_a => "UNREGISTERED",
			init_file => "C:\Users\yoavt\Laboratory architecture\FINAL\newProjact\Interrupt based IO\test3\ITCM.hex",
			intended_device_family => "Cyclone"
		)
		PORT MAP (
			clock0     => clock,
			address_a 	=> Mem_Addr, 
			q_a 			=> Instruction );
	END GENERATE;


	Mem_Addr_quartus <= Mem_Addr & "00";
	quartos: IF sim = 0 GENERATE
		inst_memory: altsyncram
		GENERIC MAP (
			operation_mode => "ROM",
			width_a => 32,
			widthad_a => 10,
			numwords_a =>1024,
			lpm_hint => "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=ITCM",
			lpm_type => "altsyncram",
			outdata_reg_a => "UNREGISTERED",
			init_file => "C:\Users\yoavt\Laboratory architecture\FINAL\newProjact\Interrupt based IO\test3\ITCM.hex",
			intended_device_family => "Cyclone"
		)
		PORT MAP (
			clock0      => clock,
			address_a 	=> Mem_Addr_quartus, 
			q_a 		=> Instruction );
	END GENERATE;


				-- Instructions always start on word address - not byte
	PC(1 DOWNTO 0) <= "00";
				-- copy output signals - allows read inside module
	PC_out 			<= PC;
	PC_plus_4_out 	<= PC_plus_4;
					-- send address to inst. memory address register
	Mem_Addr <= Next_PC;
					-- Adder to increment PC by 4        
	PC_plus_4( 9 DOWNTO 2 )  <= PC( 9 DOWNTO 2 ) + 1;
	PC_plus_4( 1 DOWNTO 0 )  <= "00";
					-- Mux to select Branch Address or PC + 4        

	Next_PC  <= X"00" WHEN Reset = '1' ELSE
		Jump_PC_se     WHEN (Jump = "01") ELSE
		JumpR_PC( 9 DOWNTO 2 )     WHEN (Jump = "10") ELSE 
		read_data(9 DOWNTO 2) WHEN TYPEtoPC = '1'
		ELSE  branch_PC;
	
	branch_PC <= Add_result  WHEN ( ( Branch = "01" ) AND ( Zero = '1' ) ) OR ( ( Branch = "10" ) AND ( Zero = '0' ) )
					else PC_plus_4( 9 DOWNTO 2 );

	Next_PC_out <= Next_PC;
	
	PROCESS
		BEGIN
			WAIT UNTIL ( clock'EVENT ) AND ( clock = '1' );
			IF reset = '1' THEN
				   PC( 9 DOWNTO 2) <= "00000000" ; 
			ELSIF  (PC_ENABLE = '1') THEN
				   PC( 9 DOWNTO 2 ) <= next_PC;
			END IF;
	END PROCESS;
END behavior;


