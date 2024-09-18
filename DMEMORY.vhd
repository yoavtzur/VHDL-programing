						--  Dmemory module (implements the data
						--  memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY dmemory IS
	GENERIC ( sim : INTEGER := 0 );
	PORT(	read_data 			: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	address 			: IN 	STD_LOGIC_VECTOR( 9 DOWNTO 0 );
        	write_data 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	   		MemRead, Memwrite 	: IN 	STD_LOGIC;
			TYPE_addr 			: IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			TYPEtoPC			: IN    STD_LOGIC;
            clock,reset			: IN 	STD_LOGIC );
END dmemory;

ARCHITECTURE behavior OF dmemory IS
SIGNAL write_clock : STD_LOGIC;
SIGNAL address_mem : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL address_mem_quartus : STD_LOGIC_VECTOR(11 DOWNTO 0);

BEGIN

	address_mem <= address WHEN TYPEtoPC = '0' ELSE ("0000" & TYPE_addr(7 DOWNTO 2));					

	modelsim: IF sim = 1 GENERATE
		data_memory : altsyncram
			GENERIC MAP  (
				operation_mode => "SINGLE_PORT",
				width_a => 32,
				widthad_a =>10 ,
				lpm_type => "altsyncram",
				outdata_reg_a => "UNREGISTERED",
				init_file => "C:\Users\yoavt\Laboratory architecture\FINAL\newProjact\Interrupt based IO\test3\DTCM.hex",
				intended_device_family => "Cyclone"
			)
			PORT MAP (
				wren_a => memwrite,
				clock0 => write_clock,
				address_a => address_mem,
				data_a => write_data,
				q_a => read_data	);
		-- Load memory address register with write clock
				write_clock <= NOT clock;
	END GENERATE;
	
	address_mem_quartus <= address_mem & "00";
	quartos: IF sim = 0 GENERATE
	data_memory : altsyncram
		GENERIC MAP  (
			operation_mode => "SINGLE_PORT",
			width_a => 32,
			widthad_a =>12 ,
			numwords_a =>4096,
			lpm_hint => "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=DTCM",
			lpm_type => "altsyncram",
			outdata_reg_a => "UNREGISTERED",
			init_file => "C:\Users\yoavt\Laboratory architecture\FINAL\newProjact\Interrupt based IO\test3\DTCM.hex",
			intended_device_family => "Cyclone"
		)
		PORT MAP (
			wren_a => memwrite,
			clock0 => write_clock,
			address_a => address_mem_quartus,
			data_a => write_data,
			q_a => read_data	);
	-- Load memory address register with write clock
			write_clock <= NOT clock;
	END GENERATE;

END behavior;

