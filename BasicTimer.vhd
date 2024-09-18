LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY  BasicTimer IS
	PORT(	clock		 	: IN 	STD_LOGIC;
			reset		 	: IN 	STD_LOGIC;
			address		 	: IN 	STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			DataBus		 	: INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			MemRead 		: IN 	STD_LOGIC;
			MemWrite 		: IN 	STD_LOGIC;
			Set_BTIFG 		: OUT 	STD_LOGIC;
			PWM_out         : OUT    STD_LOGIC);
END BasicTimer;

ARCHITECTURE behavior OF BasicTimer IS

	COMPONENT BidirPin
		GENERIC( WIDTH: INTEGER:=16 );
		PORT(   Dout: 	IN 		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
				en:		IN 		STD_LOGIC;
				Din:	OUT		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
				IOpin: 	INOUT 	STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL CS			 		: STD_LOGIC_VECTOR( 3 DOWNTO 0 );
	SIGNAL Dout	, Din			: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL en					: STD_LOGIC;
	
	SIGNAL BTCNT_reg			: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL BTCTL_reg		    : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    SIGNAL BTCCR0_reg           : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL BTCCR1_reg           : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL PWM_counter			: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');


    SIGNAL Dout_BTCTL           : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL Dout_BTCNT           : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL Dout_BTCCR0          : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL Dout_BTCCR1          : STD_LOGIC_VECTOR( 31 DOWNTO 0 );

    SIGNAL Din_BTCTL            : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL Din_BTCNT            : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL Din_BTCCR0           : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL Din_BTCCR1           : STD_LOGIC_VECTOR( 31 DOWNTO 0 );

    SIGNAL PWM_reg              : STD_LOGIC;

	SIGNAL EN_BTCTL_W, EN_BTCNT_W, EN_BTCCR0_W, EN_BTCCR1_W		: STD_LOGIC;
	SIGNAL EN_BTCTL_R, EN_BTCNT_R, EN_BTCCR0_R, EN_BTCCR1_R		: STD_LOGIC;

    SIGNAL MCLK2, MCLK4, MCLK8, SelCLK			: STD_LOGIC;

BEGIN
	
	BiDirPin_CTL: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_BTCTL,
				en			=> EN_BTCTL_R,
				Din			=> Din_BTCTL,
				IOpin 		=> DataBUS );

	BiDirPin_CNT: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_BTCNT,
    	    	en			=> EN_BTCNT_R,
				Din			=> Din_BTCNT,
				IOpin 		=> DataBUS );

	BiDirPin_BTCCR0: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_BTCCR0,
				en			=> EN_BTCCR0_R,
				Din			=> Din_BTCCR0,
				IOpin 		=> DataBUS );

	BiDirPin_BTCCR1: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_BTCCR1,
				en			=> EN_BTCCR1_R,
				Din			=> Din_BTCCR1,
				IOpin 		=> DataBUS );

	Dout_BTCTL <= X"000000" & BTCTL_reg;
	Dout_BTCNT <= BTCNT_reg;
	Dout_BTCCR0 <= BTCCR0_reg;
	Dout_BTCCR1 <= BTCCR1_reg;

	EN_BTCTL_R <= MemRead AND CS(0);
	EN_BTCNT_R <= MemRead AND CS(1);
	EN_BTCCR0_R <= MemRead AND CS(2);
	EN_BTCCR1_R <= MemRead AND CS(3);

	EN_BTCTL_W <= MemWrite AND CS(0);
	EN_BTCNT_W <= MemWrite AND CS(1) AND BTCTL_reg(5);
	EN_BTCCR0_W <= MemWrite AND CS(2);
	EN_BTCCR1_W <= MemWrite AND CS(3);
	
	WITH address SELECT
	CS <= "0001" WHEN "10111",    ----- GPIOaddress 	<= address(11) & address(5 DOWNTO 2);
		  "0010" WHEN "11000",
          "0100" WHEN "11001",
		  "1000" WHEN "11010",
		  "0000" WHEN OTHERS;


				   
	SelCLK <=  clock WHEN BTCTL_reg(4 DOWNTO 3) = "00"  OR BTCTL_reg(5) = '1' ELSE
				    MCLK2 WHEN BTCTL_reg(4 DOWNTO 3) = "01" ELSE
					MCLK4 WHEN BTCTL_reg(4 DOWNTO 3) = "10" ELSE
					MCLK8 WHEN BTCTL_reg(4 DOWNTO 3) = "11" ELSE
					clock;		   

	WITH BTCTL_reg(2 DOWNTO 0) SELECT
	Set_BTIFG <= BTCNT_reg(0)  WHEN "000",
				 BTCNT_reg(3)  WHEN "001",
				 BTCNT_reg(7)  WHEN "010",
				 BTCNT_reg(11) WHEN "011",
				 BTCNT_reg(15) WHEN "100",
				 BTCNT_reg(19) WHEN "101",
				 BTCNT_reg(23) WHEN "110",
				 BTCNT_reg(25) WHEN "111",
				 BTCNT_reg(0) WHEN OTHERS;
------------------------------------------generation of clock's-------------------------------------------------------------------------				 
	PROCESS (reset, clock)
	BEGIN
		IF reset = '1' THEN
			MCLK2 <= '0';
		ELSIF ( clock'EVENT ) AND ( clock = '1' ) THEN
			MCLK2 <= NOT MCLK2;
		END IF;
	END PROCESS;
	
	PROCESS (reset, MCLK2)
	BEGIN
		IF reset = '1' THEN
			MCLK4 <= '0';
		ELSIF ( MCLK2'EVENT ) AND ( MCLK2 = '1' ) THEN
			MCLK4 <= NOT MCLK4;
		END IF;
	END PROCESS;
	
	PROCESS (reset, MCLK4)
	BEGIN
		IF reset = '1' THEN
			MCLK8 <= '0';
		ELSIF ( MCLK4'EVENT ) AND ( MCLK4 = '1' ) THEN
			MCLK8 <= NOT MCLK8;
		END IF;
	END PROCESS;

-------------------------------------write to registers---------------------------------------------------------------------------------
	PROCESS (reset, SelCLK, EN_BTCNT_W)
	BEGIN
		IF reset = '1' THEN
			BTCNT_reg <= X"00000000";
			PWM_counter <= X"00000000";
		ELSIF ( SelCLK'EVENT ) AND ( SelCLK = '1' ) THEN
			IF BTCTL_reg(5) = '0' THEN
				BTCNT_reg <= BTCNT_reg + 1;
				PWM_counter <= PWM_counter + 1;
			ELSIF EN_BTCNT_W = '1' THEN
				BTCNT_reg <= Din_BTCNT;
			END IF;
			if PWM_counter = BTCCR0_reg THEN
				PWM_counter <= X"00000001";
			end if;
		END IF;
	END PROCESS;
	
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
	-- PROCESS (reset, SelCLK, EN_BTCNT_W)
	-- BEGIN
		-- IF reset = '1' THEN
			-- BTCNT_reg <= X"00000000";
		-- ELSIF ( SelCLK'EVENT ) AND ( SelCLK = '1' ) THEN
			-- IF BTCNT_reg = BTCCR0_reg and BTCNT_reg /= x"00000000" THEN
				-- BTCNT_reg <= (others => '0');
			-- ELSIF BTCTL_reg(5) = '0' THEN
				-- BTCNT_reg <= BTCNT_reg + 1;
			-- ELSIF EN_BTCNT_W = '1' THEN
				-- BTCNT_reg <= Din_BTCNT;
			-- END IF;
		-- END IF;
	-- END PROCESS;
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

	PROCESS (reset, clock, EN_BTCTL_W)
	BEGIN
		IF reset = '1' THEN
			BTCTL_reg <= "00100000";
		ELSIF ( clock'EVENT ) AND ( clock = '1' ) THEN
			IF EN_BTCTL_W = '1' THEN
				BTCTL_reg <= Din_BTCTL(7 DOWNTO 0);
			END IF;
		END IF;
	END PROCESS;
	
	process(reset, clock, EN_BTCCR0_W)
	begin
		if (reset = '1') then
			BTCCR0_reg <= X"00000000";
		elsif (clock'EVENT) AND (clock = '1') then
			if (EN_BTCCR0_W = '1') then
				BTCCR0_reg <= Din_BTCCR0(31 downto 0);
			end if;
		end if;
	end process;

	process(reset, clock, EN_BTCCR1_W)
	begin
		if (reset = '1') then
			BTCCR1_reg <= X"00000000";
		elsif (clock'EVENT) AND (clock = '1') then
			if (EN_BTCCR1_W = '1') then
				BTCCR1_reg <= Din_BTCCR1(31 downto 0);
			end if;
		end if;
	end process;

	----------------------------------------------PWM----------------------------------------------------------------------
	PROCESS (reset, SelCLK) 
	BEGIN
		IF reset = '1' THEN
			PWM_reg <= '0';
		ELSIF ( SelCLK'EVENT ) AND ( SelCLK = '1' ) THEN
			IF BTCTL_reg(6) = '0' THEN
				PWM_reg <= '0';
			else
				if BTCTL_reg(7) = '0' THEN ------Set/Reset------
					if PWM_counter = BTCCR1_reg THEN
						PWM_reg <= '1';
					elsif PWM_counter = BTCCR0_reg THEN
						PWM_reg <= '0';	
					end if;
				else						------Reset/Set------
					if PWM_counter = BTCCR1_reg THEN
						PWM_reg <= '0';
					elsif PWM_counter = BTCCR0_reg THEN
						PWM_reg <= '1';	
					end if;				
				end if;
			END IF;
		END IF;
	END PROCESS;

	PWM_out <= PWM_reg;
	
END behavior;