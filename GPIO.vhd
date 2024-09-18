LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY  GPIO IS
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
END GPIO;

ARCHITECTURE behavior OF GPIO IS

	COMPONENT BidirPin
		GENERIC( WIDTH: INTEGER:=16 );
		PORT(   Dout: 	IN 		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
				en:		IN 		STD_LOGIC;
				Din:	OUT		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
				IOpin: 	INOUT 	STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL CS			 	    	: STD_LOGIC_VECTOR( 6 DOWNTO 0 );
	SIGNAL Dout_SW		    	    : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Dout_LEDR		    	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Dout_HEX0		    	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Dout_HEX1		    	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Dout_HEX2		    	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Dout_HEX3		    	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Dout_HEX4		    	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Dout_HEX5		    	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );


	SIGNAL Din_SW, Din_LEDR, Din_HEX0, Din_HEX1, Din_HEX2, Din_HEX3, Din_HEX4, Din_HEX5	        : STD_LOGIC_VECTOR( 31 DOWNTO 0 );

	SIGNAL EN_LEDR_W, EN_HEX0_W, EN_HEX1_W, EN_HEX2_W, EN_HEX3_W, EN_HEX4_W, EN_HEX5_W			: STD_LOGIC;
	SIGNAL EN_LEDR_R, EN_HEX0_R, EN_HEX1_R, EN_HEX2_R, EN_HEX3_R, EN_HEX4_R, EN_HEX5_R, EN_SW_R	: STD_LOGIC;
	
	SIGNAL LEDR_reg		     	: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL HEX0_reg			    : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL HEX1_reg			    : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL HEX2_reg			    : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL HEX3_reg			    : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL HEX4_reg		    	: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL HEX5_reg			    : STD_LOGIC_VECTOR( 7 DOWNTO 0 ); 
	

BEGIN
	BiDirPin_LEDR: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_LEDR,
    	    	en			=> EN_LEDR_R,
				Din			=> Din_LEDR,
				IOpin 		=> DataBUS );
	
	BiDirPin_HEX0: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_HEX0,
    	    	en			=> EN_HEX0_R,
				Din			=> Din_HEX0,
				IOpin 		=> DataBUS );	
				
	BiDirPin_HEX1: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_HEX1,
				en			=> EN_HEX1_R,
				Din			=> Din_HEX1,
				IOpin 		=> DataBUS );
				
	BiDirPin_HEX2: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_HEX2,
				en			=> EN_HEX2_R,
				Din			=> Din_HEX2,
				IOpin 		=> DataBUS );	
				
	BiDirPin_HEX3: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_HEX3,
				en			=> EN_HEX3_R,
				Din			=> Din_HEX3,
				IOpin 		=> DataBUS );	
							
	BiDirPin_HEX4: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_HEX4,
				en			=> EN_HEX4_R,
				Din			=> Din_HEX4,
				IOpin 		=> DataBUS );
							
	BiDirPin_HEX5: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_HEX5,
				en			=> EN_HEX5_R,
				Din			=> Din_HEX5,
				IOpin 		=> DataBUS );	
				
	BiDirPin_SW: BidirPin
	GENERIC MAP ( 32 )
	PORT MAP (	Dout 		=> Dout_SW,
				en			=> EN_SW_R,
				Din			=> Din_SW,
				IOpin 		=> DataBUS );			

	WITH address SELECT
	CS <= "0000001" WHEN "10000", --LEDR
		  "0100000" WHEN "10001", --HEX0/1
		  "0010000" WHEN "10010", --HEX2/3
		  "0001000" WHEN "10011", --HEX4/5
		  "1000000" WHEN "10100", --SW
		  "0000000" WHEN OTHERS;

	Dout_LEDR <= X"000000" & LEDR_reg;
	Dout_HEX0 <= X"000000" & HEX0_reg;
	Dout_HEX1 <= X"000000" & HEX1_reg;
	Dout_HEX2 <= X"000000" & HEX2_reg;
	Dout_HEX3 <= X"000000" & HEX3_reg;
	Dout_HEX4 <= X"000000" & HEX4_reg;
	Dout_HEX5 <= X"000000" & HEX5_reg;
	Dout_SW   <= X"000000" & SW_in;

	
	EN_LEDR_W <= MemWrite AND CS(0);
	EN_HEX0_W <= MemWrite AND CS(5) AND NOT A0;
	EN_HEX1_W <= MemWrite AND CS(5) AND A0;
	EN_HEX2_W <= MemWrite AND CS(4) AND NOT A0;
	EN_HEX3_W <= MemWrite AND CS(4) AND A0;
	EN_HEX4_W <= MemWrite AND CS(3) AND NOT A0;
	EN_HEX5_W <= MemWrite AND CS(3) AND A0;

	EN_LEDR_R <= MemRead AND CS(0);
	EN_HEX0_R <= MemRead AND CS(5) AND NOT A0;
	EN_HEX1_R <= MemRead AND CS(5) AND A0;
	EN_HEX2_R <= MemRead AND CS(4) AND NOT A0;
	EN_HEX3_R <= MemRead AND CS(4) AND A0;
	EN_HEX4_R <= MemRead AND CS(3) AND NOT A0;
	EN_HEX5_R <= MemRead AND CS(3) AND A0;
	EN_SW_R   <= MemRead AND CS(6);
	

	process(reset, clock, EN_LEDR_W)
	begin
		if (reset = '1') then
			LEDR_reg <= X"00";
		elsif (clock'EVENT) AND (clock = '1') then
			if (EN_LEDR_W = '1') then
				LEDR_reg <= Din_LEDR(7 downto 0);
			end if;
		end if;
	end process;

	process(reset, clock, EN_HEX0_W)
	begin
		if (reset = '1') then
			HEX0_reg <= X"00";
		elsif (clock'EVENT) AND (clock = '1') then
			if (EN_HEX0_W = '1') then
				HEX0_reg <= Din_HEX0(7 downto 0);
			end if;
		end if;
	end process;

	process(reset, clock, EN_HEX1_W)
	begin
		if (reset = '1') then
			HEX1_reg <= X"00";
		elsif (clock'EVENT) AND (clock = '1') then
			if (EN_HEX1_W = '1') then
				HEX1_reg <= Din_HEX1(7 downto 0);
			end if;
		end if;
	end process;
	
	process(reset, clock, EN_HEX2_W)
	begin
		if (reset = '1') then
			HEX2_reg <= X"00";
		elsif (clock'EVENT) AND (clock = '1') then
			if (EN_HEX2_W = '1') then
				HEX2_reg <= Din_HEX2(7 downto 0);
			end if;
		end if;
	end process;

	process(reset, clock, EN_HEX3_W)
	begin
		if (reset = '1') then
			HEX3_reg <= X"00";
		elsif (clock'EVENT) AND (clock = '1') then
			if (EN_HEX3_W = '1') then
				HEX3_reg <= Din_HEX3(7 downto 0);
			end if;
		end if;
	end process;

	process(reset, clock, EN_HEX4_W)
	begin
		if (reset = '1') then
			HEX4_reg <= X"00";
		elsif (clock'EVENT) AND (clock = '1') then
			if (EN_HEX4_W = '1') then
				HEX4_reg <= Din_HEX4(7 downto 0);
			end if;
		end if;
	end process;
	
	process(reset, clock, EN_HEX5_W)
	begin
		if (reset = '1') then
			HEX5_reg <= X"00";
		elsif (clock'EVENT) AND (clock = '1') then
			if (EN_HEX5_W = '1') then
				HEX5_reg <= Din_HEX5(7 downto 0);
			end if;
		end if;
	end process;


	LEDR_out <= LEDR_reg;
	HEX0_out <= HEX0_reg;
	HEX1_out <= HEX1_reg;
	HEX2_out <= HEX2_reg;
	HEX3_out <= HEX3_reg;
	HEX4_out <= HEX4_reg;
	HEX5_out <= HEX5_reg;	
	
END behavior;

