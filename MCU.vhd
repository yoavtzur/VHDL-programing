LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY MCU IS

    GENERIC ( sim : INTEGER := 0 );
    PORT( 
            KEY_reset							: IN 	STD_LOGIC; 
            clock								: IN 	STD_LOGIC; 
            PC									: OUT  STD_LOGIC_VECTOR( 9 DOWNTO 0 );
            Instruction_out						: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
            LEDR_out						 	: OUT 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
            HEX0_out, HEX1_out, HEX2_out	    : OUT 	STD_LOGIC_VECTOR( 6 DOWNTO 0 );
            HEX3_out, HEX4_out, HEX5_out	    : OUT 	STD_LOGIC_VECTOR( 6 DOWNTO 0 );
            SW_in								: IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
            KEY1, KEY2, KEY3 				    : IN 	STD_LOGIC;
            PWM_out                             : OUT   STD_LOGIC;
            PC_ENABLE                           : IN    STD_LOGIC
				-- UART INTERFACE
	--			UART_TXD    : out std_logic; -- serial transmit data
		--		UART_RXD    : in  std_logic -- serial receive data
        );
END MCU;

ARCHITECTURE structure OF MCU IS

	COMPONENT PLL is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
			);
	end COMPONENT;
	
    COMPONENT MIPS
        GENERIC ( sim : INTEGER := 0 );
            PORT(	reset, clock				: IN 	STD_LOGIC; 
                PC								: OUT  STD_LOGIC_VECTOR( 9 DOWNTO 0 );
                Instruction_out					: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
                Memread_out						: OUT 	STD_LOGIC;
                Memwrite_out	 				: OUT 	STD_LOGIC;
                DataBUS							: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
                address							: OUT STD_LOGIC_VECTOR( 11 DOWNTO 0 );
                GIE	 							: OUT 	STD_LOGIC;
                INTA							: OUT STD_LOGIC;
                INTR							: IN STD_LOGIC;
                PC_ENABLE                       : IN    STD_LOGIC 
                );
    END COMPONENT; 

    COMPONENT  GPIO 
	PORT(	clock		 	: IN 	STD_LOGIC;
			reset		 	: IN 	STD_LOGIC; 
			address		 	: IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			DataBus		 	: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			MemRead 		: IN 	STD_LOGIC;
			MemWrite 		: IN 	STD_LOGIC;
			A0		 		: IN 	STD_LOGIC;
			LEDR_out		: OUT 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX0_out		: OUT 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX1_out		: OUT 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX2_out		: OUT 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX3_out		: OUT 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX4_out		: OUT 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX5_out		: OUT 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			SW_in			: IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 ));
    END COMPONENT;
    
    COMPONENT InterruptController is
        port(   clock					: IN 	STD_LOGIC; 
                address                 : IN    STD_LOGIC_VECTOR( 6 DOWNTO 0 ); -- a11, a5 downto a0
                DataBus		 	        : INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
                MemRead	 		        : IN 	STD_LOGIC;
                MemWrite	 	        : IN 	STD_LOGIC;
                irq                     : IN 	STD_LOGIC_VECTOR(6 DOWNTO 0);
                rstBtn			        : IN 	STD_LOGIC;
                GIE	 			        : IN 	STD_LOGIC;
                INTA	 		        : IN 	STD_LOGIC;
                INTR_out	 	        : OUT 	STD_LOGIC;
                reset_out  	 	        : OUT 	STD_LOGIC;
                PC_ENABLE               : IN    STD_LOGIC
            );
    end COMPONENT;

     COMPONENT BasicTimer
         PORT(	clock		 	: IN 	STD_LOGIC;
                reset		 	: IN 	STD_LOGIC; 
                address		    : IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 ); -- a11,a5-a2
                DataBus		    : INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
                MemRead 		: IN 	STD_LOGIC;
                MemWrite 		: IN 	STD_LOGIC;
                Set_BTIFG 		: OUT 	STD_LOGIC; 
                PWM_out         : OUT   STD_LOGIC);
     END COMPONENT;
        
    COMPONENT hexDecoder IS
        PORT 
        (
            bin: in STD_LOGIC_VECTOR (3 DOWNTO 0);
            hex: out STD_LOGIC_VECTOR (6 DOWNTO 0)
        );
    END COMPONENT;

 
 ---------------------------------------------------------------------
 COMPONENT unsigned_division
	PORT(	DIVCLK		: IN 	STD_LOGIC;
			RST		 	: IN 	STD_LOGIC;
		--	EN		 		: IN 	STD_LOGIC;
			address		: IN 	STD_LOGIC_VECTOR( 6 DOWNTO 0 ); -- a11, a5 downto a0
			DataBus		: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			MemRead 		: IN 	STD_LOGIC;
			MemWrite 	: IN 	STD_LOGIC;
			DIVIFG 		: OUT 	STD_LOGIC
			);
END COMPONENT;
 
 
 COMPONENT  USART IS
	PORT(	CLK		 	: IN 	STD_LOGIC;
			RST		 	: IN 	STD_LOGIC;
			address		 	: IN 	STD_LOGIC_VECTOR( 6 DOWNTO 0 ); -- a11, a5 downto a0
			DataBus		 	: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			MemRead 		: IN 	STD_LOGIC;
			MemWrite 		: IN 	STD_LOGIC
		 -- UART INTERFACE
--        UART_TXD    : out std_logic; -- serial transmit data
  --      UART_RXD    : in  std_logic; -- serial receive data
	--	  TXIFG 		: out 	STD_LOGIC;
	--	  RXIFG 		: out	STD_LOGIC;
	--	  RXError 		: out	STD_LOGIC
			);
END COMPONENT;
 --------------------------------------------------------------------

                    -- declare signals used to connect VHDL components
    SIGNAL reset			: STD_LOGIC;
    --SIGNAL fpga_clock		: STD_LOGIC;
    SIGNAL address			: STD_LOGIC_VECTOR( 11 DOWNTO 0 );
    SIGNAL GPIOaddress		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
    SIGNAL A0               : STD_LOGIC;
    SIGNAL ICaddress		: STD_LOGIC_VECTOR( 6 DOWNTO 0 );
    SIGNAL DataBUS			: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL MemRead			: STD_LOGIC;
    SIGNAL MemWrite			: STD_LOGIC;
    SIGNAL LEDR     		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    SIGNAL HEX0_bin     	: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    SIGNAL HEX1_bin     	: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    SIGNAL HEX2_bin    		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    SIGNAL HEX3_bin    		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    SIGNAL HEX4_bin    		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    SIGNAL HEX5_bin     	: STD_LOGIC_VECTOR( 7 DOWNTO 0 );

    SIGNAL INTA				: STD_LOGIC;
    SIGNAL INTR				: STD_LOGIC;
    SIGNAL GIE				: STD_LOGIC;
    SIGNAL Set_BTIFG		: STD_LOGIC;
	 SIGNAL DIVIFG		: STD_LOGIC;
	 SIGNAL TXIFG 		: 	STD_LOGIC;
	SIGNAL  RXIFG 		: 	STD_LOGIC;
	SIGNAL  Err 		: 	STD_LOGIC;
	 
    SIGNAL KEY0_NOT			: STD_LOGIC;
    SIGNAL KEY1_NOT			: STD_LOGIC;
    SIGNAL KEY2_NOT			: STD_LOGIC;
    SIGNAL KEY3_NOT			: STD_LOGIC;
	 signal pll_clock			: STD_LOGIC;

BEGIN
                    -- copy important signals to output pins for easy 
                    -- display in Simulator
    GPIOaddress	 	<= address(11) & address(5 DOWNTO 2);
    A0       	 	<= address(0);
    ICaddress	 	<= address(11) & address(5 DOWNTO 0);   
    
    KEY0_NOT <= NOT(KEY_reset);
    KEY1_NOT <= NOT(KEY1);
    KEY2_NOT <= NOT(KEY2);
    KEY3_NOT <= NOT(KEY3);
                    -- connect the 5 MIPS components   
    CPU : MIPS
    GENERIC MAP ( sim )
    PORT MAP (	reset				=> reset,
                clock				=> pll_clock,
                PC  				=> PC,
                Instruction_out		=> Instruction_out,
                Memread_out		    => MemRead,
                Memwrite_out		=> MemWrite,
                DataBUS				=> DataBUS,
                address				=> address,
                GIE					=> GIE,
                INTA				=> INTA,
                INTR				=> INTR,
                PC_ENABLE           => PC_ENABLE     
                );

    IO : GPIO
        PORT MAP (clock			=> pll_clock,
                 reset			=> reset,
                 address		=> GPIOaddress,
                 DataBus		=> DataBUS,
                 MemRead 		=> MemRead,
                 MemWrite 		=> MemWrite,
                 A0             => A0,
                 LEDR_out		=> LEDR,
                 HEX0_out		=> HEX0_bin,
                 HEX1_out		=> HEX1_bin,
                 HEX2_out		=> HEX2_bin,
                 HEX3_out		=> HEX3_bin,
                 HEX4_out		=> HEX4_bin,
                 HEX5_out		=> HEX5_bin,
                 SW_in	    	=> SW_in);
                
    IC : InterruptController
    PORT MAP (  clock			=> pll_clock,		
                address         => ICaddress,
                DataBus		 	=> DataBUS,
                MemRead	 		=> MemRead,     
                MemWrite	 	=> MemWrite,
				irq(6)	 		=> DIVIFG,
                irq(5)	 		=> KEY3_NOT,
                irq(4)	 		=> KEY2_NOT,
                irq(3)	 		=> KEY1_NOT,
                irq(2)	 		=> Set_BTIFG,
                irq(1)	 		=> '0',--'0',
                irq(0)	 		=> '0',--'0',               
                rstBtn			=> KEY0_NOT,      
                GIE	 			=> GIE,  		
                INTA	 		=> INTA,        
                INTR_out	 	=> INTR,       
                reset_out  	 	=> reset,
                PC_ENABLE       => PC_ENABLE);    
                           
	UD: unsigned_division
	PORT map(	
			DIVCLK	=> pll_clock,
			RST		=> reset,
			--EN		 	=> INTR,
			address	=> ICaddress,-- a11, a5 downto a0
			DataBus	=> DataBUS,
			MemRead 	=> MemRead,
			MemWrite => MemWrite,
			DIVIFG 	=> DIVIFG
			);			 
					 
--	URT: USART
--	PORT map(	CLK		 	=>clock,
--			RST		 	=>reset,
--			address		=>ICaddress, -- a11, a5 downto a0
--			DataBus		=> DataBus,
--			MemRead 		=>MemRead,
--			MemWrite 	=>MemWrite,
--		 -- UART INTERFACE
--        UART_TXD    =>UART_TXD, -- serial transmit data
--        UART_RXD    =>UART_RXD, -- serial receive data
--		  TXIFG 		=> TXIFG,
--		  RXIFG 		=> RXIFG,
--		  RXError 	=> Err
--			);		
		
    BT : BasicTimer
    PORT MAP (	clock		 	=> pll_clock,
                reset			=> reset,
                address		 	=> GPIOaddress,
                DataBus		 	=> DataBUS,
                MemRead 		=> MemRead,
                MemWrite 		=> MemWrite,
                Set_BTIFG 		=> Set_BTIFG, 
                PWM_out         => PWM_out);
                
    HD0 : HexDecoder
        PORT MAP (	
            bin 	=> HEX0_bin(3 DOWNTO 0),
            hex 	=> HEX0_out );
                
    HD1 : HexDecoder
        PORT MAP (	
            bin 	=> HEX1_bin(3 DOWNTO 0),
            hex 	=> HEX1_out );

    HD2 : HexDecoder
    PORT MAP (	
            bin 	=> HEX2_bin(3 DOWNTO 0),
            hex 	=> HEX2_out );
                    
    HD3 : HexDecoder
        PORT MAP (	
            bin 	=> HEX3_bin(3 DOWNTO 0),
            hex 	=> HEX3_out ); 
            
    HD4 : HexDecoder
    PORT MAP (	
            bin 	=> HEX4_bin(3 DOWNTO 0),
            hex 	=> HEX4_out );
                            
    HD5 : HexDecoder
    PORT MAP (	
            bin 	=> HEX5_bin(3 DOWNTO 0),
            hex 	=> HEX5_out );        
  
    LEDR_out <= LEDR;
            
     					
            
    quartus : IF sim = 0 GENERATE					
		Pl : PLL
		PORT MAP (
			refclk   => clock,
			 rst      => open, 
			outclk_0 => pll_clock, 
			locked   => open   			
		);
	END GENERATE quartus;

	modelsim : IF sim = 1 GENERATE					
    pll_clock <= clock;
	
	END GENERATE modelsim;

END structure;